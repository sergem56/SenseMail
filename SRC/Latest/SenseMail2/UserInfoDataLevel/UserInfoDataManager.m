//
//  UserInfoDataManager.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "UserInfoDataManager.h"
#import "SettingsEntity.h"
#import "UserInfoDataStorage.h"
#import "Encryptor.h"
#import "AddressBookEntity.h"
#import "GlobalRouter.h"
#import "CommonProcs.h"
#import "NoteEntity.h"
#import "CommonStuff.h"
#import "CertEntity.h"
#import "FullMessageEntity.h"
#import "OneTimeCert.h"
#import "ShortcutEntity.h"

@implementation UserInfoDataManager

@synthesize storage;

-(id)init
{
    if (self = [super init]) {
        storage = [[UserInfoDataStorage alloc] init];
    }
    return self;
}

-(BOOL)isPasswordNeeded
{
    return YES;
    /*
    UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    SettingsEntity* settings = [storage readSettings];
    return !([settings.pinCode isEqualToString:@""] || settings.pinCode == nil);
     */
}

-(BOOL)showAlert:(NSString *)title
{
    /*
    UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    SettingsEntity* settings = [storage readSettings];
    
    return [settings.pinCode isEqualToString:title];
     */
    return YES;
}

-(NSArray* /*SettingsEntity*/)getSettings:(NSMutableString*)pin
{
    if (!pin) {
        return [[NSArray alloc] init];
    }
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    NSMutableArray* settingsArray = [NSMutableArray arrayWithArray:[storage readSettings]];
    //NSLog(@"%@\n%@\n%@", settings.userName, settings.userNick, settings.password);
    
    // Decrypt user name, password with pin
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin]; //salt:@""];
    
    NSMutableArray* toDel = [[NSMutableArray alloc] init];
    [GlobalRouter sharedManager].keepInBg = NO;

    for (SettingsEntity* settings in settingsArray) {
        NSData* sName = [enc dataFromBase64:settings.settingsName];//NSLog(@"%@", unick);
        settings.settingsName = [enc decryptAESString:sName];
        if ([settings.settingsName isEqualToString:MESSAGE_INVALID_PWD]) {
            settings.settingsName = @"";
        }
        
        NSData* uname = [enc dataFromBase64:settings.userName];//NSLog(@"%@", uname);
        settings.userName = [enc decryptAESString:uname];
        if ([settings.userName isEqualToString:MESSAGE_INVALID_PWD]) {
            settings.userName = @"";
        }
        
        NSData* unick = [enc dataFromBase64:settings.userNick];//NSLog(@"%@", unick);
        settings.userNick = [enc decryptAESString:unick];
        if ([settings.userNick isEqualToString:MESSAGE_INVALID_PWD]) {
            settings.userNick = @"";
        }
        
        NSData* upwd = [enc dataFromBase64:settings.password];//NSLog(@"%@", upwd);
        settings.password = [enc decryptAESString:upwd];
        if ([settings.password isEqualToString:MESSAGE_INVALID_PWD]) {
            settings.password = @"";
        }
        
        // Checksum is a sort of the ID and is not encrypted
        //NSData* check = [enc dataFromBase64:settings.checksum];
        //settings.checksum = [enc decryptAESString:check];
        
        NSData* imap = [enc dataFromBase64:settings.imapServer];
        settings.imapServer = [enc decryptAESString:imap];
        if ([settings.imapServer isEqualToString:MESSAGE_INVALID_PWD]) {
            settings.imapServer = @"";
        }

        NSData* smtp = [enc dataFromBase64:settings.smtpServer];
        settings.smtpServer = [enc decryptAESString:smtp];
        if ([settings.smtpServer isEqualToString:MESSAGE_INVALID_PWD]) {
            settings.smtpServer = @"";
        }
        
        NSData* signature = [enc dataFromBase64:settings.signature];
        settings.signature = [enc decryptAESString:signature];
        if ([settings.signature isEqualToString:MESSAGE_INVALID_PWD]) {
            settings.signature = @"";
        }
        
        settings.imapPrefix = [enc decryptFromBase64:settings.imapPrefix];
        
        settings.bgColor = [[NSUserDefaults standardUserDefaults] integerForKey:[NSString stringWithFormat:@"cl%@",[Encryptor getUUIDHashForString:settings.userName]]];
        
        if (settings.SMTPAuthType == 0) {
            settings.SMTPAuthType = MCOAuthTypeSASLLogin;
        }
        
        if (settings.userName == nil || [settings.userName isEqualToString:@""]) {
            [toDel addObject:settings];
        }else{
            if([settings.userName isEqualToString:GENERAL_SETTINGS]){
                [GlobalRouter sharedManager].keepInBg = settings.keepInBg;
                [GlobalRouter sharedManager].compression = settings.compression;
                if (settings.checkPeriod == 0) {
                    settings.checkPeriod = 60;
                }
                if (settings.nMessages == 0) {
                    settings.nMessages = 10;
                }
                
                [GlobalRouter sharedManager].nMessagesToLoad = (int)settings.nMessages;
                
                if (![GlobalRouter sharedManager].keepInBg) {
                    //[CommonProcs writeValueToKeychain:@"" forAccount:smSavedPinAccount];
                    //[CommonProcs saveToKeychainAlways:@"" account:smSavedPinAccount service:@"SM"];
                }
                
                [[GlobalRouter sharedManager] getListRouter].largeFont = settings.largeFont;
                [[GlobalRouter sharedManager] getListRouter].sortByDate = settings.sortAll;
                [[GlobalRouter sharedManager] getListRouter].sortOrder = settings.sortOrder;
                [GlobalRouter sharedManager].clearOnBGSetting = settings.clearOnBG;
                [GlobalRouter sharedManager].doNotHideAccountInNotification = settings.doNotHideAccount;
                [GlobalRouter sharedManager].showShortcuts = settings.useShortcuts;
                
                // VPN
#if USESEC
                NSData* vpnUser = [enc dataFromBase64:settings.vpnUsername];
                settings.vpnUsername = [enc decryptAESString:vpnUser];
                if ([settings.vpnUsername isEqualToString:MESSAGE_INVALID_PWD]) {
                    settings.vpnUsername = @"";
                }
                
                NSData* vpnPwd = [enc dataFromBase64:settings.vpnPassword];
                settings.vpnPassword = [enc decryptAESString:vpnPwd];
                if ([settings.vpnPassword isEqualToString:MESSAGE_INVALID_PWD]) {
                    settings.vpnPassword = @"";
                }
                
                NSData* vpnS = [enc dataFromBase64:settings.vpnServer];
                settings.vpnServer = [enc decryptAESString:vpnS];
                if ([settings.vpnServer isEqualToString:MESSAGE_INVALID_PWD]) {
                    settings.vpnServer = @"";
                }
                
                NSData* vpnR = [enc dataFromBase64:settings.vpnRemoteID];
                settings.vpnRemoteID = [enc decryptAESString:vpnR];
                if ([settings.vpnRemoteID isEqualToString:MESSAGE_INVALID_PWD]) {
                    settings.vpnRemoteID = @"";
                }
                
                NSData* vpnL = [enc dataFromBase64:settings.vpnLocalID];
                settings.vpnLocalID = [enc decryptAESString:vpnL];
                if ([settings.vpnLocalID isEqualToString:MESSAGE_INVALID_PWD]) {
                    settings.vpnLocalID = @"";
                }
                
                NSData* vpnSs = [enc dataFromBase64:settings.vpnSharedSecret];
                settings.vpnSharedSecret = [enc decryptAESString:vpnSs];
                if ([settings.vpnSharedSecret isEqualToString:MESSAGE_INVALID_PWD]) {
                    settings.vpnSharedSecret = @"";
                }
                
                [GlobalRouter sharedManager].needVPN = settings.enableVPN;
#else
                [GlobalRouter sharedManager].needVPN = NO;
#endif
                
                //dispatch_async(dispatch_get_main_queue(), ^{
                //    [[[GlobalRouter sharedManager] getListRouter] showShortcutBar];
                //});
                /*
                if(settings.keepInBg){
                    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:settings.checkPeriod*60];
                }else{
                    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
                }
                 */
            }
        }
    }

    for (SettingsEntity* ent in toDel) {
        [settingsArray removeObject:ent];
    }
    
    // Might be that there's no general settings
    if (settingsArray.count == 1) {
        SettingsEntity* sett = settingsArray[0];
        if (![sett.userName isEqualToString:GENERAL_SETTINGS]) {
            SettingsEntity* general = [[SettingsEntity alloc] initWithGenericGeneral];
            [settingsArray addObject:general];
        }
    }
    return settingsArray;
}

-(BOOL)saveSettings:(SettingsEntity *)settings :(NSMutableString*)pin
{
    //!!!
    //sleep(1);
    
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    
    // Encrypt with pin
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin]; //salt:@""];
    
    
    // Write BG color setting here, it's going to be encrypted later on
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:settings.bgColor] forKey:[NSString stringWithFormat:@"cl%@",[Encryptor getUUIDHashForString:settings.userName]]];
    
    if([settings.settingsName isEqualToString:GENERAL_SETTINGS]){
        if (settings.keepInBg) {
            NSString* kkk = [[UIDevice currentDevice].identifierForVendor UUIDString];
            Encryptor* cryptor = [[Encryptor alloc] initWithSimpleKey:kkk];
            NSString* toStore = [cryptor encryptToBase64:pin];
            [CommonProcs saveToKeychainAlways:toStore account:smSavedPinAccount service:@"SM"];
        }else{
            [CommonProcs saveToKeychainAlways:@"" account:smSavedPinAccount service:@"SM"];
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:settings.sortAll] forKey:@"sortByDate"];
        /*
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:settings.largeFont] forKey:@"largeFont"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:(int)settings.sortOrder] forKey:@"sortOrder"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:settings.clearOnBG] forKey:@"clearOnBG"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:settings.doNotHideAccount] forKey:@"doNotHideAccount"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:settings.useShortcuts] forKey:@"useShortcuts"];
        */
        [[GlobalRouter sharedManager] getListRouter].largeFont = settings.largeFont;
        [[GlobalRouter sharedManager] getListRouter].sortOrder = settings.sortOrder;
        [GlobalRouter sharedManager].clearOnBGSetting = settings.clearOnBG;
        [GlobalRouter sharedManager].doNotHideAccountInNotification = settings.doNotHideAccount;
        [GlobalRouter sharedManager].showShortcuts = settings.useShortcuts;
        //dispatch_async(dispatch_get_main_queue(), ^{
        //    [[[GlobalRouter sharedManager] getListRouter] showShortcutBar];
        //});
        
        /*
        [[NSUserDefaults standardUserDefaults] setObject:settings.silentFrom forKey:@"silentFrom"];
        [[NSUserDefaults standardUserDefaults] setObject:settings.silentTo forKey:@"silentTo"];
        
         */
        
        // VPN
#if USESEC
        NSData* d1 = [enc encryptAESString:settings.vpnUsername];
        settings.vpnUsername = [enc base64FromData:d1];
        NSData* d2 = [enc encryptAESString:settings.vpnPassword];
        settings.vpnPassword = [enc base64FromData:d2];
        NSData* d3 = [enc encryptAESString:settings.vpnServer];
        settings.vpnServer = [enc base64FromData:d3];
        NSData* d4 = [enc encryptAESString:settings.vpnRemoteID];
        settings.vpnRemoteID = [enc base64FromData:d4];
        NSData* d5 = [enc encryptAESString:settings.vpnLocalID];
        settings.vpnLocalID = [enc base64FromData:d5];
        NSData* d6 = [enc encryptAESString:settings.vpnSharedSecret];
        settings.vpnSharedSecret = [enc base64FromData:d6];
#endif
    }
    
    NSData* sname = [enc encryptAESString:settings.settingsName];
    settings.settingsName = [enc base64FromData:sname];
    
    NSData* uname = [enc encryptAESString:settings.userName];
    settings.userName = [enc base64FromData:uname];
    
    NSData* unick = [enc encryptAESString:settings.userNick];
    settings.userNick = [enc base64FromData:unick];
    
    NSData* upwd = [enc encryptAESString:settings.password];
    settings.password = [enc base64FromData:upwd];
    
    if ([settings.checksum isEqualToString:@""] || settings.checksum == nil || settings.checksum.length < 10) {
        settings.checksum = [[NSUUID UUID] UUIDString];
    }
    //NSData* check = [enc encryptAESString:settings.checksum];
    settings.checksum = settings.checksum;//[enc base64FromData:check];
    
    NSData* imap = [enc encryptAESString:settings.imapServer];
    settings.imapServer = [enc base64FromData:imap];
    
    NSData* smtp = [enc encryptAESString:settings.smtpServer];
    settings.smtpServer = [enc base64FromData:smtp];
    
    NSData* signature = [enc encryptAESString:settings.signature];
    settings.signature = [enc base64FromData:signature];
    
    settings.imapPrefix = [enc encryptToBase64:settings.imapPrefix];
    
    if (settings.SMTPAuthType == 0) {
        settings.SMTPAuthType = MCOAuthTypeSASLLogin;
    }
    
    return [storage writeSettings:settings];
}

-(BOOL)deleteSetting:(SettingsEntity *)settings
{
    BOOL ret = YES;
    ret = [storage deleteSetting:settings];
    return ret;
}

#pragma mark Address book

-(NSArray*)getAddressBook:(NSMutableString*)pin groupsOnly:(BOOL)groupsOnly
{
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    NSMutableArray* items = [NSMutableArray arrayWithArray:[storage readAddressBook:groupsOnly]];;
    
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin]; //salt:@""];
    
    NSMutableArray* toDel = [[NSMutableArray alloc] init];
    for (AddressBookEntity* item in items) {
        item.name = [enc decryptFromBase64:item.name];
        item.address = [enc decryptFromBase64:item.address];
        if(item.address == nil){
            // need to delete this item
            [toDel addObject:item];
        }else{
            item.note = [enc decryptFromBase64:item.note];
            item.groupID = [enc decryptFromBase64:item.groupID];
            // Check if it's fucking long on large address book...
            //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
#if !LITE
            NSData* data = [storage readKeyFor:[Encryptor getHashForString:item.address] forDate:[NSDate date]];
            item.key = data != nil;
#endif
        }
    }
    
    if ([toDel count] > 0) {
        for (AddressBookEntity* item in toDel) {
            [items removeObject:item];
        }
    }
    //[self.receiver userInfoFinishedTask:YES];
    return items;
}

-(BOOL)saveAddressBook:(NSArray*)book pin:(NSMutableString*)pin
{
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin]; //salt:@""];
    
    for (AddressBookEntity* item in book) {
        item.name = [enc encryptToBase64:item.name];
        item.address = [enc encryptToBase64:item.address];
        item.note = [enc encryptToBase64:item.note];
        item.key = NO;// [enc encryptAESData:item.key];
        item.groupID = [enc encryptToBase64:item.groupID];
        if (item.uid == nil || [item.uid isEqualToString:@""]) {
            item.uid = [[NSUUID UUID] UUIDString];
        }
    }
    
    return [storage writeAddressBook:book];
}

-(AddressBookEntity*)findInAddressBook:(NSString*)name address:(NSString*)address pin:(NSMutableString*)pin
{
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin]; //salt:@""];
    
    AddressBookEntity* item = [[AddressBookEntity alloc] init];
    item.name = [enc encryptToBase64:name];
    item.address = [enc encryptToBase64:address];
    
    item = [storage searchItemInAddressBook:item];
    if (item != nil) {
        item.name = [enc decryptFromBase64:item.name];
        item.address = [enc decryptFromBase64:item.address];
        item.note = [enc decryptFromBase64:item.note];
        item.groupID = [enc decryptFromBase64:item.groupID];
        
        // Check if it's fucking long on large address book...
        //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
#if !LITE
        NSData* data = [storage readKeyFor:[Encryptor getHashForString:item.address] forDate:[NSDate date]];
        item.key = data != nil;
#endif
    }
    return item;
}
    
-(BOOL)deleteAddressBookItem:(AddressBookEntity*)item
{
    return [storage deleteAddressBookItem:item];
}

#pragma mark Keys & certificates
#if !LITE
-(NSData*)getKeyFor:(NSString*)address pin:(NSMutableString*)pin forDate:(NSDate*)forDate
{
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin]; //salt:@""];
    
    NSString* addressHash = [Encryptor getHashForString:address];
    
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    NSData* data = [storage readKeyFor:addressHash forDate:forDate];
    if (data == nil) {
        return nil;
    }

    return [enc decryptAESData:data];
}

-(BOOL)saveKeyForAddress:(NSString*)address yourPin:(NSMutableString*)yourPin key:(NSData*)key forDate:(NSDate *)forDate
{
    // Message sent by you To somebody is encrypted with your pin!
    Encryptor* encTo = [[Encryptor alloc] initWithStrongerKey:yourPin]; //salt:address];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:[GlobalRouter sharedManager].pin]; //salt:@""];
    
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    NSString* addressHash = [Encryptor getHashForString:address];
    
    return [storage writeKeyForAddress:addressHash keyData:[enc encryptAESData:[encTo encryptAESData:key]] forDate:forDate];
}

-(BOOL)deleteKeyFor:(NSString*)address
{
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    BOOL ret = [storage deleteKeyFor:[Encryptor getHashForString:address]];
    
    return ret;
}

-(BOOL)saveAllKeysWithNewPin:(NSMutableString *)newPin oldPin:(NSMutableString*)oldPin
{
    BOOL ret = YES;
    NSArray* keys = [storage readAllKeys];
    if (keys == nil) {
        return NO;
    }
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:oldPin];
    Encryptor* encNew = [[GlobalRouter sharedManager] getEncoderForPin:newPin];
    
    for (CertEntity* key in keys) {
        NSData* keyData = [enc decryptAESData:key.keyData];
        if (keyData == nil) {
            continue; // Wrong pin, skip it!
        }else{
            CertEntity* cert = [[CertEntity alloc] init];
            cert.keyData = keyData;
            cert.forDate = key.forDate;
            cert.forAddress = key.forAddress;
            //cert.note = [enc decryptAESString:key.note];
            
            [storage writeKeyForAddress:cert.forAddress keyData:[encNew encryptAESData:cert.keyData] forDate:cert.forDate];
        }
    }
    
    return ret;
}

-(NSMutableArray*)getCertsForAddress:(NSString*)forAddress
{
    NSMutableArray* ret = [[NSMutableArray alloc] init];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:[GlobalRouter sharedManager].pin];
    NSArray* certs = [storage readAllKeysForAddress:forAddress];
    for (CertEntity* key in certs) {
        NSData* keyData = [enc decryptAESData:key.keyData];
        if (keyData == nil) {
            continue; // Wrong pin, skip it!
        }else{
            CertEntity* cert = [[CertEntity alloc] init];
            cert.keyData = keyData;
            cert.forDate = key.forDate;
            cert.forAddress = key.forAddress;
            [ret addObject:cert]; // returns certs encrypted with stronger pwd
        }
    }
    
    return ret;
}
#endif

#pragma mark - Gallery

// Returns pairs thumbnail image + full image path
-(NSMutableDictionary*)getGalleryThumbnails:(NSMutableString*)pin
{
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin]; //salt:@""];
    
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    NSDictionary* retDict = [storage readGalleryThumbnails];
    NSMutableDictionary* ret = [[NSMutableDictionary alloc] init];
    for (NSString* key in retDict) {
        if ([key isEqualToString:@"sorted"]) {
            continue;
        }
        UIImage* temp = [UIImage imageWithData:[enc decryptAESData:[retDict valueForKey:key]]];
        if(temp != nil)
            [ret setObject:temp forKey:key];
    }
    [ret setObject:[retDict valueForKey:@"sorted"] forKey:@"sorted"];
    return ret;
}

-(UIImage*)getFullImage:(NSString*)path
{
    return [self getFullImage:path pin:[GlobalRouter sharedManager].pin];
}

-(UIImage*)getFullImage:(NSString*)path pin:(NSMutableString*)pin
{
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin]; //salt:@""];
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    
    NSData* retData = [storage readFullImage:path];
    
    UIImage* ret = [UIImage imageWithData:[enc decryptAESData:retData]];
    //[self.receiver userInfoFinishedTask:YES];
    
    return ret;
}

-(NSData*)getFullData:(NSString*)path pin:(NSMutableString*)pin
{
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin]; //salt:@""];
    
    NSData* retData = [enc decryptAESData:[storage readFullImage:path]];
    
    return retData;
}

-(BOOL)writeImageData:(UIImage*)data pin:(NSMutableString*)pin
{
    UIImage* thumb = [CommonProcs thumbnailImageFromImage:data];
    
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin]; //salt:@""];
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    
    BOOL ret = [storage writeImageData:[enc encryptAESData:UIImageJPEGRepresentation(data, 1.0)] thumb:[enc encryptAESData:UIImageJPEGRepresentation(thumb, 0.6)]];
    
    [self.receiver userInfoFinishedTask:ret];
    
    return ret;
}

-(BOOL)writeURLPathData:(NSURL*)data pin:(NSMutableString*)pin thumb:(UIImage*)thumbnail
{
    UIImage* thumb;
    if (!thumbnail) {
        UIImage* th0 = [UIImage imageWithData:[NSData dataWithContentsOfURL:data]];
        if (th0) {
            thumb = [CommonProcs thumbnailImageFromImage:th0];
        }else{
            thumb = [UIImage imageNamed:@"docIcon"];
        }
    }else{
        thumb = thumbnail;
    }
    
    NSString* ext = [data.absoluteString pathExtension];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin];
    
    BOOL ret = [storage writeDocData:[enc encryptAESData:[NSData dataWithContentsOfURL:data]] thumb:[enc encryptAESData:UIImageJPEGRepresentation(thumb, 0.6)] withExtention:ext];
    
    [self.receiver userInfoFinishedTask:ret];
    
    return ret;
}

-(BOOL)deleteImage:(NSString *)path
{
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    return [storage deleteImage:path];
}

-(BOOL)saveGalleryWithNewPin:(NSMutableString *)newPin oldPin:(NSMutableString*)oldPin
{
    BOOL ret = YES;
    //Encryptor* enc = [[Encryptor alloc] initWithKey:oldPin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:oldPin]; //salt:@""];
    //Encryptor* encNew = [[Encryptor alloc] initWithKey:newPin];
    Encryptor* encNew = [[GlobalRouter sharedManager] getEncoderForPin:newPin]; //salt:@""];
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    NSDictionary* items = [self getGalleryThumbnails:oldPin];
    for (NSString* key in items) {
        // 1. Read full image
        // 2. Decrypt it
        // 3. Encrypt it
        // 4. Write it
        NSData* fullImage = [storage readFullImage:key];
        fullImage = [enc decryptAESData:fullImage];
        if(fullImage != nil){
            UIImage* thumb = [CommonProcs thumbnailImageFromImage:[UIImage imageWithData:fullImage]];
            // 3
            fullImage = [encNew encryptAESData:fullImage];
            NSData* thumbData = [encNew encryptAESData:UIImageJPEGRepresentation(thumb, 0.6)];
            // 4
            [storage writeImageDataToPath:key fullImage:fullImage thumb:thumbData];
        }
    }
    
    return ret;
}

#pragma mark - Notes

-(NSMutableArray*)getNotes:(NSMutableString *)pin
{
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    NSMutableArray* items = [storage readNotes];
    
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin]; //salt:@""];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyyMMdd-HHmm"];
    
    NSMutableArray* toDel = [[NSMutableArray alloc] init];
    for (NoteEntity* item in items) {
        NSString* date =  [enc decryptFromBase64:item.dateString];
        if (date == nil) {
            [toDel addObject:item];
        }else{
            item.date = [dateFormat dateFromString:date];
            item.title = [enc decryptFromBase64:item.title];
            item.body = [enc decryptFromBase64:item.body];
            item.dateString = @"";
        }
    }
    
    if ([toDel count] > 0) {
        for (NoteEntity* item in toDel) {
            [items removeObject:item];
        }
    }
    
    // Sort by date
    [items sortUsingComparator:^NSComparisonResult(NoteEntity* obj1, NoteEntity* obj2){
        return [obj2.date compare:obj1.date];
    }];
    
    return items;
}

-(BOOL)saveMessageToNotes:(FullMessageEntity *)message pin:(NSMutableString *)pin
{
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin]; //salt:@""];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyyMMdd-HHmm"];
    
    NoteEntity* item = [[NoteEntity alloc] init];
    
    item.uid = [[NSUUID UUID] UUIDString];
    item.dateString = [enc encryptToBase64:[dateFormat stringFromDate:message.date]];
    item.title = [enc encryptToBase64:message.subject];
    item.body = [enc encryptToBase64:[NSString stringWithFormat:@"From:%@(%@)\nTo:%@\nDate:%@\n\n%@",message.fromAddress, message.fromName, message.toAddress, message.date, message.messageBody]];
    
    return [storage addNote:item];
}

-(BOOL)addNote:(NoteEntity *)item pin:(NSMutableString *)pin
{
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin]; //salt:@""];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyyMMdd-HHmm"];
    item.dateString = [enc encryptToBase64:[dateFormat stringFromDate:item.date]];
    item.title = [enc encryptToBase64:item.title];
    item.body = [enc encryptToBase64:item.body];
    
    return [storage addNote:item];
}

-(BOOL)deleteNote:(NoteEntity *)item pin:(NSMutableString *)pin
{
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    
    return [storage deleteNote:item];
}

-(BOOL)saveNotesWithNewPin:(NSMutableString *)newPin oldPin:(NSMutableString*)oldPin
{
    BOOL ret = YES;
    //Encryptor* enc = [[Encryptor alloc] initWithKey:newPin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:newPin]; //salt:@""];
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyyMMdd-HHmm"];
    
    NSMutableArray* items = [self getNotes:oldPin];
    for (NoteEntity* item in items) {
        item.dateString = [enc encryptToBase64:[dateFormat stringFromDate:item.date]];
        item.title = [enc encryptToBase64:item.title];
        item.body = [enc encryptToBase64:item.body];
    }
    
    ret = [storage writeNotes:items];
    
    return ret;
}

#if !LITE
-(BOOL)saveCerts:(NSArray*)certs pin:(NSMutableString *)pin
{
    // First check, if certs with that bundleID exist... or simply re-write?
    if(!certs)return NO;
    //BOOL ret = YES;
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin];
    Encryptor* expEnc = [[Encryptor alloc] initWithKey:[[UIDevice currentDevice].identifierForVendor UUIDString]];
    
    for (int i=0;i<certs.count-1;i++) { // The last one is an e-mail address
        OneTimeCert* item = certs[i];
        item.yourEmailHash = [Encryptor getSlowHashForString:item.yourEmail];
        item.otherEmailHash = [Encryptor getSlowHashForString:item.otherEmail];
        item.bundleID = [enc encryptToBase64:item.bundleID];
        item.dateUsed = [enc encryptToBase64:item.dateUsed];
        item.expirationDate = [expEnc encryptToBase64:item.expirationDate];
        item.certID = item.certID; //[enc encryptToBase64:item.certID];
        item.certData = [enc encryptAESData:item.certData];
        item.yourEmail = [enc encryptToBase64:item.yourEmail];
        item.otherEmail = [enc encryptToBase64:item.otherEmail];
#if DEBUG
        //NSLog(@"UID = %@, to=%@", item.certID, item.otherEmailHash);
#endif
    }
    
    return [storage saveCerts:certs];
}

-(OneTimeCert*)getCertWithID:(NSString*)uid from:(NSString*)fromAddress
{
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:[GlobalRouter sharedManager].pin];
    Encryptor* expEnc = [[Encryptor alloc] initWithKey:[[UIDevice currentDevice].identifierForVendor UUIDString]];
    OneTimeCert* cert =  [storage getCertWithID:uid from:[Encryptor getSlowHashForString:fromAddress]];
    if (cert) {
        cert.otherEmail = [enc decryptFromBase64:cert.otherEmail];
        cert.yourEmail = [enc decryptFromBase64:cert.yourEmail];
        cert.certData = [enc decryptAESData:cert.certData];
        cert.dateUsed = [enc decryptFromBase64:cert.dateUsed];
        cert.expirationDate = [expEnc decryptFromBase64:cert.expirationDate];
    }
    
    return cert;
}

-(OneTimeCert*)getNextCertFor:(NSString*)otherAddress from:(NSString*)fromAddress
{
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:[GlobalRouter sharedManager].pin];
    //NSString* toAddEnc = [enc encryptToBase64:otherAddress];
    //NSString* fromAddEnc = [enc encryptToBase64:fromAddress];
    OneTimeCert* cert = [storage readNextCertForAddress:[Encryptor getSlowHashForString:otherAddress] from:[Encryptor getSlowHashForString:fromAddress]];
    if (cert) {
        cert.otherEmail = otherAddress;
        cert.yourEmail = fromAddress;
        cert.certData = [enc decryptAESData:cert.certData];
        cert.dateUsed = [enc decryptFromBase64:cert.dateUsed];
        //cert.certID = [enc decryptFromBase64:cert.certID]; // Not encrypted!
    }
    
    return cert;
}

-(BOOL)setExpirationTimeForCert:(NSString*)certID expiration:(NSDate*)date dateUsed:(NSDate*) dateUsed from:(NSString*)fromAddress
{
    Encryptor* enc = [[Encryptor alloc] initWithKey:[GlobalRouter sharedManager].pin];
    Encryptor* expEnc = [[Encryptor alloc] initWithKey:[[UIDevice currentDevice].identifierForVendor UUIDString]];
    return [storage setExpirationTimeForCert:certID expiration:[expEnc encryptToBase64:[OneTimeCert getStringForDate:date] ] dateUsed:[enc encryptToBase64:[OneTimeCert getStringForDate:dateUsed] ] from:[Encryptor getSlowHashForString:fromAddress] plainExpDate:date];
}

-(BOOL)deleteCertWithID:(NSString*)uid from:(NSString*)fromAddress
{
    return [storage deleteCertWithID:uid from:[Encryptor getSlowHashForString:fromAddress]];
}

-(BOOL)deleteExpired
{
    return [storage deleteExpired];
}

-(BOOL)deleteAll
{
    return [storage deleteAll];
}

-(BOOL)deleteAllForAddress:(NSString *)toAddress from:(NSString *)fromAddress
{
    return [storage deleteAllForAddress:[Encryptor getSlowHashForString:toAddress] from:[fromAddress isEqualToString:@""]?@"":[Encryptor getSlowHashForString:fromAddress]];
}

-(void)deleteTheList:(NSArray *)list
{
    return [storage deleteTheList:list];
}

-(NSArray* /*of OneTimeCerts*/)getAllAvailableCertsForPIN:(NSMutableString*)pin
{
    NSMutableArray* ret = [[NSMutableArray alloc] init];
    NSArray* allCerts = [storage readAllCerts];
    Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* expEnc = [[Encryptor alloc] initWithKey:[[UIDevice currentDevice].identifierForVendor UUIDString]];
    // Add only those, that were decrypted successfully
    for (OneTimeCert* cert in allCerts) {
        cert.otherEmail = [enc decryptFromBase64:cert.otherEmail];
        if (cert.otherEmail == nil) {
            continue;
        }
        cert.yourEmail = [enc decryptFromBase64:cert.yourEmail];
        cert.certData = [enc decryptAESData:cert.certData];
        if (cert.certData == nil) {
            continue;
        }
        cert.bundleID = [enc decryptFromBase64:cert.bundleID];
        cert.dateUsed = [enc decryptFromBase64:cert.dateUsed];
        cert.expirationDate = [expEnc decryptFromBase64:cert.expirationDate];
        [ret addObject:cert];
    }
    return ret;
}

-(void)saveOTCsWithNewPIN:(NSMutableString*)newPIN oldPIN:(NSMutableString*)oldPIN
{
    NSArray* certs = [self getAllAvailableCertsForPIN:oldPIN];
    if (certs.count > 0) {
        [self saveCerts:certs pin:newPIN];
    }else{
#if DEBUG
        NSLog(@"No certs");
#endif
    }
}

-(void)saveOTCsWithNewAddresses:(NSString*)oldFrom oldTo:(NSString*)oldTo newFrom:(NSString*)newFrom newTo:(NSString*)newTo
{
    [storage saveOTCsWithNewAddresses:oldFrom oldTo:oldTo newFrom:newFrom newTo:newTo pin:[GlobalRouter sharedManager].pin];
}

#endif

-(void)panic
{
    [storage doPanic];
}

#pragma mark "Shortcuts"
-(NSMutableArray*)getShortcuts:(NSMutableString*)pin
{
    NSMutableArray* items = [storage readShortcuts];
    
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin];
    
    NSMutableArray* toDel = [[NSMutableArray alloc] init];
    for (ShortcutEntity* item in items) {
        NSString* UUID = item.shortcutID;// [enc decryptFromBase64:item.shortcutID];
        if (UUID == nil) {
            [toDel addObject:item];
        }else{
            item.shortcutID = UUID;
            item.shortcutName = [enc decryptFromBase64:item.shortcutName];
            item.shortcutCommand = [enc decryptFromBase64:item.shortcutCommand];
            if(!item.shortcutName && !item.shortcutCommand){
                [toDel addObject:item];
            }
        }
    }
    
    if ([toDel count] > 0) {
        for (ShortcutEntity* item in toDel) {
            [items removeObject:item];
        }
    }

    // Sort by position
    items = [NSMutableArray arrayWithArray: [items sortedArrayUsingComparator:^NSComparisonResult(ShortcutEntity* obj1, ShortcutEntity* obj2) {
      if (obj1.shortcutPosition > obj2.shortcutPosition) {
        return (NSComparisonResult)NSOrderedDescending;
      }
      if (obj1.shortcutPosition < obj2.shortcutPosition) {
        return (NSComparisonResult)NSOrderedAscending;
      }
      return (NSComparisonResult)NSOrderedSame;
    }]];
    
    return items;
}

-(BOOL)saveShortcuts:(NSMutableArray*)shortcuts pin:(NSMutableString*)pin
{
    if(!shortcuts)return NO;
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin];
    
    for (int i=0;i<shortcuts.count;i++) {
        ShortcutEntity* item = shortcuts[i];
        // position and ID are plaintext
        item.shortcutCommand = [enc encryptToBase64:item.shortcutCommand];
        item.shortcutName = [enc encryptToBase64:item.shortcutName];
    }
    
    return [storage writeShortcuts:shortcuts];
}

-(BOOL)deleteShortcut:(ShortcutEntity*)item pin:(NSMutableString*)pin
{
    BOOL ret = [storage deleteShortcut:item];
    return ret;
}

-(BOOL)saveShortcutsWithNewPin:(NSMutableString *)newPin oldPin:(NSMutableString*)oldPin
{
    BOOL ret = YES;
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:newPin];
    
    NSMutableArray* items = [self getShortcuts:oldPin];
    for (ShortcutEntity* item in items) {
        item.shortcutCommand = [enc encryptToBase64:item.shortcutCommand];
        item.shortcutName = [enc encryptToBase64:item.shortcutName];
    }
    
    ret = [storage writeShortcuts:items];
    
    return ret;
}

-(void)deleteAllShortcuts
{
    
}

@end
