//
//  ListPresenter.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIViewController.h>
#import "MessageListViewController.h"
//#import "MessageList.h"
#import "CommonStuff.h"
#import "ShortMessageEntity.h"

@class FoldersTableViewController;

@interface ListPresenter : NSObject{
    MessageListViewController* messageListViewController;
    //boxTypes currentBox;
    BOOL showingMenu;
    NSArray* savedTopToolbarItems;
    NSArray* savedBottomToolbarItems;
    //BOOL updateRequested;
    FoldersTableViewController* fvc;
    long lastKnownMessageNumber;
}

//@property (nonatomic) MessageListViewController* messageViewController;

@property (nonatomic, assign) BOOL updateRequested;
@property (nonatomic, assign) BOOL noNeedForMore;
//@property (nonatomic, assign) BOOL sortedByDate;
@property (nonatomic, assign) sortType sortType; // by date, new first, by sender

@property (nonatomic, strong) NSMutableDictionary* boxColors;

@property (nonatomic, strong) UIBarButtonItem* selectAllButton;
@property (nonatomic, assign) BOOL requestedNextBatch;

@property (nonatomic, strong) NSMutableDictionary* shortcuts;
@property (nonatomic, assign) BOOL updateShortcutBar;

-(MessageListViewController*)showListOfType:(boxTypes)type;

-(void)setList:(NSArray*)list error:(NSString*)error;
-(void)updateList;
-(void)updateItemsFlags:(ShortMessageEntity*)item;

-(BOOL)deleteItem:(ShortMessageEntity*)item;
-(void)deleteItemFromList:(ShortMessageEntity*)item;
-(void)showMessageItem:(ShortMessageEntity*)item;

-(void)exitPressed;
-(void)markMessageFavourite:(ShortMessageEntity*)item;
-(void)checkMail;
-(void)newMessage;
-(void)showSettings;
-(void)search;
-(void)doSearchWithString:(NSString*)searchStr;
-(void)showHelp;
-(void)showPP;

-(void)needShowInbox;
-(void)needShowSent;
-(void)needShowFavs;
-(void)needShowSpam;
-(void)sos;
-(void)needShowMenu;
-(void)menuWasDismissed;

-(void)needShowOtherBox;

-(void)needMoreMessages;
-(void)setNoNeed:(BOOL)bNoNeedForMore;

-(void)needEditList;
-(void)finishEditing:(BOOL)cancel;

//-(void)tellUpNoMoreButton;

-(void)clearList;
-(void)refreshList;

-(void)stopRefreshing;

-(ShortMessageEntity*)getNextShortMessageFor:(ShortMessageEntity*)item;
-(ShortMessageEntity*)getPrevShortMessageFor:(ShortMessageEntity*)item;

-(void)refreshTableHeaderAnimated:(BOOL)animated;
-(void)sortListbyDate;

-(NSString*)getFilterString;
-(void)clearFilter;

-(BOOL)isFetching;
-(void)cleanUp;

-(BOOL)isShowingMenu;
-(void)dismissMenu;

-(int)getNewMessagesOnTheList;

-(BOOL)isVCPresent;

-(void)shortcutSelected:(NSString*)shortcut;

-(void)showShortcutBar;

@end
