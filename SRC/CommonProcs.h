//
//  CommonProcs.h
//  SenseMail2
//
//  Created by Sergey on 17.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@class FullMessageEntity;
@class SettingsEntity;

@interface CommonProcs : NSObject{
}

+(NSArray*)showAttachmentsIcons:(FullMessageEntity *)currentMessage scroll:(UIScrollView *)attScroll;

+(UIImageView*)thumbnailViewFromAsset:(ALAsset*)asset;
+(UIImageView*)thumbnailViewFromPath:(NSString*)path;
+(UIImage*)fullImageFromAsset:(ALAsset*)asset;
+(UIImage*)fullImageFromPath:(NSString*)path;
+(UIImage*)getFullImage:(NSObject*)item;
+(NSString*)getTempPathForImage;
+(NSString*)getTempPathForImageInDocuments;
+(UIImage*)thumbnailImageFromImage:(UIImage*)image;

+(void)showWheelinView: (UIView*)view;
+(void)showWheelinView:(UIView*)view message:(NSString*)messageText stopButtonVisible:(BOOL)stopButtonVisible;
+(void)showProgress:(int)progress max:(int)maxValue inView:(UIView*)view;
+(void)showProgressWithTitle:(int)progress max:(int)maxValue inView:(UIView*)view title:(NSString*)title stopButton:(BOOL)stopButton;
+(void)setProgress:(int)progress max:(int)maxValue title:(NSString *)title;

+(void)setMessageInProgress:(NSString*)message;
+(NSString*)getMessageInProgress;
+(void)hideProgress;
+(void)addStopButtonInView:(UIView*)view;

+(BOOL)areSettingsEmpty:(SettingsEntity*)settings;

+(void)showBusyInView:(UIView*)view;
+(void)hideBusy;

+(void)showMessage:(NSString*)message title:(NSString*)title;

+(void)spawnProc:(SEL)selector object:(id)object withParam:(id)withObject;
+(void)spawnProcWithProgress:(SEL)selector object:(id)object withParam:(id)withObject;
+(void)spawnProcWithProgress:(SEL)selector object:(id)object withParam1:(id)withObject1 withParam2:(id)withObject2;

+(void)increment;
+(void)decrement;

@end
