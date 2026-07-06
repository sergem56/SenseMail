//
//  FirstViewController.h
//  SenseMail2
//
//  Created by Sergey on 05.02.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "ListPresenter.h"
#import "ShortMessageEntity.h"
//#import "SwipeableCell.h"
#import "CommonProcs.h"

@class  ListPresenter;
#if !LITE
@class OneTimeCertInteractor;
#endif

@interface MessageListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate> //UITableViewController
{
    dispatch_block_t alertBlock;
    BOOL updating;
    UIActivityIndicatorView* loadingCell;
    CommonProcs* cp;
}
@property (nonatomic, strong) UITableViewController* tableController;
@property (nonatomic, strong) UIRefreshControl* refreshControl;
@property (nonatomic) NSMutableArray* listItems;
@property (nonatomic, weak) ListPresenter* presenter;
@property (nonatomic, strong) NSIndexPath* currentIndex;

@property (nonatomic) IBOutlet UITableView* tableView;
@property (nonatomic) IBOutlet UIToolbar* toolBar;
@property (nonatomic) IBOutlet UIBarButtonItem* selfDestroyButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* moreButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* moreFolders;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* notesButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* galleryButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* exitButton;

@property (nonatomic, strong) NSString* filterFrom;
@property (nonatomic, assign) BOOL largeFont;

@property (nonatomic) IBOutlet NSLayoutConstraint* shortcutBarHeightConstraint;
@property (nonatomic) IBOutlet UIView* shortcutBar;
@property (nonatomic) IBOutlet UIStackView* shortcutBarStack;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)stopRefreshing;

-(IBAction)exitApp:(id)sender;
-(IBAction)markFavourite:(id)sender;
-(IBAction)filterSender:(id)sender;
-(IBAction)checkMail:(id)sender;
-(IBAction)newMessage:(id)sender;
-(IBAction)showSettings:(id)sender;
-(IBAction)search:(id)sender;
-(IBAction)showHelp:(id)sender;
//-(IBAction)showMoreActions:(id)sender;

//Tabbar
-(IBAction)showInbox:(id)sender;
-(IBAction)showSent:(id)sender;
-(IBAction)showFavs:(id)sender;
-(IBAction)showSpam:(id)sender;
-(IBAction)sos:(id)sender;
-(IBAction)showBook:(id)sender;
-(IBAction)showGallery:(id)sender;
-(IBAction)otherFolders:(id)sender;
-(IBAction)showNotes:(id)sender;

-(void)showError:(NSString*)error;

//-(void)askAndDoWithTitle:(NSString*)title text:(NSString*)alertText block:(dispatch_block_t)block;
//-(void)askAndDoWithTitle:(NSString*)title text:(NSString*)alertText block:(dispatch_block_t)block showInput:(BOOL)showInput;

-(void)didSelectItem:(NSString*)item title:(NSString*)title;

-(void)menuWasDismissed;

-(void)updateLastCell;
-(void)setCurrentIndexToCell:(UITableViewCell*)cell;
-(NSString*)getBoxName;
//-(void)showShortcutBar;
-(void)addShortcutButtonWithTitle:(NSString*)title command:(NSString*)command;

@end

