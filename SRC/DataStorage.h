//
//  DataStorage.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>
#import "CommonStuff.h"

@class DataManager;
@class ShortMessageEntity;
@class FullMessageEntity;

@class SettingsEntity;

@interface DataStorage : NSObject{
    //DataManager* manager;
    SettingsEntity* settings;
    NSString* currentBoxName;
    boxTypes currentBoxForName;
    int numberOfEmptied;
    
    NSMutableDictionary* settingsNames; // SettingsEntity+emailAddress(=userName)
    
    dispatch_semaphore_t sema;
}

//@property (nonatomic, retain) DataManager* manager;

//-(id)initWithManager:(DataManager*)man;
-(void)readShortMessagesForBox:(boxTypes)btType;
-(void)readNextShortMessagesForBox:(boxTypes)btType;

-(void)loadNMessagesWithFilter:(NSUInteger)nMessages forBox:(boxTypes)btType filter:(NSString*)fromFilter;

-(void)readFullMessageFor:(ShortMessageEntity*)message boxType:(boxTypes)btType pin:(NSString*)pin;

-(void)sendMessage:(FullMessageEntity*)message;

@property (nonatomic, strong) MCOIMAPOperation *imapCheckOp;
@property (nonatomic, strong) MCOIMAPSession *imapSession;
@property (nonatomic, strong) MCOIMAPFetchMessagesOperation *imapMessagesFetchOp;

#pragma mark Multiple accounts
@property (nonatomic, retain) NSMutableArray* imapSessions; // of MCOIMAPSession*


@property (nonatomic, strong) NSArray *messages;
@property (nonatomic, strong) NSMutableDictionary* messagesForAddress;

-(void)resetMessages;

-(void)cancelSessionOps;

-(float)getJPEGCompression;

-(void)deleteMessage:(ShortMessageEntity*)message;

-(void)toggleStarForMessage:(ShortMessageEntity*)message;
-(void)setReadFlagForMessage:(ShortMessageEntity*)message;

-(void)checkSessionForBox:(boxTypes)btType;

-(int)readNewMessagesCount;

@end
