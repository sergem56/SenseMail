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

#import "GlobalRouter.h"

@implementation UserInfoDataStorage

//@synthesize managedObjectContext;

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
            ret.keepInBg = [[toRead valueForKey:@"keepInBg"] boolValue];
            ret.checkPeriod = [[toRead valueForKey:@"checkPeriod"] integerValue];
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
        
        BOOL ret = YES;
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
            ret = NO;
        }
        
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
    NSMutableArray* toDel = [[NSMutableArray alloc] init];
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

-(NSData*)readKeyFor:(NSString *)address keyTo:(BOOL)keyTo forDate:(NSDate*)forDate
{
    NSData* ret;
    
    NSManagedObjectContext *context = [self managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    //NSDate* date = [NSDate date];
    if (forDate == nil) {
        forDate = [NSDate date];
    }
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"forAddress LIKE %@ AND date <= %@",address,forDate];
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
        if (keyTo) {
            ret = [[fetchedObjects lastObject] valueForKey:@"keyTo"];
        }else{
            ret = [[fetchedObjects lastObject] valueForKey:@"keyFrom"];
        }
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

-(BOOL)writeKeyForAddress:(NSString*)address keyTo:(NSData*)keyTo keyFrom:(NSData*)keyFrom forDate:(NSDate *)forDate
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
    
    /*
    if (fetchedObjects.count == 0) {
        toSave = [NSEntityDescription insertNewObjectForEntityForName:@"MyKeys" inManagedObjectContext:context];
    }else{
        for (int i = 0; i< fetchedObjects.count-1; i++) {
            toSave = [fetchedObjects objectAtIndex:i];
            [context deleteObject:toSave];
        }
        [context save:&error];
        toSave = [fetchedObjects lastObject];
    }
    */
    
    [toSave setValue:keyTo forKey:@"keyTo"];
    [toSave setValue:keyFrom forKey:@"keyFrom"];
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

#pragma mark - Gallery stuff

// Save thumbs with a ".tmb" extension, full size images with the same name but with no ext.
// Returns dictionary with raw thumb data and a full image file name.
-(NSDictionary*)readGalleryThumbnails
{
    NSMutableDictionary* ret = [[NSMutableDictionary alloc] init];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSError* error;
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:&error];
    for (NSString* item in directoryContent) {
        if ([[item pathExtension] isEqualToString:@"tmb"]) {
            NSString* fullPath = [documentsDirectory stringByAppendingPathComponent:item];
            NSData* val = [NSData dataWithContentsOfFile:fullPath];
            NSString* key = [fullPath stringByDeletingPathExtension];
            [ret setObject:val forKey:key];
        }
    }
    return ret;
}

-(NSData*)readFullImage:(NSString *)path
{
    return [NSData dataWithContentsOfFile:path];
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

-(NSMutableArray*)readNotes
{
    NSMutableArray* ret = [[NSMutableArray alloc] init];
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
    
    return ret;
}

-(BOOL)writeNotes:(NSMutableArray*)notes
{
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
            [toDel addObject:existingObject];
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
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
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
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
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



@end
