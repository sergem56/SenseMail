//
//  UserInfoDataStorage.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SettingsEntity;
@class AddressBookEntity;
@class NoteEntity;

@interface UserInfoDataStorage : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;

//@property (nonatomic,strong) NSManagedObjectContext* managedObjectContext;

-(NSArray*)readSettings;
-(BOOL)writeSettings:(SettingsEntity*)settings;
-(BOOL)deleteSetting:(SettingsEntity*)settings;

-(NSArray*)readAddressBook;
-(NSArray*)readAddressBook:(BOOL)groupsOnly;
-(BOOL)writeAddressBook:(NSArray*)book;
-(AddressBookEntity*)searchItemInAddressBook:(AddressBookEntity*)item;

-(NSData*)readKeyFor:(NSString*)address keyTo:(BOOL)keyTo forDate:(NSDate*)forDate;
-(BOOL)writeKeyForAddress:(NSString*)address keyTo:(NSData*)keyTo keyFrom:(NSData*)keyFrom forDate:(NSDate*)forDate;
-(BOOL)deleteKeyFor:(NSString*)address;

-(NSDictionary*)readGalleryThumbnails;
-(NSData*)readFullImage:(NSString*)path;
-(BOOL)writeImageData:(NSData*)data thumb:(NSData*)thumb;
-(BOOL)writeImageDataToPath:(NSString*)path fullImage:(NSData *)full thumb:(NSData *)thumb;
-(BOOL)deleteImage:(NSString*)path;

-(NSMutableArray*)readNotes;
-(BOOL)writeNotes:(NSMutableArray*)notes;
-(BOOL)addNote:(NoteEntity*)note;
-(BOOL)deleteNote:(NoteEntity*)note;

@end
