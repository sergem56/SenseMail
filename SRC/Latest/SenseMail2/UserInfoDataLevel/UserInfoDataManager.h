//
//  UserInfoDataManager.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CommonStuff.h"

@class SettingsEntity;
@class AddressBookEntity;
@class NoteEntity;
@class UserInfoDataStorage;
@class FullMessageEntity;
@class OneTimeCert;
@class ShortcutEntity;

@interface UserInfoDataManager : NSObject

@property (nonatomic, weak) id<userInfoNotificationReceiver> receiver;
@property (nonatomic, strong) UserInfoDataStorage* storage;

-(BOOL)isPasswordNeeded;
-(BOOL)showAlert:(NSString*)title; // Checks password, don't mind the name :)

-(NSArray*)getSettings:(NSMutableString*)pin;
-(BOOL)saveSettings:(SettingsEntity*)settings :(NSMutableString*)pin;
-(BOOL)deleteSetting:(SettingsEntity*)settings;

-(NSArray*)getAddressBook:(NSMutableString*)pin groupsOnly:(BOOL)groupsOnly;
-(BOOL)saveAddressBook:(NSArray*)book pin:(NSMutableString*)pin;
-(AddressBookEntity*)findInAddressBook:(NSString*)name address:(NSString*)address pin:(NSMutableString*)pin;
-(BOOL)deleteAddressBookItem:(AddressBookEntity*)item;

#if !LITE
-(NSData*)getKeyFor:(NSString*)address pin:(NSMutableString*)pin forDate:(NSDate*) forDate;
-(BOOL)saveKeyForAddress:(NSString*)address yourPin:(NSMutableString*)yourPin key:(NSData*)key forDate:(NSDate*)forDate;
-(BOOL)deleteKeyFor:(NSString*)address;
-(BOOL)saveAllKeysWithNewPin:(NSMutableString *)newPin oldPin:(NSMutableString*)oldPin;
-(NSMutableArray*)getCertsForAddress:(NSString*)forAddress;
#endif

-(NSMutableDictionary*)getGalleryThumbnails:(NSMutableString*)pin;
-(UIImage*)getFullImage:(NSString*)path;
-(UIImage*)getFullImage:(NSString*)path pin:(NSMutableString*)pin;
-(NSData*)getFullData:(NSString*)path pin:(NSMutableString*)pin;
-(BOOL)writeImageData:(UIImage*)data pin:(NSMutableString*)pin;
-(BOOL)writeURLPathData:(NSURL*)data pin:(NSMutableString*)pin thumb:(UIImage*)thumbnail;
-(BOOL)deleteImage:(NSString*)path;

-(BOOL)saveGalleryWithNewPin:(NSMutableString*)newPin oldPin:(NSMutableString*)oldPin;

-(NSMutableArray*)getNotes:(NSMutableString*)pin;
-(BOOL)addNote:(NoteEntity*)item pin:(NSMutableString*)pin;
-(BOOL)deleteNote:(NoteEntity*)item pin:(NSMutableString*)pin;
-(BOOL)saveNotesWithNewPin:(NSMutableString *)newPin oldPin:(NSMutableString*)oldPin;

-(BOOL)saveMessageToNotes:(FullMessageEntity*)message pin:(NSMutableString*)pin;

#if !LITE
// One-Time certs
// fromAddress is always your address, doesn't matter if you send or receive an email
// otherAddress=toAddress is always your opponent's address
-(BOOL)saveCerts:(NSArray*)certs pin:(NSMutableString *)pin;
-(OneTimeCert*)getCertWithID:(NSString*)uid from:(NSString*)fromAddress; // from address is to avoid ID-collisions since ID is 6-symbol
-(OneTimeCert*)getNextCertFor:(NSString*)otherAddress from:(NSString*)fromAddress;
-(BOOL)setExpirationTimeForCert:(NSString*)certID expiration:(NSDate*)date dateUsed:(NSDate*) dateUsed from:(NSString*)fromAddress;
-(BOOL)deleteCertWithID:(NSString*)uid from:(NSString*)fromAddress;
-(BOOL)deleteExpired;
-(BOOL)deleteAll;
-(BOOL)deleteAllForAddress:(NSString*)toAddress from:(NSString*)fromAddress;
-(void)deleteTheList:(NSArray*)list;
-(NSArray*)getAllAvailableCertsForPIN:(NSMutableString*)pin;
-(void)saveOTCsWithNewPIN:(NSMutableString*)newPIN oldPIN:(NSMutableString*)oldPIN;
-(void)saveOTCsWithNewAddresses:(NSString*)oldFrom oldTo:(NSString*)oldTo newFrom:(NSString*)newFrom newTo:(NSString*)newTo;
#endif
-(void)panic;

-(NSMutableArray*)getShortcuts:(NSMutableString*)pin;
-(BOOL)saveShortcuts:(NSArray*)shortcuts pin:(NSMutableString*)pin;
-(BOOL)deleteShortcut:(ShortcutEntity*)item pin:(NSMutableString*)pin;
-(BOOL)saveShortcutsWithNewPin:(NSMutableString *)newPin oldPin:(NSMutableString*)oldPin;
-(void)deleteAllShortcuts;

@end
