//
//  DataManager.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "DataManager.h"
#import "Encryptor.h"
#import "DataStorage.h"
#import "ListInteractor.h"
#import "GlobalRouter.h"
#import "ShortMessageEntity.h"
#import "MessageViewInteractor.h"
#import "CommonProcs.h"

#import "ModalDialogViewController.h"

@implementation DataManager

//@synthesize interactor;

/*
-(id)initWithInteractor:(ListInteractor*)inter
{
    if (self = [super init]) {
        self.interactor = inter;
    }
    return self;
}
*/

static bool sendPending = NO;

-(void)getShortMessagesForBox:(boxTypes)btType
{
    //DataStorage* dStore = [[DataStorage alloc] initWithManager:self];
    [[[GlobalRouter sharedManager] getListRouter].dataStore readShortMessagesForBox:btType];
}

-(void)getNextShortMessagesForBox:(boxTypes)btType
{
    [[[GlobalRouter sharedManager] getListRouter].dataStore readNextShortMessagesForBox:btType];
}

-(void)getShortMessagesForBoxWithFilter:(boxTypes)btType filter:(NSString*)filter
{
    [[[GlobalRouter sharedManager] getListRouter].dataStore loadNMessagesWithFilter:10 forBox:btType filter:filter];
}

-(void)dataReady:(NSArray*)data error:(NSString *)error forSettings:(NSString*)settingsID
{
    if (!(error == nil || [error isEqualToString:@""]) && data !=nil) {
        // No need to update
        
        [[[GlobalRouter sharedManager] getListRouter].interactor dataReady:nil error:[NSString stringWithFormat:@"%@: %@", settingsID,error]];
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        //[CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Decrypting...", nil) stopButton:NO];
        [CommonProcs setMessageInProgress:NSLocalizedString(@"Decrypting...", nil)];
    });
    
    // Get ShortMessageEntity
    NSMutableArray* ret = [[NSMutableArray alloc] init];
    
    int newMessagesCount = 0;
    
    BOOL useSent = NO;
    if ([GlobalRouter sharedManager].currentBox == btUseName) {
        NSArray* keys = [[GlobalRouter sharedManager].otherFolders allKeysForObject:[GlobalRouter sharedManager].currentBoxPath];
        if (keys.count > 0) {
            useSent = [[keys firstObject] rangeOfString:NSLocalizedString(@"Sent", nil)].location != NSNotFound;
        }
    }
    
    for (MCOIMAPMessage *message in data) {
        ShortMessageEntity* tmp = [[ShortMessageEntity alloc]init];
        
        tmp.settingsID = settingsID;
        
        if ([GlobalRouter sharedManager].currentBox == btSent || useSent) {
            MCOAddress* toAddr = [message.header.to objectAtIndex:0];
            tmp.fromAddress = toAddr.mailbox;
            tmp.fromName = NSLocalizedString(@"Me", nil);// toAddr.displayName;
            tmp.toAddress = message.header.from.mailbox;
        }else{
            tmp.fromAddress = message.header.from.mailbox;
            tmp.fromName = message.header.from.displayName;
            MCOAddress* toAddr = [message.header.to objectAtIndex:0];
            tmp.toAddress = toAddr.mailbox;
        }
        
        tmp.date = message.header.date;
        
        // CHECK IF encrypted
        NSString* subj = message.header.subject;
        tmp.flags = mfNone;
        tmp.size = message.size;
        
        BOOL encrypted = NO;
        if ([subj rangeOfString:signature].location != NSNotFound){
            encrypted = YES;
            tmp.encType = enTypePassword;
        }else if ([subj rangeOfString:signatureCert].location != NSNotFound){
            encrypted = YES;
            tmp.encType = enTypeCertificate;
        }else if ([subj rangeOfString:signatureTransferCert].location != NSNotFound){
            encrypted = YES;
            tmp.encType = enTypePasswordForCert;
        }else{
            encrypted = NO;
            tmp.encType = enTypeNone;
        }
        
        if (!encrypted) {
            tmp.flags |= mfNonEncrypted;
            tmp.subject = message.header.subject;
        }else{
            MCOAddress* toAddr = [message.header.to objectAtIndex:0];
            //NSLog(@"Decrypted with %@",toAddr.mailbox.lowercaseString);
            NSString* toKey;
            if (toAddr == nil) {
                toKey = @"";
            }else{
                toKey = toAddr.mailbox.lowercaseString;
            }
            Encryptor* enc = [[Encryptor alloc] initWithSimpleKey:toKey];
            if (subj.length <= signature.length+8) {
                tmp.subject = @"Invalid subj";
                tmp.salt = @"";
            }else{
                NSData* subjData = [enc dataFromBase64:[subj substringFromIndex:signature.length+8]];
                tmp.subject = [enc decryptAESString:subjData];
                tmp.salt = [subj substringWithRange:NSMakeRange(signature.length, 8)];
            }
        }
        
        tmp.messageID = [NSString stringWithFormat:@"%d",message.uid];// .header.messageID;
        if (!(message.flags & MCOMessageFlagSeen)) {
            tmp.flags |= mfNew;
            newMessagesCount++;
        }
        if (message.flags & MCOMessageFlagFlagged) {
            tmp.flags |= mfFavourite;
        }
        if (message.attachments.count > 0) {
            tmp.flags |= mfHasAttachment;
        }
        [ret addObject:tmp];
        tmp = nil;
        
        //for(MCOIMAPPart* part in message.attachments){
        //    NSLog(part.partID);
        //}
    }
    
    [GlobalRouter sharedManager].newMessages = newMessagesCount;
    if (error != nil) {
        error = [NSString stringWithFormat:@"%@: %@", settingsID,error];
    }
    [[[GlobalRouter sharedManager] getListRouter].interactor dataReady:ret error:error];
}

-(void)fullMessageReady:(NSData*)data forShort:(ShortMessageEntity*)sMessage error:(NSString *)error pin:(NSString *)pin
{
    if (data == nil) {
        [[[GlobalRouter sharedManager] getMessageRouter].interactor dataReady:nil error:error];
        return;
    }
    
    [CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Decrypting...", nil) stopButton:NO];
#warning Change it!
    [CommonProcs hideProgress];
    
    MCOMessageParser *messageParser = [[MCOMessageParser alloc] initWithData:data];
    NSString *msgPlainBody = [messageParser plainTextBodyRenderingAndStripWhitespace:YES];// htmlBodyRendering];
    
    FullMessageEntity* tmp = [[FullMessageEntity alloc] init];
    tmp.toAddress = sMessage.toAddress;
    tmp.fromAddress = sMessage.fromAddress;
    tmp.fromName = sMessage.fromName;
    tmp.date = sMessage.date;
    tmp.subject = sMessage.subject;
    tmp.encType = sMessage.encType;
    
    tmp.messageID = sMessage.messageID;
    tmp.flags = sMessage.flags;
    
    if(tmp.flags & mfNonEncrypted){
        tmp.messageBody = [messageParser htmlBodyRendering]; //msgPlainBody;
        
        for (MCOAttachment* att in [messageParser attachments]) {
            if (tmp.attachments == nil) {
                tmp.attachments = [[NSMutableArray alloc] init];
            }
            [tmp.attachments addObject:[self saveDataToFile:att.data]];
        }
    }else{
        // Decode the message
        NSString* stringCert = pin;
        if (sMessage.encType == enTypeCertificate) {
            stringCert = [self getPinForMessage:sMessage pin:pin pinTo:NO];
        }
        if(stringCert == nil || [stringCert  isEqualToString: INVALID_CERT]){
            stringCert = pin;
        }
        //Encryptor* enc = [[Encryptor alloc] initWithKey:stringCert];
        Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:stringCert salt:sMessage.salt];
        NSRange pos = [msgPlainBody rangeOfString:@" - "];
        NSString* newBody;
        if (pos.location == NSNotFound) {
            newBody = msgPlainBody;
        }else
            newBody = [msgPlainBody substringToIndex:pos.location];
        
        NSData* body = [enc dataFromBase64:newBody];
        tmp.messageBody = [enc decryptAESString:body];
        if ([tmp.messageBody isEqualToString:MESSAGE_INVALID_PWD]) {
            // Most likely wrong passworg
            tmp.messageBody = NSLocalizedString(@"Message not available", nil);
            error = NSLocalizedString(@"Message not available", nil);
        }
        
        for (MCOAttachment* att in [messageParser attachments]) {
            @autoreleasepool {
                if (tmp.attachments == nil) {
                    tmp.attachments = [[NSMutableArray alloc] init];
                }
                NSData* decoded = [enc decryptAESData:att.data];
                [tmp.attachments addObject:[self saveDataToFile:decoded]];
                decoded = nil;
            }
        }
    }
    [[[GlobalRouter sharedManager] getMessageRouter].interactor dataReady:[NSArray arrayWithObjects:tmp,nil] error:error];
}

-(NSString*)getPinForMessage:(ShortMessageEntity*)sMessage pin:(NSString*)pin pinTo:(BOOL)pinTo
{
    
    NSString* ret = nil;
    // Get pin from settings
    UserInfoDataManager* userDataMan = [[UserInfoDataManager alloc] init];
    NSData* data = [userDataMan getKeyFor:sMessage.fromAddress pin:[GlobalRouter sharedManager].pin keyTo:pinTo forDate:sMessage.date];
    if (data == nil) {
        ret = nil;
    }else{
        Encryptor* pinEnc = [[Encryptor alloc] initWithStrongerKey:pin salt:sMessage.fromAddress];
        //NSData* cert = [pinEnc decryptAESData:data];
        //ret = [pinEnc base64FromData:cert];
        ret = [pinEnc decryptAESString:data];
        if (ret == nil || [ret isEqualToString:@""]) {
            // Cert found, but pin is wrong - ask what to do!
            ret = INVALID_CERT;
        }
    }
    return ret;
}

-(NSString*)saveDataToFile:(NSData*)data
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tmpDirectory = NSTemporaryDirectory();
    NSString *path = [tmpDirectory stringByAppendingPathComponent:@"temp.jpg"];
    int ind = 1;
    while ([fileManager fileExistsAtPath:path]) {
        NSString* theFileName = [[@"test.jpg" lastPathComponent] stringByDeletingPathExtension];
        NSString* ext = [@"test.jpg" pathExtension];
        NSString* version = [NSString stringWithFormat:@"%@-%d.%@",theFileName, ind, ext];
        path = [tmpDirectory stringByAppendingPathComponent:version];
        ind++;
    }
    [fileManager createFileAtPath:path contents:data attributes:nil];
    
    return path;
}

-(void)setProgress:(int)progress max:(int)max
{
    dispatch_async(dispatch_get_main_queue(), ^{
        /*if ([[GlobalRouter sharedManager] getListRouter] != nil) {
            [[[GlobalRouter sharedManager] getListRouter].interactor setProgress:progress max:max];
        }else{
            [[[GlobalRouter sharedManager] getMessageRouter].interactor setProgress:progress max:max];
        }*/
        
        //[CommonProcs showProgress:progress max:max inView:[[GlobalRouter sharedManager] getCurrentView]];
        [CommonProcs setProgress:progress max:max title:NSLocalizedString(@"Loading...", nil)];
    });
}

-(void)tellUpNoMoreButton
{
    [[[GlobalRouter sharedManager] getListRouter] noNeedForMore:YES];
}

-(FullMessageEntity*)getFullMessageFor:(ShortMessageEntity*)item PIN:(NSString *)pin forBox:(boxTypes)btType
{
    [[[GlobalRouter sharedManager] getListRouter].dataStore readFullMessageFor:item boxType:btType pin:pin];
    
    return nil;
    
    /*
    
    sleep(2);
    
    FullMessageEntity* fMess = [[FullMessageEntity alloc] init];
    fMess.fromAddress = item.fromAddress;
    fMess.fromName = item.fromName;
    fMess.date = item.date;
    fMess.subject = item.subject;
    fMess.messageBody = @"Hi there! this is a test message sent to you by a robot. Do not reply. Do not read. Delete it as soon as possible. Nevermind.\nLorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda.\nLorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda.\n\nLorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda.\n\nLorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda.\n\nLorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda.\n\nLorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda.\n\nTHAT'S ALL!";
    fMess.flags = item.flags;
    */
    /*
    // ==== MOVED TO TESTS ====
    ////// TEST encrypt-decrypt image and string
     
    Encryptor* cryptor = [[Encryptor alloc] initWithKey:@"111122223333444455556666777788"];
    
    // UIImage test
    NSData* jpeg = UIImageJPEGRepresentation(test, 0.6);
    NSData* encoded = [cryptor encryptAESData:jpeg];
    NSData* decoded = [cryptor decryptAESData:encoded];
    UIImage* test2 = [UIImage imageWithData:decoded];
    
    // String test
    NSString* testString = @"Test string!";
    NSData* encString = [cryptor encryptAESString:testString];
    NSString* encString64 = [cryptor base64FromData:encString];
    NSData* toDec64 = [cryptor dataFromBase64:encString64];
    NSString* decString = [cryptor decryptAESString:toDec64];
    NSLog(@"Output should match: %@->%@",testString, decString);
    
    */
    /*
    NSArray* atts;
    [[GlobalRouter sharedManager] setAssets: [DataManager defaultAssetsLibrary]];
    
    UIImage* test = [UIImage imageNamed:@"test"];
    NSData *data = UIImageJPEGRepresentation(test, 1.0);
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tmpDirectory = NSTemporaryDirectory();
    NSString *path = [tmpDirectory stringByAppendingPathComponent:@"test.jpg"];
    int ind = 1;
    while ([fileManager fileExistsAtPath:path]) {
        NSString* theFileName = [[@"test.jpg" lastPathComponent] stringByDeletingPathExtension];
        NSString* ext = [@"test.jpg" pathExtension];
        NSString* version = [NSString stringWithFormat:@"%@-%d.%@",theFileName, ind, ext];
        path = [tmpDirectory stringByAppendingPathComponent:version];
        ind++;
    }
    [fileManager createFileAtPath:path contents:data attributes:nil];

    
    __block ALAsset* im1;
    __block ALAsset* im2;
    __block ALAsset* im3;
    
    im1 = [[[GlobalRouter sharedManager]getAssets] objectAtIndex:0];
    im2 = [[[GlobalRouter sharedManager]getAssets] objectAtIndex:1];
    im3 = [[[GlobalRouter sharedManager]getAssets] objectAtIndex:2];
    
    int rand = arc4random()%1;
    if(rand == 0)
        atts = [[NSArray alloc] initWithObjects: path, im1, im2, im3, nil];
    else if(rand == 1)
        atts = [[NSArray alloc] initWithObjects: im1, im2, im3, im3, im2, im1, nil];
    else
        atts = [[NSArray alloc] init];
    
    fMess.attachments = [NSMutableArray arrayWithArray:atts];
    
    return fMess;
    
    */
}

-(void)deleteTempFilesFromMessage:(FullMessageEntity*)message
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tmpDirectory = NSTemporaryDirectory();
    NSError* error;
    for (NSObject* att in message.attachments) {
        if([att isKindOfClass:[NSString class]]){
            NSString *path = [tmpDirectory stringByAppendingPathComponent:(NSString*)att];
            [DataManager rewriteFileAtPath:path];
            [fileManager removeItemAtPath:path error:&error];
        }
    }
}

+(void)rewriteFileAtPath:(NSString*)path
{
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
    unsigned long long fileSize = [attributes fileSize];
    if (fileSize < 8) {
        return;
    }
    NSFileHandle *file;
    NSMutableData *data;
    const char *bytestring = "00000000";
    data = [NSMutableData dataWithBytes:bytestring length:strlen(bytestring)];
    file = [NSFileHandle fileHandleForUpdatingAtPath:path];
    for (int i=0; i<fileSize-8; i+=8) {
        //[file seekToFileOffset:i];
        [file writeData: data];
    }
    
    [file closeFile];
}

+(void)deleteTempFiles
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tmpDirectory = NSTemporaryDirectory();
    NSError *error = nil;
    for (NSString *file in [fileManager contentsOfDirectoryAtPath:tmpDirectory error:&error]) {
        NSString* path = [NSString stringWithFormat:@"%@%@", tmpDirectory, file];
        [DataManager rewriteFileAtPath:path];
        [fileManager removeItemAtPath:path error:&error];
    }
}

-(BOOL)sendMessage:(FullMessageEntity*)message pin:(NSString*)pin
{
    if ([pin.lowercaseString isEqualToString:NSLocalizedString(@"no", nil)] ||
        [pin.lowercaseString isEqualToString:NSLocalizedString(@"\"no\"", nil)]) {
        return [self sendPlainMessage:message];
    }
    if(!message.readyToSend){
        //Prepare message for sending - encrypt, attacments array should refer to encrypted files!
        NSString* mSignature = signature;
        NSString* cert;
        if (sendPending) {
            cert = pin;
            sendPending = NO;
        }else{
            cert = [self getPinForMessage:message pin:pin pinTo:YES];
            if ([cert  isEqualToString: INVALID_CERT] && message.encType != enTypePasswordForCert) {
                //
                sendPending = YES;
                tempMessage = message;
                tempPin = pin;
                
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error reading certificate",nil) message:[NSString stringWithFormat:NSLocalizedString(@"Use %@ as a PIN-code to send this message instead of the certificate?",nil), pin] delegate:self cancelButtonTitle:NSLocalizedString(@"NO",nil) otherButtonTitles:NSLocalizedString(@"YES",nil),nil];
                [alert setTag:100];
                [alert show];
                
                return NO;
            }
            if (!(cert == nil || [cert isEqualToString:@""]) && message.encType == enTypePassword) {
                // cert found, use it
                mSignature = signatureCert;
                message.encType = enTypeCertificate;
            }else{
                cert = pin;
            }
        }
        if (message.encType == enTypePasswordForCert) {
            mSignature = signatureTransferCert;
            cert = pin;
        }
        
        //Encryptor* enc = [[Encryptor alloc] initWithKey:cert];
        NSString* salt = [Encryptor generateSalt8Bytes];
        
        Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:cert salt:salt];
        
        Encryptor* encSimple = [[Encryptor alloc] initWithSimpleKey:message.toAddress.lowercaseString];
        //NSLog(@"Encrypted with %@",message.fromAddress.lowercaseString);
        
        message.subject = [NSString stringWithFormat:@"%@%@%@",mSignature,salt,[encSimple encryptToBase64:message.subject]];
        message.messageBody = [enc encryptToBase64:message.messageBody];
        
        // Attachments - they are assets - convert them to files and encrypt, return file names
        NSMutableArray* atts = [[NSMutableArray alloc] initWithCapacity:message.attachments.count];
        for (id asset in message.attachments) {
            @autoreleasepool {
                if ([asset isKindOfClass:[NSString class]]) {
                    // Already a path... we're resending message
                }else{
                    ALAssetRepresentation* rep = [asset defaultRepresentation];
                    UIImage* img = [self getImageFromAssetRep:rep];//[[UIImage alloc] initWithCGImage: [rep fullResolutionImage]];
                    
                    float cRatio = [[[GlobalRouter sharedManager] getComposeRouter].dataStore getJPEGCompression];
                    NSData* jpeg = UIImageJPEGRepresentation(img, cRatio);
                    NSData* encoded = [enc encryptAESData:jpeg];
                    NSString* path = [self getTempPathForImage];
                    [encoded writeToFile:path atomically:YES];
                    [atts addObject:path];
                }
            }
        }
        
        message.attachments = atts;
        message.readyToSend = YES;
    }
    [[[GlobalRouter sharedManager] getComposeRouter].dataStore sendMessage:message];
    
    return YES;
}

-(BOOL)sendPlainMessage:(FullMessageEntity*)message
{
    // Attachments - they are assets - convert them to files and encrypt, return file names
    NSMutableArray* atts = [[NSMutableArray alloc] initWithCapacity:message.attachments.count];
    for (id asset in message.attachments) {
        if ([asset isKindOfClass:[NSString class]]) {
            // Already path... we're resending message
        }else{
            ALAssetRepresentation* rep = [asset defaultRepresentation];
            UIImage* img = [self getImageFromAssetRep:rep];//[[UIImage alloc] initWithCGImage: [rep fullResolutionImage]];
            
            float cRatio = [[[GlobalRouter sharedManager] getComposeRouter].dataStore getJPEGCompression];
            NSData* jpeg = UIImageJPEGRepresentation(img, cRatio);
            NSString* path = [self getTempPathForImage];
            [jpeg writeToFile:path atomically:YES];
            [atts addObject:path];
        }
    }
    
    message.attachments = atts;
    message.readyToSend = YES;
    [[[GlobalRouter sharedManager] getComposeRouter].dataStore sendMessage:message];

    return YES;
}

-(UIImage*)getImageFromAssetRep:(ALAssetRepresentation*)assetRepresentation
{
    CGImageRef fullResImage = [assetRepresentation fullResolutionImage];
    NSString *adjustment = [[assetRepresentation metadata] objectForKey:@"AdjustmentXMP"];
    if (adjustment) {
        NSData *xmpData = [adjustment dataUsingEncoding:NSUTF8StringEncoding];
        CIImage *image = [CIImage imageWithCGImage:fullResImage];
        
        NSError *error = nil;
        NSArray *filterArray = [CIFilter filterArrayFromSerializedXMP:xmpData
                                                     inputImageExtent:image.extent
                                                                error:&error];
        CIContext *context = [CIContext contextWithOptions:nil];
        if (filterArray && !error) {
            for (CIFilter *filter in filterArray) {
                [filter setValue:image forKey:kCIInputImageKey];
                image = [filter outputImage];
            }
            fullResImage = [context createCGImage:image fromRect:[image extent]];
        }
    }
    UIImage *result = [UIImage imageWithCGImage:fullResImage
                                          scale:[assetRepresentation scale]
                                    orientation:(UIImageOrientation)[assetRepresentation orientation]];
    fullResImage = nil; // iOS bug, need to nil it or there is a memory leak
    return result;
}

-(void)messageSent:(FullMessageEntity*)message error:(NSString*)error
{
    [[[GlobalRouter sharedManager] getComposeRouter] sendingResult:error];
    if (error == nil || [error isEqualToString:@""]) {
        [self deleteTempFilesFromMessage:message];
    }
}

-(NSString*)getTempPathForImage
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tmpDirectory = NSTemporaryDirectory();
    NSString *path = [tmpDirectory stringByAppendingPathComponent:@"image.jpg"];
    int ind = 1;
    while ([fileManager fileExistsAtPath:path]) {
        NSString* theFileName = [[@"image.jpg" lastPathComponent] stringByDeletingPathExtension];
        NSString* ext = [@"image.jpg" pathExtension];
        NSString* version = [NSString stringWithFormat:@"%@-%d.%@",theFileName, ind, ext];
        path = [tmpDirectory stringByAppendingPathComponent:version];
        ind++;
    }
    
    return path;
}

// TEMP - called from global router's init proc
+ (NSMutableArray*)defaultAssetsLibrary
{
    //static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    NSMutableArray* tmpAssets = [@[] mutableCopy];
    
    //dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
        
        [library enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                if(result)
                {
                    // 3
                    [tmpAssets addObject:result];
                }
            }];
            
            // 4
            //NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
            //self.assets = [tmpAssets sortedArrayUsingDescriptors:@[sort]];
            
        } failureBlock:^(NSError *error) {
            NSLog(@"Error loading images %@", error);
        }];

    //});
    
    //sleep(2);
    
    return tmpAssets;
}

-(void)deleteMessage:(ShortMessageEntity *)message
{
    [[[GlobalRouter sharedManager] getListRouter].dataStore deleteMessage:message];
}

-(void)markAsRead:(ShortMessageEntity*)message
{
    [[[GlobalRouter sharedManager] getListRouter].dataStore setReadFlagForMessage:message];
}

-(void)toggleStarForMessage:(ShortMessageEntity*)message
{
    [[[GlobalRouter sharedManager] getListRouter].dataStore toggleStarForMessage:message];
}

-(int)readNewMessagesCount
{
    return [[[GlobalRouter sharedManager] getListRouter].dataStore readNewMessagesCount];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100)
    {
        if (buttonIndex == 0)
        {
            // cancel
            [self messageSent:tempMessage error:NSLocalizedString(@"Wrong pin", nil)];
            sendPending = NO;
            tempMessage = nil;
            tempPin = nil;
        }else{
            [self sendMessage:tempMessage pin:tempPin];
        }
    }
}

@end
