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
#import "CommonProcs.h"
#import "FolderInfo.h"
#import "SessionConnectorNew.h"
#import "AppDelegate.h"
#import "Encryptor.h"
#import "OneTimeCert.h"

#define CLIENT_ID @"1093441457257-3htrj10go6k05g1lf28ad53vl1v98buj.apps.googleusercontent.com"
#define CLIENT_SECRET nil
#define KEYCHAIN_ITEM_NAME @"SenseMail OAuth20 %@"

#define TIMEOUT 10*NSEC_PER_SEC

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

-(void)revokeAuthForAddress:(NSString*)address
{
    SessionConnectorNew* toDel = nil;
    for (SessionConnectorNew* session in self.imapSessions) {
        if ([session isThisForAddress:address]) {
            [session revokeAuth];
            toDel = session;
            break;
        }
    }
    
    if (toDel != nil) {
        [self.imapSessions removeObject:toDel];
        toDel = nil;
    }
}

-(BOOL)isAddressLoggedIn:(NSString*)address
{
    BOOL ret = NO;
    for (SessionConnectorNew* session in self.imapSessions) {
        if ([session isThisForAddress:address]) {
            ret = [session isLoggedIn];
            break;
        }
    }
    
    return ret;
}

// Initial connect
-(BOOL)connectSessions:(boxTypes)btType forAddress:(NSString*)address
{
    connecting = 0;
    
    BOOL ret = YES;
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    /*NSArray**/[GlobalRouter sharedManager].allSettings = [dataMan getSettings:[GlobalRouter sharedManager].pin];
    if ([GlobalRouter sharedManager].allSettings.count < 2) {
        // No account settings yet
        if (conSem != nil) {
            dispatch_semaphore_signal(conSem);
        }
        return NO;
    }
    
    self.imapSessions = [[NSMutableArray alloc] init];
    [GlobalRouter sharedManager].accountsNames = [[NSMutableDictionary alloc] init];
    
    //__block BOOL loading = NO;
    
    for (SettingsEntity* setting in [GlobalRouter sharedManager].allSettings) {
        if ([setting.userName isEqualToString:GENERAL_SETTINGS]) {
            continue;
        }
        
        if ([setting.imapServer isEqualToString:@""]) {
            continue;
        }
        
        if (address != nil && ![setting.userName isEqualToString:address]) {
            continue;
        }
        
        connecting++;
        
        __weak __typeof__(self) weakSelf = self;
        SessionConnectorNew* tmp = [[SessionConnectorNew alloc] initWithSettings:setting];
        // Check if it's already there first
        BOOL sFound = NO;
        for (SessionConnectorNew* tmpchk in self.imapSessions) {
            if ([tmpchk.imapSession.username isEqualToString:setting.userName]) {
                sFound = YES;
                break;
            }
        }
        if(!sFound) [self.imapSessions addObject:tmp];
        [tmp connectIMAPSessionWithCompletionHandler:^(NSError* error){
            __strong __typeof__(self) strongSelf = weakSelf;
            if(!error){
                [strongSelf getAllFolderNamesForSession:tmp.imapSession];
                strongSelf->connecting--;
                [CommonProcs setSWLabelText:NSLocalizedString(@"Loading", nil)];
                int nLoad = [GlobalRouter sharedManager].nMessagesToLoad;
                if (nLoad == 0) {
                    nLoad = 10;
                }
                [strongSelf loadLastNMessages:nLoad :btType forSession:tmp.imapSession];
            }else{
#if DEBUG
                NSLog(@"Error for session %@ %@", tmp.imapSession.username, error.localizedDescription);
#endif
                [[[GlobalRouter sharedManager] getListRouter].manager dataReady:[[NSArray alloc] init] error:error.localizedDescription forSettings:[tmp getSettingsName]];
            }
        }];
        
    }
    
    return ret;
}

-(BOOL)checkConnection:(SettingsEntity*)sett
{
    
    __block BOOL ret = YES;
    
    if ([sett.imapServer isEqualToString:@""] || [sett.smtpServer isEqualToString:@""]) {
        return NO;
    }
    SessionConnectorNew* tmp = [[SessionConnectorNew alloc] initWithSettings:sett];
    
    dispatch_semaphore_t checkSem = dispatch_semaphore_create(0);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [tmp connectIMAPSessionWithCheckAndCompletionHandler:YES handler:^(NSError* error){
            if(!error){
                //[tmp cancellAllOps];
                BOOL sFound = NO;
                for (SessionConnectorNew* tmpchk in self.imapSessions) {
                    if ([tmpchk.imapSession.username isEqualToString:sett.userName]) {
                        sFound = YES;
                        break;
                    }
                }
                if(!sFound){
                    [self.imapSessions addObject:tmp];
                    NSLog(@"Added a new session to the list - %@ (%@)", sett.userName, tmp.imapSession.description);
                }
            }else{
                [[[GlobalRouter sharedManager] getListRouter].manager dataReady:[[NSArray alloc] init] error:error.localizedDescription forSettings:[tmp getSettingsName]];
                ret = NO;
            }
            dispatch_semaphore_signal(checkSem);
        }];
    });
    
    dispatch_semaphore_wait(checkSem, DISPATCH_TIME_FOREVER);
    
    return ret;
}

-(int)checkSMTPConnection:(SettingsEntity*)sett
{
    
    __block int ret = 0;
    
    SessionConnectorNew* tmp = [[SessionConnectorNew alloc] initWithSettings:sett];
    
    dispatch_semaphore_t checkSem = dispatch_semaphore_create(0);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [tmp connectSMTPSessionWithCheckAndCompletionHandler:YES handler:^(NSError* error){
            if(!error){
                [tmp cancellAllOps];
            }else{
                [[[GlobalRouter sharedManager] getListRouter].manager dataReady:[[NSArray alloc] init] error:error.localizedDescription forSettings:[tmp getSettingsName]];
                if ([error.localizedDescription containsString:@"User not found"]) {
                    ret = ERROR_NO_SUCH_USER;
                }else if([error.localizedDescription containsString:@"Cancelled"]) {
                    ret = ERROR_CANCELLED;
                }else{
                    ret = ERROR_CHECK;
                }
            }
            dispatch_semaphore_signal(checkSem);
        }];
    });
    
    dispatch_semaphore_wait(checkSem, DISPATCH_TIME_FOREVER);
    
    return ret;
}


-(void)resetMessages
{
    self.messages = [[NSArray alloc] init];
    self.messagesForAddress = [[NSMutableDictionary alloc] init];
    self.finishedForAddress = [[NSMutableDictionary alloc] init];
    self.totalForAddress = [[NSMutableDictionary alloc] init];
    self.requestedForAddress = [[NSMutableDictionary alloc] init];
}

-(void)cancelSessionOps
{
    [self.imapSession cancelAllOperations];
}

-(void)requestCurrentBoxName
{
    __weak __typeof__(self) weakSelf = self;
    currentBoxName = @"";
    MCOIMAPFetchFoldersOperation* op = [self.imapSession fetchAllFoldersOperation];
    [op start:^(NSError *error, NSArray* data) {
        if(error)NSLog(@"Request current box name error %@",error.localizedDescription);
        __strong __typeof__(self) strongSelf = weakSelf;
        for (MCOIMAPFolder* folder in data) {
            if(folder.flags & MCOIMAPFolderFlagInbox && [GlobalRouter sharedManager].currentBox == btInbox){
                strongSelf->currentBoxName = folder.path;
            }else if(folder.flags & MCOIMAPFolderFlagSentMail && [GlobalRouter sharedManager].currentBox == btSent){
                strongSelf->currentBoxName = folder.path;
            }else if(folder.flags & MCOIMAPFolderFlagStarred && [GlobalRouter sharedManager].currentBox == btFavourites){
                strongSelf->currentBoxName = folder.path;
            }else if(folder.flags & MCOIMAPFolderFlagSpam && [GlobalRouter sharedManager].currentBox == btSpam){
                strongSelf->currentBoxName = folder.path;
            }
        }
        if ([strongSelf->currentBoxName isEqualToString:@""]) {
            strongSelf->currentBoxName = @"INBOX";
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
        
        if (currentBoxesName == nil) {
            currentBoxesName = [[NSMutableDictionary alloc] init];
        }
        
        [currentBoxesName setObject:currentBoxName forKey:session.username];
        block(session);
    }else{
        __weak __typeof__(self) weakSelf = self;
        currentBoxName = @"";
        MCOIMAPFetchFoldersOperation* op = [session fetchAllFoldersOperation];
        [op start:^(NSError *error, NSArray* data) {
            __strong __typeof__(self) strongSelf = weakSelf;
            if(error){
                [[[GlobalRouter sharedManager] getListRouter].manager dataReady:nil error:error.localizedDescription forSettings:session.username];
                NSLog(@"Error fetching folders %@", error.localizedDescription);
                // Check if all fetches completed and remove the activity indicator
                
                return;
                
                
                /* // This stuff doesn't work, connect is OK, fetch fails
                 MCOIMAPOperation* connect = [session connectOperation];
                 [connect start:^(NSError *error) {
                 if (!error) {
                 [self getNameAndDoBlockWithSession:btType block:block session:session];
                 }else{
                 // Cannot reconnect, try from scratch
                 [self.imapSessions removeObject:session];
                 dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                 [self connectSession:btType loadMessages:NO forAddress:nil];
                 // Call again?
                 
                 });
                 }
                 }];
                 */
                //return;
            }else{
                strongSelf->currentBoxName = @"";
                for (MCOIMAPFolder* folder in data) {
                    if(folder.flags & MCOIMAPFolderFlagInbox && [GlobalRouter sharedManager].currentBox == btInbox){
                        // There's a Google bug here... IMAP server always needs to get inbox name as "INBOX",
                        // but it returns a localized name to show it to a user and refuses to recognize it
                        // if sent back the same. So, just use INBOX anyway.
                        strongSelf->currentBoxName = @"INBOX"; //folder.path;
                    }else if(folder.flags & MCOIMAPFolderFlagSentMail && [GlobalRouter sharedManager].currentBox == btSent){
                        strongSelf->currentBoxName = folder.path;
                    }else if(folder.flags & MCOIMAPFolderFlagStarred && [GlobalRouter sharedManager].currentBox == btFavourites){
                        strongSelf->currentBoxName = folder.path;
                    }else if(folder.flags & MCOIMAPFolderFlagSpam && [GlobalRouter sharedManager].currentBox == btSpam){
                        strongSelf->currentBoxName = folder.path;
                    }else if(folder.flags & MCOIMAPFolderFlagAllMail && [GlobalRouter sharedManager].currentBox == btAllMail){
                        strongSelf->currentBoxName = folder.path;
                    }else if(folder.flags & MCOIMAPFolderFlagDrafts && [GlobalRouter sharedManager].currentBox == btDrafts){
                        strongSelf->currentBoxName = folder.path;
                    }else if(folder.flags & MCOIMAPFolderFlagTrash && [GlobalRouter sharedManager].currentBox == btDeleted){
                        strongSelf->currentBoxName = folder.path;
                    }
                    
                    //NSLog(@"Folder: %@", folder.path);
                    
                }
            }
            if ([strongSelf->currentBoxName isEqualToString:@""]) {
                strongSelf->currentBoxName = @"INBOX";
                // Not found, try guess
                if (btType == btInbox) {
                    strongSelf->currentBoxName = @"INBOX";
                }else{
                    MCOMailProvider *accountProvider = [MCOMailProvidersManager.sharedManager providerForEmail:session.username];
                    if (accountProvider) {
                        if(btType == btSent){
                            strongSelf->currentBoxName = accountProvider.sentMailFolderPath;
                        }else if(btType == btFavourites){
                            strongSelf->currentBoxName = accountProvider.starredFolderPath;
                        }else if(btType == btSpam){
                            strongSelf->currentBoxName = accountProvider.spamFolderPath;
                        }else if(btType == btDrafts){
                            strongSelf->currentBoxName = accountProvider.draftsFolderPath;
                        }else if(btType == btAllMail){
                            strongSelf->currentBoxName = accountProvider.allMailFolderPath;
                        }else if(btType == btImportant){
                            strongSelf->currentBoxName = accountProvider.starredFolderPath;
                        }else if(btType == btDeleted){
                            strongSelf->currentBoxName = accountProvider.trashFolderPath;
                        }
                    }
                }
            }
            
            if([strongSelf->currentBoxName isEqualToString:@""]){//||currentBoxName == nil){
                strongSelf->currentBoxName = @"INBOX";
            }
            
            if (strongSelf->currentBoxesName == nil) {
                strongSelf->currentBoxesName = [[NSMutableDictionary alloc] init];
            }
            
            if(strongSelf->currentBoxName != nil){
                [strongSelf->currentBoxesName setObject:strongSelf->currentBoxName forKey:session.username];
                //NSLog(@"%@ - %@",self->currentBoxName,session.username);
            }
            
            strongSelf->currentBoxForName = [GlobalRouter sharedManager].currentBox;
            if(strongSelf->currentBoxName != nil){
                block(session);
            }else{
                [[GlobalRouter sharedManager] getListRouter].manager.nAccountsToWait--;
            }
        }];
    }//else{
    //   block(session);
    //}
}

-(void)getAllFolderNamesForSession:(MCOIMAPSession*)session
{
    MCOIMAPFetchNamespaceOperation *namespaceOp = [session fetchNamespaceOperation];
    [namespaceOp start:^(NSError *error, NSDictionary * namespaces) {
        MCOIMAPNamespace * namespace = [namespaces objectForKey:MCOIMAPNamespacePersonal];
        [session setDefaultNamespace:namespace];
        MCOIMAPFetchFoldersOperation* op = [session fetchAllFoldersOperation];
        [op start:^(NSError *error, NSArray* data) {
            if (!error) {
                if ([GlobalRouter sharedManager].otherFolders == nil) {
                    [GlobalRouter sharedManager].otherFolders = [[NSMutableDictionary alloc] init];
                }
                SettingsEntity* setTmp = [[GlobalRouter sharedManager] getSettingForAddress:session.username];// .settingsNames objectForKey:session.username];
                if (setTmp == nil) {
                    // Error
                    return;
                }
                NSString* accName = setTmp.settingsName;
                //MCOIMAPNamespace* namespace = [session defaultNamespace];
                for (MCOIMAPFolder* folder in data) {
                    NSArray* path = [namespace componentsFromPath:folder.path];//[[session defaultNamespace] componentsFromPath:folder.path];
                    NSString* folderName;
                    if (path == nil) {
                        // Some call this empty path INBOX
                        folderName = @"INBOX";
                    }else if (path.count == 1) {
                        folderName = [path objectAtIndex:0];
                        //[[GlobalRouter sharedManager].otherFolders setValue:folder.path forKey:folderName];
                    }else{
                        folderName = [path lastObject];//[path objectAtIndex:1];
                        //[[GlobalRouter sharedManager].otherFolders setValue:folder.path forKey:folderName];
                    }
                    if(folderName != nil && ![folderName isEqualToString:@"[Gmail]"]){
                        //NSMutableDictionary* listAcc = [[GlobalRouter sharedManager].otherFolders valueForKey:accName];
                        NSMutableDictionary* listAcc = [[GlobalRouter sharedManager].otherFolders objectForKey:accName];
                        if (listAcc == nil) {
                            listAcc = [[NSMutableDictionary alloc] init];
                            [[GlobalRouter sharedManager].otherFolders setValue:listAcc forKey:accName];
                        }
                        
                        //NSString* tmpKey = [NSString stringWithFormat:@"[%@] %@", accName, folderName];
                        //[[GlobalRouter sharedManager].otherFolders setValue:folder.path forKey:tmpKey];//folderName];
                        
                        FolderInfo* fi = [[FolderInfo alloc] init];
                        fi.folderPath = folder.path;
                        
                        if(folder.flags & MCOIMAPFolderFlagInbox || [folderName isEqualToString:@"INBOX"]){
                            fi.folderType = btInbox;
                        }else if(folder.flags & MCOIMAPFolderFlagSentMail){
                            fi.folderType = btSent;
                        }else if(folder.flags & MCOIMAPFolderFlagStarred){
                            fi.folderType = btFavourites;
                        }else if(folder.flags & MCOIMAPFolderFlagSpam){
                            fi.folderType = btSpam;
                        }else if(folder.flags & MCOIMAPFolderFlagTrash){
                            fi.folderType = btDeleted;
                        }else if(folder.flags & MCOIMAPFolderFlagAllMail){
                            fi.folderType = btAllMail;
                        }else if(folder.flags & MCOIMAPFolderFlagDrafts){
                            fi.folderType = btDrafts;
                        }else if(folder.flags & MCOIMAPFolderFlagImportant){
                            fi.folderType = btImportant;
                        }else{
                            fi.folderType = btUnknown;
                        }
                        
                        // Get unread count
                        MCOIMAPFolderStatusOperation* stOp = [session folderStatusOperation:fi.folderPath];//folderName];
                        [stOp start:^(NSError *error, MCOIMAPFolderStatus* info)
                         {
                             if (error) {
                                 NSLog(@"getAllFolderNames for %@ error %@",folderName, error.localizedDescription);
                             }
                             //NSLog(@"New messages for %@: %u", folderName, info.unseenCount);
                             fi.unseenCount = info.unseenCount;
                             fi.totalCount = info.messageCount;
                         }];
                        
                        [listAcc setValue:fi forKey:folderName];
                    }
                }
            }else{
                // Error. Reconnect???
                NSLog(@"getAllFolderNamesForSession error %@", error.localizedDescription);
            }
        }];
    }];
}

-(void)loadNMessagesWithFilter:(NSUInteger)nMessages forBox:(boxTypes)btType filter:(NSString*)fromFilter forSession:(MCOIMAPSession*)session
{
    if (fromFilter == nil || [fromFilter isEqualToString:@""]) {
        return [self loadLastNMessages:nMessages :btType forSession:session];
    }
    
    loadingMessages = YES;
    [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
    [CommonProcs setSWLabelText:NSLocalizedString(@"Loading", nil)];
    
    
    [[[GlobalRouter sharedManager] getListRouter].manager setProgress:0 max:10];
    
    //[self checkSessionForBox:btType];
    __weak __typeof__(self) weakSelf = self;
    void (^block)(MCOIMAPSession* session) = ^void(MCOIMAPSession* session){
        __strong __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf.finishedForAddress && session.username && ((NSNumber*)([strongSelf.finishedForAddress objectForKey:session.username])).boolValue) {
            SettingsEntity* setTmp = [[GlobalRouter sharedManager] getSettingForAddress:session.username];
            [[[GlobalRouter sharedManager] getListRouter].manager dataReady:strongSelf.messages error:[DataStorage noMoreMessages] forSettings:setTmp.settingsName];
            return;
        }
        
        if (self.requestedForAddress && [self.requestedForAddress objectForKey:session.username]) {
            // Already requested
            [[[GlobalRouter sharedManager] getListRouter].manager dataReady:[[NSArray alloc] init] error:[DataStorage fetchInProgress] forSettings:session.username];
            return;
        }
        
        // Add a session name to a dictionary of requested fetches
        // On finish, remove that name
        // If the dictionary is not empty, the fetch is in progress
        // If not finished, make a stop button together with the activity indicator in a list
        if (!self.requestedForAddress) {
            self.requestedForAddress = [[NSMutableDictionary alloc] init];
        }
        if (session.username) {
            [self.requestedForAddress setObject:@"1" forKey:session.username];
        }
        
        //MCOIMAPSearchExpression* expr;
        MCOIMAPSearchKind kind;
        if (btType == btSent) {
            //expr = [MCOIMAPSearchExpression searchTo:fromFilter];
            kind = MCOIMAPSearchKindTo;
        }else{
            //expr = [MCOIMAPSearchExpression searchFrom:fromFilter];
            kind = MCOIMAPSearchKindFrom;
        }
        
        
        //MCOIMAPSearchOperation* op = [session searchOperationWithFolder:self->currentBoxName kind:kind searchString:fromFilter];
        
        MCOIMAPSearchOperation* op;// = [session searchExpressionOperationWithFolder:self->currentBoxName expression:[MCOIMAPSearchExpression searchOr:[MCOIMAPSearchExpression searchFrom:fromFilter] other:[MCOIMAPSearchExpression searchBody:fromFilter]]];
        
        // Search flagged - it works!
        // TODO: filter types here and in a section header of the list
        if([fromFilter isEqualToString:filterStarred]){
            op = [session searchExpressionOperationWithFolder:strongSelf->currentBoxName expression:[MCOIMAPSearchExpression searchFlagged]];
        }else if([fromFilter isEqualToString:filterAnswered]){
            op = [session searchExpressionOperationWithFolder:strongSelf->currentBoxName expression:[MCOIMAPSearchExpression searchAnswered]];
        }else if([fromFilter isEqualToString:filterUnread]){
            op = [session searchExpressionOperationWithFolder:strongSelf->currentBoxName expression:[MCOIMAPSearchExpression searchUnread]];
        }else if([fromFilter isEqualToString:filterLarge]){
            op = [session searchExpressionOperationWithFolder:strongSelf->currentBoxName expression:[MCOIMAPSearchExpression searchSizeLargerThan:200*1024]];
        }else if([fromFilter isEqualToString:filterAttachments]){
            op = [session searchExpressionOperationWithFolder:strongSelf->currentBoxName expression:[MCOIMAPSearchExpression searchHeader:@"Content-Type" value:@"multipart/mixed;"]]; // Not working
        
        }else if([fromFilter isEqualToString:filterImportant]){
            op = [session searchExpressionOperationWithFolder:strongSelf->currentBoxName expression:[MCOIMAPSearchExpression searchOr:[MCOIMAPSearchExpression searchHeader:@"X-Priority" value:@"1"] other:[MCOIMAPSearchExpression searchHeader:@"X-Priority" value:@"2"]]];
            
        }else if(fromFilter.length > filterSince.length && [[fromFilter substringToIndex:filterSince.length] isEqualToString:filterSince]){
            NSString *dateString = [fromFilter substringFromIndex:filterSince.length+1];
            NSDate *dateFromString = [[NSCalendar currentCalendar] startOfDayForDate: [CommonProcs dateFromString:dateString]];
            op = [session searchExpressionOperationWithFolder:strongSelf->currentBoxName expression:[MCOIMAPSearchExpression searchSinceReceivedDate:dateFromString]];
        
        }else if(fromFilter.length > filterBefore.length && [[fromFilter substringToIndex:filterBefore.length] isEqualToString:filterBefore]){
            NSString *dateString = [fromFilter substringFromIndex:filterBefore.length+1];
            NSDate *dateFromString = [CommonProcs dateFromString:dateString];
            op = [session searchExpressionOperationWithFolder:strongSelf->currentBoxName expression:[MCOIMAPSearchExpression searchBeforeReceivedDate:dateFromString]];
        
        }else if(fromFilter.length > filterIn.length && [[fromFilter substringToIndex:filterIn.length] isEqualToString:filterIn]){
            NSString *dateString = [fromFilter substringFromIndex:filterIn.length+1];
            NSDate *dateFromString = [CommonProcs dateFromString:dateString];
            NSCalendar* cal = [NSCalendar currentCalendar];
            NSDateComponents *comp = [cal components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:dateFromString];
            [comp setDay:1];
            NSDate *dateFromStringSince = [cal dateFromComponents:comp];
            [comp setMonth:comp.month+1];
            NSDate *dateFromStringBefore = [cal dateFromComponents:comp];
            op = [session searchExpressionOperationWithFolder:strongSelf->currentBoxName expression:[MCOIMAPSearchExpression searchAnd:[MCOIMAPSearchExpression searchSinceReceivedDate:dateFromStringSince] other:[MCOIMAPSearchExpression searchBeforeReceivedDate:dateFromStringBefore]]];
        
        }else if(fromFilter.length > filterBetween.length && [[fromFilter substringToIndex:filterBetween.length] isEqualToString:filterBetween]){
            NSString *dateString = [fromFilter substringFromIndex:filterBetween.length+1];
            NSArray *datesFromString = [CommonProcs datesFromString:dateString];
            
            if (datesFromString.count == 2) {
                NSDate* date1 = [[NSCalendar currentCalendar] startOfDayForDate: datesFromString[0]];
                NSDate* date2 = [[NSCalendar currentCalendar] dateBySettingHour:23 minute:59 second:59 ofDate:datesFromString[1] options:NSCalendarWrapComponents];
                if ([date1 compare:date2] == NSOrderedDescending) { // date1 is later
                    // Swap dates
                    NSDate* tmp = date1;
                    date1 = date2;
                    date2 = tmp;
                }
                op = [session searchExpressionOperationWithFolder:strongSelf->currentBoxName expression:[MCOIMAPSearchExpression searchAnd:[MCOIMAPSearchExpression searchSinceReceivedDate:date1] other:[MCOIMAPSearchExpression searchBeforeReceivedDate:date2]]];
            }else{
                op = [session searchExpressionOperationWithFolder:strongSelf->currentBoxName expression:[MCOIMAPSearchExpression searchAnd:[MCOIMAPSearchExpression searchSinceReceivedDate:[NSDate date]] other:[MCOIMAPSearchExpression searchBeforeReceivedDate:[[NSCalendar currentCalendar] startOfDayForDate:[NSDate date]]]]];
            }
        }else if(fromFilter.length > filterOn.length && [[fromFilter substringToIndex:filterOn.length] isEqualToString:filterOn]){
            NSString *dateString = [fromFilter substringFromIndex:filterOn.length+1];
            NSDate *dateFromString = [CommonProcs dateFromString:dateString];
            op = [session searchExpressionOperationWithFolder:strongSelf->currentBoxName expression:[MCOIMAPSearchExpression searchOnReceivedDate:dateFromString]];
        
        }else if([fromFilter isEqualToString:filterProtected]){
            op = [session searchExpressionOperationWithFolder:strongSelf->currentBoxName expression:[MCOIMAPSearchExpression searchSubject:@"sm"]]; //SM@1 is not working because of the @ symbol
            
        }else if(fromFilter.length > filterFromF.length && [[fromFilter substringToIndex:filterFromF.length] isEqualToString:filterFromF]){
            NSString *fromStr = [fromFilter substringFromIndex:filterFromF.length+1];
            op = [session searchExpressionOperationWithFolder:strongSelf->currentBoxName expression:[MCOIMAPSearchExpression searchFrom:fromStr]];
        
        }else if(fromFilter.length > filterTo.length && [[fromFilter substringToIndex:filterTo.length] isEqualToString:filterTo]){
            NSString *toStr = [fromFilter substringFromIndex:filterTo.length+1];
            op = [session searchExpressionOperationWithFolder:strongSelf->currentBoxName expression:[MCOIMAPSearchExpression searchTo:toStr]];
        
        }else if(fromFilter.length > filterLargerThan.length && [[fromFilter substringToIndex:filterLargerThan.length] isEqualToString:filterLargerThan]){
            NSString *sizeStr = [fromFilter substringFromIndex:filterLargerThan.length+1];
            long szzz = [CommonProcs longFromString:sizeStr];
            if (szzz > 0) {
                op = [session searchExpressionOperationWithFolder:strongSelf->currentBoxName expression:[MCOIMAPSearchExpression searchSizeLargerThan:(int)szzz]];
            }
        }else if(fromFilter.length > filterSmallerThan.length && [[fromFilter substringToIndex:filterSmallerThan.length] isEqualToString:filterSmallerThan]){
            NSString *sizeStr = [fromFilter substringFromIndex:filterSmallerThan.length+1];
            long szzz = [CommonProcs longFromString:sizeStr];
            if (szzz > 0) {
                op = [session searchExpressionOperationWithFolder:strongSelf->currentBoxName expression:[MCOIMAPSearchExpression searchSizeSmallerThan:(int)szzz]];
            }
        }else{
            op = [session searchExpressionOperationWithFolder:strongSelf->currentBoxName expression:[MCOIMAPSearchExpression searchOr:[MCOIMAPSearchExpression searchFrom:fromFilter] other:[MCOIMAPSearchExpression searchContent:fromFilter]]];
            //[MCOIMAPSearchExpression searchGmailRaw:fromFilter]]];
        }
        
        //NSLog(@"Search operation for %@-%@", self->currentBoxName, session.hostname);
        
        [op start:^(NSError* error, MCOIndexSet* searchResult) {
            //NSLog(@"Number of messages %d", searchResult.count);
            __strong __typeof__(self) strongSelf = weakSelf;
            
            SettingsEntity* setTmp = [[GlobalRouter sharedManager] getSettingForAddress:session.username]; //.settingsNames objectForKey:session.username];
            
            if (searchResult == nil || searchResult.count == 0) {
                NSLog(@"No result for %@ with error %@", session.username, error.localizedDescription);
                //strongSelf->numberOfEmptied++;
                //if(strongSelf->numberOfEmptied == strongSelf.imapSessions.count)
                    //[[[GlobalRouter sharedManager] getListRouter].manager tellUpNoMoreButton];
                if (!strongSelf.finishedForAddress) {
                    strongSelf.finishedForAddress = [[NSMutableDictionary alloc] init];
                }
                if(session.username)
                    [strongSelf.finishedForAddress setValue:[NSNumber numberWithBool:YES] forKey:session.username];
                BOOL allDone = YES;
                for (SessionConnectorNew *sess in strongSelf.imapSessions) {
                    if (sess.imapSession.username && ![strongSelf.finishedForAddress objectForKey:sess.imapSession.username]) {
                        allDone = NO;
                        break;
                    }
                }
                
                if(allDone)
                    [[[GlobalRouter sharedManager] getListRouter].manager tellUpNoMoreButton];
                
                if(session.username)[self.requestedForAddress removeObjectForKey:session.username];
                [[[GlobalRouter sharedManager] getListRouter].manager dataReady:@[] error:error.localizedDescription forSettings:setTmp.settingsName];
                return;
            }
            
            if (!strongSelf.totalForAddress) {
                strongSelf.totalForAddress = [[NSMutableDictionary alloc] init];
            }
            if(session.username)
                [strongSelf.totalForAddress setValue:[NSNumber numberWithInteger:searchResult.count] forKey:session.username];
            
            [GlobalRouter sharedManager].totalMessages = 0;
            for (SessionConnectorNew *sess in strongSelf.imapSessions) {
                if(sess.imapSession.username){
                    NSNumber* i = (NSNumber*)[strongSelf.totalForAddress objectForKey:sess.imapSession.username];
                    [GlobalRouter sharedManager].totalMessages += (int)i.integerValue;
                }
            }
            
            //[GlobalRouter sharedManager].totalMessages += searchResult.count;
            NSInteger loadedMsg = 0;
            if(session.username)
                loadedMsg = [[self.messagesForAddress objectForKey:session.username] integerValue];
            //int loaded = (int)self.messages.count;
            int nLoad = [GlobalRouter sharedManager].nMessagesToLoad;
            if (nLoad == 0) {
                nLoad = 10;
            }
            NSUInteger numberOfMessagesToLoad = MIN(nLoad,searchResult.count-loadedMsg);
            
            if (numberOfMessagesToLoad == 0)
            {
                //[[[GlobalRouter sharedManager] getListRouter].manager dataReady:nil error:NSLocalizedString(@"No messages",nil)];
                if(session.username)[self.requestedForAddress removeObjectForKey:session.username];
                [[[GlobalRouter sharedManager] getListRouter].manager dataReady:[[NSArray alloc] init] error:error.localizedDescription forSettings:setTmp.settingsName];
                
                if (!strongSelf.finishedForAddress) {
                    strongSelf.finishedForAddress = [[NSMutableDictionary alloc] init];
                }
                if(session.username)
                    [strongSelf.finishedForAddress setValue:[NSNumber numberWithBool:YES] forKey:session.username];
                
                BOOL allDone = YES;
                for (SessionConnectorNew *sess in strongSelf.imapSessions) {
                    if (sess.imapSession.username && ![strongSelf.finishedForAddress objectForKey:sess.imapSession.username]) {
                        allDone = NO;
                        break;
                    }
                }
                
                if(allDone)
                    [[[GlobalRouter sharedManager] getListRouter].manager tellUpNoMoreButton];
                
                //strongSelf->numberOfEmptied++;
                //if(strongSelf->numberOfEmptied == self.imapSessions.count)
                    //[[[GlobalRouter sharedManager] getListRouter].manager tellUpNoMoreButton];
                return;
            }
            
            // NEED to figure out how many messages to load...
            
            if (nMessages+loadedMsg >= searchResult.count) {
                // Last fetch - need to hide button for more messages
                
                if (!strongSelf.finishedForAddress) {
                    strongSelf.finishedForAddress = [[NSMutableDictionary alloc] init];
                }
                if(session.username)
                    [strongSelf.finishedForAddress setValue:[NSNumber numberWithBool:YES] forKey:session.username];
                
                BOOL allDone = YES;
                for (SessionConnectorNew *sess in strongSelf.imapSessions) {
                    if (sess.imapSession.username && ![strongSelf.finishedForAddress objectForKey:sess.imapSession.username]) {
                        allDone = NO;
                        break;
                    }
                }
                //strongSelf->numberOfEmptied++;
                //if(strongSelf->numberOfEmptied == strongSelf.imapSessions.count || btType == btUseName)
                if(allDone || btType == btUseName)
                //strongSelf->numberOfEmptied++;
                //if(strongSelf->numberOfEmptied == self.imapSessions.count)
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
            
            if ([strongSelf->currentBoxName isEqualToString:@""]) {
                strongSelf->currentBoxName = @"INBOX";
            }
            MCOIMAPFetchMessagesOperation *imapMessagesFetchOp2 /*strongSelf.imapMessagesFetchOp*/ = [session fetchMessagesOperationWithFolder:strongSelf->currentBoxName
                                                                           requestKind:requestKind
                                                                                  uids:toGet];//searchResult];
            /*strongSelf.imapMessagesFetchOp*/imapMessagesFetchOp2.extraHeaders = @[@"Disposition-Notification-To", @"X-Priority",@"Comments", @"Delay"];
            
            [/*strongSelf.imapMessagesFetchOp*/imapMessagesFetchOp2 start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                    __strong __typeof__(self) strongSelf = weakSelf;
                    NSSortDescriptor *sort =
                    [NSSortDescriptor sortDescriptorWithKey:@"header.date" ascending:NO];
                    
                    NSMutableArray *combinedMessages = [NSMutableArray arrayWithArray:messages];
                    
                    [GlobalRouter sharedManager].loadedMessages += (int)(messages.count);
                    
                    //NSLog(@"%@ set No %d", self, (int)(messages.count+loadedMsg));
                    if (strongSelf.messagesForAddress == nil) {
                        strongSelf.messagesForAddress = [[NSMutableDictionary alloc] init];
                    }
                    if(session.username)
                        [strongSelf.messagesForAddress setValue:[NSNumber numberWithInt:(int)(messages.count+loadedMsg)] forKey:session.username];
                    
                    NSArray* tmp = [combinedMessages sortedArrayUsingDescriptors:@[sort]];
                    
                    if (error) {
                        NSLog(@"Error %@", error.localizedDescription);
                    }
                    if(session.username)[self.requestedForAddress removeObjectForKey:session.username];
                    
                    BOOL found = NO;
                    for (SessionConnectorNew* sss in self.imapSessions) {
                        if ([sss.imapSession isEqual:session]) {
                            found = YES;
                            break;
                        }
                    }
                    if (!found) {
                        NSLog(@"Active session was not found");
                    }else{
                        [[[GlobalRouter sharedManager] getListRouter].manager dataReady:tmp error:error.localizedDescription forSettings:setTmp.settingsName];
                    }
                });
            }];
            
        }];
    };
    
    //[GlobalRouter sharedManager].totalMessages = 0;
    [[GlobalRouter sharedManager] getListRouter].manager.nAccountsToWait++;
    [self getNameAndDoBlockWithSession:btType block:block session:session];
}

- (void)loadLastNMessages:(NSUInteger)nMessages :(boxTypes)btType forSession:(MCOIMAPSession*)session
{
    loadingMessages = YES;
    [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
    [CommonProcs setSWLabelText:NSLocalizedString(@"Loading", nil)];
    
    __weak __typeof__(self) weakSelf = self;
    void (^block)(MCOIMAPSession* session) = ^void(MCOIMAPSession* session)
    {
        __strong __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf.finishedForAddress && session.username && ((NSNumber*)([strongSelf.finishedForAddress objectForKey:session.username])).boolValue) {
            SettingsEntity* setTmp = [[GlobalRouter sharedManager] getSettingForAddress:session.username];
            [[[GlobalRouter sharedManager] getListRouter].manager dataReady:strongSelf.messages error:/*NSLocalizedString(@"No more messages",nil)*/[DataStorage noMoreMessages] forSettings:setTmp.settingsName];
            return;
        }
        
        if (self.requestedForAddress && [self.requestedForAddress objectForKey:session.username]) {
            // Already requested
            [[[GlobalRouter sharedManager] getListRouter].manager dataReady:[[NSArray alloc] init] error:[DataStorage fetchInProgress] forSettings:session.username];
            return;
        }
        
        // Add a session name to a dictionary of requested fetches
        // On finish, remove that name
        // If the dictionary is not empty, the fetch is in progress
        // If not finished, make a stop button together with the activity indicator in a list
        if (!self.requestedForAddress) {
            self.requestedForAddress = [[NSMutableDictionary alloc] init];
        }
        if (session.username) {
            [self.requestedForAddress setObject:@"1" forKey:session.username];
        }
        
        MCOIMAPMessagesRequestKind requestKind = (MCOIMAPMessagesRequestKind)
        (MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindStructure |
         MCOIMAPMessagesRequestKindInternalDate | MCOIMAPMessagesRequestKindHeaderSubject |
         MCOIMAPMessagesRequestKindFlags | MCOIMAPMessagesRequestKindUid | MCOIMAPMessagesRequestKindSize
         //| MCOIMAPMessagesRequestKindExtraHeaders | MCOIMAPMessagesRequestKindFullHeaders
         );
        
        NSString* currentBox = [strongSelf->currentBoxesName objectForKey:session.username];
        
        MCOIMAPFolderInfoOperation *inboxFolderInfo = [session folderInfoOperation:currentBox];
        
        [inboxFolderInfo start:^(NSError *error, MCOIMAPFolderInfo *info)
         {
             if (error) {
                 NSLog(@"Load last N for %@ error %@", currentBox, error.localizedDescription);
             }
             __strong __typeof__(self) strongSelf = weakSelf;
             BOOL totalNumberOfMessagesDidChange = NO;//self.totalNumberOfInboxMessages != [info messageCount];
             NSInteger loadedMsg = [[strongSelf.messagesForAddress objectForKey:session.username] integerValue];
             
             if (loadedMsg > [info messageCount]) {
                 // Something strange... shouldn't be so,
                 loadedMsg = [info messageCount];
             }
             //NSLog(@"%@ (%@) read from %@=%ld", self, session.username, [self.messagesForAddress objectForKey:session.username], (long)loadedMsg);
             int totalNumberOfInboxMessages = [info messageCount];
             if (!strongSelf.totalForAddress) {
                 strongSelf.totalForAddress = [[NSMutableDictionary alloc] init];
             }
             [strongSelf.totalForAddress setValue:[NSNumber numberWithInteger:totalNumberOfInboxMessages] forKey:session.username];
             if (totalNumberOfInboxMessages == 0) {
                 //[GlobalRouter sharedManager].totalMessages = 0;
             }else{
                 [GlobalRouter sharedManager].totalMessages = 0;
                 for (SessionConnectorNew *sess in strongSelf.imapSessions) {
                     if(sess.imapSession.username){
                         NSNumber* i = (NSNumber*)[strongSelf.totalForAddress objectForKey:sess.imapSession.username];
                         [GlobalRouter sharedManager].totalMessages += (int)i.integerValue;
                     }
                 }
                 //[GlobalRouter sharedManager].totalMessages += totalNumberOfInboxMessages;
             }
             
             NSUInteger numberOfMessagesToLoad = MIN([info messageCount], nMessages+loadedMsg);
             SettingsEntity* setTmp = [[GlobalRouter sharedManager] getSettingForAddress:session.username];// .settingsNames objectForKey:session.username];
             
             if (numberOfMessagesToLoad == 0)
             {
                 //self.isLoading = NO;
                 if(session.username)[self.requestedForAddress removeObjectForKey:session.username];
                 [[[GlobalRouter sharedManager] getListRouter].manager dataReady:[[NSArray alloc] init] error:NSLocalizedString(@"No messages",nil) forSettings:setTmp.settingsName];
                 return;
             }
             
             if (nMessages+loadedMsg >= [info messageCount]) {
                 // Last fetch - need to hide button for more messages
                 if (!strongSelf.finishedForAddress) {
                     strongSelf.finishedForAddress = [[NSMutableDictionary alloc] init];
                 }
                 [strongSelf.finishedForAddress setValue:[NSNumber numberWithBool:YES] forKey:session.username];
                 
                 BOOL allDone = YES;
                 for (SessionConnectorNew *sess in strongSelf.imapSessions) {
                     if (sess.imapSession.username && ![strongSelf.finishedForAddress objectForKey:sess.imapSession.username]) {
                         allDone = NO;
                         break;
                     }
                 }
                 //strongSelf->numberOfEmptied++;
                 //if(strongSelf->numberOfEmptied == strongSelf.imapSessions.count || btType == btUseName)
                 if(allDone || btType == btUseName)
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
                     if(session.username)[self.requestedForAddress removeObjectForKey:session.username];
                     [[[GlobalRouter sharedManager] getListRouter].manager dataReady:strongSelf.messages error:[DataStorage noMoreMessages] forSettings:setTmp.settingsName];
                     //self->numberOfEmptied++;
                     //if(self->numberOfEmptied == self.imapSessions.count || btType == btUseName)
                     //    [[[GlobalRouter sharedManager] getListRouter].manager tellUpNoMoreButton];
                     NSLog(@"No more for %@", setTmp.userName);
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
             [session fetchMessagesByNumberOperationWithFolder:currentBox
                                                   requestKind:requestKind
                                                       numbers:
             [MCOIndexSet indexSetWithRange:fetchRange]];
            
            SessionConnectorNew* scnS;
            for (SessionConnectorNew* sss in self.imapSessions) {
                if ([sss.imapSession isEqual:session]) {
                    scnS = sss;
                    break;
                }
            }
            if (scnS) {
                scnS.currentOperation = fetchOp;
            }
             //////!!!!!!!!!!!!!!!!!!
             //fetchOp.extraHeaders = @[@"X-MAILER"];
             fetchOp.extraHeaders = @[@"Disposition-Notification-To", @"X-Priority",@"Comments", @"Delay"];
             
             [fetchOp setProgress:^(unsigned int progress) {
                 [[[GlobalRouter sharedManager] getListRouter].manager setProgress:progress max:(int)numberOfMessagesToLoad];
             }];
             
             [fetchOp start:
              ^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages)
              {
                  if (error) {
                      NSLog(@"Load last N fetchOp for %@ error %@", currentBox, error.localizedDescription);
                  }
                  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                      
                      NSSortDescriptor *sort =
                      [NSSortDescriptor sortDescriptorWithKey:@"header.date" ascending:NO];
                      
                      NSMutableArray *combinedMessages = [NSMutableArray arrayWithArray:messages];
                      [GlobalRouter sharedManager].loadedMessages += (int)(messages.count);
                      
                      //NSLog(@"%@ set No %d", self, (int)(messages.count+loadedMsg));
                      if (strongSelf.messagesForAddress == nil) {
                          strongSelf.messagesForAddress = [[NSMutableDictionary alloc] init];
                      }
                      [strongSelf.messagesForAddress setValue:[NSNumber numberWithInt:(int)(messages.count+loadedMsg)] forKey:session.username];
                      
                      NSArray* tmp = [combinedMessages sortedArrayUsingDescriptors:@[sort]];
                      
                      if(session.username)[self.requestedForAddress removeObjectForKey:session.username];
                      //if(!session)NSLog(@"Session is null!");
                      // There's an issue - if you switch off the phone while the messages are loaded, the sessions are cleared, but the callback is called anyway. We need to monitor that issue and not load messages.
                      BOOL found = NO;
                      for (SessionConnectorNew* sss in self.imapSessions) {
                          if ([sss.imapSession isEqual:session]) {
                              found = YES;
                              break;
                          }
                      }
                      if (!found) {
                          NSLog(@"Active session was not found");
                      }else{
                          if(![GlobalRouter sharedManager].goingToBG)
                              [[[GlobalRouter sharedManager] getListRouter].manager dataReady:tmp error:error.localizedDescription forSettings:setTmp.settingsName];
                      }
                      /*
                       // Test debug
                       if (session.checkCertificateEnabled) {
                       [[[GlobalRouter sharedManager] getListRouter].manager dataReady:nil error:@"The certificate for this server is invalid" forSettings:setTmp.settingsName];
                       }else{
                       [[[GlobalRouter sharedManager] getListRouter].manager dataReady:tmp error:error.localizedDescription forSettings:setTmp.settingsName];
                       }
                       */
                      strongSelf->loadingMessages = NO;
                  });
              }];
         }];
    };
    
    //numberOfEmptied = 0;
    //[GlobalRouter sharedManager].totalMessages = 0;
    
    if (btType == btUseName && ![[GlobalRouter sharedManager].currentAccount isEqualToString:@""]) {
        //NSString* emailAddr = [[GlobalRouter sharedManager].accountsNames allKeysForObject:[GlobalRouter sharedManager].currentAccount][0];
        NSString* emailAddr = [DataStorage getEmailAddressFromCurrentAccount];
        
        if([session.username isEqualToString:emailAddr]){
            [[GlobalRouter sharedManager] getListRouter].manager.nAccountsToWait++;
            [self getNameAndDoBlockWithSession:btType block:block session:session];
            NSLog(@"Calling fetch %@", session.username);
        }
    }else{
        [[GlobalRouter sharedManager] getListRouter].manager.nAccountsToWait++;
        [self getNameAndDoBlockWithSession:btType block:block session:session];
        NSLog(@"Calling fetch %@", session.username);
    }
}

-(BOOL)checkSessionsAndReconnectSyncForBox:(boxTypes)btType
{
    // self.imapSessions is edited just here or in procs called from here and nowhere else!
    
    if (connecting > 0 || conSem != nil) {
        // Connection in progress
        if(conSem != nil){
            [GlobalRouter sharedManager].connectionCancelled = YES;
            dispatch_semaphore_signal(conSem);
            conSem = nil;
        }
        [self closeAllSessionsSync:YES];
        connecting = 0;
    }
    // Check sessions and wait for check! If error, reconnect...
    __block BOOL needReconnect = NO;
    
    if (self.imapSessions == nil || btType == btNo || self.imapSessions.count == 0 || self.imapSessions.count < [GlobalRouter sharedManager].allSettings.count-1 /*|| [GlobalRouter sharedManager].otherFolders.count < [GlobalRouter sharedManager].allSettings.count-1*/){
        needReconnect = YES;
        [GlobalRouter sharedManager].currentBox = btInbox;
        if(![self connectSessions:btType forAddress:nil]){
            // No settings
            [[[GlobalRouter sharedManager] getListRouter].manager dataReady:[[NSArray alloc] init] error:NSLocalizedString(@"No settings", nil) forSettings:NSLocalizedString(@"Error",nil)];
        }
    }else{
        __weak __typeof__(self) weakSelf = self;
        NSLog(@"Total IMAP sessions = %lu", (unsigned long)self.imapSessions.count);
        for (SessionConnectorNew* session in self.imapSessions) {
            [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
                __strong __typeof__(self) strongSelf = weakSelf;
                // Session OK
                if(!error){
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [strongSelf sessionOK:session.imapSession boxType:btType];
                    });
                }else{
                    [[[GlobalRouter sharedManager] getListRouter].manager dataReady:[[NSArray alloc] init] error:error.localizedDescription forSettings:[session getSettingsName]];
                    NSLog(@"Error connecting session %@", session.imapSession.username);
                }
            }];
        }
        
        if ([GlobalRouter sharedManager].otherFolders.count < self.imapSessions.count) {
            // Some accounts are not loaded
            NSMutableArray* notLoaded = [[NSMutableArray alloc] init];
            for (SessionConnectorNew* sess in self.imapSessions) {
                NSString* accountName = [[GlobalRouter sharedManager].accountsNames valueForKey:sess.imapSession.username];
                if (![[GlobalRouter sharedManager].otherFolders objectForKey:accountName]) {
                    [notLoaded addObject:sess];
                    /*
                    [self getNameAndDoBlockWithSession:btInbox block:^(MCOIMAPSession *session) {
                        return;
                    } session:sess.imapSession];*/
                    sess.imapSession = nil;
                    [sess connectIMAPSessionWithCompletionHandler:^(NSError * _Nonnull error) {
                            [self getAllFolderNamesForSession:sess.imapSession];
                    }];
                }
            }
#if DEBUG
            NSLog(@"Account are not loaded");
#endif
        }
        
    }
    
    return NO;
}

-(void)closeAllSessionsSync:(BOOL)sync
{
    if(self.imapSessions == nil)return;
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    __block int i = 0;
    
    for (__strong __block SessionConnectorNew* session in self.imapSessions) {
        //[session.imapSession cancelAllOperations];
        [session cancellAllOpsWithClean:YES];
    }
    if(i>0 && sync)dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    //[self.imapSessions removeAllObjects];
    //if(deadSessions != nil)[deadSessions removeAllObjects];
}

-(void)sessionOK:(MCOIMAPSession*)session boxType:(boxTypes)btType
{
    [CommonProcs setSWLabelText:NSLocalizedString(@"Loading", nil)];
    int nLoad = [GlobalRouter sharedManager].nMessagesToLoad;
    if (nLoad == 0) {
        nLoad = 10;
    }
    [self loadLastNMessages:nLoad :btType forSession:session];
}

-(void)readFullHeaderForMessage:(ShortMessageEntity*)message completion:(void (^)(NSString*))completionBlock
{
    __weak __typeof__(self) weakSelf = self;
    for (SessionConnectorNew* session in self.imapSessions) {
        if([session isThisForAddress:message.toAddress]){
            [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
                __strong __typeof__(self) strongSelf = weakSelf;
                if(!error){
                    [CommonProcs setSWLabelText:NSLocalizedString(@"Loading", nil)];
                    MCOIMAPFetchMessagesOperation * op = [session.imapSession fetchMessagesOperationWithFolder:strongSelf->currentBoxName
                                                                                                   requestKind:  MCOIMAPMessagesRequestKindHeaders
                                                          | MCOIMAPMessagesRequestKindStructure
                                                          | MCOIMAPMessagesRequestKindFullHeaders
                                                          | MCOIMAPMessagesRequestKindSize
                                                          | MCOIMAPMessagesRequestKindFlags
                                                          
                                                                                                          uids:[MCOIndexSet indexSetWithIndex:[message.messageID intValue]]];
                    op.extraHeaders = @[@"X-Mailer", @"User-Agent", @"X-Sender", @"X-Envelope-From", @"Originator-Info", @"X-Priority", @"Received", @"Envelope-To", @"List-Unsubscribe", @"Content-Type", @"X-Originating-IP", @"Content-Disposition", @"Keywords", @"Comments", @"Content-Description", @"Importance", @"Sensitivity", @"Content-MD5", @"Path", @"DL-Expansion-History-Indication", @"X-Authenticated-IP", @"X-Authenticated-Sender", @"X-Mailer-Info", @"Disposition-Notification-To", @"Delay"];
                    /*
                     [session.imapSession setConnectionLogger:^(void * connectionID, MCOConnectionLogType type, NSData * data)
                     {
                     NSLog(@"START = %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                     }];
                     */
                    [op start:^(NSError * __nullable error, NSArray * messages, MCOIndexSet * vanishedMessages) {
                        //NSString* ret = @"";
                        NSMutableString* ret2 = [[NSMutableString alloc] init];
                        [ret2 appendString:@"<!DOCTYPE html> <html><head><title>Message info</title></head><body style=""font-family:verdana;""> <h3>Message info</h3>"];
                        
                        for(MCOIMAPMessage* msg in messages) {
                            //NSLog(@"%u: %@", [msg uid], [msg header]);
                            MCOMessageHeader* hdr = [msg header];
                            [ret2 appendFormat:@"<b>MessageID:</b> %@<br>", hdr.messageID];
                            [ret2 appendFormat:@"<b>Sender:</b> %@<br>", [self getStringForAddress:hdr.sender]];
                            [ret2 appendFormat:@"<b>From:</b> %@<br>", [self getStringForAddress:hdr.from]];
                            for (MCOAddress* addrto in hdr.to) {
                                [ret2 appendFormat:@"<b>To:</b> %@<br>", [self getStringForAddress:addrto]];
                            }
                            if (hdr.cc != nil) {
                                for (MCOAddress* addrto in hdr.cc) {
                                    [ret2 appendFormat:@"<b>CC:</b> %@<br>", [self getStringForAddress:addrto]];
                                }
                            }
                            if (hdr.bcc != nil) {
                                for (MCOAddress* addrto in hdr.bcc) {
                                    [ret2 appendFormat:@"<b>BCC:</b> %@<br>", [self getStringForAddress:addrto]];
                                }
                            }
                            if (hdr.replyTo != nil) {
                                for (MCOAddress* addrto in hdr.replyTo) {
                                    [ret2 appendFormat:@"<b>Reply to:</b> %@<br>", [self getStringForAddress:addrto]];
                                }
                            }
                            [ret2 appendFormat:@"<b>Date:</b> %@<br>", hdr.date];
                            [ret2 appendFormat:@"<b>Date received:</b> %@<br>", hdr.receivedDate];
                            if(hdr.userAgent != nil)
                                [ret2 appendFormat:@"<b>UserAgent:</b> %@<br>", hdr.userAgent];
                            [ret2 appendFormat:@"<b>Subject:</b> %@<br><br>", hdr.subject];
                            if (hdr.inReplyTo != nil) {
                                for (NSString* inrt in hdr.inReplyTo) {
                                    [ret2 appendFormat:@"<b>In Reply to:</b> %@<br>", inrt];
                                }
                            }
                            [ret2 appendFormat:@"<b>Message size:</b> %d bytes<br>", msg.size];
                            
                            [ret2 appendFormat:@"<b>Message flags:</b> 0x%02lX<br>", (long)msg.flags];
                            if (msg.flags & MCOMessageFlagSeen) {
                                [ret2 appendString:@"&emsp;+Seen<br>"];
                            }
                            if (msg.flags & MCOMessageFlagAnswered) {
                                [ret2 appendString:@"&emsp;+Answered<br>"];
                            }
                            if (msg.flags & MCOMessageFlagDraft) {
                                [ret2 appendString:@"&emsp;+Draft<br>"];
                            }
                            if (msg.flags & MCOMessageFlagFlagged) {
                                [ret2 appendString:@"&emsp;+Flagged<br>"];
                            }
                            if (msg.flags & MCOMessageFlagDeleted) {
                                [ret2 appendString:@"&emsp;+Deleted<br>"];
                            }
                            if (msg.flags & MCOMessageFlagForwarded) {
                                [ret2 appendString:@"&emsp;+Forwarded<br>"];
                            }
                            if (msg.flags & MCOMessageFlagSubmitted) {
                                [ret2 appendString:@"&emsp;+Submitted<br>"];
                            }
                            if (msg.flags & MCOMessageFlagSubmitPending) {
                                [ret2 appendString:@"&emsp;+Submit Pending<br>"];
                            }
                            if (msg.flags & MCOMessageFlagMDNSent) {
                                [ret2 appendString:@"&emsp;>+Message Disposition Notification Sent<br>"];
                            }
                            
                            //ret = [NSString stringWithFormat:@"%@", [msg header]];
                            
                            NSArray* allh = [msg.header allExtraHeadersNames];
                            if (allh.count > 0) {
                                [ret2 appendFormat:@"<br><b>Extra headers (%lu):</b><br>", (unsigned long)allh.count];
                                for (NSString* nm in allh) {
                                    NSString* val = [hdr extraHeaderValueForName:nm];
                                    // Quick fix as a string starting with "<" is not displayed, so get rid of it
                                    if ([val hasPrefix:@"<"]) {
                                        val = [val substringFromIndex:1];
                                        val = [val substringToIndex:val.length-1];
                                    }
                                    [ret2 appendFormat:@"- %@ %@<br>", nm, val];
#if DEBUG
                                    NSLog(@"%@ = %@", nm, [hdr extraHeaderValueForName:nm]);
#endif
                                }
                            }else{
                                [ret2 appendString:@"<br>No Extra headers<br>"];
                            }
                            
                            NSArray* cFlags = [msg customFlags];
                            if (cFlags.count > 0) {
                                [ret2 appendFormat:@"<br><b>Custom flags (%lu):</b><br>", (unsigned long)cFlags.count];
                                for (NSString* nm in cFlags) {
                                    [ret2 appendFormat:@"- %@<br>", nm];
                                    NSLog(@"%@", nm);
                                }
                            }else{
                                [ret2 appendString:@"<br>No custom flags<br>"];
                            }
                        }
                        //session.imapSession.connectionLogger = nil;
                        [ret2 appendString:@"</body></html>"];
                        completionBlock(ret2);
                    }];
                }else{
                    [[[GlobalRouter sharedManager] getListRouter].manager dataReady:[[NSArray alloc] init] error:error.localizedDescription forSettings:[session getSettingsName]];
                }
            }];
        }
    }
}

-(NSString*)getStringForAddress:(MCOAddress*)addr
{
    if (addr.displayName == nil) {
        return [NSString stringWithFormat:@"%@", addr.mailbox];
    }else{
        return [NSString stringWithFormat:@"\"%@\" %@", addr.displayName, addr.mailbox];
    }
}

-(void)readShortMessagesForBox:(boxTypes)btType
{
    [self readShortMessagesForBox:btType next:NO];
}

-(void)readShortMessagesForBox:(boxTypes)btType next:(BOOL)next
{
    if (connecting > 0) {
        // Connection in progress
        if(conSem != nil){
            [GlobalRouter sharedManager].connectionCancelled = YES;
            dispatch_semaphore_signal(conSem);
            conSem = nil;
        }
        //[self closeAllSessionsSync:YES];
        connecting = 0;
    }
    if(!next)[GlobalRouter sharedManager].loadedMessages = 0; // then you load next, that causes a bug in showing loaded
    [GlobalRouter sharedManager].currentBox = btType;
    numberOfEmptied = 0;
    [[GlobalRouter sharedManager] getListRouter].manager.nAccountsToWait = 0;
    [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
    [CommonProcs setSWLabelText:NSLocalizedString(@"Connecting", nil)];
    
    /*
    for (SessionConnectorNew* sess in self.imapSessions) {
        //[sess.imapSession cancelAllOperations];
        [sess cancellAllOps];
    }
    */
    if (btType == btUseName) {
#if DEBUG
        dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs showVanishingMessage:@"Using btUseName"];// inView:[[GlobalRouter sharedManager] getCurrentView] inRect:CGRectMake(10,100, 300, 40) timeToShow:5];
        });
#endif
        // No need to connect everything. Find out the address and load messages for it
        if ([GlobalRouter sharedManager].accountsNames == nil || [GlobalRouter sharedManager].accountsNames.count == 0) {
            return;
        }
        /*
        NSArray* foldersTemp = [[GlobalRouter sharedManager].accountsNames allKeysForObject:[GlobalRouter sharedManager].currentAccount];
        if (foldersTemp == nil || foldersTemp.count == 0) {
            return;
        }
        NSString* emailAddr = foldersTemp[0];
        */
        NSString* emailAddr = [DataStorage getEmailAddressFromCurrentAccount];
        if(!emailAddr)return;
        
        __weak __typeof__(self) weakSelf = self;
        //MCOIMAPSession* sess = [self checkSessionAndReconnectSyncForAddress:emailAddr];
        if (self.imapSessions.count == 0) {
            // Need to init again
            
        }
        
        for (SessionConnectorNew* session in self.imapSessions) {
            if([session isThisForAddress:emailAddr]){
                //[session cancellAllOps]; // Should we? Guess no...
                [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
                    __strong __typeof__(self) strongSelf = weakSelf;
                    if(!error){
                        [CommonProcs setSWLabelText:NSLocalizedString(@"Loading", nil)];
                        int nLoad = [GlobalRouter sharedManager].nMessagesToLoad;
                        if (nLoad == 0) {
                            nLoad = 10;
                        }
                        if(session){
                            [strongSelf loadLastNMessages:nLoad :btType forSession:session.imapSession];
                        }else{
                            NSLog(@"Skip reading messages as the session is nil");
                        }
                    }else{
#if DEBUG
                        NSLog(@"Error next for %@ %@", session.imapSession.username, error.localizedDescription);
#endif
                        [[[GlobalRouter sharedManager] getListRouter].manager dataReady:[[NSArray alloc] init] error:error.localizedDescription forSettings:[session getSettingsName]];
                        strongSelf->numberOfEmptied++;
                    }
                }];
            }
        }
    }else{
        // Need check sessions and reconnect if expired, after that load messages...
        [self checkSessionsAndReconnectSyncForBox:btType];
        
        if (self.imapSessions.count == 0) {
            [CommonProcs hideSmallWheel];
        }
    }
}

-(void)readNextShortMessagesForBox:(boxTypes)btType
{
    [GlobalRouter sharedManager].totalMessages = 0; // Since it's gonna add total messages to that value
    [self readShortMessagesForBox:btType next:YES];
    return;
}

+(NSString*)getEmailAddressFromCurrentAccount
{
    NSString* ret;
    NSArray* keys = [[GlobalRouter sharedManager].accountsNames allKeysForObject:[GlobalRouter sharedManager].currentAccount];
    if (keys.count == 0) {
        // Try looking for the key
        NSArray* allKeys = [[GlobalRouter sharedManager].accountsNames allKeys];
        for (NSString* kk in allKeys) {
            if ([kk isEqualToString:[GlobalRouter sharedManager].currentAccount]) {
                ret = kk;
                break;
            }
        }
    }else{
        ret = keys[0];
    }
    
    return ret;
}

-(void)readShortMessagesForBoxWithFilter:(boxTypes)btType filter:(NSString*)fromFilter
{
    if (connecting > 0) {
        // Connection in progress
        if(conSem != nil){
            [GlobalRouter sharedManager].connectionCancelled = YES;
            dispatch_semaphore_signal(conSem);
            conSem = nil;
        }
        [self closeAllSessionsSync:YES];
        connecting = 0;
    }
    
    //[GlobalRouter sharedManager].loadedMessages = 0; // Move it to list interactor
    [GlobalRouter sharedManager].totalMessages = 0;
    numberOfEmptied = 0;
    
    [GlobalRouter sharedManager].currentBox = btType;
    [[GlobalRouter sharedManager] getListRouter].manager.nAccountsToWait = 0;
    [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
    [CommonProcs setSWLabelText:NSLocalizedString(@"Connecting", nil)];
    /*
    for (SessionConnectorNew* sess in self.imapSessions) {
        //[sess.imapSession cancelAllOperations];
        [sess cancellAllOps];
    }
    */
    __weak __typeof__(self) weakSelf = self;
    if (btType == btUseName) {
        // No need to connect everything. Find out the address and load messages for it
        /*
        NSArray* keys = [[GlobalRouter sharedManager].accountsNames allKeysForObject:[GlobalRouter sharedManager].currentAccount];
        if (keys.count == 0) {
            // Try looking for the key
            return;
        }
        NSString* emailAddr = keys[0];*/
        
        NSString* emailAddr = [DataStorage getEmailAddressFromCurrentAccount];
        if(!emailAddr)return;
        
        //MCOIMAPSession* sess = [self checkSessionAndReconnectSyncForAddress:emailAddr];
        for (SessionConnectorNew* session in self.imapSessions) {
            if([session isThisForAddress:emailAddr]){
                //[session cancellAllOps];
                [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
                    __strong __typeof__(self) strongSelf = weakSelf;
                    if(!error){
                        [CommonProcs setSWLabelText:NSLocalizedString(@"Loading", nil)];
                        int nLoad = [GlobalRouter sharedManager].nMessagesToLoad;
                        if (nLoad == 0) {
                            nLoad = 10;
                        }
                        [strongSelf loadNMessagesWithFilter:nLoad forBox:btType filter:fromFilter forSession:session.imapSession];
                        //[self loadLastNMessages:10 :btType forSession:session.imapSession];
                    }else{
                        [[[GlobalRouter sharedManager] getListRouter].manager dataReady:[[NSArray alloc] init] error:error.localizedDescription forSettings:[session getSettingsName]];
                        strongSelf->numberOfEmptied++;
                    }
                }];
            }
        }
    }else{
        for (SessionConnectorNew* session in self.imapSessions) {
            [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
                __strong __typeof__(self) strongSelf = weakSelf;
                if(!error){
                    [CommonProcs setSWLabelText:NSLocalizedString(@"Loading", nil)];
                    int nLoad = [GlobalRouter sharedManager].nMessagesToLoad;
                    if (nLoad == 0) {
                        nLoad = 10;
                    }
                    [strongSelf loadNMessagesWithFilter:nLoad forBox:btType filter:fromFilter forSession:session.imapSession];
                }else{
                    [[[GlobalRouter sharedManager] getListRouter].manager dataReady:[[NSArray alloc] init] error:error.localizedDescription forSettings:[session getSettingsName]];
                    strongSelf->numberOfEmptied++;
                }
            }];
        }
        
        if (self.imapSessions.count == 0) {
            [CommonProcs hideSmallWheel];
        }
    }
}

-(void)readNextShortMessagesForBoxWithFilter:(boxTypes)btType filter:(NSString*)fromFilter
{
    
}

-(void)cancelCurrentFetch
{
    //dispatch_async(/*dispatch_get_main_queue()*/dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [currentFetchOperation cancel];
        //[self.imapSession cancelAllOperations];
        currentFetchOperation = nil;
    
    [[self.imapSession disconnectOperation] start:^(NSError * _Nullable error) {
    }];
    // delete the session from sessions and fire a new one?
    SettingsEntity* deletedSettings;
    for (int i=0; i<self.imapSessions.count; i++) {
        SessionConnectorNew* conn = self.imapSessions[i];
        if ([conn.imapSession.username isEqualToString: self.imapSession.username]) {
            deletedSettings = [conn getSettings];
            [self.imapSessions removeObject:conn];
            self.imapSession = nil;
            NSLog(@"Session Deleted for %@ (%@)", [conn getEmailAddress], conn.imapSession.description);
            //break;
        }
    }
    if (deletedSettings) {
        dispatch_async(/*dispatch_get_main_queue()*/dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            [self checkConnection:deletedSettings];
        });
    }
   // });
}

// Background attachment fetch
-(void)fetchFullMessageWithSession:(MCOIMAPSession*)session message:(ShortMessageEntity*)message boxName:(NSString*)boxName pin:(NSMutableString *)pin sessionConn:(SessionConnectorNew*)sessionConn
{
    self.imapSession = session;
    
    [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
    [CommonProcs setSWLabelText:NSLocalizedString(@"Loading attachments...", nil)];
    MCOIMAPFetchParsedContentOperation *operation = [session fetchParsedMessageOperationWithFolder:boxName uid:(uint)[message.messageID integerValue]];
    operation.shouldRunWhenCancelled = NO;
    currentFetchOperation = operation;
    [operation start:^(NSError * __nullable error, MCOMessageParser * parser)  {
      
        if(![[GlobalRouter sharedManager] isCancelled]){
            //NSLog(@"Parser-message %@-%@",parser.header.messageID, [GlobalRouter sharedManager].currentFetchingMessage.messageID);
            //if ([parser.header.messageID isEqualToString:[GlobalRouter sharedManager].currentFetchingMessage.messageID]) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                    [[[GlobalRouter sharedManager] getListRouter].manager fullParsedMessageReady:parser forShort:message error:error.localizedFailureReason pin:pin];
                });
                [GlobalRouter sharedManager].currentFetchingMessage = nil;
            //}else{
            //    NSLog(@"Messages does not match");
            //}
        }else{
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                [[[GlobalRouter sharedManager] getListRouter].manager fullParsedMessageReady:nil forShort:message error:NSLocalizedString(@"Cancelled",nil) pin:pin];
            });
        }
        [CommonProcs hideSmallWheel];
    }];
    
    __block BOOL alreadyCancelled = NO;
    //__unsafe_unretained typeof(operation) weakOp = operation;
    [operation setProgress:^(unsigned int current, unsigned int maximum) {
        //NSLog(@"progress content: %u/%u", current, maximum);
        
        if (![[GlobalRouter sharedManager] isCancelled]){
            if (![CommonProcs isSWPresent]) {
                [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
            }
            [CommonProcs setSWLabelText:[NSString stringWithFormat:@"Loaded %@/%@", [CommonProcs getByteSizeRep:current], [CommonProcs getByteSizeRep:maximum]]];
            
            //[[[GlobalRouter sharedManager] getListRouter].manager setProgress:current max:maximum];
        }else{
            //[weakOp cancel]; // ?? no need now, since I cancel all ops in session?
            if(!alreadyCancelled){
                NSLog(@"Cancelled everything");
                //
                //[session cancelAllOperations];
                //[sessionConn cancellAllOps];
                alreadyCancelled = YES;
                [self cancelCurrentFetch];
                
                /*
                [[session disconnectOperation] start:^(NSError * _Nullable error) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                        //[[[GlobalRouter sharedManager] getListRouter].manager fullParsedMessageReady:nil forShort:message error:NSLocalizedString(@"Cancelled",nil) pin:pin];
                    });
                }];*/
                
                //[weakOp cancel];
                
                /*dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                    [[[GlobalRouter sharedManager] getListRouter].manager fullParsedMessageReady:nil forShort:message error:NSLocalizedString(@"Cancelled",nil) pin:pin];
                });*/
                
                //[[GlobalRouter sharedManager] cancelQ];
            }
        }
    }];
}

-(void)doTheRequestForFullMessage:(SessionConnectorNew*)sessionConn message:(ShortMessageEntity*)message boxType:(boxTypes)btType pin:(NSMutableString *)pin
{
    __weak __typeof__(self) weakSelf = self;
    [sessionConn connectIMAPSessionWithCompletionHandler:^(NSError *error) {
        __strong __typeof__(self) strongSelf = weakSelf;
        void (^block)(MCOIMAPSession* session) = ^void(MCOIMAPSession* session){
            __strong __typeof__(self) strongSelf = weakSelf;
            
            MCOIMAPFetchMessagesOperation* opr = [session fetchMessagesOperationWithFolder:strongSelf->currentBoxName requestKind:MCOIMAPMessagesRequestKindStructure | MCOIMAPMessagesRequestKindHeaders uids:[MCOIndexSet indexSetWithIndex:[message.messageID intValue]]];
            //opr.urgent = YES;
            [opr start:^(NSError * _Nullable error, NSArray<MCOIMAPMessage *> * _Nullable messages, MCOIndexSet * _Nullable vanishedMessages) {
                if (messages.count > 0) {
                    MCOIMAPMessage* msg = messages[0];
                    NSArray* parts = [msg requiredPartsForRendering];
                    MCOIMAPPart* part = parts[0];
                    [GlobalRouter sharedManager].currentFetchingMessage = message;
                    MCOIMAPFetchContentOperation* fop = [session fetchMessageAttachmentOperationWithFolder:strongSelf->currentBoxName uid:[message.messageID intValue] partID:part.partID encoding:part.encoding];
                    //fop.urgent = YES;
                    [fop start:^(NSError * _Nullable error, NSData * _Nullable data) {
                        MCOMessageParser * parser = [MCOMessageParser messageParserWithData:data];
                        NSArray* atts = msg.attachments;
                        NSString* htmlRender = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        NSLog(@"Message has attachments %lu", (unsigned long)atts.count);
                        //if(![GlobalRouter sharedManager].isCancelled){
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                                [[[GlobalRouter sharedManager] getListRouter].manager fullParsedMessageReady:parser forShort:message error:error.localizedFailureReason pin:pin preAttachments:atts html:htmlRender];
                        });
                        
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                            [self fetchFullMessageWithSession:session message:message boxName:strongSelf->currentBoxName pin:pin sessionConn:sessionConn];
                        });
                        
                    }];
                    NSLog(@"Fetched array");
                }
            }];
            
            /* *******
            MCOIMAPFetchParsedContentOperation *operation = [session fetchParsedMessageOperationWithFolder:strongSelf->currentBoxName uid:(uint)[message.messageID integerValue]];
            
            [operation start:^(NSError * __nullable error, MCOMessageParser * parser)  {
              
                    if(![GlobalRouter sharedManager].isCancelled){ dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                        [[[GlobalRouter sharedManager] getListRouter].manager fullParsedMessageReady:parser forShort:message error:error.localizedFailureReason pin:pin];
                    });
                }
            }];
            
            __block BOOL alreadyCancelled = NO;
            //__unsafe_unretained typeof(operation) weakOp = operation;
            [operation setProgress:^(unsigned int current, unsigned int maximum) {
                //NSLog(@"progress content: %u/%u", current, maximum);
                
                if (![GlobalRouter sharedManager].isCancelled){
                    
                    [[[GlobalRouter sharedManager] getListRouter].manager setProgress:current max:maximum];
                }else{
                    //[weakOp cancel]; // ?? no need now, since I cancel all ops in session?
                    if(!alreadyCancelled){
                    [sessionConn cancellAllOps];
                        alreadyCancelled = YES;    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                        [[[GlobalRouter sharedManager] getListRouter].manager fullParsedMessageReady:nil forShort:message error:NSLocalizedString(@"Cancelled",nil) pin:pin];
                    });
                    }
                }
            }];
             */
        };
        
        [strongSelf getNameAndDoBlockWithSession:btType block:block session:sessionConn.imapSession];
    }];
}

-(void)readFullMessageFor:(ShortMessageEntity*)message boxType:(boxTypes)btType pin:(NSMutableString *)pin
{
    [[[GlobalRouter sharedManager] getListRouter].manager setProgress:0 max:10];
    
    NSString* addrToCheck = message.toAddress;
    //MCOIMAPSession* sess = [self checkSessionAndReconnectSyncForAddress:addrToCheck];
    
    BOOL found = NO;
    SessionConnectorNew* connector;
    for (SessionConnectorNew* sessionConn in self.imapSessions) {
        if([sessionConn isThisForAddress:addrToCheck]){
            found = YES;
            connector = sessionConn;
            break;
        }
    }
    if(!found){
        // Connect a new connector
        SettingsEntity* sett = [[GlobalRouter sharedManager] getSettingForAddress:message.toAddress];
        if(sett){
            
            [self checkConnection:sett];
            //connector = [self.imapSessions lastObject];
            for (SessionConnectorNew* sessionConn in self.imapSessions) {
                if([sessionConn isThisForAddress:addrToCheck]){
                    connector = sessionConn;
                    break;
                }
            }
            NSLog(@"Creating a new connector for %@ (%@)", sett.userName,connector.imapSession.description);
        }
    }
    [self doTheRequestForFullMessage:connector message:message boxType:btType pin:pin];
}

-(NSData*)buildRFCMessage:(FullMessageEntity*)message
{
    SettingsEntity* setts = [[GlobalRouter sharedManager] getSettingForAddress:message.fromAddress];
    MCOMessageBuilder * builder = [[MCOMessageBuilder alloc] init];
    if (setts) {
        [[builder header] setFrom:[MCOAddress addressWithDisplayName:setts.userNick mailbox:setts.userName]];
    }else{
        [[builder header] setFrom:[MCOAddress addressWithDisplayName:message.fromName mailbox:message.fromAddress]];
    }
    
    NSMutableArray *to = [[NSMutableArray alloc] init];
    
    MCOAddress *newAddress = [MCOAddress addressWithMailbox:message.toAddress];
    if(newAddress)[to addObject:newAddress];
    
    [[builder header] setTo:to];
    if(![message.expireOTCon isEqualToString:@""]){
        [[builder header] setExtraHeaderValue:message.expireOTCon forName:@"Comments"];
    }
    
    if (message.flags & mfImportant) {
        [[builder header] setExtraHeaderValue:@"1" forName:@"X-Priority"];
    }
    
    if (!(message.readReceiptTo == nil || [message.readReceiptTo isEqualToString:@""])) {
        [[builder header] setExtraHeaderValue:message.readReceiptTo forName:@"Disposition-Notification-To"];
    }
    
    [[builder header] setSubject:message.subject];
    [builder setHTMLBody:message.messageBody];
    
    for (NSString* att in message.attachments) {
        [builder addAttachment:[MCOAttachment attachmentWithContentsOfFile:att]];
    }
    
    [[builder header] setDate:message.date];
    [[builder header] setReceivedDate:message.date];
    
    NSData* rfc822Data = [builder data];
    
    return rfc822Data;
    
}

-(void)sendMessageWithSession:(MCOSMTPSession*)smtpSession message:(FullMessageEntity*)message
{
    SettingsEntity* setts = [[GlobalRouter sharedManager] getSettingForAddress:message.fromAddress];// .settingsNames objectForKey:message.fromAddress];
    MCOMessageBuilder * builder = [[MCOMessageBuilder alloc] init];
    [[builder header] setFrom:[MCOAddress addressWithDisplayName:setts.userNick mailbox:setts.userName]];
    NSMutableArray *to = [[NSMutableArray alloc] init];
    //for(NSString *toAddress in RECIPIENTS) {
    MCOAddress *newAddress = [MCOAddress addressWithMailbox:message.toAddress];
    if(newAddress)[to addObject:newAddress];
    // }
    [[builder header] setTo:to];
    if(!([message.expireOTCon isEqualToString:@""] || message.expireOTCon == nil)){
        [[builder header] setExtraHeaderValue:message.expireOTCon forName:@"Comments"];
        [[builder header] setExtraHeaderValue:@"1" forName:@"Delay"];
    }
    
    if (message.flags & mfImportant) {
        [[builder header] setExtraHeaderValue:@"1" forName:@"X-Priority"];
    }
    
    if (!(message.readReceiptTo == nil || [message.readReceiptTo isEqualToString:@""])) {
        [[builder header] setExtraHeaderValue:message.readReceiptTo forName:@"Disposition-Notification-To"];
    }
    
    [[builder header] setSubject:message.subject];
    
    [builder setHTMLBody:message.messageBody];
    
    for (NSString* att in message.attachments) {
        [builder addAttachment:[MCOAttachment attachmentWithContentsOfFile:att]];
    }
    
    if (message.doNotCheckServerCertificate) {
        smtpSession.checkCertificateEnabled = NO;
    }else{
        smtpSession.checkCertificateEnabled = YES;
    }
    __block NSData * rfc822Data = [builder data];
    
    MCOSMTPSendOperation *sendOperation = [smtpSession sendOperationWithData:rfc822Data];
    [sendOperation start:^(NSError *error) {
        NSString* errorDesc = nil;
        if(error){
            errorDesc = [error.userInfo valueForKey:MCOSMTPResponseKey];
            if (errorDesc == nil) {
                errorDesc = error.localizedDescription;
            }
        }
        [[[GlobalRouter sharedManager] getListRouter].manager messageSent:message error:errorDesc];
        // Close SMTP session
        rfc822Data = nil;
    }];
}

-(void)sendMessage:(FullMessageEntity *)message
{
    //[self checkSessionForAddress:message.fromAddress]; // checkSessionForBox:btEmpty];
    __weak __typeof__(self) weakSelf = self;
    for (SessionConnectorNew* session in self.imapSessions) {
        if ([session isThisForAddress:message.fromAddress]) {
            [session connectSMTPSessionWithCompletionHandler:^(NSError *error) {
                __strong __typeof__(self) strongSelf = weakSelf;
                [strongSelf sendMessageWithSession:session.smtpSession message:message];
            }];
            break;
        }
    }
}

-(float)getJPEGCompression
{
    //float cr = settings.compression;
    float cr = [GlobalRouter sharedManager].compression;
    if (cr == 0) {
        cr = 0.5;
    }
    return cr;
}

-(void)deleteMessage:(ShortMessageEntity *)message
{
    return [self deleteMessage:message reencrypting:NO];
}

// If re-encrypting do not update modsec because it will mess up the handling block of appending a message - updating take some time to complete and at that time the block is rewritten and the appending block is executed twice while modsec block is dropped. Need to fix that sometime.
-(void)deleteMessage:(ShortMessageEntity *)message reencrypting:(BOOL)reencrypting
{
    int deleted = MCOMessageFlagDeleted;
    
    //MCOIMAPSession* sessTmp = [self checkSessionAndReconnectSyncForAddress:message.toAddress];
    __weak __typeof__(self) weakSelf = self;
    for (SessionConnectorNew* session in self.imapSessions) {
        if([session isThisForAddress:message.toAddress]){
            // Create a semaphore to enable others to wait until done, since if the new operation
            // starts before the current is competed, the new completion block will be executed
            session.working = dispatch_semaphore_create(0);
            
            [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
                if(error){
                    NSLog(@"Connection error: %@",error.localizedDescription);
                    //[CommonProcs hideSmallWheel];
                    return;
                }
                __strong __typeof__(self) strongSelf = weakSelf;
                void (^block)(MCOIMAPSession* sessionIMAP) = ^void(MCOIMAPSession* sessionIMAP){
                    __strong __typeof__(self) strongSelf = weakSelf;
                    MCOIMAPOperation *op = [sessionIMAP storeFlagsOperationWithFolder:strongSelf->currentBoxName
                                                                                 uids:[MCOIndexSet indexSetWithIndex:[message.messageID integerValue]]
                                                                                 kind:MCOIMAPStoreFlagsRequestKindSet
                                                                                flags:deleted];
                    [op start:^(NSError * error) {
                        __strong __typeof__(self) strongSelf = weakSelf;
                        if(!error) {
                            //NSLog(@"Updated flags!");
                        } else {
                            NSLog(@"Error updating deleted flags:%@", error);
                        }
                        MCOIMAPOperation *deleteOp = [sessionIMAP expungeOperation:strongSelf->currentBoxName];
                        [deleteOp start:^(NSError *error) {
                            if(error) {
                                //NSLog(@"Error expunging folder:%@", error);
                            } else {
                                //NSLog(@"Successfully expunged folder");
                                // Do not update if re-encrypting a message
                                if(!reencrypting){
                                    // Need to update the numbers without reconnection here
                                    [self updateStoredHighestModSecForSession:session user:[session getEmailAddress]];
                                    //[self updateStoredHighestModSecFor:[session getEmailAddress]];
                                }
                            }
                            [CommonProcs hideSmallWheel];
                            if(session && session.working){
                                dispatch_semaphore_signal(session.working);
                                session.working = nil;
                            }
                        }];
                    }];
                };
                
                [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
                [CommonProcs setSWLabelText:NSLocalizedString(@"Deleting", nil)];
                [strongSelf getNameAndDoBlockWithSession:[GlobalRouter sharedManager].currentBox block:block session:session.imapSession];
            }];
            break;
        }
    }
}

-(void)deleteMessages:(NSArray*/*ShortMessageEntity */)messages
{
    int deleted = MCOMessageFlagDeleted;
    NSMutableDictionary* messagesBySession = [[NSMutableDictionary alloc] initWithCapacity: self.imapSessions.count];
    
    __weak __typeof__(self) weakSelf = self;
    for (SessionConnectorNew* session in self.imapSessions){
        NSMutableArray* items = [[NSMutableArray alloc] init];
        for(ShortMessageEntity* item in messages){
            if([session isThisForAddress:item.toAddress]){
                [items addObject:item];
            }
        }
        [messagesBySession setObject:items forKey:[session getSettingsName]];
    }
    for (SessionConnectorNew* session in self.imapSessions){
        NSMutableArray* items = [messagesBySession objectForKey:[session getSettingsName]];
        if (items.count == 0) {
            continue;
        }
        MCOIndexSet* uids = [[MCOIndexSet alloc] init];
        for (ShortMessageEntity* item in items) {
            [uids addIndex:[item.messageID integerValue]];
        }
        [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
            if(error){
                NSLog(@"Connection error: %@",error.localizedDescription);
                //[CommonProcs hideSmallWheel];
                return;
            }
            __strong __typeof__(self) strongSelf = weakSelf;
            void (^block)(MCOIMAPSession* sessionIMAP) = ^void(MCOIMAPSession* sessionIMAP){
                __strong __typeof__(self) strongSelf = weakSelf;
                
                MCOIMAPOperation *op = [sessionIMAP storeFlagsOperationWithFolder:strongSelf->currentBoxName
                                                                         uids:uids
                                                                         kind:MCOIMAPStoreFlagsRequestKindSet
                                                                        flags:deleted];
                [op start:^(NSError * error) {
                    __strong __typeof__(self) strongSelf = weakSelf;
                    if(!error) {
                        //NSLog(@"Updated flags!");
                    } else {
                        NSLog(@"Error updating deleted flags:%@", error);
                    }
                    MCOIMAPOperation *deleteOp = [sessionIMAP expungeOperation:strongSelf->currentBoxName];
                    [deleteOp start:^(NSError *error) {
                        if(error) {
                            //NSLog(@"Error expunging folder:%@", error);
                        } else {
                            //NSLog(@"Successfully expunged folder");
                            [CommonProcs showMessage:[NSString stringWithFormat: NSLocalizedString(@"Deleted %i messages", nil), messages.count] title:@""];
                            [self updateStoredHighestModSecFor:[session getEmailAddress]];
                        }
                        [CommonProcs hideSmallWheel];
                    }];
                }];
            };
            
            [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
            [CommonProcs setSWLabelText:NSLocalizedString(@"Deleting", nil)];
            [strongSelf getNameAndDoBlockWithSession:[GlobalRouter sharedManager].currentBox block:block session:session.imapSession];
        }];
    }
}

-(void)deleteAllMessagesFromFolder:(NSString*)folderPath
{
    //NSLog(@"Folder path to clear is %@",folderPath);
    SessionConnectorNew* sss;
    NSArray* keys = [[GlobalRouter sharedManager].accountsNames allKeysForObject:[GlobalRouter sharedManager].currentAccount];
    if (keys.count == 1) {
        for (SessionConnectorNew* ss in self.imapSessions) {
            if ([ss isThisForAddress:keys[0]]) {
                sss = ss;
                break;
            }
        }
        if (sss) {
            // Need to fetch UUIDs first and then delete the messages...
            MCOIMAPSearchOperation* opSearch = [sss.imapSession searchExpressionOperationWithFolder:folderPath expression:[MCOIMAPSearchExpression searchAll]];
            [opSearch start:^(NSError* error, MCOIndexSet* searchResult) {
                if(!error){
                    int deleted = MCOMessageFlagDeleted;
                    MCOIMAPOperation *op = [sss.imapSession storeFlagsOperationWithFolder:folderPath
                                                uids:searchResult
                                                kind:MCOIMAPStoreFlagsRequestKindSet
                                                flags:deleted];
                    [op start:^(NSError * error) {
                        //__strong __typeof__(self) strongSelf = weakSelf;
                        if(!error) {
                            //NSLog(@"Updated flags!");
                            MCOIMAPOperation *deleteOp = [sss.imapSession expungeOperation:folderPath];
                            [deleteOp start:^(NSError *error) {
                                if(error) {
                                    NSLog(@"Error expunging folder:%@", error);
                                    [CommonProcs showMessage:error.localizedDescription title:NSLocalizedString(@"Error", nil)];
                                } else {
                                    NSLog(@"Successfully expunged folder - %i", searchResult.count);
                                    [CommonProcs showMessage:[NSString stringWithFormat: NSLocalizedString(@"Deleted %i messages", nil), searchResult.count] title:@""];
                                    // Clear the list
                                    // Oops, done it before, in case of an error need to update the list
                                }
                                [CommonProcs hideSmallWheel];
                            }];
                        } else {
                            NSLog(@"Error updating deleted flags:%@", error);
                            [CommonProcs hideSmallWheel];
                            [CommonProcs showMessage:error.localizedDescription title:NSLocalizedString(@"Error", nil)];
                        }
                    }];
                }else{
                    NSLog(@"Search error %@",error.localizedDescription);
                }
            }];
        }
    }else{
        NSLog(@"Cannot delete. Error.");
        [CommonProcs showMessage:NSLocalizedString(@"Session error emptying folder",nil) title:NSLocalizedString(@"Error", nil)];
    }
    
    
}

-(void)setFlagForMessages:(NSArray*/*ShortMessageEntity */)messages flag:(int)flag
{
    //int deleted = MCOMessageFlagDeleted;
    NSMutableDictionary* messagesBySession = [[NSMutableDictionary alloc] initWithCapacity: self.imapSessions.count];
    
    __weak __typeof__(self) weakSelf = self;
    for (SessionConnectorNew* session in self.imapSessions){
        NSMutableArray* items = [[NSMutableArray alloc] init];
        for(ShortMessageEntity* item in messages){
            if([session isThisForAddress:item.toAddress]){
                [items addObject:item];
            }
        }
        [messagesBySession setObject:items forKey:[session getSettingsName]];
    }
    for (SessionConnectorNew* session in self.imapSessions){
        NSMutableArray* items = [messagesBySession objectForKey:[session getSettingsName]];
        if (items.count == 0) {
            continue;
        }
        MCOIndexSet* uids = [[MCOIndexSet alloc] init];
        for (ShortMessageEntity* item in items) {
            [uids addIndex:[item.messageID integerValue]];
        }
        [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
            __strong __typeof__(self) strongSelf = weakSelf;
            void (^block)(MCOIMAPSession* sessionIMAP) = ^void(MCOIMAPSession* sessionIMAP){
                __strong __typeof__(self) strongSelf = weakSelf;
                
                // Adds flag keeping the others. Seems that it cannot set the unseen flag
                MCOIMAPOperation *op = [sessionIMAP storeFlagsOperationWithFolder:strongSelf->currentBoxName
                                                                         uids:uids
                                                                         kind:flag==(!MCOMessageFlagSeen)?MCOIMAPStoreFlagsRequestKindRemove:MCOIMAPStoreFlagsRequestKindAdd
                                                                        flags:flag==(!MCOMessageFlagSeen)?!flag:flag];
                [op start:^(NSError * error) {
                    if(!error) {
                        //NSLog(@"Updated flags!");
                        [self updateStoredHighestModSecFor:[session getEmailAddress]];
                    } else {
                        NSLog(@"Error updating flags:%@", error);
                    }
                    [CommonProcs hideSmallWheel];
                }];
            };
            
            [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
            [CommonProcs setSWLabelText:NSLocalizedString(@"Setting...", nil)];
            [strongSelf getNameAndDoBlockWithSession:[GlobalRouter sharedManager].currentBox block:block session:session.imapSession];
        }];
    }
}

-(void)toggleStarForMessage:(ShortMessageEntity *)message
{
    //MCOIMAPSession* sessTmp = [self checkSessionAndReconnectSyncForAddress:message.toAddress];
    __weak __typeof__(self) weakSelf = self;
    for (SessionConnectorNew* sessionC in self.imapSessions) {
        if([sessionC isThisForAddress:message.toAddress]){
            [sessionC connectIMAPSessionWithCompletionHandler:^(NSError *error) {
                __strong __typeof__(self) strongSelf = weakSelf;
                void (^block)(MCOIMAPSession* session) = ^void(MCOIMAPSession* session){
                    __strong __typeof__(self) strongSelf = weakSelf;
                    MCOIMAPFetchMessagesOperation* readFlags = [session fetchMessagesOperationWithFolder:strongSelf->currentBoxName requestKind:MCOIMAPMessagesRequestKindFlags uids:[MCOIndexSet indexSetWithIndex:[message.messageID integerValue]]];
                    [readFlags start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
                        __strong __typeof__(self) strongSelf = weakSelf;
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
                            
                            MCOIMAPOperation *op = [session  storeFlagsOperationWithFolder:strongSelf->currentBoxName uids:[MCOIndexSet indexSetWithIndex:[message.messageID integerValue]] kind:flagOp flags:flags];
                            [op start:^(NSError * error) {
                                if(!error) {
                                    //NSLog(@"Updated flags!");
                                    [self updateStoredHighestModSecFor:[sessionC getEmailAddress]];
                                } else {
                                    //NSLog(@"Error updating flags:%@", error);
                                }
                                [CommonProcs hideSmallWheel];
                            }];
                            //[self updateStoredHighestModSecFor:[sessionC getEmailAddress]];
                        }
                    }];
                };
                
                [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
                [CommonProcs setSWLabelText:NSLocalizedString(@"Setting star", nil)];
                [strongSelf getNameAndDoBlockWithSession:[GlobalRouter sharedManager].currentBox block:block session:sessionC.imapSession];
            }];
        }
    }
}

-(void)setReadFlagForMessage:(ShortMessageEntity *)message
{
    //MCOIMAPSession* sessTmp = [self checkSessionAndReconnectSyncForAddress:message.toAddress];
    __weak __typeof__(self) weakSelf = self;
    __block BOOL removingUnsees = NO;
    for (SessionConnectorNew* sessionC in self.imapSessions) {
        if([sessionC isThisForAddress:message.toAddress]){
            [sessionC connectIMAPSessionWithCompletionHandler:^(NSError *error) {
                __strong __typeof__(self) strongSelf = weakSelf;
                void (^block)(MCOIMAPSession* session) = ^void(MCOIMAPSession* session){
                    __strong __typeof__(self) strongSelf = weakSelf;
                    MCOIMAPFetchMessagesOperation* readFlags = [session fetchMessagesOperationWithFolder:strongSelf->currentBoxName requestKind:MCOIMAPMessagesRequestKindFlags uids:[MCOIndexSet indexSetWithIndex:[message.messageID integerValue]]];
                    [readFlags start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
                        __strong __typeof__(self) strongSelf = weakSelf;
                        if (!error) {
                            if(messages.count > 0){
                                MCOMessageFlag flags = [(MCOIMAPMessage*)[messages objectAtIndex:0] flags];
                                flags ^= MCOMessageFlagSeen;
                                removingUnsees = flags & MCOMessageFlagSeen;
                                MCOIMAPOperation *op = [session  storeFlagsOperationWithFolder:strongSelf->currentBoxName uids:[MCOIndexSet indexSetWithIndex:[message.messageID integerValue]] kind:MCOIMAPStoreFlagsRequestKindSet flags:flags];
                                [op start:^(NSError * error) {
                                    if(!error) {
                                        //NSLog(@"Updated flags!");
                                        NSString* settName = [sessionC getSettingsName];
                                        if(settName){
                                            NSDictionary* tmp = [[GlobalRouter sharedManager].otherFolders valueForKey:settName];
                                            if(tmp){
                                                FolderInfo* fi = [tmp valueForKey:[strongSelf->currentBoxesName valueForKey:[sessionC getEmailAddress]]];
                                                if(fi)
                                                    fi.unseenCount += removingUnsees?-1:1;
                                            }
                                        }
                                        [self updateStoredHighestModSecFor:[sessionC getEmailAddress]];
                                    } else {
                                        //NSLog(@"Error updating flags:%@", error);
                                    }
                                    [CommonProcs hideSmallWheel];
                                    [sessionC disconnectSession];
                                }];
                            }
                        }
                    }];
                };
                
                [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
                [CommonProcs setSWLabelText:NSLocalizedString(@"Toggling", nil)];
                [strongSelf getNameAndDoBlockWithSession:[GlobalRouter sharedManager].currentBox block:block session:sessionC.imapSession];
            }];
        }
    }
}

-(void)setAnsweredFlagForMessage:(ShortMessageEntity *)message
{
    
    __weak __typeof__(self) weakSelf = self;
    for (SessionConnectorNew* session in self.imapSessions) {
        if([session isThisForAddress:message.toAddress]){
            [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
                __strong __typeof__(self) strongSelf = weakSelf;
                void (^block)(MCOIMAPSession* sessionIMAP) = ^void(MCOIMAPSession* sessionIMAP){
                    __strong __typeof__(self) strongSelf = weakSelf;
                    
                    // Adds flag keeping the others. Seems that it cannot set the unseen flag
                    MCOIMAPOperation *op = [sessionIMAP storeFlagsOperationWithFolder:strongSelf->currentBoxName
                                                                             uids:[MCOIndexSet indexSetWithIndex:[message.messageID integerValue]]
                                                                             kind:MCOIMAPStoreFlagsRequestKindAdd
                                                                            flags:MCOMessageFlagAnswered];
                    [op start:^(NSError * error) {
                        if(!error) {
                            //NSLog(@"Updated flags!");
                            [self updateStoredHighestModSecFor:[session getEmailAddress]];
                        } else {
                            NSLog(@"Error updating answered flag:%@", error);
                        }
                        [CommonProcs hideSmallWheel];
                    }];
                };
                
                [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
                [CommonProcs setSWLabelText:NSLocalizedString(@"Setting...", nil)];
                [strongSelf getNameAndDoBlockWithSession:[GlobalRouter sharedManager].currentBox block:block session:session.imapSession];
            }];
        }
    }
    
    /*
     //MCOIMAPSession* sessTmp = [self checkSessionAndReconnectSyncForAddress:message.toAddress];
     __weak __typeof__(self) weakSelf = self;
     for (SessionConnectorNew* session in self.imapSessions) {
     if([session isThisForAddress:message.toAddress]){
     [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
     __strong __typeof__(self) strongSelf = weakSelf;
     void (^block)(MCOIMAPSession* session) = ^void(MCOIMAPSession* session){
     __strong __typeof__(self) strongSelf = weakSelf;
     MCOIMAPFetchMessagesOperation* readFlags = [session fetchMessagesOperationWithFolder:strongSelf->currentBoxName requestKind:MCOIMAPMessagesRequestKindFlags uids:[MCOIndexSet indexSetWithIndex:[message.messageID integerValue]]];
     [readFlags start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
     __strong __typeof__(self) strongSelf = weakSelf;
     if (!error) {
     if(messages.count > 0){
     MCOMessageFlag flags = [(MCOIMAPMessage*)[messages objectAtIndex:0] flags];
     flags ^= MCOMessageFlagAnswered;
     
     MCOIMAPOperation *op = [session  storeFlagsOperationWithFolder:strongSelf->currentBoxName uids:[MCOIndexSet indexSetWithIndex:[message.messageID integerValue]] kind:MCOIMAPStoreFlagsRequestKindSet flags:flags];
     [op start:^(NSError * error) {
     if(!error) {
     //NSLog(@"Updated flags!");
     } else {
     //NSLog(@"Error updating flags:%@", error);
     }
     [CommonProcs hideSmallWheel];
     }];
     }
     }
     }];
     };
     
     [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
     [CommonProcs setSWLabelText:NSLocalizedString(@"Toggling", nil)];
     [strongSelf getNameAndDoBlockWithSession:[GlobalRouter sharedManager].currentBox block:block session:session.imapSession];
     }];
     }
     }
     */
}

// There's a problem here - we loose message flags while setting custom flags. Need to read flags first!
-(void)setCustomFlagsForMessage:(ShortMessageEntity*)message flags:(NSArray*)flags
{
    __weak __typeof__(self) weakSelf = self;
    for (SessionConnectorNew* session in self.imapSessions) {
        if([session isThisForAddress:message.toAddress]){
            [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
                __strong __typeof__(self) strongSelf = weakSelf;
                void (^block)(MCOIMAPSession* session) = ^void(MCOIMAPSession* session){
                    __strong __typeof__(self) strongSelf = weakSelf;
                    
                    MCOIMAPOperation *op = [session storeFlagsOperationWithFolder:strongSelf->currentBoxName
                                uids:[MCOIndexSet indexSetWithIndex:[message.messageID integerValue]]
                                kind:MCOIMAPStoreFlagsRequestKindAdd
                                flags:MCOMessageFlagNone
                                customFlags:flags];
                    [op start:^(NSError * error) {
                        if(!error) {
                            //NSLog(@"Updated flags!");
                        } else {
                            NSLog(@"Error updating custom flags: %@", error);
                        }
                        [CommonProcs hideSmallWheel];
                    }];
                };
                
                [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
                [CommonProcs setSWLabelText:NSLocalizedString(@"Setting...", nil)];
                [strongSelf getNameAndDoBlockWithSession:[GlobalRouter sharedManager].currentBox block:block session:session.imapSession];
            }];
        }
    }
}

-(void)removeCustomFlagsForMessage:(ShortMessageEntity*)message flags:(NSArray*)flags
{
    __weak __typeof__(self) weakSelf = self;
    for (SessionConnectorNew* session in self.imapSessions) {
        if([session isThisForAddress:message.toAddress]){
            [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
                __strong __typeof__(self) strongSelf = weakSelf;
                void (^block)(MCOIMAPSession* session) = ^void(MCOIMAPSession* session){
                    __strong __typeof__(self) strongSelf = weakSelf;
                    
                    MCOIMAPOperation *op = [session storeFlagsOperationWithFolder:strongSelf->currentBoxName
                                                                             uids:[MCOIndexSet indexSetWithIndex:[message.messageID integerValue]]
                                                                             kind:MCOIMAPStoreFlagsRequestKindRemove
                                                                            flags:MCOMessageFlagNone
                                                                      customFlags:flags];
                    [op start:^(NSError * error) {
                        if(!error) {
                            //NSLog(@"Updated flags!");
                        } else {
                            NSLog(@"Error removing custom flags: %@", error);
                        }
                        [CommonProcs hideSmallWheel];
                    }];
                };
                
                [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
                [CommonProcs setSWLabelText:NSLocalizedString(@"Setting...", nil)];
                [strongSelf getNameAndDoBlockWithSession:[GlobalRouter sharedManager].currentBox block:block session:session.imapSession];
            }];
        }
    }
}

// Gets new messages from inbox only to make it faster, got only about 30 secs to complete
-(int)bgGetNewMessageCount
{
    // 1. Connect sessions
    // 2. Get new message count
    
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    /*NSArray**/[GlobalRouter sharedManager].allSettings = [dataMan getSettings:[GlobalRouter sharedManager].pin];
    if ([GlobalRouter sharedManager].allSettings.count < 2) {
        // No account settings yet
        return 0;
    }
    
    //self.imapSessions = [[NSMutableArray alloc] init];
    //[GlobalRouter sharedManager].accountsNames = [[NSMutableDictionary alloc] init];
    __block int totalUnseen = 0;
    __block int totalRecent = 0;
    __block BOOL indicateRecent = NO;
    dispatch_group_t checkGroup = dispatch_group_create();
    __block dispatch_semaphore_t checkSem = dispatch_semaphore_create(0);
    NSMutableArray* chSessions = [[NSMutableArray alloc] init];
    //__block int i=0;
    __block NSMutableString* alertMessage = [[NSMutableString alloc] init];
    for (SettingsEntity* setting in [GlobalRouter sharedManager].allSettings) {
        if ([setting.userName isEqualToString:GENERAL_SETTINGS]) {
            continue;
        }
        
        if ([setting.imapServer isEqualToString:@""]) {
            continue;
        }
        
        dispatch_group_enter(checkGroup);
        SessionConnectorNew* tmp = [[SessionConnectorNew alloc] initWithSettings:setting];
        [chSessions addObject:tmp];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{ //dispatch_get_main_queue(), ^{
            [tmp connectIMAPSessionWithCompletionHandler:^(NSError* error){
                if(!error){
                    //[self.imapSessions addObject:tmp];
                    
                    MCOIMAPFolderStatusOperation *inboxFolderInfo = [tmp.imapSession folderStatusOperation:@"INBOX"];
                    [inboxFolderInfo start:^(NSError *error, MCOIMAPFolderStatus *info)
                     {
                         int unseenMessages = [info unseenCount];
                         totalUnseen += unseenMessages;
                         totalRecent += [info recentCount];
                         //NSLog(@"BG Last message number for %@ is %llu",setting.userName, info.highestModSeqValue);
                         NSString* addrHash = [Encryptor getUUIDHashForString:setting.userName];
                         NSString* addrHash2 = [Encryptor getUUIDHashForString:addrHash];
                         if(addrHash && addrHash2 /* must also check if info.uidValidity is unchanged */){
                             // Keychain
                             NSString* lastMSStr = [CommonProcs getStringFromKeychain:addrHash service:@"SMBGS"];
                             NSString* lastValStr = [CommonProcs getStringFromKeychain:addrHash2 service:@"SMBGS"];
                             // Might be not found...
                             if (!lastMSStr) {
                                 lastMSStr = @"0";
                             }
                             if (!lastValStr) {
                                 lastValStr = @"0";
                             }
                             //if (lastMSStr && lastValStr) {
                             uint64_t lastMS = [lastMSStr longLongValue];
                             uint32_t lastVal = (uint32_t)[lastValStr integerValue];
                             if(info.highestModSeqValue > 0 && info.uidValidity > 0){
#if DEBUG
                                 NSString* msg = [NSString stringWithFormat:@"%@: %llu/%llu, val. %u/%d\n",setting.userName, info.highestModSeqValue, lastMS, info.uidValidity, lastVal];
                                 if(info.highestModSeqValue != lastMS || info.uidValidity != lastVal){
                                     [alertMessage appendString:msg];
                                 }
                                 NSLog(@"%@", msg);
#endif
                                 if ([GlobalRouter sharedManager].doNotHideAccountInNotification) {
                                     NSString* msg = [NSString stringWithFormat:NSLocalizedString(@"%@ changed\n",nil), setting.userName];
                                     if(info.highestModSeqValue != lastMS || info.uidValidity != lastVal){
                                         [alertMessage appendString:msg];
                                     }
                                 }
                                 if(info.highestModSeqValue > 0){
                                     [CommonProcs saveToKeychainAlways:[NSString stringWithFormat:@"%llu", info.highestModSeqValue] account:addrHash service:@"SMBGS"];
                                     [CommonProcs saveToKeychainAlways:[NSString stringWithFormat:@"%u", info.uidValidity] account:addrHash2 service:@"SMBGS"];
                                 }
                                 if ((lastVal !=0 && lastVal == info.uidValidity) && ( lastMS != 0 && info.highestModSeqValue > lastMS)) {
                                     indicateRecent = YES;
                                 }
                             }else{
                                 NSLog(@"No vals for %@",setting.userName);
                                 
                             }
                             /*
                             NSInteger lastMS = [(NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:addrHash] integerValue];
                             NSInteger lastValidity = [(NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:addrHash2] integerValue];
                             [[NSUserDefaults standardUserDefaults] setInteger:(long)info.highestModSeqValue forKey:addrHash];
                             [[NSUserDefaults standardUserDefaults] setInteger:(long)info.uidValidity forKey:addrHash2];
                             if (lastValidity == info.uidValidity && ( lastMS != 0 && info.highestModSeqValue > lastMS)) {
                                 indicateRecent = YES;
                             }
                              */
                         }
                         // Here is a wierd thing. Sometimes I got a error saving NSUserDefaults that looked
                         // like a system bug according to StackOverflow. Just in case I added a delay to
                         // finish writing and the error seems to disappear... not really. Seems to be a BG
                         // access related, somehow locks the user defaults from accessing when the phone
                         // is off for a while.
                         //
                         // Keychain??? YES!
                         //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((i++)*0.2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                             //dispatch_group_leave(checkGroup);
                         //});
                         //dispatch_group_leave(checkGroup);
                         
                         MCOIMAPOperation* op = [tmp.imapSession disconnectOperation];
                         [op start:^(NSError * __nullable error) {
                             //session = nil;
#if DEBUG
                             if (error) {
                                 NSLog(@"Session disconnected with the error %@", error.localizedDescription);
                             }else{
                                 NSLog(@"Session disconnected successfully");
                             }
#endif
                             dispatch_group_leave(checkGroup);
                         }];
                     }];
                }else{
                    dispatch_group_leave(checkGroup);
                }
            }];
        });
    }
    // Use notify+semaphore instead of wait since we don't need to return before we update a badge
    dispatch_group_notify(checkGroup,dispatch_get_main_queue(),^{
    //dispatch_async(dispatch_get_main_queue(), ^{
        if([UIApplication sharedApplication].applicationState != UIApplicationStateActive){
            // Pass -1 if there're new messages but don't know how many
#if !DEBUG
            if(![GlobalRouter sharedManager].doNotHideAccountInNotification){
                alertMessage = [NSMutableString stringWithString:@""]; //@"";
            }
#endif
            [(AppDelegate*)[[UIApplication sharedApplication] delegate] gotUnseenMessages:totalUnseen recent:totalRecent>0?totalRecent:(indicateRecent?-1:0) dbgMessage:alertMessage];
            dispatch_semaphore_signal(checkSem);
        }
    });
    long res = dispatch_semaphore_wait(checkSem, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(19.0 * NSEC_PER_SEC)));
    if (res != 0) {
        // Timeout
        NSLog(@"Timeout!");
        
        for (SessionConnectorNew* ss in chSessions) {
            [ss cancellAllOps];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [(AppDelegate*)[[UIApplication sharedApplication] delegate] gotUnseenMessages:-2 recent:totalRecent>0?totalRecent:(indicateRecent?-1:0) dbgMessage:alertMessage];
        });
    }
    
    [chSessions removeAllObjects];
    chSessions = nil;
    checkGroup = nil;
    
    return totalUnseen;
}

-(int)bgGetNewMessageCount0
{
    // 1. Connect sessions
    // 2. Get new message count
    
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    /*NSArray**/[GlobalRouter sharedManager].allSettings = [dataMan getSettings:[GlobalRouter sharedManager].pin];
    if ([GlobalRouter sharedManager].allSettings.count < 2) {
        // No account settings yet
        return 0;
    }
    
    //self.imapSessions = [[NSMutableArray alloc] init];
    //[GlobalRouter sharedManager].accountsNames = [[NSMutableDictionary alloc] init];
    __block int totalUnseen = 0;
    __block int totalRecent = 0;
    //__block dispatch_semaphore_t checkSem = dispatch_semaphore_create(0);
    
    for (SettingsEntity* setting in [GlobalRouter sharedManager].allSettings) {
        if ([setting.userName isEqualToString:GENERAL_SETTINGS]) {
            continue;
        }
        
        if ([setting.imapServer isEqualToString:@""]) {
            continue;
        }
        
        __block dispatch_semaphore_t checkSem = dispatch_semaphore_create(0);
        
        SessionConnectorNew* tmp = [[SessionConnectorNew alloc] initWithSettings:setting];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [tmp connectIMAPSessionWithCompletionHandler:^(NSError* error){
                if(!error){
                    //[self.imapSessions addObject:tmp];
                    
                    MCOIMAPFolderStatusOperation *inboxFolderInfo = [tmp.imapSession folderStatusOperation:@"INBOX"];
                    [inboxFolderInfo start:^(NSError *error, MCOIMAPFolderStatus *info)
                     {
                         int unseenMessages = [info unseenCount];
                         totalUnseen += unseenMessages;
                         totalRecent += [info recentCount];
                         dispatch_semaphore_signal(checkSem);
                     }];
                }else{
                    dispatch_semaphore_signal(checkSem);
                }
            }];
        });
        dispatch_semaphore_wait(checkSem, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(25.0 * NSEC_PER_SEC))); //DISPATCH_TIME_FOREVER);
    }
    //dispatch_semaphore_wait(checkSem, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(25.0 * NSEC_PER_SEC)));
    dispatch_async(dispatch_get_main_queue(), ^{
        if([UIApplication sharedApplication].applicationState != UIApplicationStateActive){
            [(AppDelegate*)[[UIApplication sharedApplication] delegate] gotUnseenMessages:totalUnseen recent:totalRecent dbgMessage:@""];
        }
    });
    return totalUnseen;
}

-(int)readNewMessagesCountForFolder:(NSString*)folder session:(SessionConnectorNew*)session
{
    __block int ret = 0;
    
    __block dispatch_semaphore_t semaf = dispatch_semaphore_create(0);
    MCOIMAPFolderStatusOperation *inboxFolderInfo = [session.imapSession folderStatusOperation:folder];
    [inboxFolderInfo start:^(NSError *error, MCOIMAPFolderStatus *info)
     {
         if(error){
             NSLog(@"Get new message count for %@ error %@",folder, error.localizedDescription);
             ret = 0;
         }else{
             ret = [info unseenCount];
         }
         dispatch_semaphore_signal(semaf);
     }];
    dispatch_semaphore_wait(semaf, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(25.0 * NSEC_PER_SEC)));
    return ret;
}

// Not used?
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
    
    @synchronized (self.imapSessions) {
        for (SessionConnectorNew* session in self.imapSessions) {
            // global semaphore fails since it could be init'ed twice here, made it local
            __block dispatch_semaphore_t semaf = dispatch_semaphore_create(0);
            if(session.imapSession == nil){
                NSLog(@"Session is nil");
            }else{
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    block(session.imapSession, semaf);
                });
                dispatch_semaphore_wait(semaf, DISPATCH_TIME_FOREVER);
            }
        }
    }
    
    NSLog(@"New messages: %i", totalUnseen);
    
    return totalUnseen;
}

-(int)readNewMessagesCountForAll
{
    __block int totalUnseen = -1;
    __block int folderUnseen = 0;
    void (^block)(MCOIMAPSession* session, dispatch_semaphore_t sem, NSString* folder) = ^void(MCOIMAPSession* session, dispatch_semaphore_t sem, NSString* folder){
        
        MCOIMAPFolderStatusOperation *inboxFolderInfo = [session folderStatusOperation:folder];
        [inboxFolderInfo start:^(NSError *error, MCOIMAPFolderStatus *info)
         {
             NSLog(@"readNewCount error %@",error.localizedDescription);
             int unseenMessages = [info unseenCount];
             totalUnseen += unseenMessages;
             // Update other folders
             folderUnseen = unseenMessages;
             dispatch_semaphore_signal(sem);
         }];
    };
    
    @synchronized (self.imapSessions) {
        for (SessionConnectorNew* session in self.imapSessions) {
            // global semaphore fails since it could be init'ed twice here, made it local
            __block dispatch_semaphore_t semaf = dispatch_semaphore_create(0);
            if(session.imapSession == nil){
                NSLog(@"Session is nil");
            }else{
                NSString* accName = [session getSettingsName];
                NSMutableDictionary* listAcc = [[GlobalRouter sharedManager].otherFolders objectForKey:accName];//valueForKey:accName];
                if (listAcc == nil) {
                    continue;
                }
                for (NSString* folderName in [listAcc allKeys]) {
//#warning "CRASH HERE - REASON=???" // Try checking key for nil...
                    if (folderName == nil) {
                        continue;
                    }
                    FolderInfo* fi = [listAcc objectForKey:folderName];
                    if (fi == nil) {
                        continue;
                    }
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        block(session.imapSession, semaf, folderName);
                    });
                    dispatch_semaphore_wait(semaf, DISPATCH_TIME_FOREVER);
                    //NSLog(@"Unseen was=%i, set=%i", fi.unseenCount, folderUnseen);
                    fi.unseenCount = folderUnseen;
                    //NSLog(@"Made=%i", ((FolderInfo*)[listAcc valueForKey:folderName]).unseenCount);
                    folderUnseen = 0;
                }
                
            }
        }
    }
    
    NSLog(@"New messages: %i", totalUnseen);
    return totalUnseen;
}


-(void)createFolder:(NSString*)newFolderName
{
    __weak __typeof__(self) weakSelf = self;
    if (![[GlobalRouter sharedManager].currentAccount isEqualToString:@""]) {
        if ([GlobalRouter sharedManager].accountsNames) {
            NSArray* allK = [[GlobalRouter sharedManager].accountsNames allKeysForObject:[GlobalRouter sharedManager].currentAccount];
            if (!allK && allK.count == 0) {
                [CommonProcs showVanishingMessage:NSLocalizedString(@"Error: Cannot create folder",nil)];
                return;
            }
            NSString* emailAddr = allK[0];
            for (SessionConnectorNew* session in self.imapSessions) {
                if([session isThisForAddress:emailAddr]){
                    [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
                        if(!error){
                            // Create folder for this session
                            NSString * path = [[session.imapSession defaultNamespace] pathForComponents:@[newFolderName]];
                            MCOIMAPOperation *op = [session.imapSession createFolderOperation:path];
                            [op start:^(NSError *error) {
                                __strong __typeof__(self) strongSelf = weakSelf;
                                if(error){
#if DEBUG
                                    NSLog(@"Create folder error: %@", error.localizedDescription);
#endif
                                }else{
                                    [strongSelf getAllFolderNamesForSession:session.imapSession];
                                }
                            }];
                        }
                    }];
                }
            }
        }
    }
}

-(void)deleteFolder:(NSString *)folderName
{
    if (![[GlobalRouter sharedManager].currentAccount isEqualToString:@""]) {
        NSString* emailAddr = [[GlobalRouter sharedManager].accountsNames allKeysForObject:[GlobalRouter sharedManager].currentAccount][0];
        for (SessionConnectorNew* session in self.imapSessions) {
            if([session isThisForAddress:emailAddr]){
                [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
                    if(!error){
                        // Delete folder for this session
                        NSString * path = [[session.imapSession defaultNamespace] pathForComponents:@[folderName]];
                        MCOIMAPOperation *op = [session.imapSession deleteFolderOperation:path];
                        [op start:^(NSError *error) {
                            //NSLog(@"error info:%@", error);
                            
                        }];
                    }
                }];
            }
        }
    }
}

-(void)renameFolder:(NSString*)folderName newName:(NSString*)newFolderName
{
    __weak __typeof__(self) weakSelf = self;
    if (![[GlobalRouter sharedManager].currentAccount isEqualToString:@""]) {
        NSString* emailAddr = [[GlobalRouter sharedManager].accountsNames allKeysForObject:[GlobalRouter sharedManager].currentAccount][0];
        for (SessionConnectorNew* session in self.imapSessions) {
            if([session isThisForAddress:emailAddr]){
                [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
                    if(error){
                        NSLog(@"Connection error: %@",error.localizedDescription);
                        return;
                    }
                    // Create folder for this session
                    NSString * path = [[session.imapSession defaultNamespace] pathForComponents:@[folderName]];
                    NSString * newpath = [[session.imapSession defaultNamespace] pathForComponents:@[newFolderName]];
                    MCOIMAPOperation *op = [session.imapSession renameFolderOperation:path otherName:newpath];
                    [op start:^(NSError *error) {
                        if(error){
                            NSLog(@"Rename error %@", error.localizedDescription);
                        }
                        __strong __typeof__(self) strongSelf = weakSelf;
                        //NSLog(@"error info:%@", error);
                        [strongSelf getAllFolderNamesForSession:session.imapSession];
                        [CommonProcs hideSmallWheel];
                    }];
                    [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
                    [CommonProcs setSWLabelText:NSLocalizedString(@"Renaming...", nil)];
                }];
            }
        }
    }
}

-(void)copyMessage:(FullMessageEntity*)item to:(NSString*)folderPath
{
    __weak __typeof__(self) weakSelf = self;
    for (SessionConnectorNew* session in self.imapSessions) {
        if([session isThisForAddress:item.toAddress]){
            [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
            NSString* messageText = NSLocalizedString(@"Copying...", nil);
            [CommonProcs setSWLabelText:messageText];
            
            [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
                if(error){
                    NSLog(@"Connection error: %@",error.localizedDescription);
                    [CommonProcs hideSmallWheel];
                    return;
                }
                __strong __typeof__(self) strongSelf = weakSelf;
                // Create folder for this session
                NSString* folder = strongSelf->currentBoxName; //[GlobalRouter sharedManager].currentBoxPath;
                if (folder == nil || [folder isEqualToString:@""]) {
                    folder = @"INBOX";
                }
                MCOIMAPCopyMessagesOperation *op = [session.imapSession copyMessagesOperationWithFolder:folder uids:[MCOIndexSet indexSetWithIndex:[item.messageID intValue]]  destFolder:folderPath];
                [op start:^(NSError *error, NSDictionary *usDict) {
                    NSLog(@"Copy error info:%@", error);
                    [CommonProcs hideSmallWheel];
                    if (error != nil) {
                        [session cancellAllOps];
                        // Clear a session since there's a strange behaviour here - cannot connect again
                        // i.e. folder not found, INBOX or other folder, doesn't matter.
                        session.imapSession = nil;
                        [CommonProcs showMessage:error.localizedDescription title:NSLocalizedString(@"Error", nil)];
                    }else{
                        //[CommonProcs showMessage:NSLocalizedString(@"Message copied", nil) title:@""];
                        [CommonProcs showVanishingMessage:NSLocalizedString(@"Message copied", nil)];
                    }
                }];
            }];
        }
    }
}

-(void)moveMessage:(FullMessageEntity *)item to:(NSString *)folderPath
{
    __weak __typeof__(self) weakSelf = self;
    for (SessionConnectorNew* session in self.imapSessions) {
        if([session isThisForAddress:item.toAddress]){
            [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
            NSString* messageText = NSLocalizedString(@"Moving...", nil);
            [CommonProcs setSWLabelText:messageText];
            
            [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
                if(error){
                    NSLog(@"Connection error: %@",error.localizedDescription);
                    [CommonProcs hideSmallWheel];
                    return;
                }
                __strong __typeof__(self) strongSelf = weakSelf;
                // Create folder for this session
                NSString* folder = strongSelf->currentBoxName;//[GlobalRouter sharedManager].currentBoxPath;
                
                MCOIndexSet* msgUidsSet = [MCOIndexSet indexSetWithIndex:[item.messageID intValue]];
                if (folder == nil || [folder isEqualToString:@""]) {
                    folder = @"INBOX";
                }
                MCOIMAPCopyMessagesOperation *op = [session.imapSession copyMessagesOperationWithFolder:folder uids:msgUidsSet destFolder:folderPath];
                [op start:^(NSError *error, NSDictionary *usDict) {
                    NSLog(@"Copy error info:%@", error);
                    
                    if (!error) {
                        [[session.imapSession storeFlagsOperationWithFolder:folder uids:msgUidsSet kind:MCOIMAPStoreFlagsRequestKindSet flags:MCOMessageFlagDeleted] start:^(NSError *error) {
                            NSLog(@"Del error info:%@", error);
                            [CommonProcs hideSmallWheel];
                            if (!error) {
                                [[session.imapSession expungeOperation:folder] start:^(NSError *error) {
                                    // Remove message from the list
                                    [[[GlobalRouter sharedManager] getListRouter] removeItemFromList:item];
                                    [CommonProcs showMessage:NSLocalizedString(@"Message moved", nil) title:@""];
                                }];
                            }else{
                                [CommonProcs showMessage:error.localizedDescription title:NSLocalizedString(@"Error", nil)];
                                
                            }
                        }];
                    }else{
                        [CommonProcs showMessage:error.localizedDescription title:NSLocalizedString(@"Error", nil)];
                        [CommonProcs hideSmallWheel];
                    }
                }];
            }];
        }
    }
}

// Move works only within single acount since folderPath is unique... Do we need it???
-(void)moveMessages:(NSArray*)messages to:(NSString *)folderPath copyOnly:(BOOL)copyOnly
{
    NSMutableDictionary* messagesBySession = [[NSMutableDictionary alloc] initWithCapacity: self.imapSessions.count];
    
    __weak __typeof__(self) weakSelf = self;
    for (SessionConnectorNew* session in self.imapSessions){
        NSMutableArray* items = [[NSMutableArray alloc] init];
        for(ShortMessageEntity* item in messages){
            if([session isThisForAddress:item.toAddress]){
                [items addObject:item];
            }
        }
        [messagesBySession setObject:items forKey:[session getSettingsName]];
    }
    for (SessionConnectorNew* session in self.imapSessions){
        NSMutableArray* items = [messagesBySession objectForKey:[session getSettingsName]];
        if (items.count == 0) {
            continue;
        }
        MCOIndexSet* uids = [[MCOIndexSet alloc] init];
        for (ShortMessageEntity* item in items) {
            [uids addIndex:[item.messageID integerValue]];
        }
        
        [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
        NSString* messageText = copyOnly?NSLocalizedString(@"Copying...", nil):NSLocalizedString(@"Moving...", nil);
        [CommonProcs setSWLabelText:messageText];
        
        [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
            if(error){
                NSLog(@"Connection error: %@",error.localizedDescription);
                [CommonProcs hideSmallWheel];
                return;
            }
            __strong __typeof__(self) strongSelf = weakSelf;
            // Create folder for this session
            NSString* folder = strongSelf->currentBoxName;//[GlobalRouter sharedManager].currentBoxPath;
            
            if (folder == nil || [folder isEqualToString:@""]) {
                folder = @"INBOX";
            }
            MCOIMAPCopyMessagesOperation *op = [session.imapSession copyMessagesOperationWithFolder:folder uids:uids destFolder:folderPath];
            [op start:^(NSError *error, NSDictionary *usDict) {
                NSLog(@"Copy error info:%@", error);
                [CommonProcs hideSmallWheel];
                if (!error) {
                    if(!copyOnly){
                        [[session.imapSession storeFlagsOperationWithFolder:folder uids:uids kind:MCOIMAPStoreFlagsRequestKindSet flags:MCOMessageFlagDeleted] start:^(NSError *error) {
                            NSLog(@"Del error info:%@", error);
                            if (!error) {
                                [[session.imapSession expungeOperation:folder] start:^(NSError *error) {
                                    // Remove message from the list
                                    for (ShortMessageEntity* item in items) {
                                        [[[GlobalRouter sharedManager] getListRouter] removeItemFromList:item];
                                    }
                                    NSString* text = [NSString stringWithFormat:NSLocalizedString(@"%i messages moved",nil), uids.count];
                                    [CommonProcs showMessage:text title:@""];
                                }];
                            }else{
                                [CommonProcs showMessage:error.localizedDescription title:[session getSettingsName]];//NSLocalizedString(@"Error", nil)];
                            }
                        }];
                    }else{
                        NSString* text = [NSString stringWithFormat:NSLocalizedString(@"%i messages copied",nil), uids.count];
                        [CommonProcs showMessage:text title:@""];
                    }
                }else{
                    [CommonProcs showMessage:error.localizedDescription title:[session getSettingsName]];
                }
            }];
        }];
    }
}

-(void)setDoNotCheckForEmail:(NSString*)email
{
    for (SessionConnectorNew* session in self.imapSessions){
        if([session isThisForAddress:email]){
            session.imapSession.checkCertificateEnabled = NO;
            break;
        }
    }
}

-(void)appendMessage:(FullMessageEntity*)item
{
    __weak __typeof__(self) weakSelf = self;
    for (SessionConnectorNew* session in self.imapSessions) {
        if([session isThisForAddress:item.toAddress]){
            
            if(![NSThread isMainThread] && session.working){
                dispatch_semaphore_wait(session.working, dispatch_time(DISPATCH_TIME_NOW, 20*NSEC_PER_SEC));
            }
            
            [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
            NSString* messageText = NSLocalizedString(@"Appending...", nil);
            [CommonProcs setSWLabelText:messageText];
            
            [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
                if(error){
                    NSLog(@"Connection error: %@",error.localizedDescription);
                    [CommonProcs hideSmallWheel];
                    return;
                }
                __strong __typeof__(self) strongSelf = weakSelf;
                // Create folder for this session
                NSString* folder = strongSelf->currentBoxName; //[GlobalRouter sharedManager].currentBoxPath;
                if (folder == nil || [folder isEqualToString:@""]) {
                    folder = @"INBOX";
                }
                // Create rfc message data from full message
                NSData* rfcData = [self buildRFCMessage:item];
                MCOIMAPAppendMessageOperation *op = [session.imapSession appendMessageOperationWithFolder:folder messageData:rfcData flags:MCOMessageFlagNone];
                [op start:^(NSError * _Nullable error, uint32_t createdUID) {
#if DEBUG
                    NSLog(@"Append error info:%@", error.localizedDescription);
#endif
                    [CommonProcs hideSmallWheel];
                    if (error != nil) {
                        [session cancellAllOps];
                        // Clear a session since there's a strange behaviour here - cannot connect again
                        // i.e. folder not found, INBOX or other folder, doesn't matter.
                        session.imapSession = nil;
                        [CommonProcs showMessage:error.localizedDescription title:NSLocalizedString(@"Error", nil)];
                    }else{
                        // Success!
                        [CommonProcs showMessage:NSLocalizedString(@"Message encrypted", nil) title:@""];
                    }
                }];
            }];
            break;
        }
    }
}

-(BOOL)isFetching
{
    return self.requestedForAddress.count > 0;
}

+(NSString*) noMoreMessages
{
    return NSLocalizedString(@"No more messages", nil);
}

+(NSString*) fetchInProgress
{
    return NSLocalizedString(@"Fetch in progress", nil);
}

-(void)updateStoredHighestModSecForSession:(SessionConnectorNew*)session user:(NSString*)user
{
    @synchronized (session.imapSession){
        if(session.imapSession){
            MCOIMAPFolderStatusOperation *inboxFolderInfo = [session.imapSession folderStatusOperation:@"INBOX"];
            [inboxFolderInfo start:^(NSError *error, MCOIMAPFolderStatus *info)
             {
                 NSString* addrHash = [Encryptor getUUIDHashForString:user];
                 NSString* addrHash2 = [Encryptor getUUIDHashForString:addrHash];
                 if(addrHash && addrHash2){
                     [CommonProcs saveToKeychainAlways:[NSString stringWithFormat:@"%llu", info.highestModSeqValue] account:addrHash service:@"SMBGS"];
                     [CommonProcs saveToKeychainAlways:[NSString stringWithFormat:@"%u", info.uidValidity] account:addrHash2 service:@"SMBGS"];
                 }
             }];
        }
    }
}

-(void)updateStoredHighestModSecFor:(NSString*)user
{
    for (SessionConnectorNew* session in self.imapSessions) {
        if([session isThisForAddress:user]){
            [session connectIMAPSessionWithCompletionHandler:^(NSError* error){
                if(!error){
                    MCOIMAPFolderStatusOperation *inboxFolderInfo = [session.imapSession folderStatusOperation:@"INBOX"];
                    [inboxFolderInfo start:^(NSError *error, MCOIMAPFolderStatus *info)
                     {
                         NSString* addrHash = [Encryptor getUUIDHashForString:user];
                         NSString* addrHash2 = [Encryptor getUUIDHashForString:addrHash];
                         if(addrHash && addrHash2){
                             [CommonProcs saveToKeychainAlways:[NSString stringWithFormat:@"%llu", info.highestModSeqValue] account:addrHash service:@"SMBGS"];
                             [CommonProcs saveToKeychainAlways:[NSString stringWithFormat:@"%u", info.uidValidity] account:addrHash2 service:@"SMBGS"];
                             /*
                             [[NSUserDefaults standardUserDefaults] setInteger:(long)info.highestModSeqValue forKey:addrHash];
                             [[NSUserDefaults standardUserDefaults] setInteger:(long)info.uidValidity forKey:addrHash2];*/
                         }
                         //NSLog(@"Last message number for %@ is %llu",user, info.highestModSeqValue);
                     }];
                }
            }];
            break;
        }
    }
}

-(void)updateStoredHighestModSecForAll
{
    for (SessionConnectorNew* session in self.imapSessions) {
        [session connectIMAPSessionWithCompletionHandler:^(NSError* error){
            if(!error){
                MCOIMAPFolderStatusOperation *inboxFolderInfo = [session.imapSession folderStatusOperation:@"INBOX"];
                [inboxFolderInfo start:^(NSError *error, MCOIMAPFolderStatus *info)
                 {
                     NSString* addrHash = [Encryptor getUUIDHashForString:[session getEmailAddress]];
                     NSString* addrHash2 = [Encryptor getUUIDHashForString:addrHash];
                     if(addrHash && addrHash2){
                         [CommonProcs saveToKeychainAlways:[NSString stringWithFormat:@"%llu", info.highestModSeqValue] account:addrHash service:@"SMBGS"];
                         [CommonProcs saveToKeychainAlways:[NSString stringWithFormat:@"%u", info.uidValidity] account:addrHash2 service:@"SMBGS"];
                     }
                     [session disconnectSession];
                     //NSLog(@"All Last message number for %@ is %llu, uidVal is %u",[session getEmailAddress], info.highestModSeqValue, info.uidValidity);
                 }];
            }
        }];
    }
}

-(BOOL)isSessionAlive:(SessionConnectorNew *)session
{
    return [self.imapSessions indexOfObject:session inRange:NSMakeRange(0, self.imapSessions.count)] != NSNotFound;
}

-(void)reconnectAllSessions
{
    for(SessionConnectorNew* session in self.imapSessions) {
        //session.imapSession = nil;
        [session connectIMAPSessionWithCompletionHandler:^(NSError* error){
            if(!error){
                
            }
        }];
    }
}

-(void)doDeleteExpiredMessages
{
    // 1. Find messages with "Delay" extra-header == 1
    // 2. Check date and delete if expired
    // 3. Do that for "Sent" as well
    
    dispatch_queue_t deleteQ = dispatch_queue_create("DelQ", DISPATCH_QUEUE_SERIAL);
    dispatch_async(deleteQ, ^{
        [self doDeleteExpiredMessagesForFolderType:btInbox];
    });
    
    dispatch_async(deleteQ, ^{
        [self doDeleteExpiredMessagesForFolderType:btSent];
    });
}

-(void)doDeleteExpiredMessagesForFolderType:(boxTypes) folderType
{
    // 1. Find messages with "Delay" extra-header == 1
    // 2. Check date and delete if expired
    // 3. Do that for "Sent" as well
    
    //__weak __typeof__(self) weakSelf = self;
    for (SessionConnectorNew* session in self.imapSessions) {
        [session connectIMAPSessionWithCompletionHandler:^(NSError *error) {
            //__strong __typeof__(self) strongSelf = weakSelf;
            __block NSString* folderName;
            if(!error){
                //[CommonProcs setSWLabelText:NSLocalizedString(@"Loading", nil)];
                if (folderType == btInbox) {
                    folderName = @"INBOX";
                }else if (folderType == btSent) {
                    NSString* accountName = [[GlobalRouter sharedManager].accountsNames valueForKey:[session getEmailAddress]];
                    NSArray* alll = [[[GlobalRouter sharedManager].otherFolders objectForKey:accountName] allKeys];
                    for (NSString* key in alll) {
                        FolderInfo* fi = (FolderInfo*)([[[GlobalRouter sharedManager].otherFolders objectForKey:accountName] valueForKey:key]);
                        if (fi.folderType == btSent) {
                            folderName = fi.folderPath;
                            break;
                        }
                    }
                }else{
                    folderName = @"INBOX";
                }
                if (!folderName) {
                    // Sometimes there's no sent folder...
                    folderName = @"INBOX";
                }
                MCOIMAPSearchOperation* op = [session.imapSession searchExpressionOperationWithFolder:folderName expression:[MCOIMAPSearchExpression searchHeader:@"Delay" value:@"1"]];
                
                /*
                if([session.imapSession.username hasSuffix:@"yahoo.com"]){
                    [session.imapSession setConnectionLogger:^(void *connectionID, MCOConnectionLogType type, NSData *data) {
                    NSLog(@"MCOIMAPSession: [%li] %@", (long)type, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                }];
                }*/
                
                [op start:^(NSError* error, MCOIndexSet* searchResult) {
#if DEBUG
                    NSLog(@"Number of messages %d for folder %@ at %@", searchResult.count, folderName, session.imapSession.username);
#endif
                    //__strong __typeof__(self) strongSelf = weakSelf;
                    //session.imapSession.connectionLogger = nil;
                    
                    if (!error) {
                        MCOIMAPMessagesRequestKind requestKind = (MCOIMAPMessagesRequestKind)
                        (MCOIMAPMessagesRequestKindHeaders | MCOIMAPMessagesRequestKindExtraHeaders | MCOIMAPMessagesRequestKindUid);
                        
                        MCOIMAPFetchMessagesOperation *imapMessagesFetchOp2 = [session.imapSession fetchMessagesOperationWithFolder:folderName
                                            requestKind:requestKind
                                            uids:searchResult
                        ];
                        imapMessagesFetchOp2.extraHeaders = @[@"Comments"];
                        
                        [imapMessagesFetchOp2 start:^(NSError *error, NSArray *messages, MCOIndexSet *vanishedMessages) {
                            
                            MCOIndexSet* uids = [[MCOIndexSet alloc] init];
                            
                            for (MCOIMAPMessage *message in messages) {
                                NSString* extra = [message.header extraHeaderValueForName:@"Comments"];
                                NSDate* dt = [OneTimeCert getDateForString:extra];
                                if (dt) {
#if DEBUG
                                    NSLog(@"Expiration date found = %@", extra);
#endif
                                    if ([dt compare:[NSDate date]] == NSOrderedAscending) {
                                        [uids addIndex:message.uid];
                                    }
                                }
                            }
                            if (uids.count > 0) {
                                // Delete
#if DEBUG
                                NSLog(@"Deleting %i messages", uids.count);
#endif
                                //__strong __typeof__(self) strongSelf = weakSelf;
                                MCOIMAPOperation *op = [session.imapSession storeFlagsOperationWithFolder:folderName
                                            uids:uids
                                            kind:MCOIMAPStoreFlagsRequestKindSet
                                            flags:MCOMessageFlagDeleted];
                                [op start:^(NSError * error) {
                                    //__strong __typeof__(self) strongSelf = weakSelf;
                                    if(!error) {
                                        //NSLog(@"Updated flags!");
                                    } else {
#if DEBUG
                                        NSLog(@"Error updating deleted flags:%@", error);
#endif
                                    }
                                    MCOIMAPOperation *deleteOp = [session.imapSession expungeOperation:folderName];
                                    [deleteOp start:^(NSError *error) {
                                        if(error) {
                                            //NSLog(@"Error expunging folder:%@", error);
                                        } else {
                                            //NSLog(@"Successfully expunged folder");
                                            //[self updateStoredHighestModSecFor:[session getEmailAddress]];
                                        }
                                    }];
                                }];
                            }
                        }];
                    }else{
#if DEBUG
                        NSLog(@"-------------- Search error %@", error.localizedDescription);
#endif
                    }
                }];
            }
        }];
    }
}

-(void)deleteMessagesWithUIDs:(MCOIndexSet *)uids address:(NSString *)address
{
    
}

@end
