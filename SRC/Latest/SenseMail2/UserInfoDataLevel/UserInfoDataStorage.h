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
@class ShortcutEntity;
#if !LITE
@class OneTimeCert;
#endif

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
-(BOOL)deleteAddressBookItem:(AddressBookEntity*)item;

#if !LITE
-(NSArray*)readAllKeys;
-(NSMutableArray*)readAllKeysForAddress:(NSString*)address;
-(NSData*)readKeyFor:(NSString*)address forDate:(NSDate*)forDate;
-(BOOL)writeKeyForAddress:(NSString*)address keyData:(NSData*)keyData forDate:(NSDate*)forDate;
-(BOOL)deleteKeyFor:(NSString*)address;
#endif
-(NSDictionary*)readGalleryThumbnails;
-(NSData*)readFullImage:(NSString*)path;
-(BOOL)writeImageData:(NSData*)data thumb:(NSData*)thumb;
-(BOOL)writeImageDataToPath:(NSString*)path fullImage:(NSData *)full thumb:(NSData *)thumb;
-(BOOL)writeDocData:(NSData*)data thumb:(NSData*)thumb withExtention:(NSString*)ext;
-(BOOL)deleteImage:(NSString*)path;
-(void)deleteAllItemsInGallery;

-(NSMutableArray*)readNotes;
-(BOOL)writeNotes:(NSMutableArray*)notes;
-(BOOL)addNote:(NoteEntity*)note;
-(BOOL)deleteNote:(NoteEntity*)note;

#pragma mark -One-time certs
#if !LITE
-(BOOL)saveCerts:(NSArray*)certs;
-(NSArray*)getCertsForBundleID:(NSString*)bundleID;
-(OneTimeCert*)readNextCertForAddress:(NSString*)toAddress from:(NSString*)fromAddress;
-(OneTimeCert*)getCertWithID:(NSString*)uid from:(NSString*)fromAddressHash;
-(BOOL)setExpirationTimeForCert:(NSString*)certID expiration:(NSString*)date dateUsed:(NSString*) dateUsed from:(NSString*)fromAddressHash  plainExpDate:(NSDate*)plExpDate;
-(BOOL)deleteCertWithID:(NSString*)uid from:(NSString*)fromAddressHash;
-(BOOL)deleteExpired;
-(BOOL)deleteAll;
-(BOOL)deleteAllForAddress:(NSString*)toAddressHash from:(NSString*)fromAddressHash;
-(void)deleteTheList:(NSArray*)list;
-(NSArray*)readAllCerts;
-(void)saveOTCsWithNewAddresses:(NSString*)oldFrom oldTo:(NSString*)oldTo newFrom:(NSString*)newFrom newTo:(NSString*)newTo pin:(NSString*)pin;
#endif
-(void)doPanic;

-(NSMutableArray*)readShortcuts;
-(BOOL)writeShortcuts:(NSMutableArray*)shortcuts;
-(BOOL)addShortcut:(ShortcutEntity*)shortcut;
-(BOOL)deleteShortcut:(ShortcutEntity*)shortcut;
-(BOOL)deleteAllShortcuts;

@end
