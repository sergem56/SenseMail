//
//  DataStorage.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "DataStorage.h"
#import "ShortMessageEntity.h"
#import "UserInfoDataManager.h"
#import "SettingsEntity.h"
#import "GlobalRouter.h"
#import "DataManager.h"
#import "FullMessageEntity.h"

#import "FolderInfo.h"

@implementation DataStorage

//@synthesize manager;

/*
-(id)initWithManager:(DataManager*)man
{
    if (self = [super init]) {
        self.manager = man;
    }
    return self;
}
 
 */

-(BOOL)connectSession:(boxTypes)btType loadMessages:(BOOL)load
{
    BOOL ret = YES;
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
//#warning Change it!
    NSArray* allSettings = [dataMan getSettings:[GlobalRouter sharedManager].pin];
    settingsNames = [[NSMutableDictionary alloc] init];
    
    self.imapSessions = [[NSMutableArray alloc] init];
    [GlobalRouter sharedManager].accountsNames = [[NSMutableDictionary alloc] init];
    
    __block BOOL loading = NO;
    
    for (SettingsEntity* setting in allSettings) {
        if ([setting.userName isEqualToString:GENERAL_SETTINGS]) {
            continue;
        }
        MCOIMAPSession* tmp = [[MCOIMAPSession alloc] init];
        self.imapSession = tmp;
        tmp.hostname = setting.imapServer;
        tmp.port = 993;
        tmp.username = setting.userName;
        tmp.password = setting.password;
        tmp.connectionType = MCOConnectionTypeTLS;
        if (tmp.username != nil) {
            [self.imapSessions addObject:tmp];
            [settingsNames setObject:setting forKey:setting.userName];
            [[GlobalRouter sharedManager].accountsNames setObject:setting.settingsName forKey:setting.userName];
        }
        
        self.imapCheckOp = [tmp checkAccountOperation];
        [self.imapCheckOp start:^(NSError *error) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                if (error == nil) {
                    [self getAllFolderNamesForSession:tmp];
                    if(load && !loading){
                        loading = YES;
                        [self loadLastNMessages:10 :btType];
                    }
                }else{
                    if(load)
                        [[[GlobalRouter sharedManager] getListRouter].manager dataReady:nil error:error.localizedFailureReason forSettings:setting.settingsName];
                }
            });
        }];
    }
    
    /*
    self.imapCheckOp = [self.imapSession checkAccountOperation];
    //__unsafe_unretained DataStorage* weakSelf = self;
    [self.imapCheckOp start:^(NSError *error) {
        //NSLog(@"finished checking account.");
        //__strong DataStorage* strongSelf = weakSelf;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            if (error == nil) {
                [self getAllFolderNames];
                if(load)
                    [self loadLastNMessages:10 :btType];
            } else {
                //NSLog(@"error loading account: %@", error);
                if(load)
                    [[[GlobalRouter sharedManager] getListRouter].manager dataReady:nil error:error.localizedDescription forSettings:nil];
            }
        });
    }];
    */
    return ret;
}

-(void)resetMessages
{
    self.messages = [[NSArray alloc] init];
    self.messagesForAddress = [[NSMutableDictionary alloc] init];
}

-(void)cancelSessionOps
{
    [self.imapSession cancelAllOperations];
}

-(void)requestCurrentBoxName
{
    currentBoxName = @"";
    MCOIMAPFetchFoldersOperation* op = [self.imapSession fetchAllFoldersOperation];
    [op start:^(NSError *error, NSArray* data) {
        for (MCOIMAPFolder* folder in data) {
            if(folder.flags & MCOIMAPFolderFlagInbox && [GlobalRouter sharedManager].currentBox == btInbox){
                currentBoxName = folder.path;
            }else if(folder.flags & MCOIMAPFolderFlagSentMail && [GlobalRouter sharedManager].currentBox == btSent){
                currentBoxName = folder.path;
            }else if(folder.flags & MCOIMAPFolderFlagStarred && [GlobalRouter sharedManager].currentBox == btFavourites){
                currentBoxName = folder.path;
            }else if(folder.flags & MCOIMAPFolderFlagSpam && [GlobalRouter sharedManager].currentBox == btSpam){
                currentBoxName = folder.path;
            }
        }
        if ([currentBoxName isEqualToString:@""]) {
            currentBoxName = @"INBOX";
        }
    }];
}

-(void)getNameAndDoBlock:(boxTypes)btType block:(void(^)(MCOIMAPSession* session))block//(dispatch_block_t) block
{
    [self getNameAndDoBlockWithSession:btType block:block session:self.imapSession];
}

-(void)getNameAndDoBlockWithSession:(boxTypes)btType block:(void(^)(MCOIMAPSession* session))block session:(MCOIMAPSession*)session
{
    if (btType == btUseName) {
        currentBoxName = [GlobalRouter sharedManager].currentBoxPath;
        currentBoxForName = btUseName;
        block(session);
    }else if (currentBoxForName != [GlobalRouter sharedManager].currentBox || ([currentBoxName isEqualToString:@""]||currentBoxName == nil))
    {
        currentBoxName = @"";
        MCOIMAPFetchFoldersOperation* op = [session fetchAllFoldersOperation];
        [op start:^(NSError *error, NSArray* data) {
            for (MCOIMAPFolder* folder in data) {
                if(folder.flags & MCOIMAPFolderFlagInbox && [GlobalRouter sharedManager].currentBox == btInbox){
                    currentBoxName = folder.path;
                }else if(folder.flags & MCOIMAPFolderFlagSentMail && [GlobalRouter sharedManager].currentBox == btSent){
                    currentBoxName = folder.path;
                }else if(folder.flags & MCOIMAPFolderFlagStarred && [GlobalRouter sharedManager].currentBox == btFavourites){
                    currentBoxName = folder.path;
                }else if(folder.flags & MCOIMAPFolderFlagSpam && [GlobalRouter sharedManager].currentBox == btSpam){
                    currentBoxName = folder.path;
                }
                
                //NSLog(@"Folder: %@", folder.path);
                
            }
            if ([currentBoxName isEqualToString:@""]) {
                currentBoxName = @"INBOX";
                // Not found, try guess
                if (btType == btInbox) {
                    currentBoxName = @"INBOX";
                }else{
                    MCOMailProvider *accountProvider = [MCOMailProvidersManager.sharedManager providerForEmail:session.username];
                    if (accountProvider) {
                        if(btType == btSent){
                            currentBoxName = accountProvider.sentMailFolderPath;
                        }else if(btType == btFavourites){
                            currentBoxName = accountProvider.starredFolderPath;
                        }else if(btType == btSpam){
                            currentBoxName = accountProvider.spamFolderPath;
                        }
                    }
                }
            }
            
            if([currentBoxName isEqualToString:@""]||currentBoxName == nil){
                currentBoxName = @"INBOX";
            }
            
            currentBoxForName = [GlobalRouter sharedManager].currentBox;
            block(session);
        }];
    }else{
        block(session);
    }
}

-(void)getAllFolderNamesForSession:(MCOIMAPSession*)session
{
    MCOIMAPFetchFoldersOperation* op = [session fetchAllFoldersOperation];
    [op start:^(NSError *error, NSArray* data) {
        if (!error) {
            if ([GlobalRouter sharedManager].otherFolders == nil) {
                [GlobalRouter sharedManager].otherFolders = [[NSMutableDictionary alloc] init];
            }
            SettingsEntity* setTmp = [settingsNames objectForKey:session.username];
            NSString* accName = setTmp.settingsName;
            for (MCOIMAPFolder* folder in data) {
                NSArray* path = [[session defaultNamespace] componentsFromPath:folder.path];
                NSString* folderName;
                if (path.count == 1) {
                    folderName = [path objectAtIndex:0];
                    //[[GlobalRouter sharedManager].otherFolders setValue:folder.path forKey:folderName];
                }else{
                    folderName = [path objectAtIndex:1];
                    //[[GlobalRouter sharedManager].otherFolders setValue:folder.path forKey:folderName];
                }
                if(folderName != nil && ![folderName isEqualToString:@"[Gmail]"]){
                    NSMutableDictionary* listAcc = [[GlobalRouter sharedManager].otherFolders valueForKey:accName];
                    if (listAcc == nil) {
                        listAcc = [[NSMutableDictionary alloc] init];
                        [[GlobalRouter sharedManager].otherFolders setValue:listAcc forKey:accName];
                    }
                    
                    //NSString* tmpKey = [NSString stringWithFormat:@"[%@] %@", accName, folderName];
                    //[[GlobalRouter sharedManager].otherFolders setValue:folder.path forKey:tmpKey];//folderName];
                    
                    FolderInfo* fi = [[FolderInfo alloc] init];
                    fi.folderPath = folder.path;
                    
                    if(folder.flags & MCOIMAPFolderFlagInbox){
                        fi.folderType = btInbox;
                    }else if(folder.flags & MCOIMAPFolderFlagSentMail){
                        fi.folderType = btSent;
                    }else if(folder.flags & MCOIMAPFolderFlagStarred){
                        fi.folderType = btFavourites;
                    }else if(folder.flags & MCOIMAPFolderFlagSpam){
                        fi.folderType = btSpam;
                    }else if(folder.flags & MCOIMAPFolderFlagTrash){
                        //fi.folderType = bt;
                    }
                    
                    //[listAcc setValue:folder.path forKey:folderName];
                    [listAcc setValue:fi forKey:folderName];
                }
                //[[GlobalRouter sharedManager] addButton:folderName];
            }
        }
    }];
    /*
    - (void)registerAccountWithEmail:(NSString*) email {
        MCOMailProvider *accountProvider = [MCOMailProvidersManager.sharedManager providerForEmail:email];
        if (!accountProvider) {
            NSLog(@"No provider available for email: %@", email);
            return;
        }
        //Check if the account provides you with IMAP services
        NSArray *imapServices = accountProvider.imapServices;
        if (imapServices.count != 0) [
                                      MCONetService *imapService = imapServices[0];
                                      MCOIMAPSession *session = [[MCOIMAPSession alloc] init];
                                      [session setHostname:imapService.hostname];
                                      [session setPort:imapService.port];
                                      [session setUsername:email];
                                      [session setPassword:@"1234567890"];
                                      [session setConnectionType:imapService.connectionType];
                                      }
                                      }
     */
}

/*
-(NSString*)getBoxNameFor:(boxTypes)btType
{
    if (currentBoxForName == [GlobalRouter sharedManager].currentBox && ![currentBoxName isEqualToString:@""]) {
        return currentBoxName;
    }
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    currentBoxName = @"";
    MCOIMAPFetchFoldersOperation* op = [self.imapSession fetchAllFoldersOperation];
    [op start:^(NSError *error, NSArray* data) {
        for (MCOIMAPFolder* folder in data) {
            if(folder.flags == MCOIMAPFolderFlagInbox && [GlobalRouter sharedManager].currentBox == btInbox){
                currentBoxName = folder.path;
            }else if(folder.flags == MCOIMAPFolderFlagSentMail && [GlobalRouter sharedManager].currentBox == btSent){
                currentBoxName = folder.path;
            }else if(folder.flags == MCOIMAPFolderFlagStarred && [GlobalRouter sharedManager].currentBox == btFavourites){
                currentBoxName = folder.path;
            }else if(folder.flags == MCOIMAPFolderFlagSpam && [GlobalRouter sharedManager].currentBox == btSpam){
                currentBoxName = folder.path;
            }
        }
        if ([currentBoxName isEqualToString:@""]) {
            currentBoxName = @"INBOX";
        }
        
        dispatch_semaphore_signal(sema);
    }];
    
    dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, 20000000000));// DISPATCH_TIME_FOREVER);
    
    if ([currentBoxName isEqualToString:@""]) {
        currentBoxName = @"INBOX";
    }else{
        currentBoxForName = [GlobalRouter sharedManager].currentBox;
    }
    
    return currentBoxName;
}
 */

-(void)loadNMessagesWithFilter:(NSUInteger)nMessages forBox:(boxTypes)btType filter:(NSString*)fromFilter
{
    [[[GlobalRouter sharedManager] getListRouter].manager setProgress:0 max:10];
    
    [self checkSessionForBox:btType];
    
    void (^block)(MCOIMAPSession* session) = ^void(MCOIMAPSession* session){
        MCOIMAPSearchExpression* expr;
        if (btType == btSent) {
            expr = [MCOIMAPSearchExpression searchTo:fromFilter];
        }else{
            expr = [MCOIMAPSearchExpression searchFrom:fromFilter];
        }
        MCOIMAPSearchOperation* op = [session searchExpressionOperationWithFolder:currentBoxName expression:expr];
        
        [op start:^(NSError* error, MCOIndexSet* searchResult) {
            //NSLog(@"Count of message %d", searchResult.count);
            [GlobalRouter sharedManager].totalMessages = searchResult.count;
            
            /*
            NSMutableArray * result = [NSMutableArray array];
            [searchResult enumerateIndexes:^(uint64_t idx) {
                [result addObject:[NSNumber numberWithLongLong:idx]];// numberWithLongLongInt:idx]];
            }];
            */
            
            NSInteger loadedMsg = [[self.messagesForAddress objectForKey:session.username] integerValue];
            //int loaded = (int)self.messages.count;
            NSUInteger numberOfMessagesToLoad = MIN(10,searchResult.count-loadedMsg);
            SettingsEntity* setTmp = [settingsNames objectForKey:session.username];
            
            if (numberOfMessagesToLoad == 0)
            {
                //[[[GlobalRouter sharedManager] getListRouter].manager dataReady:nil error:NSLocalizedString(@"No messages",nil)];
                return;
            }

            // NEED to figure out how many messages to load...
            
            if (nMessages+loadedMsg >= searchResult.count) {
                // Last fetch - need to hide button for more messages
                [[[GlobalRouter sharedManager] getListRouter].manager tellUpNoMoreButton];
            }

            MCOIndexSet* toGet = [[MCOIndexSet alloc] init];
            __block int i = 0;
            __block int j = 0;
            int total = searchResult.count;
            // It's in reverse order...
            [searchResult enumerateIndexes:^(uint64_t idx) {
                //NSLog(@"Index %llu", idx);
                if (i >= total-loadedMsg-numberOfMessagesToLoad && j < numberOfMessagesToLoad) {
                    [toGet addIndex:idx];
                    j++;
                }
                i++;
            }];
            
            MCOIMAPMessagesRequestKind requestKind = (MCOIMAPMessagesRequestKind)
             (MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure |
              MCOIMAPMessagesRequestKindInternalDate | MCOIMAPMessagesRequestKindHeaderSubject |
              MCOIMAPMessagesRequestKindFlags | MCOIMAPMessagesRequestKindUid | MCOIMAPMessagesRequestKindSize);
             
            self.imapMessagesFetchOp = [session fetchMessagesOperationWithFolder:currentBoxName
                                                                                   requestKind:requestKind
                                                                                     uids:toGet];//searchResult];
            
            [self.imapMessagesFetchOp start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                    //NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"header.date" ascending:NO];
                    
                    //NSMutableArray *combinedMessages = [NSMutableArray arrayWithArray:messages];
                    //[combinedMessages addObjectsFromArray:self.messages];
                    
                    //self.messages = [combinedMessages sortedArrayUsingDescriptors:@[sort]];
                    
                    //self.messages = [messages sortedArrayUsingDescriptors:@[sort]];
                    //[[[GlobalRouter sharedManager] getListRouter].manager dataReady:self.messages error:error.description];
                    
                    NSSortDescriptor *sort =
                    [NSSortDescriptor sortDescriptorWithKey:@"header.date" ascending:NO];
                    
                    NSMutableArray *combinedMessages = [NSMutableArray arrayWithArray:messages];
                    //[combinedMessages addObjectsFromArray:self.messages];
                    
                    [self.messagesForAddress setValue:[NSNumber numberWithInt:(int)(messages.count+loadedMsg)] forKey:session.username];
                    
                    NSArray* tmp = [combinedMessages sortedArrayUsingDescriptors:@[sort]];
                    
                    [[[GlobalRouter sharedManager] getListRouter].manager dataReady:tmp error:error.description forSettings:setTmp.settingsName];
                });
            }];
            
        }];
    };
    
    numberOfEmptied = 0;
    [GlobalRouter sharedManager].totalMessages = 0;
//#warning !!!
    for (MCOIMAPSession* session in self.imapSessions) {
        [self getNameAndDoBlockWithSession:btType block:block session:session];
    }
}

- (void)loadLastNMessages:(NSUInteger)nMessages :(boxTypes)btType
{
    //self.isLoading = YES;
    
    //dispatch_block_t block = ^{
    void (^block)(MCOIMAPSession* session) = ^void(MCOIMAPSession* session){
        MCOIMAPMessagesRequestKind requestKind = (MCOIMAPMessagesRequestKind)
        (MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure |
         MCOIMAPMessagesRequestKindInternalDate | MCOIMAPMessagesRequestKindHeaderSubject |
         MCOIMAPMessagesRequestKindFlags | MCOIMAPMessagesRequestKindUid | MCOIMAPMessagesRequestKindSize);
        
        MCOIMAPFolderInfoOperation *inboxFolderInfo = [session folderInfoOperation:currentBoxName];
        
        [inboxFolderInfo start:^(NSError *error, MCOIMAPFolderInfo *info)
         {
             BOOL totalNumberOfMessagesDidChange = NO;//self.totalNumberOfInboxMessages != [info messageCount];
             NSInteger loadedMsg = [[self.messagesForAddress objectForKey:session.username] integerValue];
             int totalNumberOfInboxMessages = [info messageCount];
             if (totalNumberOfInboxMessages == 0) {
                 [GlobalRouter sharedManager].totalMessages = 0;
             }else{
                 [GlobalRouter sharedManager].totalMessages += totalNumberOfInboxMessages;
             }
             
             NSUInteger numberOfMessagesToLoad = MIN([info messageCount], nMessages+loadedMsg);
             SettingsEntity* setTmp = [settingsNames objectForKey:session.username];
             
             if (numberOfMessagesToLoad == 0)
             {
                 //self.isLoading = NO;
                 [[[GlobalRouter sharedManager] getListRouter].manager dataReady:nil error:NSLocalizedString(@"No messages",nil) forSettings:setTmp.settingsName];
                 return;
             }
             
             if (nMessages+loadedMsg >= [info messageCount]) {
                 // Last fetch - need to hide button for more messages
                 numberOfEmptied++;
                 if(numberOfEmptied == self.imapSessions.count)
                     [[[GlobalRouter sharedManager] getListRouter].manager tellUpNoMoreButton];
             }
             
             MCORange fetchRange;
             
             // If total number of messages did not change since last fetch,
             // assume nothing was deleted since our last fetch and just
             // fetch what we don't have
             
             if (!totalNumberOfMessagesDidChange && loadedMsg)// self.messages.count)
             {
                 numberOfMessagesToLoad -= loadedMsg;// self.messages.count;
                 if (numberOfMessagesToLoad <= 0) {
                     [[[GlobalRouter sharedManager] getListRouter].manager dataReady:self.messages error:NSLocalizedString(@"No more messages",nil) forSettings:setTmp.settingsName];
                     return;
                     
                 }
                 
                 fetchRange =
                 MCORangeMake(totalNumberOfInboxMessages -
                              //self.messages.count -
                              loadedMsg -
                              (numberOfMessagesToLoad - 1),
                              (numberOfMessagesToLoad - 1));
             }
             
             // Else just fetch the last N messages
             else
             {
                 fetchRange =
                 MCORangeMake(totalNumberOfInboxMessages -
                              (numberOfMessagesToLoad - 1),
                              (numberOfMessagesToLoad - 1));
             }
             
             //self.imapMessagesFetchOp =
             MCOIMAPFetchMessagesOperation* fetchOp =
             [session fetchMessagesByNumberOperationWithFolder:currentBoxName
                                                            requestKind:requestKind
                                                                numbers:
              [MCOIndexSet indexSetWithRange:fetchRange]];
             
             //__unsafe_unretained typeof(self) weakSelf = self;
             [fetchOp setProgress:^(unsigned int progress) {
                 //__strong typeof(self) strongSelf = weakSelf;
                 //NSLog(@"Progress: %u of %u", progress, numberOfMessagesToLoad);
                 [[[GlobalRouter sharedManager] getListRouter].manager setProgress:progress max:(int)numberOfMessagesToLoad];
             }];
             
             [fetchOp start:
              ^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages)
              {
                  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                      //__strong typeof(self) strongSelf = weakSelf;
                      //NSLog(@"fetched all messages.");
                      
                      NSSortDescriptor *sort =
                      [NSSortDescriptor sortDescriptorWithKey:@"header.date" ascending:NO];
                      
                      NSMutableArray *combinedMessages = [NSMutableArray arrayWithArray:messages];
                      //[combinedMessages addObjectsFromArray:self.messages];
                      
                      [self.messagesForAddress setValue:[NSNumber numberWithInt:(int)(messages.count+loadedMsg)] forKey:session.username];
                      
                      NSArray* tmp = [combinedMessages sortedArrayUsingDescriptors:@[sort]];
                      
                      [[[GlobalRouter sharedManager] getListRouter].manager dataReady:tmp error:error.description forSettings:setTmp.settingsName];
                  });
              }];
         }];
        };
    numberOfEmptied = 0;
    [GlobalRouter sharedManager].totalMessages = 0;
    
    if (btType == btUseName && ![[GlobalRouter sharedManager].currentAccount isEqualToString:@""]) {
        //MCOIMAPSession* tmpS;
        NSString* emailAddr = [[GlobalRouter sharedManager].accountsNames allKeysForObject:[GlobalRouter sharedManager].currentAccount][0];
        for (MCOIMAPSession* session in self.imapSessions) {
            if([session.username isEqualToString:emailAddr]){
                [self getNameAndDoBlockWithSession:btType block:block session:session];
            }
        }
    }else{
        for (MCOIMAPSession* session in self.imapSessions) {
            //self.imapSession = session;
            [self getNameAndDoBlockWithSession:btType block:block session:session];
        }
    }
}

-(void)readShortMessagesForBox:(boxTypes)btType
{
    [[[GlobalRouter sharedManager] getListRouter].manager setProgress:0 max:10];
    [self connectSession:btType loadMessages:YES];
}

-(void)readNextShortMessagesForBox:(boxTypes)btType
{
    [[[GlobalRouter sharedManager] getListRouter].manager setProgress:0 max:10];
    [self loadLastNMessages:10+0/*self.messages.count*/ :btType];
}

-(void)checkSessionForBox:(boxTypes)btType
{
    if (self.imapSession == nil) {
        [self connectSession:btType loadMessages:NO];
        return;
    }
    
    MCOIMAPOperation *noopOperation = [self.imapSession noopOperation];
    
    [noopOperation start:^(NSError *error) {
        if (!error) {
            //NSLog(@"Success!");
        }
        
        else {
            //NSLog(@"noopOperation failed: %@", error);
            [self connectSession:btType loadMessages:NO];
        }
    }];
}

-(MCOIMAPSession*)checkSessionForAddress:(NSString*)address
{
    sema = dispatch_semaphore_create(0);
    
    MCOIMAPSession* ret = nil;
    for (MCOIMAPSession* sess in self.imapSessions) {
        if ([sess.username isEqualToString:address]) {
            ret = sess;
            break;
        }
    }
    if (ret == nil) {
        // Shouldn't get here
        [self connectSession:btEmpty loadMessages:NO];
        dispatch_semaphore_signal(sema); // !!!
        return nil;
    }
    //self.imapSession = ret;
    
    MCOIMAPOperation *noopOperation = [ret noopOperation];
    [noopOperation start:^(NSError *error) {
        if (!error) {
            dispatch_semaphore_signal(sema);
        }else {
            //NSLog(@"noopOperation failed: %@", error);
            MCOIMAPOperation* connect = [ret connectOperation];
            [connect start:^(NSError *error) {
                dispatch_semaphore_signal(sema);
                
            }];
        }
    }];
    
    return ret;
}


-(void)readFullMessageFor:(ShortMessageEntity*)message boxType:(boxTypes)btType pin:(NSString *)pin
{
    [[[GlobalRouter sharedManager] getMessageRouter].manager setProgress:0 max:10];
    
    //sema = dispatch_semaphore_create(0);
    MCOIMAPSession* sess = [self checkSessionForAddress:message.toAddress];
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    sema = nil;
    
    //NSString* box = [self getBoxNameFor:btType];
    void (^block)(MCOIMAPSession* session) = ^void(MCOIMAPSession* session){
        MCOIMAPFetchContentOperation *operation = [session fetchMessageOperationWithFolder:currentBoxName uid:(uint)[message.messageID integerValue]];
        
        [operation start:^(NSError *error, NSData *data) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                [[[GlobalRouter sharedManager] getMessageRouter].manager fullMessageReady:data forShort:message error:error.localizedFailureReason pin:pin];
            });
        }];
        
        __unsafe_unretained typeof(operation) weakOp = operation;
        [operation setProgress:^(unsigned int current, unsigned int maximum) {
            //NSLog(@"progress content: %u/%u", current, maximum);
            
            if (![GlobalRouter sharedManager].isCancelled)
                [[[GlobalRouter sharedManager] getMessageRouter].manager setProgress:current max:maximum];
            if ([GlobalRouter sharedManager].isCancelled) {
                [weakOp cancel]; // ?? no need now, since I cancel all ops in session?
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                    [[[GlobalRouter sharedManager] getMessageRouter].manager fullMessageReady:nil forShort:message error:@"Cancelled" pin:pin];
                });
            }
        }];
    };
    
    
//#warning !!!
    [self getNameAndDoBlockWithSession:btType block:block session:sess];
}

-(void)sendMessage:(FullMessageEntity *)message
{
    [self checkSessionForBox:btEmpty];
    
    MCOSMTPSession *smtpSession = [[MCOSMTPSession alloc] init];
    
    SettingsEntity* setts = [settingsNames objectForKey:message.fromAddress];
    
    smtpSession.hostname = setts.smtpServer;
    smtpSession.port = (uint)setts.smtpPort;
    smtpSession.username = setts.userName;
    smtpSession.password = setts.password;
    smtpSession.authType = (MCOAuthTypeSASLPlain | MCOAuthTypeSASLLogin);
    smtpSession.connectionType = MCOConnectionTypeTLS;
    
    MCOMessageBuilder * builder = [[MCOMessageBuilder alloc] init];
    [[builder header] setFrom:[MCOAddress addressWithDisplayName:setts.userNick mailbox:setts.userName]];
    NSMutableArray *to = [[NSMutableArray alloc] init];
    //for(NSString *toAddress in RECIPIENTS) {
        MCOAddress *newAddress = [MCOAddress addressWithMailbox:message.toAddress];
        [to addObject:newAddress];
   // }
    [[builder header] setTo:to];
    
    [[builder header] setSubject:message.subject];
    [builder setHTMLBody:message.messageBody];
    
    for (NSString* att in message.attachments) {
        [builder addAttachment:[MCOAttachment attachmentWithContentsOfFile:att]];
    }
    
    NSData * rfc822Data = [builder data];
    
    MCOSMTPSendOperation *sendOperation = [smtpSession sendOperationWithData:rfc822Data];
    [sendOperation start:^(NSError *error) {
        [[[GlobalRouter sharedManager] getComposeRouter].manager messageSent:message error:error.localizedFailureReason];
    }];
    
    
}

-(float)getJPEGCompression
{
    float cr = settings.compression;
    if (cr == 0) {
        cr = 0.5;
    }
    return cr;
}

-(void)deleteMessage:(ShortMessageEntity *)message
{
    //[self checkSessionForBox:btEmpty];
    
    int deleted = MCOMessageFlagDeleted;
    
    //NSString* box = [self getBoxNameFor:[GlobalRouter sharedManager].currentBox];
    MCOIMAPSession* sessTmp = [self checkSessionForAddress:message.toAddress];
    
    if (sessTmp == nil) {
        sessTmp = [self checkSessionForAddress:[[GlobalRouter sharedManager].accountsNames allKeysForObject:[GlobalRouter sharedManager].currentAccount][0]];
    }
    
    void (^block)(MCOIMAPSession* session) = ^void(MCOIMAPSession* session){
        MCOIMAPOperation *op = [session storeFlagsOperationWithFolder:currentBoxName
                                                                 uids:[MCOIndexSet indexSetWithIndex:[message.messageID integerValue]]
                                                                 kind:MCOIMAPStoreFlagsRequestKindSet
                                                                flags:deleted];
        [op start:^(NSError * error) {
            if(!error) {
                //NSLog(@"Updated flags!");
            } else {
                //NSLog(@"Error updating flags:%@", error);
            }
            
            //if(deleted) {
                MCOIMAPOperation *deleteOp = [session expungeOperation:currentBoxName];
                [deleteOp start:^(NSError *error) {
                    if(error) {
                        //NSLog(@"Error expunging folder:%@", error);
                    } else {
                        //NSLog(@"Successfully expunged folder");
                    }
                }];
            //}
        }];
    };
    
//#warning !!!
    [self getNameAndDoBlockWithSession:[GlobalRouter sharedManager].currentBox block:block session:sessTmp];
}

-(void)toggleStarForMessage:(ShortMessageEntity *)message
{
    //NSString* box = [self getBoxNameFor:[GlobalRouter sharedManager].currentBox];
    //[self checkSessionForBox:btEmpty];
    
    MCOIMAPSession* sessTmp = [self checkSessionForAddress:message.toAddress];
    
    void (^block)(MCOIMAPSession* session) = ^void(MCOIMAPSession* session){
        MCOIMAPFetchMessagesOperation* readFlags = [session fetchMessagesOperationWithFolder:currentBoxName requestKind:MCOIMAPMessagesRequestKindFlags uids:[MCOIndexSet indexSetWithIndex:[message.messageID integerValue]]];
        [readFlags start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
            if (!error) {
                MCOMessageFlag flags = [(MCOIMAPMessage*)[messages objectAtIndex:0] flags];
                
        
                MCOIMAPStoreFlagsRequestKind flagOp;
                if (flags & MCOMessageFlagFlagged) {
                    flagOp = MCOIMAPStoreFlagsRequestKindRemove;
                    flags = MCOMessageFlagFlagged;
                }else{
                    flagOp = MCOIMAPStoreFlagsRequestKindSet;
                    flags |= MCOMessageFlagFlagged;
                }
                
                MCOIMAPOperation *op = [session  storeFlagsOperationWithFolder:currentBoxName uids:[MCOIndexSet indexSetWithIndex:[message.messageID integerValue]] kind:flagOp flags:flags];
                [op start:^(NSError * error) {
                    if(!error) {
                        //NSLog(@"Updated flags!");
                    } else {
                        //NSLog(@"Error updating flags:%@", error);
                    }
                }];
            }
        }];
    };
    
//#warning !!!
    [self getNameAndDoBlockWithSession:[GlobalRouter sharedManager].currentBox block:block session:sessTmp];
}

-(void)setReadFlagForMessage:(ShortMessageEntity *)message
{
    //NSString* box = [self getBoxNameFor:[GlobalRouter sharedManager].currentBox];
    //[self checkSessionForBox:btEmpty];
    
    MCOIMAPSession* sessTmp = [self checkSessionForAddress:message.toAddress];
    
    void (^block)(MCOIMAPSession* session) = ^void(MCOIMAPSession* session){
        MCOIMAPFetchMessagesOperation* readFlags = [session fetchMessagesOperationWithFolder:currentBoxName requestKind:MCOIMAPMessagesRequestKindFlags uids:[MCOIndexSet indexSetWithIndex:[message.messageID integerValue]]];
        [readFlags start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
            if (!error) {
                if(messages.count > 0){
                    MCOMessageFlag flags = [(MCOIMAPMessage*)[messages objectAtIndex:0] flags];
                    flags |= MCOMessageFlagSeen;
                    
                    MCOIMAPOperation *op = [session  storeFlagsOperationWithFolder:currentBoxName uids:[MCOIndexSet indexSetWithIndex:[message.messageID integerValue]] kind:MCOIMAPStoreFlagsRequestKindSet flags:flags];
                    [op start:^(NSError * error) {
                        if(!error) {
                            //NSLog(@"Updated flags!");
                        } else {
                            //NSLog(@"Error updating flags:%@", error);
                        }
                    }];
                }
            }
        }];
    };
    
//#warning !!!
    [self getNameAndDoBlockWithSession:[GlobalRouter sharedManager].currentBox block:block session:sessTmp];
}

-(int)readNewMessagesCount
{
    __block int totalUnseen = 0;
    void (^block)(MCOIMAPSession* session, dispatch_semaphore_t sem) = ^void(MCOIMAPSession* session, dispatch_semaphore_t sem){
    
        MCOIMAPFolderStatusOperation *inboxFolderInfo = [session folderStatusOperation:@"INBOX"];
        [inboxFolderInfo start:^(NSError *error, MCOIMAPFolderStatus *info)
         {
             int unseenMessages = [info unseenCount];
             totalUnseen += unseenMessages;
             dispatch_semaphore_signal(sem);
         }];
    };
    
    //[self connectSession:btInbox loadMessages:NO];
    
    for (MCOIMAPSession* session in self.imapSessions) {
        // global semaphore fails since it could be init'ed twice here, made it local
        __block dispatch_semaphore_t semaf = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            block(session, semaf);
        });
        dispatch_semaphore_wait(semaf, DISPATCH_TIME_FOREVER);
    }
    
    //NSLog(@"New messages: %i", totalUnseen);
    return totalUnseen;
}

@end
