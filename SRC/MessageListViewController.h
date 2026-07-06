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

@class  ListPresenter;

@interface MessageListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate> //UITableViewController
{
    dispatch_block_t alertBlock;
}
@property (nonatomic, strong) UITableViewController* tableController;
@property (nonatomic, strong) UIRefreshControl* refreshControl;
@property (nonatomic) NSMutableArray* listItems;
@property (nonatomic, weak) ListPresenter* presenter;

@property (nonatomic) IBOutlet UITableView* tableView;
@property (nonatomic) IBOutlet UIToolbar* toolBar;
@property (nonatomic) IBOutlet UIBarButtonItem* selfDestroyButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* moreButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* moreFolders;

@property (nonatomic, strong) NSString* filterFrom;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)stopRefreshing;

-(IBAction)exitApp:(id)sender;
-(IBAction)markFavourite:(id)sender;
-(IBAction)checkMail:(id)sender;
-(IBAction)newMessage:(id)sender;
-(IBAction)showSettings:(id)sender;
-(IBAction)search:(id)sender;
-(IBAction)showHelp:(id)sender;
-(IBAction)showMoreActions:(id)sender;

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

-(void)askAndDoWithTitle:(NSString*)title text:(NSString*)alertText block:(dispatch_block_t)block;

-(void)didSelectItem:(NSString*)item title:(NSString*)title;

@end

