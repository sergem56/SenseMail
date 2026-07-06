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
#import "CommonProcs.h"

@implementation ListPresenter

@synthesize noNeedForMore;

-(MessageListViewController*)showListOfType:(boxTypes)type
{
    // Get the list from interactor and pass it to view controller
    //
    //ListInteractor* lin = [[ListInteractor alloc] init];
    //[lin getMessagesForBox:type];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [messageListViewController.listItems removeAllObjects];
        [messageListViewController.tableView reloadData];
        [GlobalRouter sharedManager].totalMessages = 0;
        
        //[CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Loading...", nil) stopButton:YES];
    });
    
    [[[GlobalRouter sharedManager] getListRouter].interactor requestMessagesForBox:type];
    
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

-(void)setList:(NSArray *)list error:(NSString*)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs hideProgress];
        if ([error isEqualToString:@""] || error == nil) {
            if(messageListViewController.listItems == nil){
                messageListViewController.listItems = [NSMutableArray arrayWithArray:list];
            }else{
                [messageListViewController.listItems addObjectsFromArray: [NSMutableArray arrayWithArray:list]];
                
                NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
                NSArray* tmp = [messageListViewController.listItems sortedArrayUsingDescriptors:@[sort]];
                messageListViewController.listItems = [NSMutableArray arrayWithArray:tmp];
            }
            [self updateList];
        }else if([error isEqualToString:NSLocalizedString(@"No more messages", nil)]){
            [messageListViewController showError:error];
        }else{
            //messageListViewController.listItems = [[NSMutableArray alloc]init];
            //[self updateList];
            [messageListViewController showError:error];
        }
        
        [messageListViewController stopRefreshing];
    });
}

-(void)updateList
{
    [messageListViewController.tableView reloadData];
}

-(BOOL)deleteItem:(ShortMessageEntity *)item
{
    [[[GlobalRouter sharedManager] getListRouter].interactor needDeleteMessage:item];
    [messageListViewController.listItems removeObject:item];
    return YES;
}

-(void)deleteItemFromList:(ShortMessageEntity*)item
{
    for (ShortMessageEntity* ent in messageListViewController.listItems) {
        if (ent.messageID == item.messageID) {
            [messageListViewController.listItems removeObject:ent];
            [GlobalRouter sharedManager].totalMessages--;
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
        }
    }
    if (needUpdate) {
        [self updateList];
    }
}

-(void)showMessageItem:(ShortMessageEntity *)item
{
    [[GlobalRouter sharedManager] needShowMessage:item];
}

-(void)exitPressed
{
    [CommonProcs showWheelinView:[[GlobalRouter sharedManager] getCurrentView]  message:NSLocalizedString(@"Cleaning up...", nil) stopButtonVisible:NO];
    [DataManager deleteTempFiles];
    if([GlobalRouter sharedManager].keepInBg){
        [[UIApplication sharedApplication] performSelector:@selector(suspend)];
        [CommonProcs hideProgress];
    }else{
        exit(0);
    }
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [messageListViewController.listItems removeAllObjects];
        [messageListViewController.tableView reloadData];
        [CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Loading...", nil) stopButton:YES];
    });
    
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

// Nav bar
-(void)needShowInbox
{
    [[GlobalRouter sharedManager] needShowInbox];
}

-(void)needShowSent
{
    [[GlobalRouter sharedManager] needShowSent];
}

-(void)needShowFavs
{
    [[GlobalRouter sharedManager] needShowFavs];
}

-(void)needShowSpam
{
    [[GlobalRouter sharedManager] needShowSpam];
}

-(void)needShowOtherBox
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [messageListViewController.listItems removeAllObjects];
        [messageListViewController.tableView reloadData];
        [GlobalRouter sharedManager].totalMessages = 0;
    });
    [[GlobalRouter sharedManager] needShowOtherBox];
}

-(void)sos
{
    [[GlobalRouter sharedManager] sos];
}

-(void)search
{
    [messageListViewController askAndDoWithTitle:NSLocalizedString(@"Find messages", nil) text:NSLocalizedString(@"Enter sender address", nil) block:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [messageListViewController.listItems removeAllObjects];
            [messageListViewController.tableView reloadData];
        });
        [[[GlobalRouter sharedManager] getListRouter].interactor requestMessagesForBoxWithFilter :[GlobalRouter sharedManager].currentBox filter:messageListViewController.filterFrom];
    }];
    //[[GlobalRouter sharedManager] needSearch];
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
    [messageListViewController.tableView reloadData];
    [GlobalRouter sharedManager].currentBox = btEmpty;
}

@end
