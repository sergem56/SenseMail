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

-(NSArray* /*SettingsEntity*/)getSettings:(NSString*)pin
{
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    NSMutableArray* settingsArray = [NSMutableArray arrayWithArray:[storage readSettings]];
    //NSLog(@"%@\n%@\n%@", settings.userName, settings.userNick, settings.password);
    
    // Decrypt user name, password with pin
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin salt:@""];
    
    NSMutableArray* toDel = [[NSMutableArray alloc] init];
    [GlobalRouter sharedManager].keepInBg = YES;

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
        
        settings.imapPrefix = [enc decryptFromBase64:settings.imapPrefix];
        
        if (settings.userName == nil || [settings.userName isEqualToString:@""]) {
            [toDel addObject:settings];
        }else{
            if([settings.userName isEqualToString:GENERAL_SETTINGS]){
                [GlobalRouter sharedManager].keepInBg = settings.keepInBg;
                if (settings.checkPeriod == 0) {
                    settings.checkPeriod = 60;
                }
                [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:settings.checkPeriod*60];
            }
        }
    }
    
    if (![GlobalRouter sharedManager].keepInBg) {
        [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"salt"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }

    for (SettingsEntity* ent in toDel) {
        [settingsArray removeObject:ent];
    }
    
    return settingsArray;
}

-(BOOL)saveSettings:(SettingsEntity *)settings :(NSString*)pin
{
    //!!!
    //sleep(1);
    
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    
    // Encrypt with pin
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin salt:@""];
    
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
    
    settings.imapPrefix = [enc encryptToBase64:settings.imapPrefix];
    
    return [storage writeSettings:settings];
}

-(BOOL)deleteSetting:(SettingsEntity *)settings
{
    BOOL ret = YES;
    ret = [storage deleteSetting:settings];
    return ret;
}

#pragma mark Address book

-(NSArray*)getAddressBook:(NSString*)pin groupsOnly:(BOOL)groupsOnly
{
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    NSArray* items = [storage readAddressBook:groupsOnly];
    
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin salt:@""];
    
    for (AddressBookEntity* item in items) {
        item.name = [enc decryptFromBase64:item.name];
        item.address = [enc decryptFromBase64:item.address];
        item.note = [enc decryptFromBase64:item.note];
        item.groupID = [enc decryptFromBase64:item.groupID];
        
        // Check if it's fucking long on large address book...
        //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
        NSData* data = [storage readKeyFor:[Encryptor getHashForString:item.address] keyTo:NO forDate:[NSDate date]];
        item.key = data != nil;
    }
    //[self.receiver userInfoFinishedTask:YES];
    return items;
}

-(BOOL)saveAddressBook:(NSArray*)book pin:(NSString*)pin
{
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin salt:@""];
    
    for (AddressBookEntity* item in book) {
        item.name = [enc encryptToBase64:item.name];
        item.address = [enc encryptToBase64:item.address];
        item.note = [enc encryptToBase64:item.note];
        item.key = NO;// [enc encryptAESData:item.key];
        item.groupID = [enc encryptToBase64:item.groupID];
    }
    
    return [storage writeAddressBook:book];
}

-(AddressBookEntity*)findInAddressBook:(NSString*)name address:(NSString*)address pin:(NSString*)pin
{
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin salt:@""];
    
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
        NSData* data = [storage readKeyFor:[Encryptor getHashForString:item.address] keyTo:NO forDate:[NSDate date]];
        item.key = data != nil;
    }
    return item;
}

#pragma mark Keys & certificates

-(NSData*)getKeyFor:(NSString*)address pin:(NSString*)pin keyTo:(BOOL)keyTo forDate:(NSDate*)forDate
{
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin salt:@""];
    
    NSString* addressHash = [Encryptor getHashForString:address];
    
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    NSData* data = [storage readKeyFor:addressHash keyTo:keyTo forDate:forDate];
    if (data == nil) {
        return nil;
    }

    return [enc decryptAESData:data];
}

-(BOOL)saveKeyForAddress:(NSString*)address yourPin:(NSString*)yourPin otherPin:(NSString*)otherPin key:(NSData*)key forDate:(NSDate *)forDate
{
    // Message sent by you To somebody is encrypted with your pin!
    Encryptor* encFrom = [[Encryptor alloc] initWithStrongerKey:otherPin salt:address];
    Encryptor* encTo = [[Encryptor alloc] initWithStrongerKey:yourPin salt:address];
    //Encryptor* enc = [[Encryptor alloc] initWithKey:[GlobalRouter sharedManager].pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:[GlobalRouter sharedManager].pin salt:@""];
    
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    NSString* addressHash = [Encryptor getHashForString:address];
    
    return [storage writeKeyForAddress:addressHash keyTo:[enc encryptAESData:[encTo encryptAESData:key]] keyFrom:[enc encryptAESData:[encFrom encryptAESData:key]] forDate:forDate];
}

-(BOOL)deleteKeyFor:(NSString*)address
{
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    BOOL ret = [storage deleteKeyFor:[Encryptor getHashForString:address]];
    
    return ret;
}

#pragma mark - Gallery

// Returns pairs thumbnail image + full image path
-(NSMutableDictionary*)getGalleryThumbnails:(NSString*)pin
{
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin salt:@""];
    
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    NSDictionary* retDict = [storage readGalleryThumbnails];
    NSMutableDictionary* ret = [[NSMutableDictionary alloc] init];
    for (NSString* key in retDict) {
        UIImage* temp = [UIImage imageWithData:[enc decryptAESData:[retDict valueForKey:key]]];
        if(temp != nil)
            [ret setObject:temp forKey:key];
    }
    return ret;
}

-(UIImage*)getFullImage:(NSString*)path
{
    return [self getFullImage:path pin:[GlobalRouter sharedManager].pin];
}

-(UIImage*)getFullImage:(NSString*)path pin:(NSString*)pin
{
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin salt:@""];
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    
    NSData* retData = [storage readFullImage:path];
    
    UIImage* ret = [UIImage imageWithData:[enc decryptAESData:retData]];
    //[self.receiver userInfoFinishedTask:YES];
    
    return ret;
}

-(BOOL)writeImageData:(UIImage*)data pin:(NSString*)pin
{
    UIImage* thumb = [CommonProcs thumbnailImageFromImage:data];
    
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin salt:@""];
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    
    BOOL ret = [storage writeImageData:[enc encryptAESData:UIImageJPEGRepresentation(data, 1.0)] thumb:[enc encryptAESData:UIImageJPEGRepresentation(thumb, 0.6)]];
    
    [self.receiver userInfoFinishedTask:ret];
    
    return ret;
}

-(BOOL)deleteImage:(NSString *)path
{
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    return [storage deleteImage:path];
}

-(BOOL)saveGalleryWithNewPin:(NSString *)newPin oldPin:(NSString*)oldPin
{
    BOOL ret = YES;
    //Encryptor* enc = [[Encryptor alloc] initWithKey:oldPin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:oldPin salt:@""];
    //Encryptor* encNew = [[Encryptor alloc] initWithKey:newPin];
    Encryptor* encNew = [[GlobalRouter sharedManager] getEncoderForPin:newPin salt:@""];
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    NSDictionary* items = [self getGalleryThumbnails:oldPin];
    for (NSString* key in items) {
        // 1. Read full image
        // 2. Decrypt it
        // 3. Encrypt it
        // 4. Write it
        NSData* fullImage = [storage readFullImage:key];
        fullImage = [enc decryptAESData:fullImage];
        UIImage* thumb = [CommonProcs thumbnailImageFromImage:[UIImage imageWithData:fullImage]];
        // 3
        fullImage = [encNew encryptAESData:fullImage];
        NSData* thumbData = [encNew encryptAESData:UIImageJPEGRepresentation(thumb, 0.6)];
        // 4
        [storage writeImageDataToPath:key fullImage:fullImage thumb:thumbData];
    }
    
    return ret;
}

#pragma mark - Notes

-(NSMutableArray*)getNotes:(NSString *)pin
{
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    NSMutableArray* items = [storage readNotes];
    
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin salt:@""];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyyMMdd-HHmm"];
    
    for (NoteEntity* item in items) {
        NSString* date =  [enc decryptFromBase64:item.dateString];
        item.date = [dateFormat dateFromString:date];
        item.title = [enc decryptFromBase64:item.title];
        item.body = [enc decryptFromBase64:item.body];
        item.dateString = @"";
    }
    
    // Sort by date
    [items sortUsingComparator:^NSComparisonResult(NoteEntity* obj1, NoteEntity* obj2){
        return [obj2.date compare:obj1.date];
    }];
    
    return items;
}

-(BOOL)addNote:(NoteEntity *)item pin:(NSString *)pin
{
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    //Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:pin salt:@""];
    
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyyMMdd-HHmm"];
    item.dateString = [enc encryptToBase64:[dateFormat stringFromDate:item.date]];
    item.title = [enc encryptToBase64:item.title];
    item.body = [enc encryptToBase64:item.body];
    
    return [storage addNote:item];
}

-(BOOL)deleteNote:(NoteEntity *)item pin:(NSString *)pin
{
    //UserInfoDataStorage* storage = [[UserInfoDataStorage alloc]init];
    
    return [storage deleteNote:item];
}

-(BOOL)saveNotesWithNewPin:(NSString *)newPin oldPin:(NSString*)oldPin
{
    BOOL ret = YES;
    //Encryptor* enc = [[Encryptor alloc] initWithKey:newPin];
    Encryptor* enc = [[GlobalRouter sharedManager] getEncoderForPin:newPin salt:@""];
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

@end
