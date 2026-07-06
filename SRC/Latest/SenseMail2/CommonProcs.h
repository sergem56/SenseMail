//
//  CommonProcs.h
//  SenseMail2
//
//  Created by Sergey on 17.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
//#import <StoreKit/StoreKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "SelectFolderViewController.h"
#import <Photos/Photos.h>
#import <QuickLook/QuickLook.h>

@class FullMessageEntity;
@class SettingsEntity;
@class FullMessageEntity;
@class KeychainWrapper;

@interface CommonProcs : NSObject <UIActionSheetDelegate, selectedFolderReceiver> {
    FullMessageEntity* currentMessage;
    BOOL isMoving;
}

#define smSavedPinAccount @"smSalt"
+(NSString*)getStringFromKeychainForAccount:(NSString*)account;
+(void)writeValueToKeychain:(id)value forAccount:(NSString*)account;

+(NSArray*)showAttachmentsIcons:(FullMessageEntity *)currentMessage scroll:(UIScrollView *)attScroll;
+(NSString*)getSizeRep:(unsigned long long)size;
+(NSString*)getByteSizeRep:(unsigned long long)size;

//+(UIImageView*)thumbnailViewFromAsset:(ALAsset*)asset;
+(UIImageView*)thumbnailViewFromPath:(NSString*)path;
//+(UIImage*)fullImageFromAsset:(ALAsset*)asset;
+(UIImage*)fullImageFromPHAsset:(PHAsset*)asset;
+(UIImage*)fullImageFromPath:(NSString*)path;
+(UIImage*)getFullImage:(NSObject*)item;
+(NSString*)getTempPathForImage;
+(NSString*)getTempPathForDoc:(NSString*)ext;
+(NSString*)getTempPathForImageInDocuments;
+(NSString*)getTempPathForImageInDocumentsWithExtension:(NSString*)extention;
+(NSString*)getGalleryPath;
+(UIImage*)thumbnailImageFromImage:(UIImage*)image;
+(NSString*)copyFileToTemp:(NSString*)filename;
+(NSString*)copyFileToDocs:(NSString*)filename;
+(NSString*)saveImageForPHAssetToTempFile:(PHAsset*)asset;

+(void)showSmallWheelinView:(UIView*)view;
+(void)setSWLabelText:(NSString*)text;
+(void)hideSmallWheel;
+(BOOL)isSWPresent;
+(void)showWheelinView: (UIView*)view;
+(void)showWheelinView:(UIView*)view message:(NSString*)messageText stopButtonVisible:(BOOL)stopButtonVisible;
+(void)showWheelinView:(UIView*)view message:(NSString*)messageText stopButtonVisible:(BOOL)stopButtonVisible withBlock:(void(^)(void))stopBl;
+(void)showProgress:(int)progress max:(int)maxValue inView:(UIView*)view;
+(void)showProgressWithTitle:(int)progress max:(int)maxValue inView:(UIView*)view title:(NSString*)title stopButton:(BOOL)stopButton;
+(void)showProgressWithTitle:(int)progress max:(int)maxValue inView:(UIView*)view title:(NSString *)title stopButton:(BOOL)stopButton withBlock:(void(^)(void))stopBl;
+(void)setProgress:(int)progress max:(int)maxValue title:(NSString *)title;
+(UIView*)getDimView;

+(void)setMessageInProgress:(NSString*)message;
+(NSString*)getMessageInProgress;
+(void)hideProgress;
+(void)hideProgressAlways;
+(void)addStopButtonInView:(UIView*)view;
+(void)addStopButtonInView:(UIView*)view withBlock:(void(^)(void))stopBl;

+(BOOL)areSettingsEmpty:(SettingsEntity*)settings;

+(void)showBusyInView:(UIView*)view;
+(void)hideBusy;

+(void)showMessage:(NSString*)message title:(NSString*)title;
+(void)askAndDoWithTitle:(NSString*)title text:(NSString*)alertText block:(dispatch_block_t)block;
+(void)askYesNoAndDoWithTitle:(NSString*)title text:(NSString*)alertText blockYes:(dispatch_block_t)blockYes blockNo:(dispatch_block_t)blockNo;
+(void)askYesNoAndDoWithTitles:(NSString*)title text:(NSString*)alertText button1Title:(NSString*)button1Title button2Title:(NSString*)button2Title blockYes:(dispatch_block_t)blockYes blockNo:(dispatch_block_t)blockNo;
+(void)thisFeatureIsInFull:(NSString*)feature;

+(void)spawnProc:(SEL)selector object:(id)object withParam:(id)withObject;
+(void)spawnProcWithProgress:(SEL)selector object:(id)object withParam:(id)withObject;
+(void)spawnProcWithProgress:(SEL)selector object:(id)object withParam1:(id)withObject1 withParam2:(id)withObject2;
+(void)spawnProcWithProgress:(SEL)selector object:(id)object withParam:(id)withObject onMain:(BOOL)onMain;

+(void)increment;
+(void)decrement;

+(NSString*)getPathIntoDocs:(NSString*)fileName;
#ifdef STRONG
+(void)askToMakeKeyFile;
#endif

-(void)wantMoveMessage:(FullMessageEntity*)item fromRect:(CGRect)rect canForward:(BOOL)canForward fromView:(UIView*)viewS fromVC:(UIViewController*)vcS;
#if !LITE
+(void)saveCert:(NSString*)/*Base64*/cert forAddress:(NSString*)address;
#endif
+(BOOL)getSaveResult;

+(void)startPing;

+(NSTextCheckingResult*)isEmailValid:(NSString*)email;
+(NSDate*)dateFromString:(NSString*)string;
+(NSArray*)datesFromString:(NSString*)string;
+(long)longFromString:(NSString*)string;

+(UIImage*)getThumbnailFromURL:(NSURL*)url delegate:(id)delegate;
+(UIImage*)screenshot:(UIView*)theView;
+(UIImage*)sizeAndTypeOnThumbForPath:(NSString*)path thumbnail:(UIImage*)thumb;

+(void)showVanishingMessage:(NSString*)message inView:(UIView*)inView inRect:(CGRect)inRect timeToShow:(int)timeToShow;
+(void)showVanishingMessage:(NSString*)message;
+(void)showVanishingErrorMessage:(NSString*)message;

+(BOOL)checkBioIDAvailable;

+(void)wipeString:(NSString *)string;
+(void)wipeData:(NSData*)data;

+(void)saveToKeychainAlways:(NSString*)toSave account:(NSString*)account service:(NSString*)service;
+(NSString*)getStringFromKeychain:(NSString*)account service:(NSString*)service;
+(CFDataRef)getPersistentDataFromKeychain:(NSString*)account service:(NSString*)service;

+(NSArray*)getColorValues;
+(NSArray*)getColorNames;

@end
