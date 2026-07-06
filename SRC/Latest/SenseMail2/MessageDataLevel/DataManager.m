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
#import "FolderInfo.h"
#import "SessionConnectorNew.h"
#import "SettingsEntity.h"

#import <ImageIO/ImageIO.h>

#import "ModalDialogViewController.h"
#if !LITE
#import "OneTimeCertInteractor.h"
#import "OneTimeCert.h"
#endif
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

-(void)setBadge
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        int nm = [[GlobalRouter sharedManager] getNewMessagesCount];
        if(nm >= 0)
            [UIApplication sharedApplication].applicationIconBadgeNumber = nm;
    });
}

-(void)getShortMessagesForBox:(boxTypes)btType
{
    [GlobalRouter sharedManager].newMessages = 0;
    //DataStorage* dStore = [[DataStorage alloc] initWithManager:self];
    [[[GlobalRouter sharedManager] getListRouter].dataStore readShortMessagesForBox:btType];
    
    //[self setBadge];
}

-(void)getNextShortMessagesForBox:(boxTypes)btType
{
    [[[GlobalRouter sharedManager] getListRouter].dataStore readNextShortMessagesForBox:btType];
    
    //[self setBadge];
}

-(void)getShortMessagesForBoxWithFilter:(boxTypes)btType filter:(NSString*)filter
{
    //[GlobalRouter sharedManager].newMessages = 0;
    //[[[GlobalRouter sharedManager] getListRouter].dataStore loadNMessagesWithFilter:10 forBox:btType filter:filter];
    [[[GlobalRouter sharedManager] getListRouter].dataStore readShortMessagesForBoxWithFilter:btType filter:filter];
    
    //[self setBadge];
}

-(void)readFullHeaderForMessage:(ShortMessageEntity*)message
{
    [[[GlobalRouter sharedManager] getListRouter].dataStore readFullHeaderForMessage:message completion:^(NSString* ret) {
            //NSLog(@"%@", ret);
            // NEED to push a view!
        
        [[GlobalRouter sharedManager] showMessageInfo:ret];
        }
     ];
    
    //[self deleteExpiredMessages];
}

-(void)dataReady:(NSArray*)data error:(NSString *)error forSettings:(NSString*)settingsID
{
    if (!(error == nil || [error isEqualToString:@""])){// && data !=nil) {
        // No need to update
        if([error containsString:@"The certificate for this server is invalid"]){
            NSString* emailAddr;
            for (SettingsEntity* sett in [GlobalRouter sharedManager].allSettings) {
                if ([sett.settingsName isEqualToString:settingsID]) {
                    emailAddr = sett.userName;
                    break;
                }
            }
                
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:[NSString stringWithFormat: NSLocalizedString(@"The SSL certificate for %@ is invalid", nil), emailAddr]
                                             message:NSLocalizedString(@"Disable certificate check for this session?", nil)
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                //__weak __typeof__(self) weakSelf = self;
                UIAlertAction* sendIt = [UIAlertAction
                                         actionWithTitle:NSLocalizedString(@"Yes",nil)
                                         style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction * action)
                                         {
                                             //__strong __typeof__(self) strongSelf = weakSelf;
                                             if(emailAddr && ![emailAddr isEqualToString:@""]){
                                                 [[[GlobalRouter sharedManager] getListRouter].dataStore setDoNotCheckForEmail:emailAddr];
                                             }
                                         }];
                [alert addAction:sendIt];
                
                UIAlertAction* cancel = [UIAlertAction
                                         actionWithTitle:NSLocalizedString(@"No",nil)
                                         style:UIAlertActionStyleCancel
                                         handler:^(UIAlertAction * action)
                                         {
                                             
                                         }];
                [alert addAction:cancel];
                
                UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
                alert.popoverPresentationController.sourceView = pView;
                alert.popoverPresentationController.sourceRect = pView.frame;
                [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
            });
        }else if([error containsString: [DataStorage noMoreMessages]]/*NSLocalizedString(@"No messages",nil)]*/){
            // Do not show "No messages" alert, it's redundant
            //[[[GlobalRouter sharedManager] getListRouter].interactor dataReady:nil error:nil];//[NSString stringWithFormat:@"%@: %@", settingsID,error]];
#if DEBUG
            NSLog(@"No messages for %@", settingsID);
#endif
        }else if([error containsString:[DataStorage fetchInProgress]]){
            // Do not show alert, it's redundant
#if DEBUG
            NSLog(@"Request in process for %@", settingsID);
#endif
        }else if([error containsString:@"User not found"] || [error containsString:@"Cancelled"] ){
                    // Do not show alert, it's redundant
        #if DEBUG
                    NSLog(@"User not found for %@", settingsID);
        #endif
        }else{
            [[[GlobalRouter sharedManager] getListRouter].interactor dataReady:nil error:[NSString stringWithFormat:@"%@: %@", settingsID,error]];
        }
        
        _nAccountsToWait--;
        
        if(_nAccountsToWait <= 0)
            [CommonProcs hideSmallWheel];
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
        //NSDictionary* tempD = [[GlobalRouter sharedManager].otherFolders valueForKey:[GlobalRouter sharedManager].currentAccount];
        NSDictionary* tempD = [[GlobalRouter sharedManager].otherFolders objectForKey:[GlobalRouter sharedManager].currentAccount];
        NSArray* flds = [tempD allValues];
        for (FolderInfo* fif in flds) {
            if (fif.folderType == btSent && [fif.folderPath isEqualToString:[GlobalRouter sharedManager].currentBoxPath]) {
                useSent = YES;
                break;
            }
        }
    }
    
    MCOIndexSet* uidsToDel = [[MCOIndexSet alloc] init];
    
    for (MCOIMAPMessage *message in data) {
        
        // Check protected filter
        if([[GlobalRouter sharedManager].currentFilter isEqualToString:filterProtected]){
            if ([message.header.subject rangeOfString:@"SM@1"].location == NSNotFound) {
                NSLog(@"Deleting...");
                continue;
            }
        }
        
        // Check if the message is expired
        if ([[message.header extraHeaderValueForName:@"Delay"] isEqualToString:@"1"]) {
            NSString* extra = [message.header extraHeaderValueForName:@"Comments"];
            NSDate* dt = [OneTimeCert getDateForString:extra];
            if (dt) {
                NSLog(@"Expiration date found = %@", extra);
                if ([dt compare:[NSDate date]] == NSOrderedAscending) {
                    // delete
                    [uidsToDel addIndex:message.uid];
                    if (!(message.flags & MCOMessageFlagSeen)) {
                        // Deleting unseen message
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSInteger badge = [UIApplication sharedApplication].applicationIconBadgeNumber;
                            badge--;
                            if (badge >= 0) {
                                [UIApplication sharedApplication].applicationIconBadgeNumber = badge;
                            }
                        });
                    }
                    NSLog(@"Expired message from %@ marked for deletion", message.header.from.displayName);
                    // Create a short message with some fields to identify it for deletion
                    //
                    ShortMessageEntity* tmp = [[ShortMessageEntity alloc] init];
                    tmp.messageID = [NSString stringWithFormat:@"%d",message.uid];
                    if ([GlobalRouter sharedManager].currentBox == btSent || useSent) {
                        MCOAddress* toAddr = [message.header.to objectAtIndex:0];
                        tmp.fromAddress = toAddr.mailbox;
                        tmp.fromName = NSLocalizedString(@"Me", nil);// toAddr.displayName;
                        tmp.toAddress = message.header.from.mailbox;
                    }else{
                        tmp.fromAddress = message.header.from.mailbox;
                        tmp.fromName = message.header.from.displayName;
                        MCOAddress* toAddr;
                        if (message.header.to.count == 1) {
                            toAddr = [message.header.to objectAtIndex:0];
                            tmp.toAddress = toAddr.mailbox;
                        }else{
                            NSArray* addressTmp = [[GlobalRouter sharedManager].accountsNames allKeysForObject:settingsID];
                            tmp.toAddress = [addressTmp firstObject];
                        }
                    }
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                        [self deleteMessage:tmp];
                    });
                    continue;
                }
            }
        }
        
        ShortMessageEntity* tmp = [[ShortMessageEntity alloc] init];
        tmp.mutationNumber = 0;
        //NSLog(@"X-MAILER = %@", message.header.allExtraHeadersNames);
        NSString* extra = [message.header extraHeaderValueForName:@"Disposition-Notification-To"];
        if(extra){
            // "Name <email@addre.ss>" from thunderbird. from others - ???
            NSString* addrrr;
            NSRange first = [extra rangeOfString:@"<"];
            if (first.location != NSNotFound) {
                NSRange last = [extra rangeOfString:@">"];
                if (last.location != NSNotFound) {
                    addrrr = [extra substringWithRange:NSMakeRange(first.location+1, last.location-first.location-1)];
                }
            }else{
                addrrr = extra;
            }
            //NSLog(@"Disposition-Notification-To = %@",addrrr);
            tmp.readReceiptTo = addrrr;
        }else{
            tmp.readReceiptTo = nil;
        }
        
        NSString* comm = [message.header extraHeaderValueForName:@"Comments"];
        if(comm){
            // Check the date
            
            tmp.expireOTCon = comm;
            NSLog(@"Expiration date found %@",comm);
        }else{
            tmp.expireOTCon = nil;
        }
        
        tmp.settingsID = settingsID;
        
        if ([GlobalRouter sharedManager].currentBox == btSent || useSent) {
            MCOAddress* toAddr = [message.header.to objectAtIndex:0];
            tmp.fromAddress = toAddr.mailbox;
            tmp.fromName = NSLocalizedString(@"Me", nil);// toAddr.displayName;
            tmp.toAddress = message.header.from.mailbox;
        }else{
            tmp.fromAddress = message.header.from.mailbox;
            tmp.fromName = message.header.from.displayName;
            MCOAddress* toAddr;
            if (message.header.to.count == 1) {
                toAddr = [message.header.to objectAtIndex:0];
                tmp.toAddress = toAddr.mailbox;
            }else{
                NSArray* addressTmp = [[GlobalRouter sharedManager].accountsNames allKeysForObject:settingsID];
                tmp.toAddress = [addressTmp firstObject];
            }
            if(message.header.replyTo.count > 0){
                MCOAddress* ra = [message.header.replyTo objectAtIndex:0];
                if(ra)tmp.replyToAddress = ra.mailbox;
            }else{
                tmp.replyToAddress = tmp.fromAddress;
            }
        }
        
        if(tmp.fromAddress == nil){
            tmp.fromAddress = @"";
        }
        if(tmp.toAddress == nil){
            tmp.toAddress = @"";
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
        }else if ([subj rangeOfString:signatureOTC].location != NSNotFound){
            encrypted = YES;
            tmp.encType = enTypeOTC;
        }else if ([subj rangeOfString:signatureTransferCert].location != NSNotFound){
            encrypted = YES;
            tmp.encType = enTypePasswordForCert;
        }else if ([subj rangeOfString:signatureMutable].location != NSNotFound){
            encrypted = YES;
            tmp.encType = enTypeMutablePassword;
        }else if ([subj rangeOfString:signatureMutable2].location != NSNotFound){
            encrypted = YES;
            tmp.encType = enTypeMutablePassword2;
        }else if ([subj rangeOfString:signatureMutableCert].location != NSNotFound){
            encrypted = YES;
            tmp.encType = enTypeMutableCertificate;
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
            if (subj.length <= signature.length+8/*salt*/) {
                tmp.subject = @"Invalid subj";
                tmp.salt = @"";
            }else{
                int additionalOffset = 0;
                if (tmp.encType == enTypeOTC) {
                    additionalOffset = 6;
                    NSString* keyID = [subj substringWithRange:NSMakeRange(signatureOTC.length,6)];
                    tmp.keyID = keyID;
                }else if(tmp.encType == enTypeMutablePassword){
                    additionalOffset = mutationLength;
                    NSString* mNumber = [subj substringWithRange:NSMakeRange(signatureMutable.length,mutationLength)];
                    //NSScanner* scanner = [NSScanner scannerWithString:mNumber];
                    uint nm = [Encryptor intFromBase26:mNumber];
                    //[scanner scanHexInt:&nm];
                    tmp.mutationNumber = nm + mutationOffset;
                }else if(tmp.encType == enTypeMutablePassword2){
                    additionalOffset = mutationLength;
                    NSString* mNumber = [subj substringWithRange:NSMakeRange(signatureMutable2.length,mutationLength)];
                    //NSScanner* scanner = [NSScanner scannerWithString:mNumber];
                    uint nm = [Encryptor intFromBase36:mNumber];
                    //[scanner scanHexInt:&nm];
                    tmp.mutationNumber = nm + mutationOffset2;
                }else if(tmp.encType == enTypeMutableCertificate){
                    additionalOffset = mutationLength;
                    NSString* mNumber = [subj substringWithRange:NSMakeRange(signatureMutableCert.length,mutationLength)];
                    //NSScanner* scanner = [NSScanner scannerWithString:mNumber];
                    uint nm = [Encryptor intFromBase26:mNumber];
                    //[scanner scanHexInt:&nm];
                    tmp.mutationNumber = nm + mutationOffset;
                }
                NSData* subjData = [enc dataFromBase64:[subj substringFromIndex:(signature.length+additionalOffset)]];//+8]];
                tmp.subject = [enc decryptAESString:subjData];
                if(tmp.subject == nil){
                    tmp.subject = NSLocalizedString(@"Invalid subject", nil);
                }
                //tmp.salt = [subj substringWithRange:NSMakeRange(signature.length, 8)];
            }
        }
        
        NSString* imp = [message.header extraHeaderValueForName:@"X-Priority"];
        if(imp){
            int priority = (int)[[imp substringToIndex:1] integerValue];
            if (priority < 3) {
                tmp.flags |= mfImportant;
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
        if (message.flags & MCOMessageFlagAnswered) {
            tmp.flags |= mfAnswered;
        }
        if (message.attachments.count > 0 || message.htmlInlineAttachments.count > 0) {
            tmp.flags |= mfHasAttachment;
        }
        [ret addObject:tmp];
        tmp = nil;
        
        //for(MCOIMAPPart* part in message.attachments){
        //    NSLog(part.partID);
        //}
    }
    
    [GlobalRouter sharedManager].newMessages += newMessagesCount;
    if (error != nil) {
        error = [NSString stringWithFormat:@"%@: %@", settingsID,error];
    }
    
    _nAccountsToWait--;
    if(_nAccountsToWait < 0)_nAccountsToWait = 0;
    
    if(_nAccountsToWait == 0){
        [CommonProcs hideSmallWheel];
        
        [self deleteExpiredMessages];
        //[self setBadge];
    }
    
    [[[GlobalRouter sharedManager] getListRouter].interactor dataReady:ret error:error];
}

// Used to show an error. Not used any more.
-(void)fullMessageReady:(NSData*)data forShort:(ShortMessageEntity*)sMessage error:(NSString *)error pin:(NSMutableString *)pin
{
    if (data == nil) {
        [[[GlobalRouter sharedManager] getMessageRouter].interactor dataReady:nil error:error];
        return;
    }
    
    [CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Decrypting...", nil) stopButton:NO];
//#warning Change it!
    [CommonProcs hideProgress];
#ifdef DEBUG
#warning Linker warnings suppressed (-w in build settings-other linker flags)
#endif
    
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
            [tmp.attachments addObject:[self saveDataToFile:att.data fileName:att.filename]];
        }
    }else{
        // Decode the message
        NSMutableString* stringCert = pin;
#if !LITE
        if (sMessage.encType == enTypeCertificate) {
            stringCert = [self getPinForMessage:sMessage pin:pin pinTo:NO];
        }else if (sMessage.encType == enTypeOTC) {
            // Get the key ID and read that key
            // KeyID is stored... where? In the subject line, after the signature, 6 symbols
            OneTimeCert* otc = [[GlobalRouter sharedManager].oneTimeCertInteractor getCertWithID:sMessage.keyID from:sMessage.fromAddress];
            stringCert = [otc getCertString];
        }
#endif
        if(stringCert == nil || [stringCert  isEqualToString: INVALID_CERT]){
            stringCert = pin;
        }
        //Encryptor* enc = [[Encryptor alloc] initWithKey:stringCert];
        Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:stringCert]; //salt:sMessage.salt];
        // Indicate it is a mail message (for a coder)
        enc.isMail = YES;
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
                [tmp.attachments addObject:[self saveDataToFile:decoded fileName:att.filename]];
                decoded = nil;
            }
        }
        enc.isMail = NO;
    }
    [[[GlobalRouter sharedManager] getMessageRouter].interactor dataReady:[NSArray arrayWithObjects:tmp,nil] error:error];
}

////////////////////////////
-(void)fullParsedMessageReady:(MCOMessageParser*)messageParser forShort:(ShortMessageEntity*)sMessage error:(NSString *)error pin:(NSMutableString *)pin
{
    [self fullParsedMessageReady:messageParser forShort:sMessage error:error pin:pin preAttachments:nil html:nil];
}

-(void)fullParsedMessageReady:(MCOMessageParser*)messageParser forShort:(ShortMessageEntity*)sMessage error:(NSString *)error pin:(NSMutableString *)pin preAttachments:(NSArray*)preAttachments html:(NSString*)html
{
    if (messageParser == nil) {
        [[[GlobalRouter sharedManager] getMessageRouter].interactor dataReady:nil error:error];
        return;
    }
    
    //[CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Decrypting...", nil) stopButton:NO];
    [CommonProcs setMessageInProgress:NSLocalizedString(@"Decrypting...", nil)];
    
    //MCOMessageParser *messageParser = [[MCOMessageParser alloc] initWithData:data];
    NSString *msgPlainBody = [messageParser plainTextBodyRenderingAndStripWhitespace:YES];// htmlBodyRendering];
    
    FullMessageEntity* tmp = [[FullMessageEntity alloc] init];
    tmp.toAddress = sMessage.toAddress;
    tmp.fromAddress = sMessage.fromAddress;
    tmp.fromName = sMessage.fromName;
    tmp.replyToAddress = sMessage.replyToAddress;
    tmp.date = sMessage.date;
    tmp.subject = sMessage.subject;
    tmp.encType = sMessage.encType;
    tmp.keyID = sMessage.keyID;
    tmp.expireOTCon = sMessage.expireOTCon;
    
    tmp.messageID = sMessage.messageID;
    tmp.flags = sMessage.flags;
    tmp.size = sMessage.size;
    
    tmp.mutationNumber = sMessage.mutationNumber;
    
    BOOL certNotAvailable = NO;
    if(tmp.flags & mfNonEncrypted){
        tmp.messageBody = html?html:[messageParser htmlBodyRendering]; //msgPlainBody;
        if (preAttachments) {
            if (tmp.attachments == nil) {
                tmp.attachments = [[NSMutableArray alloc] init];
            }
            for (MCOAbstractPart* part in preAttachments) {
                [tmp.attachments addObject:part.filename];
            }
        }
        for (MCOAttachment* att in [messageParser attachments]) {
            if (tmp.attachments == nil) {
                tmp.attachments = [[NSMutableArray alloc] init];
            }
            [tmp.attachments addObject:[self saveDataToFile:att.data fileName:att.filename]];
        }
        
        for (MCOAttachment* att in [messageParser htmlInlineAttachments]) {
            if (tmp.attachments == nil) {
                tmp.attachments = [[NSMutableArray alloc] init];
            }
            [tmp.attachments addObject:[self saveDataToFile:att.data fileName:att.filename]];
        }
    }else{
        // Decode the message
        NSMutableString* stringCert = pin;
#if !LITE
        if (sMessage.encType == enTypeCertificate || sMessage.encType == enTypeMutableCertificate) {
            stringCert = [self getPinForMessage:sMessage pin:pin pinTo:NO]; // was no?
        }else if (sMessage.encType == enTypeOTC) {
            // Get the key ID and read that key
            // KeyID is stored... where? In the subject line, after the signature, 6 symbols
            OneTimeCert* otc = [[GlobalRouter sharedManager].oneTimeCertInteractor getCertWithID:sMessage.keyID from:sMessage.toAddress];
            if (!otc) {
                // Cert is unavailable, probably expired
                certNotAvailable = YES;
            }else{
                stringCert = [otc getCertString];
            }
            if (!stringCert) {
                stringCert = [NSMutableString stringWithString: @""]; // gonna be wrong pwd, cert expired
            }
            // Check and set the expiration date
            if (!([sMessage.expireOTCon isEqualToString:@""] || sMessage.expireOTCon == nil)) {
                if ([otc.expirationDate isEqualToString:@""] || otc.expirationDate == nil) {
                    [[GlobalRouter sharedManager].oneTimeCertInteractor setExpirationTimeForCert:otc.certID expiration:[OneTimeCert getDateForString:sMessage.expireOTCon] dateUsed:[NSDate date] from:sMessage.toAddress];
                }
            }
        }
#endif
        if(stringCert == nil || [stringCert  isEqualToString: INVALID_CERT]){
            stringCert = pin;
        }
        if (certNotAvailable) {
            tmp.messageBody = NSLocalizedString(@"Cannot find a One-Time Certificate for the message.\nMost likely it is expired and has been deleted.", nil);
            error = tmp.messageBody;
        }else{
            Encryptor* enc;// = [[Encryptor alloc] initWithKey:stringCert];
            if (sMessage.mutationNumber > 0) {
                enc = [[Encryptor alloc] initWithMutableKey:stringCert mutations:sMessage.mutationNumber];
            }else{
                enc = [[GlobalRouter sharedManager] getEncoderForPin:stringCert]; //salt:sMessage.salt];
            }
            
            // Indicate it is a mail message (for a coder)
            enc.isMail = YES;
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
                    [tmp.attachments addObject:[self saveDataToFile:decoded fileName:att.filename]];
                    decoded = nil;
                }
            }
            
            for (MCOAttachment* att in [messageParser htmlInlineAttachments]) {
                @autoreleasepool {
                    if (tmp.attachments == nil) {
                        tmp.attachments = [[NSMutableArray alloc] init];
                    }
                    NSData* decoded = [enc decryptAESData:att.data];
                    if(decoded){
                        [tmp.attachments addObject:[self saveDataToFile:decoded fileName:att.filename]];
                        decoded = nil;
                    }
                }
            }
            
            if (preAttachments) {
                if (tmp.attachments == nil) {
                    tmp.attachments = [[NSMutableArray alloc] init];
                }
                for (MCOAbstractPart* part in preAttachments) {
                    [tmp.attachments addObject:@"Loading"];
                }
            }
            enc.isMail = NO;
        }
    }
    
    [CommonProcs hideProgress];
    
    [[[GlobalRouter sharedManager] getMessageRouter].interactor dataReady:[NSArray arrayWithObjects:tmp,nil] error:error];
}
//////////////////////////////////
#pragma mark Certificates

-(NSMutableString*)getPinForAddress:(NSString*)address pin:(NSMutableString*)pin pinTo:(BOOL)pinTo
{
    
    NSMutableString* ret = nil;
#if !LITE
    // Get pin from settings
    UserInfoDataManager* userDataMan = [[UserInfoDataManager alloc] init];
    NSData* data = [userDataMan getKeyFor:address pin:[GlobalRouter sharedManager].pin forDate:[NSDate date]];
    if (data == nil) {
        ret = nil;
    }else{
        Encryptor* pinEnc = [[Encryptor alloc] initWithStrongerKey:pin]; //salt:address];
        //NSData* cert = [pinEnc decryptAESData:data];
        //ret = [pinEnc base64FromData:cert];
        ret = [pinEnc decryptAESString:data];
        if (ret == nil || [ret isEqualToString:@""] || [ret isEqualToString: MESSAGE_INVALID_PWD]) {
            // Cert found, but pin is wrong - ask what to do!
            ret = [NSMutableString stringWithString: INVALID_CERT];
        }
    }
#endif
    return ret;
}

-(NSMutableString*)getPinForMessage:(ShortMessageEntity*)sMessage pin:(NSMutableString*)pin pinTo:(BOOL)pinTo
{
    
    NSMutableString* ret = nil;
#if !LITE
    // Get pin from settings
    UserInfoDataManager* userDataMan = [[UserInfoDataManager alloc] init];
    NSString* useAddress = pinTo?sMessage.toAddress:sMessage.fromAddress;
    NSData* data = [userDataMan getKeyFor:useAddress pin:[GlobalRouter sharedManager].pin forDate:sMessage.date];
    if (data == nil) {
        ret = nil; // or try setting a received pin? Will not be of much help since it is encrypted by cert, not by pin
    }else{
        Encryptor* pinEnc = [[Encryptor alloc] initWithStrongerKey:pin]; //salt:useAddress];
        //NSData* cert = [pinEnc decryptAESData:data];
        //ret = [pinEnc base64FromData:cert];
        ret = [pinEnc decryptAESString:data];
        if (ret == nil || [ret isEqualToString:@""] || [ret isEqualToString: MESSAGE_INVALID_PWD]) {
            // Cert found, but pin is wrong - ask what to do!
            ret = [NSMutableString stringWithString: INVALID_CERT];
        }
    }
#endif
    return ret;
}

-(NSString*)saveDataToFile:(NSData*)data fileName:(NSString*)filename
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tmpDirectory = NSTemporaryDirectory();
    NSString *path = [tmpDirectory stringByAppendingPathComponent:filename];// @"temp.jpg"];
    int ind = 1;
    while ([fileManager fileExistsAtPath:path]) {
        //NSString* theFileName = [[@"test.jpg" lastPathComponent] stringByDeletingPathExtension];
        NSString* theFileName = [[filename lastPathComponent] stringByDeletingPathExtension];
        //NSString* ext = [@"test.jpg" pathExtension];
        NSString* ext = [filename pathExtension];
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

-(FullMessageEntity*)getFullMessageFor:(ShortMessageEntity*)item PIN:(NSMutableString *)pin forBox:(boxTypes)btType
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

+(void)deleteTempFilesFromMessage:(FullMessageEntity*)message
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //NSString *tmpDirectory = NSTemporaryDirectory();
    NSError* error;
    for (NSObject* att in message.attachments) {
        if([att isKindOfClass:[NSString class]]){
            //NSString *path = [tmpDirectory stringByAppendingPathComponent:(NSString*)att];
            [DataManager rewriteFileAtPath:(NSString*)att];
            [fileManager removeItemAtPath:(NSString*)att error:&error];
#if DEBUG
            if(error)NSLog(@"Error deleting file %@ %@", att, error.localizedDescription);
#endif
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
    //const char *bytestring = "00000000";
    long step;
    char* buf;
    if (fileSize >= 256*1024) {
        step = 256*1024;
        buf = malloc(256*1024);
        memset(buf, 0, step);
        data = [NSMutableData dataWithBytesNoCopy:buf length:step];
    }else{
        step = (long)fileSize;
        buf = malloc((long)fileSize);
        memset(buf, 0, step);
        data = [NSMutableData dataWithBytesNoCopy:buf length:step];
    }
    
    file = [NSFileHandle fileHandleForUpdatingAtPath:path];
    for (int i=0; i<fileSize-step; i+=step) {
        //[file seekToFileOffset:i];
        @try {
            [file writeData: data];
        } @catch (NSException *exception) {
            break;
        }
    }
    data = nil;
    //free(buf); // NSData will free it as it was init'ed with NoCopy
    [file closeFile];
}

// Rewriting ones takes about 3 seconds for ~400 Mb file on iPhone 6S
+(void)deleteTempFiles
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tmpDirectory = NSTemporaryDirectory();
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        NSError *error = nil;
        for (NSString *file in [fileManager contentsOfDirectoryAtPath:tmpDirectory error:&error]) {
            NSString* path = [NSString stringWithFormat:@"%@%@", tmpDirectory, file];
                [DataManager rewriteFileAtPath:path];
                NSError *error2 = nil;
                [fileManager removeItemAtPath:path error:&error2];
        }
    });
    //sleep(5);
}

// Message pin - check if there's a certificate for that pin&recipient
// If use OTC, pin is OTC ready to use
-(BOOL)sendMessage:(FullMessageEntity*)message pin:(NSMutableString*)pin
{
    if ([pin.lowercaseString isEqualToString:NSLocalizedString(@"no", nil).lowercaseString] ||
        [[pin.lowercaseString stringByReplacingOccurrencesOfString:@"\"" withString:@""] isEqualToString:NSLocalizedString(@"no", nil).lowercaseString] || [pin.lowercaseString isEqualToString:@"no"]) {
        return [self sendPlainMessage:message];
    }
    if(!message.readyToSend){
        //Prepare message for sending - encrypt, attacments array should refer to encrypted files!
        NSString* mSignature = signature;
        NSMutableString* cert;
        NSString* otcID = @"";
        if(message.encType == enTypeOTC){
            cert = pin;
            mSignature = signatureOTC;
            otcID = message.keyID;
        }else if (sendPending) {
            cert = pin;
            if (message.encType == enTypeMutablePassword2) {
                cert = pin;
                mSignature = signatureMutable2;
                otcID = [Encryptor getTheNumberBase36:message.mutationNumber];
                // Check if the number is longer than 4 symbols
                if (otcID.length > 4) {
                    otcID = [otcID substringToIndex:4];
                    uint nm = [Encryptor intFromBase36:otcID];
                    message.mutationNumber = nm;
                }
            }else if (message.mutationNumber > 0) {
                cert = pin;
                message.encType = enTypeMutablePassword;
                mSignature = signatureMutable;
                otcID = [Encryptor getTheNumberBase26:message.mutationNumber];
                // Check if the number is longer than 4 symbols
                if (otcID.length > 4) {
                    otcID = [otcID substringToIndex:4];
                    uint nm = [Encryptor intFromBase26:otcID];
                    message.mutationNumber = nm;
                }
            }
            sendPending = NO;
        }else{
            cert = [self getPinForMessage:message pin:pin pinTo:YES];
            if ([cert isEqualToString:INVALID_CERT] && message.encType != enTypePasswordForCert) {
                //
                sendPending = YES;
                tempMessage = message;
                tempPin = pin;
                __weak __typeof__(self) weakSelf = self;
                dispatch_async(dispatch_get_main_queue(), ^{ // All the UIAlertController stuff should be on the main thread, overwise we'll get warnings
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error reading certificate",nil) message:[NSString stringWithFormat:NSLocalizedString(@"Use %@ as a PIN-code to send this message instead of the certificate?",nil), pin] preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"YES",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                        dispatch_async(dispatch_get_main_queue(), ^{ // Already there?
                            [CommonProcs showWheelinView:[[GlobalRouter sharedManager] getCurrentView] message:NSLocalizedString(@"Sending...", nil) stopButtonVisible:YES];
                        });
                        __strong __typeof__(self) strongSelf = weakSelf;
                        
                        [strongSelf sendMessage:strongSelf->tempMessage pin:strongSelf->tempPin];
                    }];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"NO",nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
                        __strong __typeof__(self) strongSelf = weakSelf;
                        [strongSelf messageSent:strongSelf->tempMessage error:NSLocalizedString(@"Wrong pin", nil)];
                        sendPending = NO;
                        strongSelf->tempMessage = nil;
                        strongSelf->tempPin = nil;
                    }];
                    [alert addAction:okAction];
                    [alert addAction:cancelAction];
                    [CommonProcs hideProgress];
                    [[[GlobalRouter sharedManager] getTopViewController] presentViewController:alert animated:YES completion:nil];
                });
                /*
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error reading certificate",nil) message:[NSString stringWithFormat:NSLocalizedString(@"Use %@ as a PIN-code to send this message instead of the certificate?",nil), pin] delegate:self cancelButtonTitle:NSLocalizedString(@"NO",nil) otherButtonTitles:NSLocalizedString(@"YES",nil),nil];
                [alert setTag:100];
                if ([NSThread isMainThread]) {
                    [alert show];
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [alert show];
                    });
                }
                */
                return NO;
            }
            if (!(cert == nil || [cert isEqualToString:@""]) && (message.encType == enTypePassword || message.encType == enTypeCertificate)) {
                // cert found, use it
                if (message.mutationNumber > 0) {
                    // use cert with mutations?
                    message.encType = enTypeMutableCertificate;
                    mSignature = signatureMutableCert;
                    otcID = [Encryptor getTheNumberBase26:message.mutationNumber];
                    // Check if the number is longer than 4 symbols
                    if (otcID.length > 4) {
                        otcID = [otcID substringToIndex:4];
                        uint nm = [Encryptor intFromBase26:otcID];
                        message.mutationNumber = nm;
                    }
                }else{
                    mSignature = signatureCert;
                    message.encType = enTypeCertificate;
                    message.mutationNumber = 0;
                }
            }else{
                if (message.encType == enTypeMutablePassword2) {
                    cert = pin;
                    mSignature = signatureMutable2;
                    otcID = [Encryptor getTheNumberBase36:message.mutationNumber];
                    // Check if the number is longer than 4 symbols
                    if (otcID.length > 4) {
                        otcID = [otcID substringToIndex:4];
                        uint nm = [Encryptor intFromBase36:otcID];
                        message.mutationNumber = nm;
                    }
                    //NSLog(@"Mutation number is %@", otcID);
                }else if (message.mutationNumber > 0) {
                    cert = pin;
                    message.encType = enTypeMutablePassword;
                    mSignature = signatureMutable;
                    otcID = [Encryptor getTheNumberBase26:message.mutationNumber];
                    // Check if the number is longer than 4 symbols
                    if (otcID.length > 4) {
                        otcID = [otcID substringToIndex:4];
                        uint nm = [Encryptor intFromBase26:otcID];
                        message.mutationNumber = nm;
                    }
                    //NSLog(@"Mutation number is %@", otcID);
                }else{
                    cert = pin;
                }
            }
        }
        if (message.encType == enTypePasswordForCert) {
            mSignature = signatureTransferCert;
            cert = pin;
        }
        
        //Encryptor* enc = [[Encryptor alloc] initWithKey:cert];
        //NSString* salt = [Encryptor generateSalt8Bytes];
        
        Encryptor* enc; //salt:salt];
        if (message.encType == enTypeMutablePassword || message.encType == enTypeMutableCertificate) {
            enc = [[Encryptor alloc] initWithMutableKey:cert mutations:message.mutationNumber+mutationOffset];
        }else if (message.encType == enTypeMutablePassword2) {
            enc = [[Encryptor alloc] initWithMutableKey:cert mutations:message.mutationNumber+mutationOffset2];
        }else{
            enc = [[GlobalRouter sharedManager] getEncoderForPin:cert];
        }
        enc.isMail = YES;
        
        Encryptor* encSimple = [[Encryptor alloc] initWithSimpleKey:message.toAddress.lowercaseString];
        //NSLog(@"Encrypted with %@",message.fromAddress.lowercaseString);
        
        //message.subject = [NSString stringWithFormat:@"%@%@%@",mSignature,salt,[encSimple encryptToBase64:message.subject]];
        message.subject = [NSString stringWithFormat:@"%@%@%@",mSignature,otcID,[encSimple encryptToBase64:message.subject]];
        message.messageBody = [enc encryptToBase64:message.messageBody];
        
        // Attachments - they are assets - convert them to files and encrypt, return file names
        NSMutableArray* atts = [[NSMutableArray alloc] initWithCapacity:message.attachments.count];
        for (id asset in message.attachments) {
            @autoreleasepool {
                if ([asset isKindOfClass:[NSString class]]) {
                    // Already a path... not an image...
                    NSData* otherFile = [NSData dataWithContentsOfFile:asset];
                    NSData* encoded = [enc encryptAESData:otherFile];
                    [encoded writeToFile:asset atomically:YES];
                    [atts addObject:asset];
                    otherFile = nil;
                    encoded = nil;
                }else{
                    //ALAssetRepresentation* rep = [asset defaultRepresentation];
                    //UIImage* img = [self getImageFromAssetRep:rep];//[[UIImage alloc] initWithCGImage: [rep fullResolutionImage]];
                    UIImage* img = [CommonProcs fullImageFromPHAsset:asset];  //[self fullSizeImageForAssetRepresentation:rep];
                    float cRatio = [[[GlobalRouter sharedManager] getListRouter].dataStore getJPEGCompression];
                    NSData* jpeg = UIImageJPEGRepresentation(img, cRatio);
                    NSData* encoded = [enc encryptAESData:jpeg];
                    NSString* path = [self getTempPathForImage];
                    [encoded writeToFile:path atomically:YES];
                    [atts addObject:path];
                    img = nil;
                    jpeg = nil;
                    encoded = nil;
                    //rep = nil;
                }
            }
        }
        
        message.attachments = atts;
        message.readyToSend = YES;
        
        enc.isMail = NO;
    }
    [[[GlobalRouter sharedManager] getListRouter].dataStore sendMessage:message];
    
    return YES;
}

-(FullMessageEntity*)prepareMessageForAppending:(FullMessageEntity*)message pin:(NSMutableString*)pin
{
    //FullMessageEntity* ret = [message copy];
    
#if DEBUG
    NSLog(@"Subject = %@, Body = %@", message.subject, message.messageBody);
#endif
    //Prepare message for sending - encrypt, attacments array should refer to encrypted files!
    NSString* mSignature = signature;
    __block NSMutableString* cert;
    NSString* otcID = @"";
    if(message.encType == enTypeOTC){
        cert = pin;
        mSignature = signatureOTC;
        otcID = message.keyID;
    }else if (sendPending) {
        cert = pin;
        if (message.encType == enTypeMutablePassword2) {
            cert = pin;
            mSignature = signatureMutable2;
            otcID = [Encryptor getTheNumberBase36:message.mutationNumber];
            // Check if the number is longer than 4 symbols
            if (otcID.length > 4) {
                otcID = [otcID substringToIndex:4];
                uint nm = [Encryptor intFromBase36:otcID];
                message.mutationNumber = nm;
            }
        }else if (message.mutationNumber > 0) {
            cert = pin;
            message.encType = enTypeMutablePassword;
            mSignature = signatureMutable;
            otcID = [Encryptor getTheNumberBase26:message.mutationNumber];
            // Check if the number is longer than 4 symbols
            if (otcID.length > 4) {
                otcID = [otcID substringToIndex:4];
                uint nm = [Encryptor intFromBase26:otcID];
                message.mutationNumber = nm;
            }
        }
        sendPending = NO;
    }else{
        cert = [self getPinForMessage:message pin:pin pinTo:NO]; // Do I need to set pinTo to NO?
        
        if ([cert isEqualToString:INVALID_CERT] && message.encType != enTypePasswordForCert) {
            //
            sendPending = YES;
            tempMessage = message;
            tempPin = pin;
            __weak __typeof__(self) weakSelf = self;
            dispatch_semaphore_t wrongPinSem = dispatch_semaphore_create(0);
            dispatch_async(dispatch_get_main_queue(), ^{ // All the UIAlertController stuff should be on the main thread, overwise we'll get warnings
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error reading certificate",nil) message:[NSString stringWithFormat:NSLocalizedString(@"Use %@ as a PIN-code to send this message instead of the certificate?",nil), pin] preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"YES",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
                    /*
                    dispatch_async(dispatch_get_main_queue(), ^{ // Already there?
                        [CommonProcs showWheelinView:[[GlobalRouter sharedManager] getCurrentView] message:NSLocalizedString(@"Sending...", nil) stopButtonVisible:YES];
                    });
                    __strong __typeof__(self) strongSelf = weakSelf;
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                        [[[GlobalRouter sharedManager] getListRouter].dataStore appendMessage:strongSelf->tempMessage];
                    });*/
                    cert = pin;
                    message.encType = enTypeMutablePassword;
                    dispatch_semaphore_signal(wrongPinSem);
                }];
                UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"NO",nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
                    __strong __typeof__(self) strongSelf = weakSelf;
                    [strongSelf messageSent:strongSelf->tempMessage error:NSLocalizedString(@"Wrong pin", nil)];
                    sendPending = NO;
                    strongSelf->tempMessage = nil;
                    strongSelf->tempPin = nil;
                    dispatch_semaphore_signal(wrongPinSem);
                }];
                [alert addAction:okAction];
                [alert addAction:cancelAction];
                [CommonProcs hideProgress];
                [[[GlobalRouter sharedManager] getTopViewController] presentViewController:alert animated:YES completion:nil];
            });
            dispatch_semaphore_wait(wrongPinSem, DISPATCH_TIME_FOREVER);
            if (!tempMessage) {
                return nil;
            }
            //return nil;
        }
        if (!(cert == nil || [cert isEqualToString:@""]) && (message.encType == enTypePassword || message.encType == enTypeCertificate)) {
            // cert found, use it
            if (message.mutationNumber > 0) {
                // use cert with mutations?
                message.encType = enTypeMutableCertificate;
                mSignature = signatureMutableCert;
                otcID = [Encryptor getTheNumberBase26:message.mutationNumber];
                // Check if the number is longer than 4 symbols
                if (otcID.length > 4) {
                    otcID = [otcID substringToIndex:4];
                    uint nm = [Encryptor intFromBase26:otcID];
                    message.mutationNumber = nm;
                }
            }else{
                mSignature = signatureCert;
                message.encType = enTypeCertificate;
                message.mutationNumber = 0;
            }
        }else{
            if (message.encType == enTypeMutablePassword2) {
                cert = pin;
                mSignature = signatureMutable2;
                otcID = [Encryptor getTheNumberBase36:message.mutationNumber];
                // Check if the number is longer than 4 symbols
                if (otcID.length > 4) {
                    otcID = [otcID substringToIndex:4];
                    uint nm = [Encryptor intFromBase36:otcID];
                    message.mutationNumber = nm;
                }
            }else if (message.mutationNumber > 0) {
                cert = pin;
                message.encType = enTypeMutablePassword;
                mSignature = signatureMutable;
                otcID = [Encryptor getTheNumberBase26:message.mutationNumber];
                // Check if the number is longer than 4 symbols
                if (otcID.length > 4) {
                    otcID = [otcID substringToIndex:4];
                    uint nm = [Encryptor intFromBase26:otcID];
                    message.mutationNumber = nm;
                }
                //NSLog(@"Mutation number is %@", otcID);
            }else{
                cert = pin;
            }
        }
    }
    if (message.encType == enTypePasswordForCert) {
        mSignature = signatureTransferCert;
        cert = pin;
    }
    
    Encryptor* enc; //salt:salt];
    if (message.encType == enTypeMutablePassword || message.encType == enTypeMutableCertificate) {
        enc = [[Encryptor alloc] initWithMutableKey:cert mutations:message.mutationNumber+mutationOffset];
    }else if (message.encType == enTypeMutablePassword2) {
        enc = [[Encryptor alloc] initWithMutableKey:cert mutations:message.mutationNumber+mutationOffset2];
    }else{
        enc = [[GlobalRouter sharedManager] getEncoderForPin:cert];
    }
    enc.isMail = YES;
    
    Encryptor* encSimple = [[Encryptor alloc] initWithSimpleKey:message.toAddress.lowercaseString];
    //NSLog(@"Encrypted with %@",message.fromAddress.lowercaseString);
    
    message.subject = [NSString stringWithFormat:@"%@%@%@",mSignature,otcID,[encSimple encryptToBase64:message.subject]];
    message.messageBody = [enc encryptToBase64:message.messageBody];
    
    //message.fromAddress = [enc encryptToBase64:message.fromAddress];
    
    // Attachments - they are assets - convert them to files and encrypt, return file names
    NSMutableArray* atts = [[NSMutableArray alloc] initWithCapacity:message.attachments.count];
    for (id asset in message.attachments) {
        @autoreleasepool {
            if ([asset isKindOfClass:[NSString class]]) {
                // Already a path... not an image...
                NSData* otherFile = [NSData dataWithContentsOfFile:asset];
                NSData* encoded = [enc encryptAESData:otherFile];
                [encoded writeToFile:asset atomically:YES];
                [atts addObject:asset];
                otherFile = nil;
                encoded = nil;
            }else{
                UIImage* img = [CommonProcs fullImageFromPHAsset:asset];  //[self fullSizeImageForAssetRepresentation:rep];
                float cRatio = [[[GlobalRouter sharedManager] getListRouter].dataStore getJPEGCompression];
                NSData* jpeg = UIImageJPEGRepresentation(img, cRatio);
                NSData* encoded = [enc encryptAESData:jpeg];
                NSString* path = [self getTempPathForImage];
                [encoded writeToFile:path atomically:YES];
                [atts addObject:path];
                img = nil;
                jpeg = nil;
                encoded = nil;
            }
        }
    }
    
    message.attachments = atts;
    message.readyToSend = YES;
    
    enc.isMail = NO;
    return message;
}

-(BOOL)sendPlainMessage:(FullMessageEntity*)message
{
    // Attachments - they are assets - convert them to files and encrypt, return file names
    NSMutableArray* atts = [[NSMutableArray alloc] initWithCapacity:message.attachments.count];
    for (id asset in message.attachments) {
        if ([asset isKindOfClass:[NSString class]]) {
            // Already path... we're resending message
            [atts addObject:asset];
        }else{
            //ALAssetRepresentation* rep = [asset defaultRepresentation];
            UIImage* img = [CommonProcs fullImageFromPHAsset:asset]; //[self getImageFromAssetRep:rep];//[[UIImage alloc] initWithCGImage: [rep fullResolutionImage]];
            
            float cRatio = [[[GlobalRouter sharedManager] getListRouter].dataStore getJPEGCompression];
            NSData* jpeg = UIImageJPEGRepresentation(img, cRatio);
            NSString* path = [self getTempPathForImage];
            [jpeg writeToFile:path atomically:YES];
            [atts addObject:path];
        }
    }
    message.messageBody = [message.messageBody stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
    
    message.attachments = atts;
    message.readyToSend = YES;
    [[[GlobalRouter sharedManager] getListRouter].dataStore sendMessage:message];

    return YES;
}

/*
// This one uses much less memory
-(UIImage *)fullSizeImageForAssetRepresentation:(ALAssetRepresentation *)assetRepresentation
{
    UIImage *result = nil;
    NSData *data = nil;
    
    uint8_t *buffer = (uint8_t *)malloc(sizeof(uint8_t)*((uint)[assetRepresentation size]));
    if (buffer != NULL) {
        NSError *error = nil;
        NSUInteger bytesRead = [assetRepresentation getBytes:buffer fromOffset:0 length:(uint)[assetRepresentation size] error:&error];
        data = [NSData dataWithBytes:buffer length:bytesRead];
        
        free(buffer);
    }
    
    if ([data length])
    {
        CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, nil);
        
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        
        [options setObject:(id)kCFBooleanTrue forKey:(id)kCGImageSourceShouldAllowFloat];
        //[options setObject:(id)kCFBooleanTrue forKey:(id)kCGImageSourceCreateThumbnailFromImageAlways];
        //[options setObject:(id)[NSNumber numberWithFloat:640.0f] forKey:(id)kCGImageSourceThumbnailMaxPixelSize];
        
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, (__bridge CFDictionaryRef)options); //eCreateThumbnailAtIndex(sourceRef, 0, (__bridge CFDictionaryRef)options);
        
        if (imageRef) {
            result = [UIImage imageWithCGImage:imageRef scale:[assetRepresentation scale] orientation:(UIImageOrientation)[assetRepresentation orientation]];
            CGImageRelease(imageRef);
        }
        
        if (sourceRef)
            CFRelease(sourceRef);
        data = nil;
    }
    
    return result;
}*/

/*
// This one eats up 50 MB of memory and doesn't release it... donna why
-(UIImage*)getImageFromAssetRep:(ALAssetRepresentation*)assetRepresentation
{
    UIImage *result;
    
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
    result = [UIImage imageWithCGImage:fullResImage
                                          scale:[assetRepresentation scale]
                                    orientation:(UIImageOrientation)[assetRepresentation orientation]];
    fullResImage = nil; // iOS bug, need to nil it or there is a memory leak
    
    return result;
}*/

-(void)messageSent:(FullMessageEntity*)message error:(NSString*)error
{
    [[[GlobalRouter sharedManager] getComposeRouter] sendingResult:error];
    if (error == nil || [error isEqualToString:@""]) {
        [DataManager deleteTempFilesFromMessage:message];
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

/*
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
*/

-(void)deleteMessage:(ShortMessageEntity *)message
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[[GlobalRouter sharedManager] getListRouter].dataStore deleteMessage:message];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (message.flags&mfNew) {
                NSInteger badge = [UIApplication sharedApplication].applicationIconBadgeNumber-1;
                if (badge >= 0) {
                    [UIApplication sharedApplication].applicationIconBadgeNumber = badge;
                }
            }
        });
    });
}

-(void)deleteMessages:(NSArray*)messages
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[[GlobalRouter sharedManager] getListRouter].dataStore deleteMessages:messages];
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSInteger badge = [UIApplication sharedApplication].applicationIconBadgeNumber;
        for (ShortMessageEntity* message in messages) {
            if (message.flags&mfNew) {
                badge--;
            }
        }
        if (badge >= 0) {
            [UIApplication sharedApplication].applicationIconBadgeNumber = badge;
        }
    });
}

-(void)deleteAllMessagesFromFolder:(NSString*)folderPath
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[[GlobalRouter sharedManager] getListRouter].dataStore deleteAllMessagesFromFolder:folderPath];
    });
}

-(void)setFlagForMessages:(NSArray*)messages flag:(int)flag
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[[GlobalRouter sharedManager] getListRouter].dataStore setFlagForMessages:messages flag:flag];
    });
}

-(void)setCustomFlagsForMessage:(ShortMessageEntity*)message flags:(NSArray*)flags
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[[GlobalRouter sharedManager] getListRouter].dataStore setCustomFlagsForMessage:message flags:flags];
    });
}

-(void)removeCustomFlagsForMessage:(ShortMessageEntity*)message flags:(NSArray*)flags
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[[GlobalRouter sharedManager] getListRouter].dataStore removeCustomFlagsForMessage:message flags:flags];
    });
}

-(void)updateBadgeForMessage:(ShortMessageEntity*)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        int toAdd = 0;
        if (message.flags&mfNew) {
            // Would be unread, increase badge number
            toAdd = 1;
        }else{
            toAdd = -1;
        }
        NSInteger badge = [UIApplication sharedApplication].applicationIconBadgeNumber + toAdd;
        if (badge >= 0) {
            [UIApplication sharedApplication].applicationIconBadgeNumber = badge;
        }
    });
}

-(void)markAsRead:(ShortMessageEntity*)message
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[[GlobalRouter sharedManager] getListRouter].dataStore setReadFlagForMessage:message];
    });
    [self updateBadgeForMessage:message];
    
    //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        //[self setBadge];
    //});
    
}

-(void)toggleStarForMessage:(ShortMessageEntity*)message
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[[GlobalRouter sharedManager] getListRouter].dataStore toggleStarForMessage:message];
    });
}

-(void)markAsAnswered:(ShortMessageEntity*)message
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[[GlobalRouter sharedManager] getListRouter].dataStore setAnsweredFlagForMessage:message];
    });
}

-(int)readNewMessagesCountForFolder:(NSString*)folder address:(NSString*)address
{
    int ret = 0;
    DataStorage* store = [[GlobalRouter sharedManager] getListRouter].dataStore;
    if (folder == nil || [folder isEqualToString:@""]) {
        folder = @"INBOX";
    }
    
    //TODO: potentially slow, since we are waiting for each account, but can do it async
    if (address == nil || [address isEqualToString:@""]) {
        // For all addresses and sessions
        //for (SessionConnectorNew* sess in store.imapSessions) {
        for(int i=0;i<store.imapSessions.count;i++){
            if (!store.imapSessions || i>=store.imapSessions.count) {
                break;
            }
            SessionConnectorNew* sess = store.imapSessions[i];
            if(![GlobalRouter notInited] && [[[GlobalRouter sharedManager] getListRouter] isActive] && ![GlobalRouter sharedManager].goingToBG)
                ret += [store readNewMessagesCountForFolder:folder session:sess];
        }
    }else{
        for (SessionConnectorNew* sess in store.imapSessions) {
            if ([sess isThisForAddress:address]) {
                ret = [store readNewMessagesCountForFolder:folder session:sess];
                break;
            }
        }
    }
    
    return ret;
}

-(int)readNewMessagesCountBG
{
    return [[[GlobalRouter sharedManager] getListRouter].dataStore bgGetNewMessageCount];
}

-(int)readNewMessagesCount
{
    //return [[[GlobalRouter sharedManager] getListRouter].dataStore bgGetNewMessageCount];
    //dispatch_async(dispatch_get_main_queue(), ^{
        if([UIApplication sharedApplication].applicationState == UIApplicationStateActive){
            return [[[GlobalRouter sharedManager] getListRouter].dataStore readNewMessagesCountForAll];
        }else{
            return [[[GlobalRouter sharedManager] getListRouter].dataStore bgGetNewMessageCount];// readNewMessagesCount];
        }
    //});
}

/*
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
*/
-(void)createFolder:(NSString*)newFolderName
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[[GlobalRouter sharedManager] getListRouter].dataStore createFolder:newFolderName];
    });
}

-(void)renameFolder:(NSString*)folderName newName:(NSString*)newFolderName
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[[GlobalRouter sharedManager] getListRouter].dataStore renameFolder:folderName newName:newFolderName];
    });
}

-(void)copyMessage:(FullMessageEntity *)item to:(NSString *)folderPath
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[[GlobalRouter sharedManager] getListRouter].dataStore copyMessage:item to:folderPath];
    });
}

-(void)moveMessage:(FullMessageEntity *)item to:(NSString *)folderPath
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[[GlobalRouter sharedManager] getListRouter].dataStore moveMessage:item to:folderPath];
    });
}

-(void)copyMessages:(NSArray *)items to:(NSString *)folderPath
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[[GlobalRouter sharedManager] getListRouter].dataStore moveMessages:items to:folderPath copyOnly:YES];
    });
}

-(void)moveMessages:(NSArray*)items to:(NSString *)folderPath
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[[GlobalRouter sharedManager] getListRouter].dataStore moveMessages:items to:folderPath copyOnly:NO];
    });
}

-(void)checkMailSessions
{
    [GlobalRouter sharedManager].totalMessages = 0; 
    [[[GlobalRouter sharedManager] getListRouter].dataStore readShortMessagesForBox:btNo];
}

-(void)settingsWasDeletedForAddress:(NSString*)address
{
    [[[GlobalRouter sharedManager] getListRouter].dataStore revokeAuthForAddress:address];
}

-(void)logoutForAddress:(NSString *)address
{
    [[[GlobalRouter sharedManager] getListRouter].dataStore revokeAuthForAddress:address];
}

-(BOOL)isAddressLoggedIn:(NSString *)address
{
    return [[[GlobalRouter sharedManager] getListRouter].dataStore isAddressLoggedIn:address];
}

-(void)clearSessions
{
    [[[GlobalRouter sharedManager] getListRouter].dataStore closeAllSessionsSync:NO];
    //[[[GlobalRouter sharedManager] getListRouter].dataStore.imapSessions removeAllObjects];
}

-(BOOL)checkConnection:(SettingsEntity*)sett
{
    return [[[GlobalRouter sharedManager] getListRouter].dataStore checkConnection:sett];
}

-(int)checkSMTPConnection:(SettingsEntity*)sett
{
    return [[[GlobalRouter sharedManager] getListRouter].dataStore checkSMTPConnection:sett];
}

// Encrypt the message on the server. Actually, create a new encrypted message and delete
// the old one
-(void)encryptExistingMessage:(FullMessageEntity *)item pin:(NSMutableString *)newPin
{
    if(!item.readyToSend){
        NSLog(@"Preparing for appending");
        item = [self prepareMessageForAppending:item pin:newPin];
    }
 
    // Need to wait until done... implemented with semaphore in delete operation
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[[GlobalRouter sharedManager] getListRouter].dataStore deleteMessage:item reencrypting:YES];
        
        if(item){
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                [[[GlobalRouter sharedManager] getListRouter].dataStore appendMessage:item];
            });
        }else{
            // Append will be done from the prepareMessageForSendind proc
        }
    });
}

-(void)reconnectAll
{
    [[[GlobalRouter sharedManager] getListRouter].dataStore reconnectAllSessions];
}
     
-(void)deleteExpiredMessages
{
    [[[GlobalRouter sharedManager] getListRouter].dataStore doDeleteExpiredMessages];
}

@end
