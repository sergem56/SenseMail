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

@interface UserInfoDataManager : NSObject

@property (nonatomic, weak) id<userInfoNotificationReceiver> receiver;
@property (nonatomic, strong) UserInfoDataStorage* storage;

-(BOOL)isPasswordNeeded;
-(BOOL)showAlert:(NSString*)title; // Checks password, don't mind the name :)

-(NSArray*)getSettings:(NSString*)pin;
-(BOOL)saveSettings:(SettingsEntity*)settings :(NSString*)pin;
-(BOOL)deleteSetting:(SettingsEntity*)settings;

-(NSArray*)getAddressBook:(NSString*)pin groupsOnly:(BOOL)groupsOnly;
-(BOOL)saveAddressBook:(NSArray*)book pin:(NSString*)pin;
-(AddressBookEntity*)findInAddressBook:(NSString*)name address:(NSString*)address pin:(NSString*)pin;

-(NSData*)getKeyFor:(NSString*)address pin:(NSString*)pin keyTo:(BOOL)keyTo forDate:(NSDate*) forDate;
-(BOOL)saveKeyForAddress:(NSString*)address yourPin:(NSString*)yourPin otherPin:(NSString*)otherPin key:(NSData*)key forDate:(NSDate*)forDate;
-(BOOL)deleteKeyFor:(NSString*)address;

-(NSMutableDictionary*)getGalleryThumbnails:(NSString*)pin;
-(UIImage*)getFullImage:(NSString*)path;
-(UIImage*)getFullImage:(NSString*)path pin:(NSString*)pin;
-(BOOL)writeImageData:(UIImage*)data pin:(NSString*)pin;
-(BOOL)deleteImage:(NSString*)path;

-(BOOL)saveGalleryWithNewPin:(NSString*)newPin oldPin:(NSString*)oldPin;

-(NSMutableArray*)getNotes:(NSString*)pin;
-(BOOL)addNote:(NoteEntity*)item pin:(NSString*)pin;
-(BOOL)deleteNote:(NoteEntity*)item pin:(NSString*)pin;
-(BOOL)saveNotesWithNewPin:(NSString *)newPin oldPin:(NSString*)oldPin;

@end
