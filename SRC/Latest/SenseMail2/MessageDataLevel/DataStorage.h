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
#import <UIKit/UIKit.h>

//#import "FXKeychain.h"
//#import "GTMOAuth2ViewControllerTouch.h"


@class DataManager;
@class ShortMessageEntity;
@class FullMessageEntity;

@class SettingsEntity;
@class SessionConnectorNew;

@interface DataStorage : NSObject{
    //DataManager* manager;
    //SettingsEntity* settings;
    NSMutableDictionary* currentBoxesName;
    NSString* currentBoxName;
    boxTypes currentBoxForName;
    int numberOfEmptied;
    
    //NSMutableDictionary* settingsNames; // SettingsEntity+emailAddress(=userName) // Moved to Global Router
    
    dispatch_semaphore_t sema;
    dispatch_semaphore_t conSem;
    dispatch_semaphore_t authSem;
    dispatch_semaphore_t authSemRev;
    NSMutableArray* authQ;
    
    int connecting;
    SettingsEntity* currentSettings;
    BOOL performingConnect;
    NSMutableDictionary* oauthSettings;
    
    //GTMOAuth2ViewControllerTouch* authViewController;
    MCOSMTPSession* currentSMTPSession;
    FullMessageEntity* currentMessage;
    BOOL currentLoad;
    BOOL stopCycle;
    BOOL loadingMessages;
    
    NSMutableArray* deadSessions;
    
    MCOIMAPFetchParsedContentOperation* currentFetchOperation;
}

//@property (nonatomic, retain) DataManager* manager;

//-(id)initWithManager:(DataManager*)man;
-(void)readShortMessagesForBox:(boxTypes)btType;
-(void)readNextShortMessagesForBox:(boxTypes)btType;

-(void)readShortMessagesForBoxWithFilter:(boxTypes)btType filter:(NSString*)fromFilter;
-(void)readNextShortMessagesForBoxWithFilter:(boxTypes)btType filter:(NSString*)fromFilter;

//-(void)loadNMessagesWithFilter:(NSUInteger)nMessages forBox:(boxTypes)btType filter:(NSString*)fromFilter;

-(void)readFullMessageFor:(ShortMessageEntity*)message boxType:(boxTypes)btType pin:(NSMutableString*)pin;

-(void)sendMessage:(FullMessageEntity*)message;

@property (nonatomic, strong) MCOIMAPOperation *imapCheckOp;
@property (nonatomic, strong) MCOIMAPSession *imapSession;
@property (nonatomic, strong) MCOIMAPFetchMessagesOperation *imapMessagesFetchOp;

#pragma mark Multiple accounts
@property (nonatomic, retain) NSMutableArray* imapSessions; // of SessionConnectorNew*


@property (nonatomic, strong) NSArray *messages;
@property (nonatomic, strong) NSMutableDictionary* messagesForAddress;
@property (nonatomic, strong) NSMutableDictionary* finishedForAddress; // No more messages in this box
@property (nonatomic, strong) NSMutableDictionary* totalForAddress;
@property (nonatomic, strong) NSMutableDictionary* requestedForAddress; // Fetch requested for that box

-(void)resetMessages;

-(void)cancelSessionOps;

-(float)getJPEGCompression;

-(void)deleteMessage:(ShortMessageEntity*)message;
-(void)deleteMessage:(ShortMessageEntity *)message reencrypting:(BOOL)reencrypting;
-(void)deleteMessages:(NSArray*/*ShortMessageEntity */)messages;
-(void)deleteAllMessagesFromFolder:(NSString*)folderPath;

-(void)setFlagForMessages:(NSArray*)messages flag:(int)flag;
-(void)setCustomFlagsForMessage:(ShortMessageEntity*)message flags:(NSArray*)flags;
-(void)removeCustomFlagsForMessage:(ShortMessageEntity*)message flags:(NSArray*)flags;

-(void)toggleStarForMessage:(ShortMessageEntity*)message;
-(void)setReadFlagForMessage:(ShortMessageEntity*)message;
-(void)setAnsweredFlagForMessage:(ShortMessageEntity *)message;

//-(void)checkSessionForBox:(boxTypes)btType;

-(int)readNewMessagesCount;
-(int)bgGetNewMessageCount;
-(int)readNewMessagesCountForAll;
-(int)readNewMessagesCountForFolder:(NSString*)folder session:(SessionConnectorNew*)session;

-(void)createFolder:(NSString*)newFolderName;
-(void)deleteFolder:(NSString*)folderName;
-(void)renameFolder:(NSString*)folderName newName:(NSString*)newFolderName;

-(void)copyMessage:(FullMessageEntity*)item to:(NSString*)folderPath;
-(void)moveMessage:(FullMessageEntity*)item to:(NSString*)folderPath;
-(void)moveMessages:(NSArray*)messages to:(NSString *)folderPath copyOnly:(BOOL)copyOnly;

-(void)revokeAuthForAddress:(NSString*)address;
-(BOOL)isAddressLoggedIn:(NSString*)address;

-(void)closeAllSessionsSync:(BOOL)sync;

-(BOOL)checkConnection:(SettingsEntity*)sett;
-(int)checkSMTPConnection:(SettingsEntity*)sett;

-(void)readFullHeaderForMessage:(ShortMessageEntity*)message completion:(void (^)(NSString*))completionBlock;

-(void)setDoNotCheckForEmail:(NSString*)email;
-(void)appendMessage:(FullMessageEntity*)item;

-(BOOL)isFetching;

// Error messages
+(NSString*) noMoreMessages;
+(NSString*) fetchInProgress;

-(void)updateStoredHighestModSecForAll;
-(BOOL)isSessionAlive:(SessionConnectorNew*)session;

+(NSString*)getEmailAddressFromCurrentAccount;

-(void)reconnectAllSessions;

-(void)doDeleteExpiredMessages;
-(void)deleteMessagesWithUIDs:(MCOIndexSet*)uids address:(NSString*)address;

-(void)cancelCurrentFetch;

@end
