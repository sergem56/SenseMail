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

#import <MailCore/MailCore.h>

@class ListInteractor;
@class SettingsEntity;

@interface DataManager : NSObject{
    //ListInteractor* interactor;
    FullMessageEntity* tempMessage;
    NSMutableString* tempPin;
}

@property (nonatomic, assign) int nAccountsToWait;

//-(id)initWithInteractor:(ListInteractor*)inter;

-(void)getShortMessagesForBox:(boxTypes)btType;
-(void)getNextShortMessagesForBox:(boxTypes)btType;

-(void)getShortMessagesForBoxWithFilter:(boxTypes)btType filter:(NSString*)filter;

-(void)dataReady:(NSArray*)data error:(NSString *)error forSettings:(NSString*)settingsID;
-(void)setProgress:(int)progress max:(int)max;

-(FullMessageEntity*)getFullMessageFor:(ShortMessageEntity*)item PIN:(NSMutableString *)pin forBox:(boxTypes)btType;
-(void)fullMessageReady:(NSData*)data  forShort:(ShortMessageEntity*)sMessage error:(NSString*)error pin:(NSMutableString*)pin;
-(void)fullParsedMessageReady:(MCOMessageParser*)messageParser forShort:(ShortMessageEntity*)sMessage error:(NSString *)error pin:(NSMutableString *)pin;
-(void)fullParsedMessageReady:(MCOMessageParser*)messageParser forShort:(ShortMessageEntity*)sMessage error:(NSString *)error pin:(NSMutableString *)pin preAttachments:(NSArray*)preAttachments html:(NSString*)html;

-(void)tellUpNoMoreButton;

-(BOOL)sendMessage:(FullMessageEntity*)message pin:(NSMutableString*)pin;
-(void)messageSent:(FullMessageEntity*)message error:(NSString*)error;

-(void)deleteMessage:(ShortMessageEntity*)message;
-(void)deleteMessages:(NSArray*)messages;
-(void)deleteAllMessagesFromFolder:(NSString*)folderPath;
-(void)setFlagForMessages:(NSArray*)messages flag:(int)flag;
-(void)setCustomFlagsForMessage:(ShortMessageEntity*)message flags:(NSArray*)flags;
-(void)removeCustomFlagsForMessage:(ShortMessageEntity*)message flags:(NSArray*)flags;
-(void)markAsRead:(ShortMessageEntity*)message;
-(void)toggleStarForMessage:(ShortMessageEntity*)message;
-(void)markAsAnswered:(ShortMessageEntity*)message;

-(NSMutableString*)getPinForMessage:(ShortMessageEntity*)sMessage pin:(NSMutableString*)pin pinTo:(BOOL)pinTo;
-(NSMutableString*)getPinForAddress:(NSString*)address pin:(NSMutableString*)pin pinTo:(BOOL)pinTo;

-(int)readNewMessagesCount;
-(int)readNewMessagesCountBG;
-(int)readNewMessagesCountForFolder:(NSString*)folder address:(NSString*)address;

-(void)createFolder:(NSString*)newFolderName;
-(void)renameFolder:(NSString*)folderName newName:(NSString*)newFolderName;
-(void)copyMessage:(FullMessageEntity*)item to:(NSString*)folderPath;
-(void)copyMessages:(NSArray *)items to:(NSString *)folderPath;
-(void)moveMessage:(FullMessageEntity*)item to:(NSString*)folderPath;
-(void)moveMessages:(NSArray *)items to:(NSString *)folderPath;

//+(NSMutableArray*)defaultAssetsLibrary;
+(void)deleteTempFilesFromMessage:(FullMessageEntity*)message;
+(void)deleteTempFiles;
+(void)rewriteFileAtPath:(NSString*)path;

-(void)checkMailSessions;
-(BOOL)checkConnection:(SettingsEntity*)sett;
-(int)checkSMTPConnection:(SettingsEntity*)sett;
-(void)settingsWasDeletedForAddress:(NSString*)address;

-(void)logoutForAddress:(NSString*)address;
-(BOOL)isAddressLoggedIn:(NSString*)address;

-(void)readFullHeaderForMessage:(ShortMessageEntity*)message;

-(void)clearSessions;
-(void)encryptExistingMessage:(FullMessageEntity*)item pin:(NSMutableString*)newPin;
-(void)reconnectAll;

-(void)deleteExpiredMessages;

@end
