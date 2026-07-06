//
//  UserInfoDataStorage.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "UserInfoDataStorage.h"
#import "SettingsEntity.h"
#import <CoreData/CoreData.h>
#import "AddressBookEntity.h"
#import "Encryptor.h"
#import "CommonProcs.h"
#import "DataManager.h"
#import "NoteEntity.h"
#if !LITE
#import "CertEntity.h"
#import "OneTimeCert.h"
#endif

#import "GlobalRouter.h"
#import "ShortcutEntity.h"

@implementation UserInfoDataStorage

//@synthesize managedObjectContext;

-(BOOL)isDatabaseEmpty
{
    return NO;
}

-(NSArray* /*SettingsEntity*/)readSettings
{
    NSMutableArray* retArray = [[NSMutableArray alloc] init];
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Settings"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSError *error;
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    //NSLog(@"Settings count = %lu", (unsigned long)fetchedObjects.count);
    if(fetchedObjects.count == 0){
        SettingsEntity* ret1 = [[SettingsEntity alloc] init];
        ret1.imapPrefix = @"[GMAIL]";
        ret1.smtpPort = 465;
        ret1.keepInBg = NO;
        ret1.useBioID = NO;
        ret1.connectionTypeSMTP = SMConnectionTypeTLS;
        ret1.connectionTypeIMAP = SMConnectionTypeTLS;
        ret1.SMTPAuthType = MCOAuthTypeSASLLogin;
        [retArray addObject:ret1];
    }else{
        for (NSManagedObject* toRead in fetchedObjects) {
            SettingsEntity* ret = [[SettingsEntity alloc] init];
            ret.settingsName = [toRead valueForKey:@"settingsName"];
            ret.userName = [toRead valueForKey:@"userName"];
            ret.password = [toRead valueForKey:@"password"];
            ret.userNick = [toRead valueForKey:@"userNick"];
            ret.imapServer = [toRead valueForKey:@"imapServer"];
            ret.imapPrefix = [toRead valueForKey:@"imapPrefix"];
            ret.smtpServer = [toRead valueForKey:@"smtpServer"];
            ret.smtpPort = [[toRead valueForKey:@"smtpPort"] integerValue];
            ret.checksum = [toRead valueForKey:@"checksum"];
            ret.compression = [[toRead valueForKey:@"jpegCompression"] floatValue];
#if PERIODIC_CHECK
            ret.keepInBg = [[toRead valueForKey:@"keepInBg"] boolValue];
            ret.checkPeriod = [[toRead valueForKey:@"checkPeriod"] integerValue];
#else
            ret.keepInBg = NO;
            ret.checkPeriod = 0;
#endif
            ret.nMessages = [[toRead valueForKey:@"nMessages"] integerValue];
            ret.useBioID = [[toRead valueForKey:@"useBioID"] boolValue];
            // New values
            ret.imapPort = [[toRead valueForKey:@"imapPort"] integerValue];
            ret.connectionTypeSMTP = [[toRead valueForKey:@"connectionTypeSMTP"] integerValue];
            ret.connectionTypeIMAP = [[toRead valueForKey:@"connectionTypeIMAP"] integerValue];
            ret.SMTPAuthType = [[toRead valueForKey:@"smtpAuthType"] integerValue];
            ret.signature = [toRead valueForKey:@"signature"];
            
            // VPN
            ret.enableVPN = [[toRead valueForKey:@"enableVPN"] boolValue]; // Not encrypted
            ret.vpnUsername = [toRead valueForKey:@"vpnUsername"];
            ret.vpnPassword = [toRead valueForKey:@"vpnPassword"];
            ret.vpnServer = [toRead valueForKey:@"vpnServer"];
            ret.vpnRemoteID = [toRead valueForKey:@"vpnRemoteID"];
            ret.vpnLocalID = [toRead valueForKey:@"vpnLocalID"];
            ret.vpnSharedSecret = [toRead valueForKey:@"vpnSharedSecret"];
            ret.vpnProtocol = [toRead valueForKey:@"vpnProtocol"]; // Not encrypted
            ret.vpnAuthMethod = [[toRead valueForKey:@"vpnAuthMethod"] integerValue]; // Not encrypted
            ret.vpnUseExtAuth = [[toRead valueForKey:@"vpnUseExtAuth"] boolValue]; // Not encrypted
            
            //if([ret.settingsName isEqualToString:GENERAL_SETTINGS]){
            id val = [[NSUserDefaults standardUserDefaults] objectForKey:@"sortByDate"];
            if (val != nil) {
                ret.sortAll = [val boolValue];
            }else{
                ret.sortAll = NO;
            }
            
            // Migrate from the user defaults
            // Check the settings first, if not exists, check the defaults
            
            ret.largeFont = [[toRead valueForKey:@"largeFont"] boolValue];
            ret.sortOrder = [[toRead valueForKey:@"sortOrder"] longValue];
            // This setting is crucial, if not found, make it YES
            id cleanOnBGSetting = [toRead valueForKey:@"cleanOnBg"];
            if(cleanOnBGSetting){
                ret.clearOnBG = [cleanOnBGSetting boolValue];
            }else{
                // Try user defaults
                id val = [[NSUserDefaults standardUserDefaults] objectForKey:@"clearOnBg"];
                if (val != nil) {
                    ret.clearOnBG = [val boolValue];
                }else{
                    ret.clearOnBG = YES;
                }
            }
            ret.doNotHideAccount = [[toRead valueForKey:@"doNotHideAccount"] boolValue];
            ret.useShortcuts = [[toRead valueForKey:@"useShortcuts"] boolValue];
            ret.silentFrom = [toRead valueForKey:@"silentFrom"];
            ret.silentTo = [toRead valueForKey:@"silentTo"];
            
            /*
            ret.largeFont = [[[NSUserDefaults standardUserDefaults] objectForKey:@"largeFont"] boolValue];
            
            ret.sortOrder = [[[NSUserDefaults standardUserDefaults] objectForKey:@"sortOrder"] integerValue];
            
            id clearOnBGid = [[NSUserDefaults standardUserDefaults] objectForKey:@"clearOnBG"];
            if (clearOnBGid) {
                ret.clearOnBG = [clearOnBGid boolValue];
            }else{
                ret.clearOnBG = YES;
            }
            
            id doHotHide = [[NSUserDefaults standardUserDefaults] objectForKey:@"doNotHideAccount"];
            if (doHotHide) {
                ret.doNotHideAccount = [doHotHide boolValue];
            }else{
                ret.doNotHideAccount = NO;
            }
            
            id useShortcuts = [[NSUserDefaults standardUserDefaults] objectForKey:@"useShortcuts"];
            if (useShortcuts) {
                ret.useShortcuts = [useShortcuts boolValue];
            }else{
                ret.useShortcuts = NO;
            }
            
            NSDate* silentFrom = [[NSUserDefaults standardUserDefaults] objectForKey:@"silentFrom"];
            if (silentFrom) {
                ret.silentFrom = silentFrom;
            }else{
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
                dateFormatter.dateFormat = @"k:mm";
                NSDate* dttt = [dateFormatter dateFromString:@"00:00"];
                ret.silentFrom = dttt;
            }
            
            NSDate* silentTo = [[NSUserDefaults standardUserDefaults] objectForKey:@"silentTo"];
            if (silentTo) {
                ret.silentTo = silentTo;
            }else{
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
                dateFormatter.dateFormat = @"k:mm";
                NSDate* dttt = [dateFormatter dateFromString:@"00:00"];
                ret.silentTo = dttt;
            }
            */
            
            //ret.clearOnBG = [[[NSUserDefaults standardUserDefaults] objectForKey:@"clearOnBG"] boolValue];
            //}
            [retArray addObject:ret];
        }
    }
    
    return retArray;
}

-(BOOL)writeSettings:(SettingsEntity *)settings
{
    @synchronized([[GlobalRouter sharedManager] getSettingsRouter]){
        
        NSManagedObjectContext *context = [self managedObjectContext];
        //[context setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy]; // TEMP
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Settings"
                                                  inManagedObjectContext:context];
        [fetchRequest setEntity:entity];
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"checksum LIKE %@",settings.checksum];
        
        [fetchRequest setPredicate:predicate];
        
        NSError *error;
        
        NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
        NSManagedObject *toSave;
        
        if (fetchedObjects.count == 0) {
            toSave = [NSEntityDescription insertNewObjectForEntityForName:@"Settings" inManagedObjectContext:context];
        }else{
            toSave = [fetchedObjects objectAtIndex:0];
        }
        
        [toSave setValue:settings.settingsName forKey:@"settingsName"];
        [toSave setValue:settings.userName forKey:@"userName"];
        [toSave setValue:settings.password forKey:@"password"];
        [toSave setValue:settings.userNick forKey:@"userNick"];
        [toSave setValue:settings.imapServer forKey:@"imapServer"];
        [toSave setValue:settings.imapPrefix forKey:@"imapPrefix"];
        [toSave setValue:settings.smtpServer forKey:@"smtpServer"];
        [toSave setValue:[NSNumber numberWithInt:(int)settings.smtpPort] forKey:@"smtpPort"];
        [toSave setValue:settings.checksum forKey:@"checksum"];
        [toSave setValue:[NSNumber numberWithFloat:settings.compression] forKey:@"jpegCompression"];
        [toSave setValue:[NSNumber numberWithBool:settings.keepInBg] forKey:@"keepInBg"];
        [toSave setValue:[NSNumber numberWithInt:(int)settings.checkPeriod] forKey:@"checkPeriod"];
        [toSave setValue:[NSNumber numberWithInt:(int)settings.nMessages] forKey:@"nMessages"];
        [toSave setValue:[NSNumber numberWithBool:settings.useBioID] forKey:@"useBioID"];
        // New vals
        [toSave setValue:[NSNumber numberWithInt:(int)settings.imapPort] forKey:@"imapPort"];
        [toSave setValue:[NSNumber numberWithInt:(int)settings.connectionTypeSMTP] forKey:@"connectionTypeSMTP"];
        [toSave setValue:[NSNumber numberWithInt:(int)settings.connectionTypeIMAP] forKey:@"connectionTypeIMAP"];
        [toSave setValue:[NSNumber numberWithInt:(int)settings.SMTPAuthType] forKey:@"smtpAuthType"];
        [toSave setValue:settings.signature forKey:@"signature"];
        
        [toSave setValue:[NSNumber numberWithBool:settings.largeFont] forKey:@"largeFont"];
        [toSave setValue:[NSNumber numberWithInt:(int)settings.sortOrder] forKey:@"sortOrder"];
        [toSave setValue:[NSNumber numberWithBool:settings.clearOnBG] forKey:@"cleanOnBg"];
        [toSave setValue:[NSNumber numberWithBool:settings.doNotHideAccount] forKey:@"doNotHideAccount"];
        [toSave setValue:[NSNumber numberWithBool:settings.useShortcuts] forKey:@"useShortcuts"];
        [toSave setValue:settings.silentTo forKey:@"silentTo"];
        [toSave setValue:settings.silentFrom forKey:@"silentFrom"];
        
        // VPN
        [toSave setValue:settings.vpnUsername forKey:@"vpnUsername"];
        [toSave setValue:settings.vpnPassword forKey:@"vpnPassword"];
        [toSave setValue:[NSNumber numberWithBool:settings.enableVPN] forKey:@"enableVPN"];
        [toSave setValue:settings.vpnServer forKey:@"vpnServer"];
        [toSave setValue:settings.vpnRemoteID forKey:@"vpnRemoteID"];
        [toSave setValue:settings.vpnLocalID forKey:@"vpnLocalID"];
        [toSave setValue:settings.vpnSharedSecret forKey:@"vpnSharedSecret"];
        [toSave setValue:[NSNumber numberWithInt:(int)settings.vpnAuthMethod] forKey:@"vpnAuthMethod"];
        [toSave setValue:settings.vpnProtocol forKey:@"vpnProtocol"];
        [toSave setValue:[NSNumber numberWithBool:settings.vpnUseExtAuth] forKey:@"vpnUseExtAuth"];
        
        BOOL ret = YES;
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            ret = NO;
        }else{
            // Settings done
            
        }
        
        // Save sort and large font to user defaults
        //if([settings.settingsName isEqualToString:GENERAL_SETTINGS]){
            
        //}
        return ret;
    }
}

-(BOOL)deleteSetting:(SettingsEntity *)settings
{
    BOOL ret = YES;
    
    @synchronized([[GlobalRouter sharedManager] getSettingsRouter]){
        NSManagedObjectContext *context = [self managedObjectContext];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Settings"
                                                  inManagedObjectContext:context];
        [fetchRequest setEntity:entity];
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"checksum LIKE %@",settings.checksum];
        
        [fetchRequest setPredicate:predicate];
        
        NSError *error;
        
        NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
        NSManagedObject *toDel;
        
        if (fetchedObjects.count == 0) {
            ret = NO;
        }else{
            toDel = [fetchedObjects objectAtIndex:0];
            [context deleteObject:toDel];
            if (![context save:&error]) {
                NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
                ret = NO;
            }
        }
    }
    
    return  ret;
}

-(BOOL)deleteAllSettings
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Settings"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // since everything is encrypted, we need to go throug all the results to find out our cert...
    fetchRequest.fetchLimit = 1000;
    int fetchOffset = 1000;
    NSError *error;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
#if DEBUG
    NSLog(@"Certs found to delete all = %lu", (unsigned long)fetchedObjects.count);
#endif
    int toDel = 0;
    while (fetchedObjects.count > 0) {
        for (NSManagedObject* setting in fetchedObjects) {
            [context deleteObject:setting];
            toDel++;
        }
        if (fetchedObjects.count == 1000) {
            // Fetch next 1000
            fetchRequest.fetchOffset = fetchOffset;
            fetchOffset +=1000;
            fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
            //NSLog(@"Next fetch");
        }else{
            break;
        }
    }
    BOOL ret = NO;
    if(toDel > 0){
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            ret = NO;
        }else{
            ret = YES;
        }
    }else{
        ret = YES;
    }
    return ret;
}


-(NSArray*)readAddressBook
{
    return [self readAddressBook:NO];
}

-(NSArray*)readAddressBook:(BOOL)groupsOnly
{
    NSMutableArray* ret = [[NSMutableArray alloc] init];
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AddressBook"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSError *error;
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    //NSLog(@"Settings count = %lu", (unsigned long)fetchedObjects.count);
    if(fetchedObjects.count == 0){
        
    }else{
        for (NSManagedObject* item in fetchedObjects) {
            
            /*
            NSManagedObjectContext *context2 = [self managedObjectContext];
            
            NSFetchRequest *fetchRequest2 = [[NSFetchRequest alloc] init];
            NSPredicate* predicate2 = [NSPredicate predicateWithFormat:@"forAddress LIKE %@",[Encryptor getHashForString:[item valueForKey:@"address"]]];
            [fetchRequest2 setPredicate:predicate2];
            NSEntityDescription *entity2 = [NSEntityDescription entityForName:@"MyKeys"
                                                      inManagedObjectContext:context2];
            [fetchRequest2 setEntity:entity2];
            NSError *error2;
            NSArray *fetchedObjects2 = [context2 executeFetchRequest:fetchRequest2 error:&error2];
            */
            AddressBookEntity* ben = [[AddressBookEntity alloc] init];
            ben.name = [item valueForKey:@"name"];
            ben.address = [item valueForKey:@"address"];
            ben.note = [item valueForKey:@"note"];
            ben.uid = [item valueForKey:@"uid"];
            ben.key = NO;//fetchedObjects2.count != 0;
            ben.isGroup = [[item valueForKey:@"isGroup"] boolValue];
            ben.groupID = [item valueForKey:@"groupID"];
            if (groupsOnly) {
                if (ben.isGroup) {
                    [ret addObject:ben];
                }
            }else{
                [ret addObject:ben];
            }
        }
    }
    
    return [NSArray arrayWithArray:ret];
}

-(BOOL)writeAddressBook:(NSArray*)book
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AddressBook"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSManagedObject *toSave;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    //NSMutableArray* toDel = [[NSMutableArray alloc] init];
    for(AddressBookEntity* item in book){
        BOOL found = NO;
        
        //AddressBookEntity* source;
        for (NSManagedObject* existingObject in fetchedObjects) {
            if ([[existingObject valueForKey:@"uid"] isEqualToString:item.uid]){//((AddressBookEntity*)existingObject).uid == item.uid) {
                toSave = existingObject;
                //source = item;
                found = YES;
            }
        }
        if(!found){
            toSave = [NSEntityDescription insertNewObjectForEntityForName:@"AddressBook" inManagedObjectContext:context];
            [toSave setValue:item.uid forKey:@"uid"];
        }
        
        [toSave setValue:item.name forKey:@"name"];
        [toSave setValue:item.address forKey:@"address"];
        [toSave setValue:item.note forKey:@"note"];
        [toSave setValue: [NSNumber numberWithBool:item.key] forKey:@"key"];
        [toSave setValue: [NSNumber numberWithBool:item.isGroup] forKey:@"isGroup"];
        [toSave setValue:item.groupID forKey:@"groupID"];
    }
    /*
    for (NSManagedObject* existingObject in fetchedObjects) {
        BOOL found = NO;
        for(AddressBookEntity* item in book){
            if ([[existingObject valueForKey:@"uid"] isEqualToString:item.uid]){//((AddressBookEntity*)existingObject).uid == item.uid) {
                found = YES;
            }
        }
        if (!found) {
            [toDel addObject:existingObject];
        }
    }
    
    for (NSManagedObject* item in toDel) {
        [context deleteObject:item];
    }
    */
    
    BOOL ret = YES;
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        ret = NO;
    }
    
    return ret;
}

-(AddressBookEntity*)searchItemInAddressBook:(AddressBookEntity*)item
{
    //BOOL ret = NO;
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AddressBook"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    //NSPredicate* predicate = [NSPredicate predicateWithFormat:@"name LIKE %@ AND address LIKE %@",item.name,item.address];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"address LIKE %@",item.address];

    [fetchRequest setPredicate:predicate];

    NSError *error;
    NSManagedObject* found;
    AddressBookEntity *ben = nil;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects.count == 0) {
        
    }else{
        found = [fetchedObjects lastObject];
        ben = [[AddressBookEntity alloc] init];
        ben.name = [found valueForKey:@"name"];
        ben.address = [found valueForKey:@"address"];
        ben.note = [found valueForKey:@"note"];
        ben.uid = [found valueForKey:@"uid"];
        ben.key = NO;//fetchedObjects2.count != 0;
        ben.isGroup = [[found valueForKey:@"isGroup"] boolValue];
        ben.groupID = [found valueForKey:@"groupID"];
    }
    
    return ben;
}
    
    
-(BOOL)deleteAddressBookItem:(AddressBookEntity*)item
{
    BOOL ret = NO;
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AddressBook"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    //NSPredicate* predicate = [NSPredicate predicateWithFormat:@"name LIKE %@ AND address LIKE %@",item.name,item.address];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"uid == %@",item.uid];
    
    [fetchRequest setPredicate:predicate];
    
    NSError *error;
    NSManagedObject* found;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects.count == 0) {
        
    }else{
        found = [fetchedObjects lastObject];
        [context deleteObject:found];
        [context save:&error];
        if (!error) {
            ret = YES;
        }
    }
    return ret;
}

-(BOOL)deleteAllAddressBook
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AddressBook"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // since everything is encrypted, we need to go throug all the results to find out our cert...
    fetchRequest.fetchLimit = 1000;
    int fetchOffset = 1000;
    NSError *error;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
#if DEBUG
    NSLog(@"Certs found to delete all = %lu", (unsigned long)fetchedObjects.count);
#endif
    int toDel = 0;
    while (fetchedObjects.count > 0) {
        for (NSManagedObject* ab in fetchedObjects) {
            [context deleteObject:ab];
            toDel++;
        }
        if (fetchedObjects.count == 1000) {
            // Fetch next 1000
            fetchRequest.fetchOffset = fetchOffset;
            fetchOffset +=1000;
            fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
            //NSLog(@"Next fetch");
        }else{
            break;
        }
    }
    BOOL ret = NO;
    if(toDel > 0){
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            ret = NO;
        }else{
            ret = YES;
        }
    }else{
        ret = YES;
    }
    return ret;
}

#pragma Certificates

#if !LITE
-(NSArray*)readAllKeys
{
    NSMutableArray* ret;
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MyKeys" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if(fetchedObjects.count == 0){
        return nil;
    }else{
        ret = [[NSMutableArray alloc] init];
        
        for (NSManagedObject* item in fetchedObjects) {
            CertEntity* cert = [[CertEntity alloc] init];
            cert.forAddress = [item valueForKey:@"forAddress"];
            cert.keyData = [item valueForKey:@"keyData"];
            cert.forDate = [item valueForKey:@"date"];
            cert.note = [item valueForKey:@"note"];
            [ret addObject:cert];
        }
    }
 
    return ret;
}

-(NSMutableArray*)readAllKeysForAddress:(NSString*)address
{
    NSMutableArray* ret;
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"forAddress LIKE %@",address];
    [fetchRequest setPredicate:predicate];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MyKeys"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSSortDescriptor* sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:(YES)];
    [fetchRequest setSortDescriptors:@[sort]];
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if(fetchedObjects.count == 0){
        ret = nil;
    }else{
        ret = [[NSMutableArray alloc] init];
        for (NSManagedObject* item in fetchedObjects) {
            CertEntity* cert = [[CertEntity alloc] init];
            cert.forAddress = [item valueForKey:@"forAddress"];
            cert.keyData = [item valueForKey:@"keyData"];
            cert.forDate = [item valueForKey:@"date"];
            cert.note = [item valueForKey:@"note"];
            [ret addObject:cert];
        }
    }
    context = nil;
    fetchRequest = nil;
    
    return ret;
}

-(NSData*)readKeyFor:(NSString *)address forDate:(NSDate*)forDate
{
    NSData* ret;
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    //NSDate* date = [NSDate date];
    if (forDate == nil) {
        forDate = [NSDate date];
    }
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"forAddress LIKE %@ AND date <= %@",address,forDate];
    //NSPredicate* predicate = [NSPredicate predicateWithFormat:@"date <= %@",forDate];
    [fetchRequest setPredicate:predicate];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MyKeys"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSSortDescriptor* sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:(YES)];
    [fetchRequest setSortDescriptors:@[sort]];
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if(fetchedObjects.count == 0){
        ret = nil;
    }else{
        ret = [[fetchedObjects lastObject] valueForKey:@"keyData"];
    }
    context = nil;
    fetchRequest = nil;
    
    return ret;
}

-(BOOL)deleteKeyFor:(NSString*)address
{
    BOOL ret = YES;
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"forAddress == %@",address];
    [fetchRequest setPredicate:predicate];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MyKeys"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if(fetchedObjects.count == 0){
        ret = YES;
    }else{
        for (NSManagedObject* item in fetchedObjects) {
            [context deleteObject:item];
        }
    }
    
    if (![context save:&error]) {
        ret = NO;
    }
    
    return ret;

}

-(BOOL)writeKeyForAddress:(NSString*)address keyData:(NSData*)keyData forDate:(NSDate *)forDate
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"forAddress LIKE %@",address];
    [fetchRequest setPredicate:predicate];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MyKeys"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSError *error;
    
    //NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];

    NSManagedObject *toSave;
    
    toSave = [NSEntityDescription insertNewObjectForEntityForName:@"MyKeys" inManagedObjectContext:context];
    
    [toSave setValue:keyData forKey:@"keyData"];
    [toSave setValue:address forKey:@"forAddress"];
    if (forDate == nil) {
        forDate = [NSDate date];
    }
    [toSave setValue:forDate forKey:@"date"];
        
    BOOL ret = YES;
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        ret = NO;
    }
    
    return ret;
}

-(BOOL)deleteAllKeys
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"MyKeys"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // since everything is encrypted, we need to go throug all the results to find out our cert...
    fetchRequest.fetchLimit = 1000;
    int fetchOffset = 1000;
    NSError *error;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
#if DEBUG
    NSLog(@"Certs found to delete all = %lu", (unsigned long)fetchedObjects.count);
#endif
    int toDel = 0;
    while (fetchedObjects.count > 0) {
        for (NSManagedObject* key in fetchedObjects) {
            [context deleteObject:key];
            toDel++;
        }
        if (fetchedObjects.count == 1000) {
            // Fetch next 1000
            fetchRequest.fetchOffset = fetchOffset;
            fetchOffset +=1000;
            fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
            //NSLog(@"Next fetch");
        }else{
            break;
        }
    }
    BOOL ret = NO;
    if(toDel > 0){
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            ret = NO;
        }else{
            ret = YES;
        }
    }else{
        ret = YES;
    }
    return ret;
}

#endif

#pragma mark - Gallery stuff

-(void)checkOldGallery
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSError* error;
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:&error];
    
    // Check if Gallery exists
    NSString* galPath = [documentsDirectory stringByAppendingPathComponent:@"Gallery"];
    BOOL isGalleryPresent = [[NSFileManager defaultManager] fileExistsAtPath:galPath isDirectory:NULL];
    if (!isGalleryPresent) {
        [[NSFileManager defaultManager] createDirectoryAtPath:galPath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    
    for (NSString* item in directoryContent) {
        if ([[item pathExtension] isEqualToString:@"tmb"]) {
            NSString* fullSrcPath = [documentsDirectory stringByAppendingPathComponent:item];
            NSString* fullDstPath = [galPath stringByAppendingPathComponent:item];
            [[NSFileManager defaultManager] moveItemAtPath:fullSrcPath toPath:fullDstPath error:&error];
            [[NSFileManager defaultManager] moveItemAtPath:[fullSrcPath stringByDeletingPathExtension] toPath:[fullDstPath stringByDeletingPathExtension] error:&error];
        }
    }
}

// Save thumbs with a ".tmb" extension, full size images with the same name but with no ext.
// Returns dictionary with raw thumb data and a full image file name.
-(NSDictionary*)readGalleryThumbnails
{
    [self checkOldGallery];
    
    NSMutableDictionary* ret = [[NSMutableDictionary alloc] init];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSError* error;
    NSString* galleryDir = [documentsDirectory stringByAppendingPathComponent:@"Gallery"];
    //NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:galleryDir error:&error];
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL fileURLWithPath:galleryDir]
        includingPropertiesForKeys:@[NSURLCreationDateKey]
        options:NSDirectoryEnumerationSkipsHiddenFiles
        error:&error];
    
    NSArray *sortedContent = [directoryContent sortedArrayUsingComparator:
                              ^(NSURL *file1, NSURL *file2)
                              {
                                  // compare
                                  NSDate *file1Date;
                                  [file1 getResourceValue:&file1Date forKey:NSURLCreationDateKey error:nil];
                                  
                                  NSDate *file2Date;
                                  [file2 getResourceValue:&file2Date forKey:NSURLCreationDateKey error:nil];
                                  
                                  // Ascending:
                                  //return [file1Date compare: file2Date];
                                  // Descending:
                                  return [file2Date compare: file1Date];
                              }];
    NSMutableArray* sortedKeys = [[NSMutableArray alloc] init];
    for (NSString* item in sortedContent){// directoryContent) {
        if ([[item pathExtension] isEqualToString:@"tmb"]) {
            NSString* fullPath = [galleryDir stringByAppendingPathComponent:[item lastPathComponent]];
            NSData* val = [NSData dataWithContentsOfFile:fullPath];
            NSString* key = [fullPath stringByDeletingPathExtension];
            [ret setObject:val forKey:key];
            [sortedKeys addObject:key];
        }
    }
    [ret setObject:sortedKeys forKey:@"sorted"];
    return ret;
}

-(NSData*)readFullImage:(NSString *)path
{
    return [NSData dataWithContentsOfFile:path];
}

-(BOOL)writeDocData:(NSData*)data thumb:(NSData*)thumb withExtention:(NSString*)ext
{
    if (data == nil || thumb == nil) {
        return NO;
    }
    
    BOOL ret = YES;
    NSString* fullPath = [CommonProcs getTempPathForImageInDocumentsWithExtension:ext];
    NSString* thumbPath = [fullPath stringByAppendingPathExtension:@"tmb"];
    
    ret = [data writeToFile:fullPath atomically:YES];
    ret &= [thumb writeToFile:thumbPath atomically:YES];
    
    return ret;
}

-(BOOL)writeImageData:(NSData *)data thumb:(NSData *)thumb
{
    if (data == nil || thumb == nil) {
        return NO;
    }
    
    BOOL ret = YES;
    NSString* fullPath = [CommonProcs getTempPathForImageInDocuments];
    NSString* thumbPath = [fullPath stringByAppendingPathExtension:@"tmb"];
    
    ret = [data writeToFile:fullPath atomically:YES];
    ret &= [thumb writeToFile:thumbPath atomically:YES];
    
    return ret;
}

-(BOOL)writeImageDataToPath:(NSString*)path fullImage:(NSData *)full thumb:(NSData *)thumb
{
    if (full == nil || thumb == nil) {
        return NO;
    }
    
    BOOL ret = YES;
    NSString* thumbPath = [path stringByAppendingPathExtension:@"tmb"];
    
    ret = [full writeToFile:path atomically:YES];
    ret &= [thumb writeToFile:thumbPath atomically:YES];
    
    return ret;
}


-(BOOL)deleteImage:(NSString *)path
{
    BOOL ret = YES;
    if (path == nil || [path isEqualToString:@""]) {
        return NO;
    }
    NSString* thumbPath = [path stringByAppendingPathExtension:@"tmb"];
    [DataManager rewriteFileAtPath:path];
    [DataManager rewriteFileAtPath:thumbPath];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError* error;
    [fileManager removeItemAtPath:path error:&error];
    [fileManager removeItemAtPath:thumbPath error:&error];
    
    if (error) {
        ret = NO;
    }
    return ret;
}

-(void)deleteAllItemsInGallery
{
    NSString* galleryPath = [CommonProcs getGalleryPath];
    // Iterate through all objects and delete them all
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray* content = [fm contentsOfDirectoryAtPath:galleryPath error:&error];
    for (NSString *file in content){
        // Spawn parallel processes?
        NSString* toDel = [galleryPath stringByAppendingPathComponent:file];
        [DataManager rewriteFileAtPath:toDel];
        BOOL success = [fm removeItemAtPath:toDel error:&error];
        if (!success || error){
#if DEBUG
            NSLog(@"Failed to delete %@", toDel);
#endif
        }else{
#if DEBUG
            NSLog(@"Deleted %@", toDel);
#endif
        }
    }
}

-(NSMutableArray*)readNotes
{
    NSMutableArray* ret = [[NSMutableArray alloc] init];
    
#ifndef DEMO
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notes"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSError *error;
    
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if(fetchedObjects.count == 0){
        
    }else{
        for (NSManagedObject* item in fetchedObjects) {
            NoteEntity* ben = [[NoteEntity alloc] init];
            ben.uid = [item valueForKey:@"uid"];
            ben.dateString = [item valueForKey:@"dateString"];
            ben.title = [item valueForKey:@"title"];
            ben.body = [item valueForKey:@"body"];
            [ret addObject:ben];
        }
    }
#endif
    
    return ret;
}

-(BOOL)writeNotes:(NSMutableArray*)notes
{
    if (notes.count == 0) {
        return YES;
    }
    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notes"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSManagedObject *toSave;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    NSMutableArray* toDel = [[NSMutableArray alloc] init];
    for(NoteEntity* item in notes){
        BOOL found = NO;
        
        //NoteEntity* source;
        for (NSManagedObject* existingObject in fetchedObjects) {
            if ([[existingObject valueForKey:@"uid"] isEqualToString:item.uid]) {
                toSave = existingObject;
                //source = item;
                found = YES;
            }
        }
        if(!found){
            toSave = [NSEntityDescription insertNewObjectForEntityForName:@"Notes" inManagedObjectContext:context];
            [toSave setValue:item.uid forKey:@"uid"];
        }
        
        [toSave setValue:item.dateString forKey:@"dateString"];
        [toSave setValue:item.title forKey:@"title"];
        [toSave setValue:item.body forKey:@"body"];
    }
    
    for (NSManagedObject* existingObject in fetchedObjects) {
        BOOL found = NO;
        for(NoteEntity* item in notes){
            if ([[existingObject valueForKey:@"uid"] isEqualToString:item.uid]) {
                found = YES;
            }
        }
        if (!found) {
            //[toDel addObject:existingObject]; // There's a bug, notes for other pin get deleted...
        }
    }
    
    for (NSManagedObject* item in toDel) {
        [context deleteObject:item];
    }
    
    BOOL ret = YES;
    if([context hasChanges]){
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            ret = NO;
        }
    }
    return ret;
}

-(BOOL)addNote:(NoteEntity *)note
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notes"
                                              inManagedObjectContext:context];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"uid == %@",note.uid];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSManagedObject *toSave;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    BOOL found = NO;
    if (fetchedObjects.count > 0) {
        found = YES;
        toSave = [fetchedObjects lastObject];
    }
    
    if(!found){
        toSave = [NSEntityDescription insertNewObjectForEntityForName:@"Notes" inManagedObjectContext:context];
        [toSave setValue:note.uid forKey:@"uid"];
    }
    
    [toSave setValue:note.dateString forKey:@"dateString"];
    [toSave setValue:note.title forKey:@"title"];
    [toSave setValue:note.body forKey:@"body"];
    
    BOOL ret = YES;
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        ret = NO;
    }
    
    return ret;
}

-(BOOL)deleteNote:(NoteEntity *)note
{
    BOOL ret = YES;
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notes"
                                              inManagedObjectContext:context];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"uid == %@",note.uid];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setEntity:entity];
    NSError *error;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects.count > 0) {
        for (NSManagedObject* toDel in fetchedObjects) {
            [context deleteObject:toDel];
        }
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            ret = NO;
        }
    }
    
    return ret;
}

-(BOOL)deleteAllNotes
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Notes"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // since everything is encrypted, we need to go throug all the results to find out our cert...
    fetchRequest.fetchLimit = 1000;
    int fetchOffset = 1000;
    NSError *error;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
#if DEBUG
    NSLog(@"Certs found to delete all = %lu", (unsigned long)fetchedObjects.count);
#endif
    int toDel = 0;
    while (fetchedObjects.count > 0) {
        for (NSManagedObject* note in fetchedObjects) {
            [context deleteObject:note];
            toDel++;
        }
        if (fetchedObjects.count == 1000) {
            // Fetch next 1000
            fetchRequest.fetchOffset = fetchOffset;
            fetchOffset +=1000;
            fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
            //NSLog(@"Next fetch");
        }else{
            break;
        }
    }
    BOOL ret = NO;
    if(toDel > 0){
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            ret = NO;
        }else{
            ret = YES;
        }
    }else{
        ret = YES;
    }
    return ret;
}

#pragma mark OneTimeCerts
#if !LITE

// There was a problem with a faster proc - somehow fetchRequest returned not all the matching certs -
// every time the number was different - 193 certs in a database, but returned 5,9,90,95 etc...
// Can make a bit faster check by executing COUNT instead of SELECT, if there are not many matching
// NSError *error = nil;
// NSUInteger count = [managedObjectContext countForFetchRequest:request
//                                                        error:&error];
// if (count == NSNotFound) {
// NSLog(@"Error: %@", error);
// return 0;
// }
// return count;
-(BOOL)saveCerts:(NSArray *)certs
{
    BOOL ret = YES;
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSError *error;
    NSManagedObject *toSave;
    //NSError* error;
    for (int i=0;i<certs.count-1;i++) {
        OneTimeCert* item = certs[i];
        NSLog(@"Processing cert with id %@", item.certID);
        toSave = nil;
        if (item == nil) {
            NSLog(@"Nil item");
            continue;
        }
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneTimeCerts" inManagedObjectContext:context];
        [fetchRequest setEntity:entity];
        
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"uid = %@",item.certID];
        [fetchRequest setPredicate:predicate];
        
        // since everything is encrypted, we need to go throug all the results to find out our cert...
        NSError *error;
        NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
        
        //NSLog(@"Cert %@-to=%@ from=%@",item, item.otherEmailHash, item.yourEmailHash);
        if(fetchedObjects.count == 0){
            toSave = [NSEntityDescription insertNewObjectForEntityForName:@"OneTimeCerts" inManagedObjectContext:context];
        }else{
            for (NSManagedObject* cert in fetchedObjects) {
                if(!toSave){
                    NSLog(@"Found cert with id=%@", item.certID);
                    toSave = cert;
                }else{
                    [context deleteObject:cert]; // delete doubles
                    NSLog(@"Found double cert with id=%@", item.certID);
                }
            }
        }
        [toSave setValue:item.bundleID forKey:@"bundleID"];
        [toSave setValue:item.certID forKey:@"uid"];
        [toSave setValue:item.certData forKey:@"cert"];
        [toSave setValue:item.dateUsed forKey:@"dateUsed"];
        [toSave setValue:item.expirationDate forKey:@"dateExpired"];
        [toSave setValue:item.yourEmail forKey:@"fromAddress"];
        [toSave setValue:item.otherEmail forKey:@"toAddress"];
        [toSave setValue:item.yourEmailHash forKey:@"fromAddressHash"];
        [toSave setValue:item.otherEmailHash forKey:@"toAddressHash"];
        
        // Move that outside of a cycle? But if one fails - no one is saved...
    }
    
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        ret = NO;
    }
    
    return ret;
}
/*
-(BOOL)saveCerts:(NSArray *)certs
{
    BOOL ret = YES;
    NSManagedObjectContext *context = [self managedObjectContext];
    // Read all certs with matching address hashes and do search in that array
    // inefficient, time-consuming, but need to do that not to make clones in case
    // of pin change
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneTimeCerts" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    OneTimeCert* example;
    for (int i=0; i<certs.count-1; i++) {
        example = (OneTimeCert*)certs[i];
        if (example != nil && example.yourEmailHash != nil && example.otherEmailHash != nil) {
            break;
        }
    }
    if (!example) {
        return NO;
    }
    
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"(fromAddressHash == %@ AND toAddressHash == %@) OR (fromAddressHash == %@ AND toAddressHash == %@)",example.yourEmailHash, example.otherEmailHash, example.otherEmail, example.yourEmailHash];
    //NSPredicate* predicate = [NSPredicate predicateWithFormat:@"(%K = %@ AND %K = %@) OR (%K = %@ AND %K = %@)",@"fromAddressHash",example.yourEmailHash, @"toAddressHash",example.otherEmailHash,@"fromAddressHash", example.otherEmail, @"toAddressHash", example.yourEmailHash];
    [fetchRequest setPredicate:predicate];

    // since everything is encrypted, we need to go throug all the results to find out our cert...
    NSError *error;
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    NSLog(@"Found %lu saved certs", (unsigned long)fetchedObjects.count);
    NSManagedObject *toSave;
    //NSError* error;
    for (int i=0;i<certs.count-1;i++) {
        OneTimeCert* item = certs[i];
        if (item == nil) {
            continue;
        }
        // find cert in fetch result
        toSave = nil;
        BOOL found = NO;
        for (NSManagedObject* mObj in fetchedObjects) {
            if ([[mObj valueForKey:@"uid"] isEqualToString:item.certID]) {
                if(!found){
                    toSave = mObj;
                    NSLog(@"Found cert with ID=%@", item.certID);
                    found = YES;
                }else{
                    NSLog(@"Found one more cert with ID=%@", item.certID);
                    [context deleteObject:mObj];
                }
                //break;
            }else{
                //NSLog(@"%@ is not equal to %@", [mObj valueForKey:@"uid"], item.certID);
            }
        }
        //NSLog(@"Cert %@-to=%@ from=%@",item, item.otherEmailHash, item.yourEmailHash);
        if(!toSave)
            toSave = [NSEntityDescription insertNewObjectForEntityForName:@"OneTimeCerts" inManagedObjectContext:context];
        [toSave setValue:item.bundleID forKey:@"bundleID"];
        [toSave setValue:item.certID forKey:@"uid"];
        [toSave setValue:item.certData forKey:@"cert"];
        [toSave setValue:item.dateUsed forKey:@"dateUsed"];
        [toSave setValue:item.expirationDate forKey:@"dateExpired"];
        [toSave setValue:item.yourEmail forKey:@"fromAddress"];
        [toSave setValue:item.otherEmail forKey:@"toAddress"];
        [toSave setValue:item.yourEmailHash forKey:@"fromAddressHash"];
        [toSave setValue:item.otherEmailHash forKey:@"toAddressHash"];
        
        // Move that outside of a cycle? But if one fails - no one is saved...
    }
    
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        ret = NO;
    }
    
    return ret;
}
*/

-(NSArray*)getCertsForBundleID:(NSString*)bundleID
{
    return nil;
}

// to and from addresses are already encrypted with pin... no way, salt is there, cannot compare encrypted strings, they are different every time
// NOT Encrypted anymore, we save hash of the emails and need to fetch all the matches with hash and find not used certs
-(OneTimeCert*)readNextCertForAddress:(NSString *)toAddress from:(NSString *)fromAddress
{
    //NSData* ret;
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneTimeCerts"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"(fromAddressHash == %@ AND toAddressHash == %@) OR (toAddressHash == %@ AND fromAddressHash == %@)",fromAddress, toAddress, fromAddress, toAddress];
    [fetchRequest setPredicate:predicate];
    
    // since everything is encrypted, we need to go throug all the results to find out our cert...
    fetchRequest.fetchLimit = 1000;
    int fetchOffset = 1000;
    NSError *error;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    OneTimeCert* otc = nil;
    Encryptor* enc = [[Encryptor alloc] initWithKey:[GlobalRouter sharedManager].pin];
#if DEBUG
    NSLog(@"Certs found = %lu", (unsigned long)fetchedObjects.count);
#endif
    while (fetchedObjects.count > 0) {
        for (NSManagedObject* cert in fetchedObjects) {
            NSString* dtusd = [enc decryptFromBase64:[cert valueForKey:@"dateUsed"]];
            //NSString* dtexp = [enc decryptFromBase64:[cert valueForKey:@"dateExpired"]];
#if DEBUG
            NSLog(@"Date used = %@", dtusd);
#endif
            if ([dtusd isEqualToString:@""] && !cert.isFault) {
                otc = [[OneTimeCert alloc] init];
                otc.certID = [cert valueForKey:@"uid"];
                otc.certData = [cert valueForKey:@"cert"];
                otc.yourEmail = [cert valueForKey:@"fromAddress"];
                otc.otherEmail = [cert valueForKey:@"toAddress"];
                otc.dateUsed = [cert valueForKey:@"dateUsed"];
                //NSLog(@"Raw cert date='%@'", otc.dateUsed);
                goto ret;
            }
        }
        if (!otc && fetchedObjects.count == 1000) {
            // Fetch next 1000
            fetchRequest.fetchOffset = fetchOffset;
            fetchOffset +=1000;
            fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
            //NSLog(@"Next fetch");
        }else{
            break;
        }
    }
ret:
    return otc;
}

-(OneTimeCert*)getCertWithID:(NSString*)uid from:(NSString*)fromAddressHash
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneTimeCerts"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"(fromAddressHash == %@ OR toAddressHash == %@) AND uid == %@",fromAddressHash, fromAddressHash, uid];
    [fetchRequest setPredicate:predicate];
    
    NSError *error;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    OneTimeCert* otc = nil;
    if (fetchedObjects.count > 0) {
        NSManagedObject* cert = [fetchedObjects lastObject];
        otc = [[OneTimeCert alloc] init];
        otc.certID = [cert valueForKey:@"uid"];
        otc.certData = [cert valueForKey:@"cert"];
        otc.yourEmail = [cert valueForKey:@"fromAddress"];
        otc.otherEmail = [cert valueForKey:@"toAddress"];
        otc.dateUsed = [cert valueForKey:@"dateUsed"];
        otc.expirationDate = [cert valueForKey:@"dateExpired"];
    }

    return otc;
}

-(BOOL)setExpirationTimeForCert:(NSString*)certID expiration:(NSString*)date dateUsed:(NSString*) dateUsed from:(NSString*)fromAddressHash plainExpDate:(NSDate*)plExpDate
{
    BOOL ret = NO;
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneTimeCerts"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"(fromAddressHash == %@ OR toAddressHash == %@) AND uid == %@",fromAddressHash, fromAddressHash, certID];
    [fetchRequest setPredicate:predicate];
    
    NSError *error;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects.count > 0) {
        for (NSManagedObject* cert in fetchedObjects) { // What if certs double? Set date to all of them!
            if([plExpDate compare:[NSDate date]] == NSOrderedAscending){
                // Cert already expired... delete it?
                [cert setValue:[[Encryptor getUUIDofLength:64] dataUsingEncoding:NSUTF8StringEncoding] forKey:@"cert"]; // Overwrite cert data
                [context save:&error];
                [context deleteObject:cert];
            }else{
                [cert setValue:dateUsed forKey:@"dateUsed"];
                [cert setValue:date forKey:@"dateExpired"];
            }
        }
        
        if (![context save:&error]) {
#if DEBUG
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
#endif
            ret = NO;
        }else{
            ret = YES;
        }
    }else{
        // Shouldn't get here. Perhaps the cert is already deleted...
        ret = NO;
#if DEBUG
        NSLog(@"Something strange, cert not found...");
#endif
    }
    
    return ret;
}

-(BOOL)deleteCertWithID:(NSString*)uid from:(NSString*)fromAddressHash
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneTimeCerts"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"(fromAddressHash == %@ OR toAddressHash == %@) AND uid == %@",fromAddressHash, fromAddressHash, uid];
    [fetchRequest setPredicate:predicate];
    
    NSError *error;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    BOOL ret = NO;
    if (fetchedObjects.count > 0) {
        for (NSManagedObject* cert in fetchedObjects) {
            //NSManagedObject* cert = [fetchedObjects lastObject];
            [cert setValue:[[Encryptor getUUIDofLength:64] dataUsingEncoding:NSUTF8StringEncoding] forKey:@"cert"]; // Overwrite cert data
            [context save:&error];
            [context deleteObject:cert];
        }
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            ret = NO;
        }else{
            ret = YES;
        }
    }
    
    return ret;
}

-(BOOL)deleteExpired
{
    //NSData* ret;
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneTimeCerts"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // since everything is encrypted, we need to go throug all the results to find out our cert...
    fetchRequest.fetchLimit = 1000;
    int fetchOffset = 1000;
    NSError *error;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    //Encryptor* enc = [[Encryptor alloc] initWithKey:[GlobalRouter sharedManager].pin];
    Encryptor* expEnc = [[Encryptor alloc] initWithKey:[[UIDevice currentDevice].identifierForVendor UUIDString]];
#if DEBUG
    NSLog(@"Certs found = %lu", (unsigned long)fetchedObjects.count);
#endif
    int toDel = 0;
    while (fetchedObjects.count > 0) {
        for (NSManagedObject* cert in fetchedObjects) {
            NSString* dtusd = [expEnc decryptFromBase64:[cert valueForKey:@"dateExpired"]];
            if (!(dtusd == nil || [dtusd isEqual:MESSAGE_INVALID_PWD] || [dtusd isEqualToString:@""]) && !cert.isFault) {
                if([[OneTimeCert getDateForString:dtusd] compare:[NSDate date]] == NSOrderedAscending){
                    [cert setValue:[[Encryptor getUUIDofLength:32] dataUsingEncoding:NSUTF8StringEncoding] forKey:@"cert"]; // overwrite again
                    //[context save:&error]; save here to overwrite?
                    [context deleteObject:cert];
                    toDel++;
                }
            }
        }
        if (fetchedObjects.count == 1000) {
            // Fetch next 1000
            fetchRequest.fetchOffset = fetchOffset;
            fetchOffset +=1000;
            fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
            //NSLog(@"Next fetch");
        }else{
            break;
        }
    }
    BOOL ret = NO;
    if(toDel > 0){
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            ret = NO;
        }else{
#if DEBUG
            NSLog(@"deleted = %d",toDel);
#endif
            ret = YES;
        }
    }else{
        ret = YES;
    }
    return ret;
}

-(BOOL)deleteAll
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneTimeCerts"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // since everything is encrypted, we need to go throug all the results to find out our cert...
    fetchRequest.fetchLimit = 1000;
    int fetchOffset = 1000;
    NSError *error;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
#if DEBUG
    NSLog(@"Certs found to delete all = %lu", (unsigned long)fetchedObjects.count);
#endif
    int toDel = 0;
    while (fetchedObjects.count > 0) {
        for (NSManagedObject* cert in fetchedObjects) {
            [context deleteObject:cert];
            toDel++;
        }
        if (fetchedObjects.count == 1000) {
            // Fetch next 1000
            fetchRequest.fetchOffset = fetchOffset;
            fetchOffset +=1000;
            fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
            //NSLog(@"Next fetch");
        }else{
            break;
        }
    }
    BOOL ret = NO;
    if(toDel > 0){
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            ret = NO;
        }else{
            ret = YES;
        }
    }else{
        ret = YES;
    }
    return ret;
}

-(BOOL)deleteAllForAddress:(NSString *)toAddressHash from:(NSString *)fromAddressHash
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneTimeCerts"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"fromAddressHash == %@ AND toAddressHash == %@ ",fromAddressHash, toAddressHash/*, fromAddressHash, toAddressHash*/]; // OR (toAddressHash == %@ AND fromAddressHash == %@)
    if ([fromAddressHash isEqualToString:@""]) {
        predicate = [NSPredicate predicateWithFormat:@"toAddressHash == %@", toAddressHash/*, toAddressHash*/]; // OR fromAddressHash == %@
    }
    
    [fetchRequest setPredicate:predicate];
    
    // since everything is encrypted, we need to go throug all the results to find out our cert...
    fetchRequest.fetchLimit = 1000;
    int fetchOffset = 1000;
    NSError *error;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
#if DEBUG
    NSLog(@"Certs found to delete all = %lu", (unsigned long)fetchedObjects.count);
#endif
    int toDel = 0;
    while (fetchedObjects.count > 0) {
        for (NSManagedObject* cert in fetchedObjects) {
            [context deleteObject:cert];
            toDel++;
        }
        if (fetchedObjects.count == 1000) {
            // Fetch next 1000
            fetchRequest.fetchOffset = fetchOffset;
            fetchOffset +=1000;
            fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
            //NSLog(@"Next fetch");
        }else{
            break;
        }
    }
    BOOL ret = NO;
    if(toDel > 0){
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            ret = NO;
        }else{
            ret = YES;
        }
    }else{
        ret = YES;
    }
    return ret;
}

-(void)deleteTheList:(NSArray *)list
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneTimeCerts"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    for (OneTimeCert* cert in list) {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"uid == %@",cert.certID];
        [fetchRequest setPredicate:predicate];
        
        NSError *error;
        
        NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
        BOOL ret = NO;
        if (fetchedObjects.count > 0) {
            for (NSManagedObject* cert in fetchedObjects) {
                //NSManagedObject* cert = [fetchedObjects lastObject];
                [cert setValue:[[Encryptor getUUIDofLength:64] dataUsingEncoding:NSUTF8StringEncoding] forKey:@"cert"]; // Overwrite cert data
                [context save:&error]; // Save to overwrite
                [context deleteObject:cert];
            }
            if (![context save:&error]) {
                NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
                ret = NO;
            }else{
                ret = YES;
            }
        }
    }
}

-(NSArray*)readAllCerts
{
    NSMutableArray* ret = [[NSMutableArray alloc] init];
    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneTimeCerts"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // since everything is encrypted, we need to go throug all the results to find out our cert...
    fetchRequest.fetchLimit = 1000;
    int fetchOffset = 1000;
    NSError *error;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
#if DEBUG
    NSLog(@"All Certs found = %lu", (unsigned long)fetchedObjects.count);
#endif
    while (fetchedObjects.count > 0) {
        for (NSManagedObject* cert in fetchedObjects) {
            OneTimeCert* otc = nil;
            otc = [[OneTimeCert alloc] init];
            otc.certID = [cert valueForKey:@"uid"];
            otc.bundleID = [cert valueForKey:@"bundleID"];
            otc.certData = [cert valueForKey:@"cert"];
            otc.yourEmail = [cert valueForKey:@"fromAddress"];
            otc.otherEmail = [cert valueForKey:@"toAddress"];
            otc.dateUsed = [cert valueForKey:@"dateUsed"];
            otc.expirationDate = [cert valueForKey:@"dateExpired"];
            otc.yourEmailHash = [cert valueForKey:@"fromAddressHash"];
            otc.otherEmailHash = [cert valueForKey:@"toAddressHash"];
            [ret addObject:otc];
        }
        if (fetchedObjects.count == 1000) {
            // Fetch next 1000
            fetchRequest.fetchOffset = fetchOffset;
            fetchOffset +=1000;
            fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
            NSLog(@"Next fetch");
        }else{
            break;
        }
    }
    
    return ret;
}

-(void)saveOTCsWithNewAddresses:(NSString*)oldFrom oldTo:(NSString*)oldTo newFrom:(NSString*)newFrom newTo:(NSString*)newTo pin:(NSString*)pin
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"OneTimeCerts"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"(fromAddressHash == %@ AND toAddressHash == %@) OR (toAddressHash == %@ AND fromAddressHash == %@)",[Encryptor getSlowHashForString:oldFrom], [Encryptor getSlowHashForString:oldTo], [Encryptor getSlowHashForString:oldFrom], [Encryptor getSlowHashForString:oldTo]];
    
    [fetchRequest setPredicate:predicate];
    
    // since everything is encrypted, we need to go throug all the results to find out our cert...
    fetchRequest.fetchLimit = 1000;
    int fetchOffset = 1000;
    NSError *error;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
#if DEBUG
    NSLog(@"Certs found to change all = %lu", (unsigned long)fetchedObjects.count);
#endif
    Encryptor* enc = [[Encryptor alloc] initWithKey:pin];
    while (fetchedObjects.count > 0) {
        for (NSManagedObject* cert in fetchedObjects) {
            [cert setValue:[enc encryptToBase64:newFrom] forKey:@"fromAddress"];
            [cert setValue:[enc encryptToBase64:newTo] forKey:@"toAddress"];
            [cert setValue:[Encryptor getSlowHashForString:newFrom] forKey:@"fromAddressHash"];
            [cert setValue:[Encryptor getSlowHashForString:newTo] forKey:@"toAddressHash"];
        }
        if (fetchedObjects.count == 1000) {
            // Fetch next 1000
            fetchRequest.fetchOffset = fetchOffset;
            fetchOffset +=1000;
            fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
            //NSLog(@"Next fetch");
        }else{
            break;
        }
    }
    BOOL ret = NO;
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        ret = NO;
    }else{
        ret = YES;
    }
    
    //return ret;
}

#endif

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "st-mobdev.testCore" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"UserDataModel" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"SenseMail2.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    // Migrate to the new version of the data model automatically
    NSDictionary *options =
    @{
      NSMigratePersistentStoresAutomaticallyOption:@YES,
      NSPersistentStoreFileProtectionKey:NSFileProtectionCompleteUntilFirstUserAuthentication, //NSFileProtectionComplete,
      NSInferMappingModelAutomaticallyOption:@YES,
      NSSQLiteManualVacuumOption:@YES // return the free space, get rid of deleted items
    };
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        //abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            //abort();
        }
    }
}

-(void)doPanic
{
    // 1. delete all settings. This is the first thing to do
    // 2. delete address book
    // 3. delete notes
    // 4. delete keychain items
    // 5. delete certs
    // 6. delete OTC
    // 7. delete gallery
    // 8. delete user defaults
    // 9. delete shortcuts
    
    // 1.
    [self deleteAllSettings];
    // 2.
    [self deleteAllAddressBook];
    //3.
    [self deleteAllNotes];
    // 4.
    NSMutableDictionary *returnDictionary0 = [[NSMutableDictionary alloc] init];
    [returnDictionary0 setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [returnDictionary0 setObject:@"SMService" forKey:(__bridge id)kSecAttrService];
    [returnDictionary0 setObject:@"SMAccount" forKey:(__bridge id)kSecAttrAccount];
    SecItemDelete((__bridge CFDictionaryRef)returnDictionary0);
    // 5.
#if !LITE
    [self deleteAllKeys];
    // 6.
    [self deleteAll];
#endif
    // 7.
    [self deleteAllItemsInGallery];
    // 8.
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    // 9.
    [self deleteAllShortcuts];
    
    NSLog(@"All clear!");
}

-(NSMutableArray*)readShortcuts
{
    NSMutableArray* ret = [[NSMutableArray alloc] init];
        
    #ifndef DEMO
        NSManagedObjectContext *context = [self managedObjectContext];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Shortcuts"
                                                  inManagedObjectContext:context];
        [fetchRequest setEntity:entity];
        NSError *error;
        
        NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
        
        if(fetchedObjects.count == 0){
            
        }else{
            for (NSManagedObject* item in fetchedObjects) {
                ShortcutEntity* ben = [[ShortcutEntity alloc] init];
                ben.shortcutPosition = [[item valueForKey:@"shPosition"] intValue];
                ben.shortcutID = [item valueForKey:@"shID"];
                ben.shortcutCommand = [item valueForKey:@"shCommand"];
                ben.shortcutName = [item valueForKey:@"shName"];
                [ret addObject:ben];
            }
        }
    #endif
        
    return ret;
}

-(BOOL)writeShortcuts:(NSMutableArray*)shortcuts
{
    if (shortcuts.count == 0) {
        return YES;
    }
    
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Shortcuts"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    NSError *error;
    NSManagedObject *toSave;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    for(ShortcutEntity* item in shortcuts){
        BOOL found = NO;
        
        for (NSManagedObject* existingObject in fetchedObjects) {
            if ([[existingObject valueForKey:@"shID"] isEqualToString:item.shortcutID]) {
                toSave = existingObject;
                found = YES;
            }
        }
        if(!found){
            toSave = [NSEntityDescription insertNewObjectForEntityForName:@"Shortcuts" inManagedObjectContext:context];
            [toSave setValue:item.shortcutID forKey:@"shID"];
        }
        [toSave setValue:[NSNumber numberWithInt:item.shortcutPosition] forKey:@"shPosition"];
        [toSave setValue:item.shortcutCommand forKey:@"shCommand"];
        [toSave setValue:item.shortcutName forKey:@"shName"];
    }
    
    BOOL ret = YES;
    if([context hasChanges]){
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            ret = NO;
        }
    }
    return ret;
}

-(BOOL)addShortcut:(ShortcutEntity*)shortcut
{
    return YES;
}

-(BOOL)deleteShortcut:(ShortcutEntity*)shortcut
{
    BOOL ret = YES;
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Shortcuts"
                                              inManagedObjectContext:context];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"shID == %@",shortcut.shortcutID];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setEntity:entity];
    NSError *error;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if (fetchedObjects.count > 0) {
        for (NSManagedObject* toDel in fetchedObjects) {
            [context deleteObject:toDel];
        }
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            ret = NO;
        }
    }
    
    return ret;
}

-(BOOL)deleteAllShortcuts
{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Shortcuts"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // since everything is encrypted, we need to go throug all the results to find out our cert...
    fetchRequest.fetchLimit = 1000;
    int fetchOffset = 1000;
    NSError *error;
    
    NSArray* fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
    
#if DEBUG
    NSLog(@"Shortcuts found to delete all = %lu", (unsigned long)fetchedObjects.count);
#endif
    int toDel = 0;
    while (fetchedObjects.count > 0) {
        for (NSManagedObject* note in fetchedObjects) {
            [context deleteObject:note];
            toDel++;
        }
        if (fetchedObjects.count == 1000) {
            // Fetch next 1000
            fetchRequest.fetchOffset = fetchOffset;
            fetchOffset +=1000;
            fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];
            //NSLog(@"Next fetch");
        }else{
            break;
        }
    }
    BOOL ret = NO;
    if(toDel > 0){
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            ret = NO;
        }else{
            ret = YES;
        }
    }else{
        ret = YES;
    }
    
    return ret;
}

@end
