//
//  DataManager.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
//#import <MailCore/MailCore.h>
//#import "MessageList.h"
#import "CommonStuff.h"
#import "ShortMessageEntity.h"
#import "FullMessageEntity.h"

@class ListInteractor;

@interface DataManager : NSObject{
    //ListInteractor* interactor;
    FullMessageEntity* tempMessage;
    NSString* tempPin;
}

//@property (nonatomic) ListInteractor* interactor;

//-(id)initWithInteractor:(ListInteractor*)inter;

-(void)getShortMessagesForBox:(boxTypes)btType;
-(void)getNextShortMessagesForBox:(boxTypes)btType;

-(void)getShortMessagesForBoxWithFilter:(boxTypes)btType filter:(NSString*)filter;

-(void)dataReady:(NSArray*)data error:(NSString *)error forSettings:(NSString*)settingsID;
-(void)setProgress:(int)progress max:(int)max;

-(FullMessageEntity*)getFullMessageFor:(ShortMessageEntity*)item PIN:(NSString *)pin forBox:(boxTypes)btType;
-(void)fullMessageReady:(NSData*)data  forShort:(ShortMessageEntity*)sMessage error:(NSString*)error pin:(NSString*)pin;

-(void)tellUpNoMoreButton;

-(BOOL)sendMessage:(FullMessageEntity*)message pin:(NSString*)pin;
-(void)messageSent:(FullMessageEntity*)message error:(NSString*)error;

-(void)deleteMessage:(ShortMessageEntity*)message;
-(void)markAsRead:(ShortMessageEntity*)message;
-(void)toggleStarForMessage:(ShortMessageEntity*)message;

-(NSString*)getPinForMessage:(ShortMessageEntity*)sMessage pin:(NSString*)pin pinTo:(BOOL)pinTo;

-(int)readNewMessagesCount;

+(NSMutableArray*)defaultAssetsLibrary;
+(void)deleteTempFiles;
+(void)rewriteFileAtPath:(NSString*)path;

@end
