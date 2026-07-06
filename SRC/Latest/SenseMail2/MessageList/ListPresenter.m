//
//  ListPresenter.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "ListPresenter.h"
#import "MessageListViewController.h"
#import "ListInteractor.h"
#import "GlobalRouter.h"
#import "DataManager.h"
#import "DataStorage.h"
#import "CommonProcs.h"
#import "FoldersTableViewController.h"
#import "EasySetupInteractor.h"
#import "SettingsEntity.h"
#import "SearchInteractor.h"
#import "ShortcutEntity.h"

@implementation ListPresenter

@synthesize noNeedForMore, updateRequested;

-(MessageListViewController*)showListOfType:(boxTypes)type
{
    // Get the list from interactor and pass it to view controller
    //
    //ListInteractor* lin = [[ListInteractor alloc] init];
    //[lin getMessagesForBox:type];
    updateRequested = NO;
    self.requestedNextBatch = NO;
    
    __weak __typeof__(self) weakSelf = self;
    if(messageListViewController && messageListViewController.listItems.count > 0){
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof__(self) strongSelf = weakSelf;
            [strongSelf->messageListViewController.listItems removeAllObjects];
            [strongSelf->messageListViewController.tableView reloadData];
            [GlobalRouter sharedManager].totalMessages = 0;
            
            //[CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Loading...", nil) stopButton:YES];
        });
    }
    
    updateRequested = YES;
    if([GlobalRouter sharedManager].currentFilter != nil && ![[GlobalRouter sharedManager].currentFilter isEqualToString:@""]){
        [[[GlobalRouter sharedManager] getListRouter].interactor requestMessagesForBoxWithFilter:type filter:[GlobalRouter sharedManager].currentFilter];
    }else{
        [[[GlobalRouter sharedManager] getListRouter].interactor requestMessagesForBox:type];
    }
    
    if(messageListViewController == nil)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        messageListViewController = [storyboard instantiateViewControllerWithIdentifier:@"MessageList2"];
    }
    // Populate the list
    //messageListViewController.listItems = [NSMutableArray arrayWithArray:items];
    //lvc.presenter = self;
    messageListViewController.presenter = self;
    
    //currentBox = type;
    
    return messageListViewController;
    
}

-(NSMutableArray*)getUnreadUp:(NSMutableArray*)list
{
    NSMutableArray* ret = [[NSMutableArray alloc] initWithCapacity:list.count];
    int numChanged = 0;
    for (int i=(int)list.count-1; i>=0; i--) {
        ShortMessageEntity* item = list[i];
        if (item.flags&mfNew) {
            [ret insertObject:item atIndex:0];
            numChanged++;
        }else{
            [ret insertObject:item atIndex:numChanged];
        }
    }
    
    // Sort by date within new. Wow! Bubbles!
    for(int j=0;j<numChanged;j++){
        for (int i=0; i<ret.count-1; i++) {
            ShortMessageEntity* item1 = ret[i];
            ShortMessageEntity* item2 = ret[i+1];
            if (item1.flags&mfNew && item2.flags&mfNew) {
                if ([item2.date compare:item1.date] == NSOrderedDescending) {
                    ShortMessageEntity* itemTmp = ret[i];
                    ret[i] = ret[i+1];
                    ret[i+1] = itemTmp;
                }
            }else{
                break;
            }
        }
    }
    
    return ret;
}

-(void)sortAndAddTheList:(NSArray*)list
{
    listSortOrder sortOrder = [[GlobalRouter sharedManager] getListRouter].sortOrder;
    @synchronized (messageListViewController.listItems) {
        if (sortOrder == lsDateEverything) {
            [messageListViewController.listItems addObjectsFromArray: [NSMutableArray arrayWithArray:list]];
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
            NSArray* tmp = [messageListViewController.listItems sortedArrayUsingDescriptors:@[sort]];
            messageListViewController.listItems = [NSMutableArray arrayWithArray:tmp];
        }else if(sortOrder == lsAccount || sortOrder == lsAccountNewOnTop){
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
            NSArray* tmp = [list sortedArrayUsingDescriptors:@[sort]];
            [messageListViewController.listItems addObjectsFromArray: [NSMutableArray arrayWithArray:tmp]];
            if (sortOrder == lsAccountNewOnTop && !self.requestedNextBatch) {
                messageListViewController.listItems = [self getUnreadUp:messageListViewController.listItems];
            }
        }else if(sortOrder == lsDate || sortOrder == lsDateNewOnTop){
            // Need to sort by date all newly added
            NSMutableArray* toSort = [[NSMutableArray alloc] init];
            if (lastKnownMessageNumber == 0) {
                // Sort all
                [toSort addObjectsFromArray:messageListViewController.listItems];
                [toSort addObjectsFromArray:list];
            }else{
                for (long i=lastKnownMessageNumber; i<messageListViewController.listItems.count; i++) {
                    [toSort addObject:messageListViewController.listItems[i]];
                }
                [toSort addObjectsFromArray:list];
            }
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
            NSArray* tmp = [toSort sortedArrayUsingDescriptors:@[sort]];
            for (long i=lastKnownMessageNumber,j=0; j<toSort.count; j++,i++) {
                if (i>=messageListViewController.listItems.count) {
                    [messageListViewController.listItems addObject:tmp[j]];
                }else{
                    messageListViewController.listItems[i] = tmp[j];
                }
            }
            
            if (sortOrder == lsDateNewOnTop && !self.requestedNextBatch) {
                messageListViewController.listItems = [self getUnreadUp:messageListViewController.listItems];
            }
        }
    }
}

-(void)setList:(NSArray*)list error:(NSString*)error
{
    /*
    MessageListRouter* rt = [[GlobalRouter sharedManager] getListRouter];
    rt.largeFont = [[[NSUserDefaults standardUserDefaults] objectForKey:@"largeFont"] boolValue];
    
    id val = [[NSUserDefaults standardUserDefaults] objectForKey:@"sortByDate"];
    if(val != nil){
        rt.sortByDate = [val boolValue];
    }else{
        // Set the default on
        rt.sortByDate = YES;
    }
    */
    showingMenu = NO;
    //self.sortedByDate = YES;
    self.sortType = sotDate;
    messageListViewController.largeFont = [[GlobalRouter sharedManager] getListRouter].largeFont;
    
    // This is a week point - when we load messages with filter, if there's nothing to load it returns an empty array, then the updateRequest flag is unset and a new batch is requested from the message list autoload. And again and again. We need to stop the loop.
    // Looks like it's OK now...
    if (!error && updateRequested && list.count == 0) {
        //self.noNeedForMore = YES; // no, it stops early
        [messageListViewController stopRefreshing];
        
        return;
    }else{
        updateRequested = NO;
    }
    
    // Color the address lines to emphasize different boxes
    NSArray* colors = [CommonProcs getColorValues];
    
    if (self.boxColors == nil || self.boxColors.count == 0) {
        self.boxColors = [[NSMutableDictionary alloc] init];
        //int i=0;
    }
    
    for (SettingsEntity* sett in [GlobalRouter sharedManager].allSettings) {
        [self.boxColors setObject:colors[sett.bgColor] forKey:sett.settingsName];
    }
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [CommonProcs hideProgress];
        if ([error isEqualToString:@""] || error == nil) {
            if(strongSelf->messageListViewController.listItems == nil){
                if (list == nil) {
                    strongSelf->messageListViewController.listItems = [[NSMutableArray alloc] init];
                }else{
                    strongSelf->messageListViewController.listItems = [NSMutableArray arrayWithArray:list];
                }
                //[self updateList];
            }else{
                [self sortAndAddTheList:list];
                /*
                // Sorting is strange - load next messages and a message might go up to the
                // already viewed messages since they are sorted by date
                if([GlobalRouter sharedManager].getListRouter.sortByDate){
                    if(list){
                        [strongSelf->messageListViewController.listItems addObjectsFromArray: [NSMutableArray arrayWithArray:list]];
                        
                        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
                        NSArray* tmp = [strongSelf->messageListViewController.listItems sortedArrayUsingDescriptors:@[sort]];
                        strongSelf->messageListViewController.listItems = [NSMutableArray arrayWithArray:tmp];
                    }
                }else{
                    if(list){
                        @synchronized (strongSelf->messageListViewController.listItems) { // listItems changes while sorting, is the lock still the same?
                        // Add the new array after the shown messages
                        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
                        NSArray* tmp = [list sortedArrayUsingDescriptors:@[sort]];
                        
                        //if (strongSelf->messageListViewController.listItems.count > 0) {
                        //    [strongSelf->messageListViewController.listItems addObject:[[ShortMessageEntity alloc]init]];
                        //}
                        [strongSelf->messageListViewController.listItems addObjectsFromArray: [NSMutableArray arrayWithArray:tmp]];
                        // ==== end sorting change
                        
                        // Here we get an array of messages, with no sorting. We need to bring the new messages on top, but for the first set of messages
                        // Sort unread, but it will consider other flags that we ignore for now
                        if(!self.requestedNextBatch){ // How to detect it is the first set? Since if we load the next part of mesages, all the unread will go up, that is not the desired behaviour at all. Added a flag.
#if DEBUG
                            NSLog(@"Sorting!");
#endif
                            / *
                            NSSortDescriptor *sort2 = [NSSortDescriptor sortDescriptorWithKey:@"flags" ascending:NO  comparator:^(id obj1, id obj2) {
                                
                                if (([obj1 longValue] & mfNew) > 0 && ([obj2 longValue] & mfNew) > 0) {
                                    return (NSComparisonResult)NSOrderedSame; // The same
                                }else if (([obj1 longValue] & mfNew) > 0 && ([obj2 longValue] & mfNew) == 0) {
                                    return (NSComparisonResult)NSOrderedDescending; // New goes up
                                }else if (([obj1 longValue] & mfNew) == 0 && ((long)obj2 & mfNew) > 0) {
                                    return (NSComparisonResult)NSOrderedAscending; // Not new goes down
                                }else if (([obj1 longValue] & mfNew) == 0 && ([obj2 longValue] & mfNew) == 0) {
                                    return (NSComparisonResult)NSOrderedSame;
                                }
                                
                                return (NSComparisonResult)NSOrderedAscending; // if not new, go down both
                            }];
                            
                            //NSSortDescriptor *sort3 = [NSSortDescriptor sortDescriptorWithKey:@"fromName" ascending:NO];
                            NSArray* tmp2 = [strongSelf->messageListViewController.listItems sortedArrayUsingDescriptors:@[sort2]];
                            strongSelf->messageListViewController.listItems = [NSMutableArray arrayWithArray:tmp2];
                             * /
                            strongSelf->messageListViewController.listItems = [self getUnreadUp:strongSelf->messageListViewController.listItems];
                        }else{
#if DEBUG
                            NSLog(@"No sort");
#endif
                        }
                        }
                    }
                }*/
                
                // Extract addresses for autocomplete
                if ([GlobalRouter sharedManager].possibleAddresses == nil) {
                    //[GlobalRouter sharedManager].possibleAddresses = [[NSMutableArray alloc] init];
                    [[GlobalRouter sharedManager] initPossibleAddresses];
                }else{
                    //[[GlobalRouter sharedManager].possibleAddresses removeAllObjects];
                    [[GlobalRouter sharedManager] initPossibleAddresses];
                }
                for (ShortMessageEntity* item in strongSelf->messageListViewController.listItems) {
                    [[GlobalRouter sharedManager] addPossibleAddressFromShortMessage:item];
                }
            }
            [strongSelf updateList];
        }else if([error containsString:NSLocalizedString(@"No more messages", nil)]){
            //[strongSelf->messageListViewController showError:error];
            [strongSelf->messageListViewController updateLastCell];
            [strongSelf updateList];
        }else if([error containsString:NSLocalizedString(@"No settings", nil)]){
            [CommonProcs askAndDoWithTitle:NSLocalizedString(@"No settings", nil) text:[NSString stringWithFormat:@"%@?", NSLocalizedString(@"Add account", nil)] block:^{
                [[GlobalRouter sharedManager] showAddMaster]; //needSettingsWithNew];
            }];
        }else{
            //[CommonProcs showVanishingMessage:NSLocalizedString(@"Error", nil)];
            [CommonProcs showVanishingErrorMessage:error];
            //[strongSelf->messageListViewController showError:error];
            // remove the spinner from the last row
            [strongSelf->messageListViewController updateLastCell];
        }
        
        [strongSelf->messageListViewController stopRefreshing];
    });
}

-(void)updateList
{
    [self updateListAnimated:NO];
}

-(void)refreshList
{
    [messageListViewController.tableView reloadData];
}

-(void)updateListAnimated:(BOOL)animated
{
    //if (messageListViewController.isViewLoaded && messageListViewController.view.window) {
        __weak __typeof__(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof__(self) strongSelf = weakSelf;
            [strongSelf->messageListViewController.tableView reloadData];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [strongSelf refreshTableHeaderAnimated:animated];
            });
        });
    //}
}

-(void)sortListbyDate
{
    // Extra loop... need to fix the comparator - FIXED
    /*
    for (ShortMessageEntity* ent in messageListViewController.listItems) {
        ent.unreadForSort = ent.flags & mfNew;
    }
    */
    
    // Remove page delimiters
    NSMutableArray* toDel = [[NSMutableArray alloc] init];
    for (ShortMessageEntity* ent in messageListViewController.listItems) {
        if (!ent.fromAddress) {
            [toDel addObject:ent];
        }
    }
    for (ShortMessageEntity* ent in toDel) {
        [messageListViewController.listItems removeObject:ent];
    }
    
    NSSortDescriptor *sort;
    NSArray* sortDescriptors;
    
    // Sort order - Date->New->Sender
    
    if(self.sortType == sotDate){//self.sortedByDate){
        // Sort unread first
        sort = [NSSortDescriptor sortDescriptorWithKey:@"flags" ascending:NO  comparator:^(id obj1, id obj2) {
            
            if (([obj1 longValue] & mfNew) > 0 && ((long)obj2 & mfNew) > 0) {
                return (NSComparisonResult)NSOrderedSame; // The same
            }else if (([obj1 longValue] & mfNew) > 0 && ((long)obj2 & mfNew) == 0) {
                return (NSComparisonResult)NSOrderedDescending; // New goes up
            }else if (([obj1 longValue] & mfNew) == 0 && ((long)obj2 & mfNew) > 0) {
                return (NSComparisonResult)NSOrderedAscending; // Not new goes down
            }
            
            return (NSComparisonResult)NSOrderedAscending; // if not new, go down both
        }];
        // Sort by date within new
        NSSortDescriptor *sort2 = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
        sortDescriptors = @[sort, sort2];
        self.sortType = sotNew;
    }else if(self.sortType == sotNew){
        sort = [NSSortDescriptor sortDescriptorWithKey:@"fromAddress" ascending:YES];
        sortDescriptors = @[sort];
        self.sortType = sotSender;
    }else{
        // sort by date
        sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
        sortDescriptors = @[sort];
        self.sortType = sotDate;
    }
    
    NSArray* tmp = [messageListViewController.listItems sortedArrayUsingDescriptors:sortDescriptors];
    messageListViewController.listItems = [NSMutableArray arrayWithArray:tmp];
    
    [self updateListAnimated:NO];
    //self.sortedByDate = !self.sortedByDate;
}

-(BOOL)deleteItem:(ShortMessageEntity *)item
{
    [[[GlobalRouter sharedManager] getListRouter].interactor needDeleteMessage:item];
    [messageListViewController.listItems removeObject:item];
    //[GlobalRouter sharedManager].totalMessages--;
    //[messageListViewController.tableView reloadData];
    return YES;
}

-(void)deleteItemFromList:(ShortMessageEntity*)item
{
    for (ShortMessageEntity* ent in messageListViewController.listItems) {
        if (ent.messageID == item.messageID) {
            [messageListViewController.listItems removeObject:ent];
            [GlobalRouter sharedManager].totalMessages--;
            [GlobalRouter sharedManager].loadedMessages--;
            [messageListViewController.tableView reloadData];
            break;
        }
    }
}

-(void)updateItemsFlags:(ShortMessageEntity*)item
{
    bool needUpdate = NO;
    for (ShortMessageEntity* ent in messageListViewController.listItems) {
        if (ent.messageID == item.messageID) {
            ent.flags = item.flags;
            needUpdate = YES;
            break;
        }
    }
    if (needUpdate) {
        [self updateList];
    }
}

-(void)showMessageItem:(ShortMessageEntity *)item
{
    dispatch_async([[GlobalRouter sharedManager] getQ], ^{
        [[GlobalRouter sharedManager] needShowMessage:item];
    });
}

-(void)exitPressed
{
    [[GlobalRouter sharedManager] needExit];
}

-(void)markMessageFavourite:(ShortMessageEntity *)item
{
    //Pass it over to mark message in data layer
    [[[GlobalRouter sharedManager] getListRouter].interactor needStarForMessage:item];
    
    item.flags ^= mfFavourite;
    [messageListViewController.tableView reloadData];
}

-(void)checkMail
{
    [self clearListData];
    
    [GlobalRouter sharedManager].totalMessages = 0;
    
    if ([GlobalRouter sharedManager].currentBox == btEmpty) {
        [GlobalRouter sharedManager].currentBox = btInbox;
    }
    if ([messageListViewController.filterFrom isEqualToString:@""]) {
        [[[GlobalRouter sharedManager] getListRouter].interactor requestMessagesForBox:[GlobalRouter sharedManager].currentBox];
    }else{
        [[[GlobalRouter sharedManager] getListRouter].interactor requestMessagesForBoxWithFilter :[GlobalRouter sharedManager].currentBox filter:messageListViewController.filterFrom];
    }
}

-(void)needMoreMessages
{
    if (updateRequested) {
        return;
    }else{
        updateRequested = YES;
    }
    lastKnownMessageNumber = messageListViewController.listItems.count;
    
    self.requestedNextBatch = YES;
    if ([messageListViewController.filterFrom isEqualToString:@""]) {
        [[[GlobalRouter sharedManager] getListRouter].interactor requestNextMessagesForBox:[GlobalRouter sharedManager].currentBox];
    }else{
        [[[GlobalRouter sharedManager] getListRouter].interactor requestNextMessagesForBoxWithFilter :[GlobalRouter sharedManager].currentBox filter:messageListViewController.filterFrom];
    }
}

-(void)newMessage
{
    [[GlobalRouter sharedManager] newMessage];
}

-(void)showSettings
{
    [[GlobalRouter sharedManager] needSettings];
}

-(void)clearListData
{
    updateRequested = NO;
    self.requestedNextBatch = NO;
    lastKnownMessageNumber = 0;
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [strongSelf->messageListViewController.listItems removeAllObjects];
        [strongSelf->messageListViewController.tableView reloadData];
        [GlobalRouter sharedManager].totalMessages = 0;
    });
}

// Nav bar
-(void)needShowInbox
{
    /*
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs addStopButtonInView:[[GlobalRouter sharedManager] getCurrentView]];
    });
    */
    [self clearListData];
    [GlobalRouter sharedManager].currentBox = btInbox;
    
    [[GlobalRouter sharedManager] needShowInbox];
    
    ////////// DBG
    /*
    dispatch_async(dispatch_get_main_queue(), ^{
        EasySetupInteractor* esi = [[EasySetupInteractor alloc] init];
        [esi showMasterInNC:[[GlobalRouter sharedManager] getNavController]];
    });
     */
}

-(void)needShowSent
{
    /*
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs addStopButtonInView:[[GlobalRouter sharedManager] getCurrentView]];
    });
    */
    [self clearListData];
    [[GlobalRouter sharedManager] needShowSent];
}

-(void)needShowFavs
{
    /*
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs addStopButtonInView:[[GlobalRouter sharedManager] getCurrentView]];
    });
     */
    [self clearListData];
    [[GlobalRouter sharedManager] needShowFavs];
}

-(void)needShowSpam
{
    /*
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs addStopButtonInView:[[GlobalRouter sharedManager] getCurrentView]];
    });
     */
    [self clearListData];
    [[GlobalRouter sharedManager] needShowSpam];
}

-(void)needShowOtherBox
{
    [self clearListData];
    [[GlobalRouter sharedManager] needShowOtherBox];
}

-(void)sos
{
    [[GlobalRouter sharedManager] sos];
}

// Not used any more?
-(void)search
{
    __weak __typeof__(self) weakSelf = self;
    [CommonProcs askAndDoWithTitle:NSLocalizedString(@"Find messages", nil) text:NSLocalizedString(@"Enter sender address", nil) block:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof__(self) strongSelf = weakSelf;
            [strongSelf->messageListViewController.listItems removeAllObjects];
            [strongSelf->messageListViewController.tableView reloadData];
            [CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Loading...", nil) stopButton:YES];
        });
        __strong __typeof__(self) strongSelf = weakSelf;
        [[[GlobalRouter sharedManager] getListRouter].interactor requestMessagesForBoxWithFilter :[GlobalRouter sharedManager].currentBox filter:[NSString stringWithString: strongSelf->messageListViewController.filterFrom]];
        //messageListViewController.filterFrom = @"";
    }];
    //[[GlobalRouter sharedManager] needSearch];
}

-(void)doSearchWithString:(NSString*)searchStr
{
    [self clearListData];
    
    [GlobalRouter sharedManager].currentFilter = searchStr;
    messageListViewController.filterFrom = searchStr;
    [GlobalRouter sharedManager].totalMessages = 0;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[[GlobalRouter sharedManager] getListRouter].interactor requestMessagesForBoxWithFilter :[GlobalRouter sharedManager].currentBox filter:searchStr];
    });
}

-(void)showHelp
{
    [[GlobalRouter sharedManager] needShowHelp];
}

-(void)showPP
{
    [[GlobalRouter sharedManager] needShowPP];
}

-(void)clearList
{
    messageListViewController.listItems = [@[] mutableCopy];
    if ([NSThread isMainThread]) {
        [messageListViewController.tableView reloadData];
    }else{
        __weak __typeof__(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof__(self) strongSelf = weakSelf;
            [strongSelf->messageListViewController.tableView reloadData];
        });
    }
    [GlobalRouter sharedManager].totalMessages = 0;
    [GlobalRouter sharedManager].loadedMessages = 0;
    lastKnownMessageNumber = 0;
    //[GlobalRouter sharedManager].currentBox = btEmpty;
}

-(void)stopRefreshing
{
    updateRequested = NO;
    [messageListViewController stopRefreshing];
}

-(ShortMessageEntity*)getNextShortMessageFor:(ShortMessageEntity*)item
{
    ShortMessageEntity* ret = nil;
    BOOL retNext = NO;
    for (ShortMessageEntity* ent in messageListViewController.listItems) {
        if (retNext) {
            ret = ent;
            break;
        }
        if (ent.messageID == item.messageID) {
            retNext = YES;
        }
    }
    
    return ret;
}

-(ShortMessageEntity*)getPrevShortMessageFor:(ShortMessageEntity*)item
{
    ShortMessageEntity* ret = nil;
    for (ShortMessageEntity* ent in messageListViewController.listItems) {
        if (ent.messageID == item.messageID) {
            break;
        }
        ret = ent;
    }

    return ret;
}

-(void)setNoNeed:(BOOL)bNoNeedForMore
{
    self.noNeedForMore = bNoNeedForMore;
    // Update last row if visible
    //[messageListViewController updateLastCell];
}

-(void)needShowMenu
{
    /*
     UIStoryboard * sb = [UIStoryboard storyboardWithName:@"SelectStoryboard" bundle:nil];
     TableSelectViewController * vc = [sb instantiateViewControllerWithIdentifier:@"AccountSelect"];
     vc.caller = self;
     vc.items = [[GlobalRouter sharedManager].otherFolders allKeys];
     //[self.navigationController pushViewController:vc animated:true];
     */
    
    if (showingMenu) {
        return;
    }
    
    fvc = [[FoldersTableViewController alloc] init];
    fvc.caller = messageListViewController;
    
    /*
    // this looks better, but it flashes black bg instead of previous view -
    // there's an implicit animation that fades in/out view controllers
    
    CATransition* transition = [CATransition animation];
     transition.duration = 0.25;
     transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
     transition.type = kCATransitionPush;
     transition.subtype= kCATransitionFromLeft;
    
    [messageListViewController.navigationController.view.layer addAnimation:transition forKey:kCATransition];
     [messageListViewController.navigationController pushViewController:fvc animated:NO];
    */
    
    //[messageListViewController.navigationController pushViewController:fvc animated:YES];
    
    [messageListViewController addChildViewController:fvc];
    showingMenu = YES;
    fvc.view.tag = 80001;
    
    fvc.view.frame = CGRectMake(-messageListViewController.view.frame.size.width, 0, messageListViewController.view.frame.size.width, messageListViewController.view.frame.size.height-44); //fvc.view.frame.size.height);
    [messageListViewController.view addSubview:fvc.view];
    [fvc didMoveToParentViewController:messageListViewController];
    
    // Shadow, don't forget to set maskToBounds or shadow won't appear
    fvc.view.layer.masksToBounds = NO;
    [fvc.view.layer setShadowColor:[UIColor grayColor].CGColor];
    [fvc.view.layer setShadowOpacity:0.5];
    [fvc.view.layer setShadowOffset:CGSizeMake(3, 0)];
    
    [fvc updateFolderList];
    __weak __typeof__(self) weakSelf = self;
    [UIView animateWithDuration:0.3 delay:0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut) animations:^{
        __strong __typeof__(self) strongSelf = weakSelf;
        strongSelf->fvc.view.frame = CGRectMake(0, 0, strongSelf->fvc.view.frame.size.width, strongSelf->fvc.view.frame.size.height);
        //[messageListViewController.navigationController setToolbarHidden:YES];
    }
    completion:^(BOOL finished) {
        if (finished) {
        }
    }];
    
    /*
     // Flickers black again
     [self.navigationController pushViewController:fvc animated:NO];
     UIViewController* dummy = [[UIViewController alloc] init];
     [self.navigationController pushViewController:dummy animated:NO];
     [self.navigationController popViewControllerAnimated:YES];
     */

}

-(void)menuWasDismissed
{
    showingMenu = NO;
    //if (self.updateShortcutBar) {
    [self showShortcutBar];
    //}
}

-(void)refreshTableHeaderAnimated:(BOOL)animated
{
    // [self.tableView headerViewForSection:1].textLabel.text = [self tableView:self.tableView titleForHeaderInSection:1];
    UIView* hdr = [messageListViewController.tableView viewWithTag:8007];
    UILabel* label = [hdr viewWithTag:8008];// .textLabel;
    NSString* labelText = @"";
    if([GlobalRouter sharedManager].newMessages > [GlobalRouter sharedManager].newMessagesTotal)
    {
        // This is the error, sholdn't be so, recalculate
        
    }
    
    NSString* boxName = [messageListViewController getBoxName];
    if (![boxName isEqualToString:@""]) {
        if ([messageListViewController.filterFrom isEqualToString:@""]) {
            if([GlobalRouter sharedManager].loadedMessages == 0){
                //[label setText:[NSString stringWithFormat:@"%@ (%d)",boxName, [GlobalRouter sharedManager].totalMessages]];
                labelText = [NSString stringWithFormat:@"%@ (%d)",boxName, [GlobalRouter sharedManager].totalMessages];
            }else{
                if([GlobalRouter sharedManager].newMessages > 0 && [GlobalRouter sharedManager].newMessagesTotal > 0){
                    //NSLog(@"%i",[GlobalRouter sharedManager].newMessagesTotal);
                    //[label setText:[NSString stringWithFormat:@"%@ %d of %d, unread %d of %d",boxName, [GlobalRouter sharedManager].loadedMessages, [GlobalRouter sharedManager].totalMessages,[GlobalRouter sharedManager].newMessages,[GlobalRouter sharedManager].newMessagesTotal]];
                    labelText = [NSString stringWithFormat:@"%@ %d of %d, unread %d of %d",boxName, [GlobalRouter sharedManager].loadedMessages, [GlobalRouter sharedManager].totalMessages,[GlobalRouter sharedManager].newMessages,[GlobalRouter sharedManager].newMessagesTotal];
                }else{
                    //[label setText:[NSString stringWithFormat:@"%@ %d of %d",boxName, [GlobalRouter sharedManager].loadedMessages, [GlobalRouter sharedManager].totalMessages]];
                    labelText = [NSString stringWithFormat:@"%@ %d of %d",boxName, [GlobalRouter sharedManager].loadedMessages, [GlobalRouter sharedManager].totalMessages];
                }
            }
        }else{
            //[label setText:[NSString stringWithFormat:@"%@ '%@' (%d)",boxName, messageListViewController.filterFrom, [GlobalRouter sharedManager].totalMessages]];
            if([GlobalRouter sharedManager].newMessages > 0 && [GlobalRouter sharedManager].newMessagesTotal > 0){
                labelText = [NSString stringWithFormat:@"%@ '%@' %d of %d, unread %d",boxName, [self getFilterString], [GlobalRouter sharedManager].loadedMessages, [GlobalRouter sharedManager].totalMessages,[GlobalRouter sharedManager].newMessages /*,[GlobalRouter sharedManager].newMessagesTotal*/];
            }else{
                labelText = [NSString stringWithFormat:@"%@ '%@' %d of %d",boxName, [self getFilterString], [GlobalRouter sharedManager].loadedMessages, [GlobalRouter sharedManager].totalMessages];
            }
        }
        
    }else{
        //[label setText:@""];
    }
    
    [label setText:labelText];
    if(animated){
        label.alpha = 0;
        [UIView animateWithDuration:0.55 delay:0 options: UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         label.alpha = 1;
                     }
                     completion:^(BOOL fin){
                         if (fin) {
                         }
                     }];
    }
    
    UIImageView* sortedImage = [hdr viewWithTag:8009];
    //[sortedImage setImage:[UIImage imageNamed:self.sortedByDate?@"downArrow":@"circleNewMessages"]];
    if (self.sortType == sotDate) {
        [sortedImage setImage:[UIImage imageNamed:@"downArrow"]];
    }else if(self.sortType == sotNew){
        [sortedImage setImage:[UIImage imageNamed:@"circleNewMessages"]];
    }else if (self.sortType == sotSender){
        [sortedImage setImage:[UIImage imageNamed:@"sortSender"]];
    }
}

-(NSString*)getFilterString
{
    NSString* filterString;
    if ([messageListViewController.filterFrom isEqualToString:filterUnread]) {
        filterString = NSLocalizedString(@"Unread",nil);
    }else if ([messageListViewController.filterFrom isEqualToString:filterStarred]) {
        filterString = NSLocalizedString(@"Flagged",nil);
    }else if ([messageListViewController.filterFrom isEqualToString:filterLarge]) {
        filterString = NSLocalizedString(@"Large mail",nil);
    }else if ([messageListViewController.filterFrom isEqualToString:filterAnswered]) {
        filterString = NSLocalizedString(@"Answered",nil);
    }else if ([messageListViewController.filterFrom isEqualToString:filterAttachments]) {
        filterString = NSLocalizedString(@"With attachments",nil);
    }else if ([messageListViewController.filterFrom isEqualToString:filterProtected]) {
        filterString = NSLocalizedString(@"Protected",nil);
    }else if ([messageListViewController.filterFrom isEqualToString:filterImportant]) {
        filterString = NSLocalizedString(@"Important",nil);
    }else if([messageListViewController.filterFrom hasPrefix:filterBefore]){
        NSString* dateString = [messageListViewController.filterFrom substringFromIndex:filterBefore.length+1];
        filterString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Mail before",nil), dateString];
    }else if([messageListViewController.filterFrom hasPrefix:filterSince]){
        NSString* dateString = [messageListViewController.filterFrom substringFromIndex:filterSince.length+1];
        filterString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Mail after",nil), dateString];
    }else if([messageListViewController.filterFrom hasPrefix:filterOn]){
        NSString* dateString = [messageListViewController.filterFrom substringFromIndex:filterOn.length+1];
        filterString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Mail on",nil), dateString];
    }else if([messageListViewController.filterFrom hasPrefix:filterIn]){
        NSString* dateString = [messageListViewController.filterFrom substringFromIndex:filterIn.length+1];
        NSDate* dtt = [CommonProcs dateFromString:dateString];
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"LLLL YYYY"];
        NSString* month = [formatter stringFromDate:dtt];
        filterString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Mail in",nil), month];
    }else if([messageListViewController.filterFrom hasPrefix:filterBetween]){
        NSString* dateString = [messageListViewController.filterFrom substringFromIndex:filterBetween.length+1];
        NSArray* dtt = [CommonProcs datesFromString:dateString];
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        [formatter setDateStyle:NSDateFormatterShortStyle];// setDateFormat:@"LL YY"];
        NSString* date1 = [formatter stringFromDate:dtt[0]];
        NSString* date2 = [formatter stringFromDate:dtt[1]];
        filterString = [NSString stringWithFormat:@"%@ %@ - %@", NSLocalizedString(@"Between",nil), date1,date2];
    }else if([messageListViewController.filterFrom hasPrefix:filterFromF]){
        NSString* fromString = [messageListViewController.filterFrom substringFromIndex:filterFromF.length+1];
        filterString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"From:",nil), fromString];
    }else if([messageListViewController.filterFrom hasPrefix:filterTo]){
        NSString* toString = [messageListViewController.filterFrom substringFromIndex:filterTo.length+1];
        filterString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"To:",nil), toString];
    }else if([messageListViewController.filterFrom hasPrefix:filterLargerThan]){
        NSString* sizeString = [messageListViewController.filterFrom substringFromIndex:filterLargerThan.length+1];
        filterString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Larger than:",nil), sizeString];
    }else if([messageListViewController.filterFrom hasPrefix:filterSmallerThan]){
        NSString* sizeString = [messageListViewController.filterFrom substringFromIndex:filterSmallerThan.length+1];
        filterString = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Smaller than:",nil), sizeString];
    }else{
        filterString = messageListViewController.filterFrom;
    }
    
    return filterString;
}

-(void)clearFilter
{
    messageListViewController.filterFrom = @"";
    [GlobalRouter sharedManager].currentFilter = @"";
}

-(void)needEditList
{
    // return if list is empty
    if (messageListViewController.listItems.count == 0) {
        if (messageListViewController.tableView.isEditing) {
            [messageListViewController.tableView setEditing:NO animated:YES];
        }
        return;
    }
    // return yes from - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:
    [messageListViewController.tableView setEditing:!messageListViewController.tableView.isEditing animated:YES];
    // Need to change buttons to move-copy-delete
    // messageListViewController.navigationController.toolbar - bottom toolbar
    // messageListViewController.toolBar - top toolbar
    
    if (!messageListViewController.tableView.isEditing) {
        [messageListViewController.navigationController.toolbar setItems:savedBottomToolbarItems animated:YES];
        [messageListViewController.toolBar setItems:savedTopToolbarItems animated:YES];
    }else{
         self.selectAllButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Select all",nil) style:UIBarButtonItemStylePlain target:self action:@selector(selectAll)];
        
        UIBarButtonItem *actionItem = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                       target:self
                                       action:@selector(needActionForEdit)];
        
        UIBarButtonItem* flex1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                       target:self
                                       action:@selector(finishEditing:)];
        
        NSArray *bottomButtons = [[NSArray alloc] initWithObjects:self.selectAllButton, actionItem, flex1, cancelItem, nil];
        
        savedBottomToolbarItems = messageListViewController.navigationController.toolbar.items;
        [messageListViewController.navigationController.toolbar setItems:bottomButtons animated:YES];
        
        UIBarButtonItem *deleteItem = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                       target:self
                                       action:@selector(deleteSelected)];
        UIBarButtonItem* flex2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        
        UIBarButtonItem *deleteAllItem;
        NSArray *topButtons;
        if([[GlobalRouter sharedManager] canClearCurrentBox]){
            deleteAllItem = [[UIBarButtonItem alloc]
                                          initWithTitle:NSLocalizedString(@"Empty Folder", nil) style:UIBarButtonItemStylePlain target:self action:@selector(deleteAll)];
            
            topButtons = [[NSArray alloc] initWithObjects:deleteAllItem, flex2, deleteItem, nil];
        }else{
        /*UIBarButtonItem *actionItem = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                       target:self
                                       action:@selector(needActionForEdit)];
        */
            topButtons = [[NSArray alloc] initWithObjects:flex2, deleteItem, nil];
        }
        savedTopToolbarItems = messageListViewController.toolBar.items;
        [messageListViewController.toolBar setItems:topButtons animated:YES];
    }
}

-(void)finishEditing:(BOOL)cancel
{
    [messageListViewController.tableView setEditing:NO animated:YES];
    [messageListViewController.navigationController.toolbar setItems:savedBottomToolbarItems animated:YES];
    [messageListViewController.toolBar setItems:savedTopToolbarItems animated:YES];
}

-(void)selectAll
{
    NSArray *selectedRows = [messageListViewController.tableView indexPathsForSelectedRows];
    if(selectedRows.count == messageListViewController.listItems.count){
        // All selected, change button to deselect
        self.selectAllButton.title = NSLocalizedString(@"Select all",nil);
        for (int i=0; i<messageListViewController.listItems.count; i++) {
            [messageListViewController.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO];
        }
    }else{
        for (int i=0; i<messageListViewController.listItems.count; i++) {
            [messageListViewController.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        self.selectAllButton.title = NSLocalizedString(@"Deselect all",nil);
    }
}

-(void)deleteSelected
{
    long selectedNum = [[messageListViewController.tableView indexPathsForSelectedRows] count];
    if (selectedNum == 0) {
        return;
    }
    // Confirm fist?
    NSString *actionTitle;
    if (selectedNum == 1) {
        actionTitle = NSLocalizedString(@"Are you sure you want to remove this item?", @"");
    }else{
        actionTitle = [NSString stringWithFormat:NSLocalizedString(@"Are you sure you want to remove %i items?", @""),[[messageListViewController.tableView indexPathsForSelectedRows] count] ];;
    }
    
    NSString *cancelTitle = NSLocalizedString(@"Cancel", @"Cancel title for item removal action");
    NSString *okTitle = NSLocalizedString(@"OK", @"OK title for item removal action");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:actionTitle message:@"" preferredStyle:UIAlertControllerStyleAlert];
    __weak __typeof__(self) weakSelf = self;
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        __strong __typeof__(self) strongSelf = weakSelf;
        NSArray *selectedRows = [strongSelf->messageListViewController.tableView indexPathsForSelectedRows];
        NSMutableArray* selectedMessages = [[NSMutableArray alloc] init];
        for (NSIndexPath* sel in selectedRows) {
            [selectedMessages addObject:strongSelf->messageListViewController.listItems[sel.row]];
        }
        
        [[[GlobalRouter sharedManager] getListRouter].interactor needDeleteMessages:selectedMessages];
        
        for (ShortMessageEntity* item in selectedMessages) {
            [self deleteItemFromList:item];
        }
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
        // Other action
    }];
    [alert addAction:okAction];
    [alert addAction:cancelAction];
    
    [messageListViewController presentViewController:alert animated:YES completion:nil];
}

-(void)deleteAll
{
    // Confirm fist?
    NSString *actionTitle = NSLocalizedString(@"Are you sure you want to remove all items from the folder?", @"");
    
    NSString *cancelTitle = NSLocalizedString(@"No", @"Cancel title for item removal action");
    NSString *okTitle = NSLocalizedString(@"Yes", @"OK title for item removal action");
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:actionTitle message:@"" preferredStyle:UIAlertControllerStyleAlert];
    //__weak __typeof__(self) weakSelf = self;
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:okTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        //__strong __typeof__(self) strongSelf = weakSelf;
        
        [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
        [CommonProcs setSWLabelText:NSLocalizedString(@"Deleting...", nil)];
        
        [[[GlobalRouter sharedManager] getListRouter].interactor needDeleteAllMessagesFromFolder];
        [self clearListData];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
        // Other action
    }];
    [alert addAction:okAction];
    [alert addAction:cancelAction];
    
    [messageListViewController presentViewController:alert animated:YES completion:nil];
}

-(void)needActionForEdit
{
    NSString *actionTitle;
    if (([[messageListViewController.tableView indexPathsForSelectedRows] count] == 1)) {
        actionTitle = NSLocalizedString(@"Select action for an item", @"");
    }else{
        actionTitle = [NSString stringWithFormat:NSLocalizedString(@"Select action for %i items", @""),[[messageListViewController.tableView indexPathsForSelectedRows] count] ];;
    }
    
    NSString *cancelTitle = NSLocalizedString(@"Cancel",nil);
    //NSString *setUnreadTitle = NSLocalizedString(@"Mark as unread",nil);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:actionTitle message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    /*
    UIAlertAction *setUnreadAction = [UIAlertAction actionWithTitle:setUnreadTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        
        NSArray *selectedRows = [self->messageListViewController.tableView indexPathsForSelectedRows];
        NSMutableArray* selectedMessages = [[NSMutableArray alloc] init];
        for (NSIndexPath* sel in selectedRows) {
            [selectedMessages addObject:self->messageListViewController.listItems[sel.row]];
        }
        
        [[[GlobalRouter sharedManager] getListRouter].interactor needSetUnreadForMessages:selectedMessages];
        
    }];
    */
    __weak __typeof__(self) weakSelf = self;
    UIAlertAction *markReadAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Mark as read only",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        __strong __typeof__(self) strongSelf = weakSelf;
        NSArray *selectedRows = [strongSelf->messageListViewController.tableView indexPathsForSelectedRows];
        if(selectedRows.count > 0){
            NSMutableArray* selectedMessages = [[NSMutableArray alloc] init];
            for (NSIndexPath* sel in selectedRows) {
                ShortMessageEntity* item = strongSelf->messageListViewController.listItems[sel.row];
                [selectedMessages addObject:item];
                if(item.flags&mfNew)item.flags ^= mfNew;
            }
            
            [[[GlobalRouter sharedManager] getListRouter].interactor needSetReadForMessages:selectedMessages];
            [self updateList];
        }
    }];
    
    UIAlertAction *markUnreadAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Mark as unread",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        __strong __typeof__(self) strongSelf = weakSelf;
        NSArray *selectedRows = [strongSelf->messageListViewController.tableView indexPathsForSelectedRows];
        if(selectedRows.count > 0){
            NSMutableArray* selectedMessages = [[NSMutableArray alloc] init];
            for (NSIndexPath* sel in selectedRows) {
                ShortMessageEntity* item = strongSelf->messageListViewController.listItems[sel.row];
                [selectedMessages addObject:item];
                if(!(item.flags&mfNew))item.flags |= mfNew;
            }
            
            [[[GlobalRouter sharedManager] getListRouter].interactor needSetUnreadForMessages:selectedMessages];
            [self updateList];
        }
    }];
    UIAlertAction *setStarAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Set star",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        __strong __typeof__(self) strongSelf = weakSelf;
        NSArray *selectedRows = [strongSelf->messageListViewController.tableView indexPathsForSelectedRows];
        if(selectedRows.count > 0){
            NSMutableArray* selectedMessages = [[NSMutableArray alloc] init];
            for (NSIndexPath* sel in selectedRows) {
                //[selectedMessages addObject:self->messageListViewController.listItems[sel.row]];
                ShortMessageEntity* item = strongSelf->messageListViewController.listItems[sel.row];
                [selectedMessages addObject:item];
                item.flags |= mfFavourite;
            }
            
            [[[GlobalRouter sharedManager] getListRouter].interactor needSetStarForMessages:selectedMessages];
            [self updateList];
        }
    }];
    
    UIAlertAction *copyAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Copy to folder",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        __strong __typeof__(self) strongSelf = weakSelf;
        NSArray *selectedRows = [strongSelf->messageListViewController.tableView indexPathsForSelectedRows];
        if(selectedRows.count >0){
            NSMutableArray* selectedMessages = [[NSMutableArray alloc] init];
            for (NSIndexPath* sel in selectedRows) {
                //[selectedMessages addObject:self->messageListViewController.listItems[sel.row]];
                ShortMessageEntity* item = strongSelf->messageListViewController.listItems[sel.row];
                [selectedMessages addObject:item];
            }
            
            [[[GlobalRouter sharedManager] getListRouter].interactor needCopyMessages:selectedMessages];
            [self finishEditing:YES]; // someone restores the bottom panel, need to find out, but for the time being just go out of edit mode
        }
    }];
    
    UIAlertAction *moveAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Move to folder",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        __strong __typeof__(self) strongSelf = weakSelf;
        NSArray *selectedRows = [strongSelf->messageListViewController.tableView indexPathsForSelectedRows];
        if(selectedRows.count > 0){
            NSMutableArray* selectedMessages = [[NSMutableArray alloc] init];
            for (NSIndexPath* sel in selectedRows) {
                //[selectedMessages addObject:self->messageListViewController.listItems[sel.row]];
                ShortMessageEntity* item = strongSelf->messageListViewController.listItems[sel.row];
                [selectedMessages addObject:item];
            }
            
            [[[GlobalRouter sharedManager] getListRouter].interactor needMoveMessages:selectedMessages];
            [self finishEditing:YES]; // someone restores the bottom panel, need to find out, but for the time being just go out of edit mode
            
            // delete, ignoring error, a message with move error will be deleted from the list, but will appear on refresh
            for (ShortMessageEntity* item in selectedMessages) {
                [self deleteItemFromList:item];
            }
        }
    }];
    
    /*
    UIAlertAction *unsetStarAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Unset star",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        
        NSArray *selectedRows = [self->messageListViewController.tableView indexPathsForSelectedRows];
        NSMutableArray* selectedMessages = [[NSMutableArray alloc] init];
        for (NSIndexPath* sel in selectedRows) {
            [selectedMessages addObject:self->messageListViewController.listItems[sel.row]];
        }
        
    }];
     */
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        [self deleteSelected];
        
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
        // Other action
    }];
    [alert addAction:markReadAction];
    [alert addAction:markUnreadAction];
    [alert addAction:setStarAction];
    //[alert addAction:unsetStarAction];
    [alert addAction:copyAction];
    [alert addAction:moveAction];
    [alert addAction:deleteAction];
    [alert addAction:cancelAction];
    
    [messageListViewController presentViewController:alert animated:YES completion:nil];
}

/*
 
 -(void)movePanelRight {
	UIView *childView = [self getLeftView];
	[self.view sendSubviewToBack:childView];
 
	[UIView animateWithDuration:SLIDE_TIMING delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
 _centerViewController.view.frame = CGRectMake(self.view.frame.size.width - PANEL_WIDTH, 0, self.view.frame.size.width, self.view.frame.size.height);
 }
 completion:^(BOOL finished) {
 if (finished) {
 _centerViewController.leftButton.tag = 0;
 }
 }];
 }
 
 -(void)movePanelToOriginalPosition {
	[UIView animateWithDuration:SLIDE_TIMING delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
 _centerViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
 }
 completion:^(BOOL finished) {
 if (finished) {
 [self resetMainView];
 }
 }];
 }

 
*/

-(BOOL)isFetching
{
    return [[[GlobalRouter sharedManager] getListRouter] isFetching];
}

-(void)cleanUp
{
    self.requestedNextBatch = NO;
    messageListViewController = nil;
}

-(BOOL)isShowingMenu
{
    return showingMenu;
}

-(void)dismissMenu
{
    if (fvc) {
        [fvc closeView];
        fvc = nil;
        showingMenu = NO;
    }
}

-(int)getNewMessagesOnTheList
{
    int ret = 0;
    for (ShortMessageEntity* ms in messageListViewController.listItems) {
        if (ms.flags & mfNew) {
            ret++;
        }
    }
    return ret;
}

-(BOOL)isVCPresent
{
    return messageListViewController != nil;
}

-(void)shortcutSelected:(NSString *)shortcut
{
    NSString* command = [self.shortcuts valueForKey:shortcut];
    if (command.length == 1) {
        switch (command.intValue) {
            case scFavs:
                [self needShowFavs];
                break;
                
            case scSent:
                [self needShowSent];
                break;
                
            case scSpam:
            [self needShowSpam];
            break;
                
            default:
                break;
        }
    }else if ([command substringToIndex:1].intValue == scFilter){
        NSRange del = [command rangeOfString:@"\n"];
        if(del.location != NSNotFound){
            NSString* searchType = [command substringWithRange:NSMakeRange(1, del.location-1)];
            NSString* searchText = [command substringFromIndex:del.location+1];
            NSLog(@"Path & box = %@ at %@", searchType, searchText);
            SearchInteractor* sint = [[SearchInteractor alloc] init];
            [sint searchWithType:searchType.intValue text:searchText];
        }else{
            // Search the string
            NSString* search = [command substringFromIndex:1];
            [[GlobalRouter sharedManager] needSearchWithString:search];
        }
        
    }else if ([command substringToIndex:1].intValue == scCustomFolder){
        NSRange del = [command rangeOfString:@"\n"];
        if(del.location != NSNotFound){
            NSString* customPath = [command substringWithRange:NSMakeRange(1, del.location-1)];
            NSString* box = [command substringFromIndex:del.location+1];
            NSLog(@"Path & box = %@ at %@", customPath, box);
            [GlobalRouter sharedManager].currentBoxPath = customPath;
            [GlobalRouter sharedManager].currentBox = btUseName;
            [GlobalRouter sharedManager].currentAccount = box;
            [CommonProcs spawnProcWithProgress:@selector(needShowOtherBox) object:self withParam:nil];
        }
    }
}

-(void)showShortcutBar
{
    //[messageListViewController showShortcutBar];
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        return;
    }
    if ([GlobalRouter sharedManager].showShortcuts) {
        if ((messageListViewController.shortcutBarHeightConstraint.constant > 10 || messageListViewController.shortcutBarStack.subviews.count > 0) && !self.updateShortcutBar) {
            return;
        }
        self.updateShortcutBar = NO;
        
        for (UIView* sbv in messageListViewController.shortcutBarStack.subviews) {
            [messageListViewController.shortcutBarStack removeArrangedSubview:sbv];
            [sbv removeFromSuperview];
        }
        
        UserInfoDataManager* man = [[UserInfoDataManager alloc] init];
        NSMutableArray* shortcuts = [man getShortcuts:[GlobalRouter sharedManager].pin];
        if (shortcuts.count == 0) {
            messageListViewController.shortcutBarHeightConstraint.constant = 0;
            return;
        }
        for (ShortcutEntity* item in shortcuts) {
            [messageListViewController addShortcutButtonWithTitle:item.shortcutName command:item.shortcutCommand];
        }
        messageListViewController.shortcutBarHeightConstraint.constant = 30;
        
        /*
        [messageListViewController addShortcutButtonWithTitle:NSLocalizedString(@"Spam",nil) command:[NSString stringWithFormat:@"%li", (long)scSpam]];
        
        // Search command format: scFilter+stSearchType+\n+Search string
        // For example search before 11/11/2011 = scFilter+stDateBefore+\n+@"11/11/2011"
        [messageListViewController addShortcutButtonWithTitle:NSLocalizedString(@"Last Week",nil) command:[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stLastWeek, @""]];
        
        // Shortcut to a folder has the following format: scCustomFolder+FolderName+\n+Email Address - NOTE that Email Address should be the account name, but it could be changed by the user and the command going to be invalid...
        [messageListViewController addShortcutButtonWithTitle:NSLocalizedString(@"MEGA",nil) command:[NSString stringWithFormat:@"%li%@\n%@", (long)scCustomFolder, @"TETS", @"dac12890@yahoo.com"]];
        [messageListViewController addShortcutButtonWithTitle:NSLocalizedString(@"Mapping",nil) command:[NSString stringWithFormat:@"%li%@", (long)scFilter, @"mapping"]];
        [messageListViewController addShortcutButtonWithTitle:NSLocalizedString(@"Mapping2",nil) command:[NSString stringWithFormat:@"%li%ld\n%@", (long)scFilter, (long)stUserInput, @"mapping"]];
        [messageListViewController addShortcutButtonWithTitle:NSLocalizedString(@"Starred",nil) command:[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stFlagged, @""]];
         */
    }else{
        // Check for nil!!! Looks like not needed any more
        if (messageListViewController.shortcutBarHeightConstraint == nil) {
            self.updateShortcutBar = YES;
        }else{
            self.updateShortcutBar = NO;
        }
        if (messageListViewController.shortcutBarHeightConstraint.constant == 0) {
            //return;
        }
        messageListViewController.shortcutBarHeightConstraint.constant = 0;
        for (UIView* sbv in messageListViewController.shortcutBarStack.subviews) {
            [messageListViewController.shortcutBarStack removeArrangedSubview:sbv];
            [sbv removeFromSuperview];
        }
        
    }
}


@end
