//
//  FirstViewController.m
//  SenseMail2
//
//  Created by Sergey on 05.02.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "MessageListViewController.h"
#import "ShortMessageEntity.h"
#import "GlobalRouter.h"
#import "CommonProcs.h"
//#import "TableSelectViewController.h"
#import "FolderInfo.h"
#import "DetailViewController.h"
#import "FoldersTableViewController.h"
//#import "SwipeableCell.h"
#import "WindowMinimizer.h"
#import "Encryptor.h"

#import "WelcomeContentViewController.h"
#if !LITE
#import "OneTimeCertInteractor.h"
#import "OneTimeCert.h"
#endif

#import "DataManager.h"

@interface MessageListViewController ()
{
    
}
@end

@implementation MessageListViewController

@synthesize listItems, refreshControl, filterFrom, largeFont;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    // Initialize the refresh control (via table view controller)
    self.tableController = [[UITableViewController alloc] init];
    [self addChildViewController:self.tableController];
    self.tableController.tableView = self.tableView;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    if (@available(iOS 13.0, *)) {
        self.refreshControl.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        // Fallback on earlier versions
        self.refreshControl.backgroundColor = [UIColor whiteColor];
    }
    self.refreshControl.tintColor = [UIColor colorWithRed:166/255.0 green:177/255.0 blue:186/255.0 alpha:1.0];//[UIColor  blueColor];
    [self.refreshControl addTarget:self
                            action:@selector(checkMail:)
                  forControlEvents:UIControlEventValueChanged];
    self.tableController.refreshControl = refreshControl;
    
    self.filterFrom = @"";
    
    //self.title = @"Messages";
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back",nil) style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backButton;
    
    //self.navigationController.delegate = self;
    
    /*
    for (int i=0; i<5; i++) {
        NSLog(@"%@",[Encryptor generatePassword:3]);
    }
    */
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // change last two icons to sent and spam
        [self.notesButton setAction:@selector(showSent:)];
        [self.notesButton setImage:[UIImage imageNamed:@"outboxCircle"]];
        
        [self.galleryButton setAction:@selector(showSpam:)];
        [self.galleryButton setImage:[UIImage imageNamed:@"spamCircle"]];
        
        NSMutableArray* buttons = [self.toolBar.items mutableCopy];
        UIBarButtonItem *barButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"split"]
                                                                           style:UIBarButtonItemStylePlain target:self action:@selector(showMaster)];
        [buttons replaceObjectAtIndex:[buttons indexOfObject:self.exitButton] withObject:barButtonItem];
        
        self.toolBar.items = buttons;
        //[self.exitButton setAction:@selector(showMaster)];
        //[self.exitButton setImage:[UIImage imageNamed:@"split"]];
    }
    
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    
    UISwipeGestureRecognizer* openMenuGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(otherFolders:)];
    openMenuGesture.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:openMenuGesture];
    
#pragma mark Shortcut bar
    self.shortcutBarHeightConstraint.constant = 0;
    //[self.presenter showShortcutBar];
    /*
    if ([GlobalRouter sharedManager].showShortcuts) {
        self.shortcutBarHeightConstraint.constant = 30;
        [self addShortcutButtonWithTitle:NSLocalizedString(@"Spam",nil) command:[NSString stringWithFormat:@"%li", (long)scSpam]];
        
        // Search command format: scFilter+stSearchType+\n+Search string
        // For example search before 11/11/2011 = scFilter+stDateBefore+\n+@"11/11/2011"
        [self addShortcutButtonWithTitle:NSLocalizedString(@"Last Week",nil) command:[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stLastWeek, @""]];
        
        // Shortcut to a folder has the following format: scCustomFolder+FolderName+\n+Email Address - NOTE that Email Address should be the account name, but it could be changed by the user and the command going to be invalid...
        [self addShortcutButtonWithTitle:NSLocalizedString(@"MEGA",nil) command:[NSString stringWithFormat:@"%li%@\n%@", (long)scCustomFolder, @"TETS", @"dac12890@yahoo.com"]];
        [self addShortcutButtonWithTitle:NSLocalizedString(@"Mapping",nil) command:[NSString stringWithFormat:@"%li%@", (long)scFilter, @"mapping"]];
    }else{
        self.shortcutBarHeightConstraint.constant = 0;
    }*/
}
/* // Moved it to presenter
-(void)showShortcutBar
{
    if ([GlobalRouter sharedManager].showShortcuts) {
        if (self.shortcutBarHeightConstraint.constant > 10) {
            return;
        }
        self.shortcutBarHeightConstraint.constant = 30;
        
        [self addShortcutButtonWithTitle:NSLocalizedString(@"Spam",nil) command:[NSString stringWithFormat:@"%li", (long)scSpam]];
        
        // Search command format: scFilter+stSearchType+\n+Search string
        // For example search before 11/11/2011 = scFilter+stDateBefore+\n+@"11/11/2011"
        [self addShortcutButtonWithTitle:NSLocalizedString(@"Last Week",nil) command:[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stLastWeek, @""]];
        
        // Shortcut to a folder has the following format: scCustomFolder+FolderName+\n+Email Address - NOTE that Email Address should be the account name, but it could be changed by the user and the command going to be invalid...
        [self addShortcutButtonWithTitle:NSLocalizedString(@"MEGA",nil) command:[NSString stringWithFormat:@"%li%@\n%@", (long)scCustomFolder, @"TETS", @"dac12890@yahoo.com"]];
        [self addShortcutButtonWithTitle:NSLocalizedString(@"Mapping",nil) command:[NSString stringWithFormat:@"%li%@", (long)scFilter, @"mapping"]];
    }else{
        if (self.shortcutBarHeightConstraint.constant == 0) {
            return;
        }
        self.shortcutBarHeightConstraint.constant = 0;
        for (UIView* sbv in self.shortcutBarStack.subviews) {
            [self.shortcutBarStack removeArrangedSubview:sbv];
            [sbv removeFromSuperview];
        }
        
    }
}*/

-(void)addShortcutButtonWithTitle:(NSString*)title command:(NSString*)command
{
    /*UIButton* testButton2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [testButton2 setTitle:title forState:UIControlStateNormal];
    [testButton2 setFrame:CGRectMake(2, 1, 60, 28)];
    [testButton2.titleLabel setFont:[UIFont systemFontOfSize:11]];
    [testButton2 addTarget:self action:@selector(shortcut:) forControlEvents:UIControlEventTouchUpInside];*/
    
    if(!title)return;
    
    UILabel* testButton2 = [[UILabel alloc] init];
    testButton2.adjustsFontSizeToFitWidth = YES;
    testButton2.minimumScaleFactor = 0.4;
    [testButton2 setText:title];
    [testButton2 setFrame:CGRectMake(2, 1, 60, 28)];
    [testButton2 setFont:[UIFont systemFontOfSize:11]];
    testButton2.textAlignment = NSTextAlignmentCenter;
    testButton2.userInteractionEnabled = YES;
    UITapGestureRecognizer* tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(shortcut:)];
    [testButton2 addGestureRecognizer:tapper];
    [[testButton2 layer] setCornerRadius:2.0f];
    [[testButton2 layer] setMasksToBounds:YES];
    [[testButton2 layer] setBorderWidth:0.35f];
    [[testButton2 layer] setBorderColor:[UIColor lightGrayColor].CGColor];
    [self.shortcutBarStack addArrangedSubview:testButton2];
    
    if (!self.presenter.shortcuts) {
        self.presenter.shortcuts = [[NSMutableDictionary alloc] init];
    }
    [self.presenter.shortcuts setValue:command forKey:title];
}

-(void)shortcut:(UITapGestureRecognizer*)sender
{
    NSString* text = ((UILabel*)(sender.view)).text;
    NSLog(@"Button pressed %@", text);
    [self.presenter shortcutSelected:text];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    if (self.tableView.isEditing) {
        return;
    }
    // There's a strange bug - sometimes refresh control doesn't dissapear when a view appears
    [self.refreshControl endRefreshing];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    updating = NO;
    
    // Move it to initialPush? As it's being called every time the view appears
    if(![GlobalRouter notInited] && [GlobalRouter sharedManager].thisIsTheFirstRun){
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"welcome" bundle:nil];
        WelcomeContentViewController *wcvc = [sb instantiateViewControllerWithIdentifier:@"Welcome01"];
        
        //[self presentViewController:wcvc animated:YES completion:nil];
        [[[GlobalRouter sharedManager] getTopViewController] presentViewController:wcvc animated:YES completion:nil];
        
        //[GlobalRouter sharedManager].thisIsTheFirstRun = NO;
        [GlobalRouter sharedManager].waitingForPin = NO;
    }
    
    if ([GlobalRouter sharedManager].currentFilter == nil || [[GlobalRouter sharedManager].currentFilter isEqualToString:@""]) {
        self.filterFrom = @"";
    }
    
    largeFont = [[GlobalRouter sharedManager] getListRouter].largeFont;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.presenter.updateShortcutBar = YES;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if(self.navigationController && ![GlobalRouter sharedManager].goingToBG){
        if (![self.navigationController.viewControllers containsObject:self]) {
            // Seems to pop it off, need to push it back
            NSLog(@"Going to be the error! Popping off!!!!!\n!!!!!!!!!!!!!!!!!!!!!!!!!!");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[[GlobalRouter sharedManager] getListRouter] showListInNavController:self.navigationController forBox:btInbox];
            });
        }
    }
}

/*
-(void)viewDidAppear:(BOOL)animated
{
    // On iPad in landscape mode this is not called at start-up...
    if([GlobalRouter sharedManager].thisIsTheFirstRun){
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"welcome" bundle:nil];
        WelcomeContentViewController *wcvc = [sb instantiateViewControllerWithIdentifier:@"Welcome01"];
        [self presentViewController:wcvc animated:YES completion:nil];
        
        [GlobalRouter sharedManager].thisIsTheFirstRun = NO;
        [GlobalRouter sharedManager].waitingForPin = NO;
    }
}
*/

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
// #warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
// #warning Incomplete method implementation.
    // Return the number of rows in the section.
    if (section == 1) {
        return 1;
    }
    return listItems.count;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if (section == 0 && !(filterFrom == nil || [filterFrom isEqualToString:@""])) {
        if ([view.subviews.lastObject isKindOfClass:[UIButton class]]) {
            return;
        }
        UIButton *button = [[UIButton alloc] init];
        button.frame = CGRectMake(view.frame.size.width - 20.0, 0, 20.0, view.frame.size.height); // x,y,width,height
        [button setTitle:@"✕" forState:UIControlStateNormal];
        [button addTarget:self action:@selector(deleteFilter:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:button];
    }
}

-(void)deleteFilter:(id)sender
{
    filterFrom = @"";
    [GlobalRouter sharedManager].currentFilter = @"";
    [self checkMail:nil];
}

#pragma mark - SwipeableCellDelegate
- (void)buttonOneActionForItemText:(NSString *)itemText inRect:(CGRect)inRect
{
    // delete message
    ShortMessageEntity* toRemove = (ShortMessageEntity*)[self.listItems objectAtIndex:self.currentIndex.row];
    
    //GlobalRouter* gr = (GlobalRouter*)[GlobalRouter sharedManager];
    if([self.presenter deleteItem:toRemove]){
        [self.tableView deleteRowsAtIndexPaths:@[self.currentIndex] withRowAnimation:UITableViewRowAnimationFade];
        [GlobalRouter sharedManager].totalMessages--;
        
        // Update header
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self updateHeader0];
        });
        
        self.currentIndex = nil;
    }
}

-(void)updateHeader0
{
    // This is slow... but works.
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)buttonTwoActionForItemText:(NSString *)itemText inRect:(CGRect)inRect
{
    // show menu - this is already in messageviewpresenter+messageviewcontroller
    //[[GlobalRouter sharedManager] getMessageRouter]
    if (!cp) {
        cp = [[CommonProcs alloc] init];
    }
    
    [cp wantMoveMessage:[self.listItems objectAtIndex:self.currentIndex.row] fromRect:inRect canForward:NO fromView:self.view fromVC:self];
}

-(void)setCurrentIndexToCell:(UITableViewCell*)cell
{
    self.currentIndex = [self.tableView indexPathForCell:cell];
}

#pragma mark - ----------------

-(void)setStringWithIcon:(NSString*)string icon:(UIImage*)icon toLabel:(UILabel*)label
{
    NSTextAttachment *imageAttachment = [[NSTextAttachment alloc] init];
    imageAttachment.image = icon;
    int imageHeight = 20;
    CGFloat imageOffsetY = -(imageHeight - label.font.pointSize)/2.0; //-5.0;
    imageAttachment.bounds = CGRectMake(0, imageOffsetY, imageHeight, imageHeight);
    //CGFloat imageOffsetY = -(icon.size.height - label.font.pointSize)/2.0; //-5.0;
    //imageAttachment.bounds = CGRectMake(0, imageOffsetY, imageAttachment.image.size.width, imageAttachment.image.size.height);
    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:imageAttachment];
    NSMutableAttributedString *completeText= [[NSMutableAttributedString alloc] initWithString:@""];
    [completeText appendAttributedString:attachmentString];
    NSMutableAttributedString *textAfterIcon= [[NSMutableAttributedString alloc] initWithString:string];
    [completeText appendAttributedString:textAfterIcon];
    label.textAlignment=NSTextAlignmentLeft;
    label.attributedText=completeText;
}


 // to try this code instead of a swipable cell
 -(NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
 
     ShortMessageEntity* mes = self.listItems[indexPath.row];
     NSString* titleRead = mes.flags & mfNew?NSLocalizedString(@"Mark\nread",nil):NSLocalizedString(@"Mark\nunread",nil);
     UITableViewRowAction *readAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:titleRead handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
         //NSLog(@"More");
         self.currentIndex = indexPath;
         // Get the screen rect of the cell
         [[[GlobalRouter sharedManager] getListRouter].manager markAsRead:mes];
         mes.flags ^= mfNew;
         if (mes.flags & mfNew) {
             // we set the flag
             [GlobalRouter sharedManager].newMessages++;
             [GlobalRouter sharedManager].newMessagesTotal++;
         }else{
             [GlobalRouter sharedManager].newMessages--;
             [GlobalRouter sharedManager].newMessagesTotal--;
         }
         [[GlobalRouter sharedManager] updateCurrentList];
     }];
     readAction.backgroundColor = [UIColor blueColor];
     
     UITableViewRowAction *editAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleNormal title:NSLocalizedString(@"More...",nil) handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
         //NSLog(@"More");
         self.currentIndex = indexPath;
         // Get the screen rect of the cell
         [self buttonTwoActionForItemText:@"" inRect:[self.tableView convertRect:[self.tableView rectForRowAtIndexPath:indexPath] toView:[self.tableView superview]]];
     }];
     editAction.backgroundColor = [UIColor lightGrayColor];
     
     UITableViewRowAction *deleteAction = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDestructive title:NSLocalizedString(@"Delete",nil)  handler:^(UITableViewRowAction *action, NSIndexPath *indexPath){
         //NSLog(@"Delete");
         self.currentIndex = indexPath;
         [self buttonOneActionForItemText:@"" inRect:CGRectZero];
     }];
     //deleteAction.backgroundColor = [UIColor redColor];
     return @[readAction, editAction, deleteAction];
 }


 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
 
 // Configure the cell...
     //SwipeableCell *cell;
     UITableViewCell* cell;
     
     //largeFont = YES;
     if (indexPath.row == 1 && self.presenter.updateShortcutBar) {
         [self.presenter showShortcutBar];
         
     }
     
     if (indexPath.section == 0){
         ShortMessageEntity* item = (ShortMessageEntity*)[self.listItems objectAtIndex:indexPath.row];
         if (item.fromAddress == nil) {
             cell = [tableView dequeueReusableCellWithIdentifier:@"PageCell"];
             /*if (cell == nil) {
                 cell = [[SwipeableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PageCell"];
             }*/
             return cell;
         }

         static NSString *CellIdentifier = @"MessageListTableViewCell";
         
         cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
         if (cell == nil) {
             cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
         }
         
         //cell.delegate = self;
         
         // Reset cell
         UIImageView* att = (UIImageView*)[cell.contentView viewWithTag:2];
         att.hidden = NO;
         att = (UIImageView*)[cell.contentView viewWithTag:1];
         att.hidden = NO;
         
         //ShortMessageEntity* item = (ShortMessageEntity*)[self.listItems objectAtIndex:indexPath.row];
         
         UILabel *name = (UILabel *)[cell.contentView viewWithTag:10];
         // Show encryption mark
         NSString* nameString;
         if ([item.fromName isEqualToString:@""] || item.fromName == nil) {
             nameString = item.fromAddress;
         }else{
             nameString = item.fromName;
         }
         
         //NSString* mark = @"";
         if (item.encType == enTypeCertificate || item.encType == enTypeMutableCertificate) {
             //mark = @"🔐";
             [name setTextColor:[UIColor colorWithRed:0 green:100.0/255 blue:0 alpha:1]];
             [name setText:nameString];
             //[name setText:[NSString stringWithFormat:@"%@%@",mark,nameString]];
             [name setTextAlignment:NSTextAlignmentLeft];
         }else if(item.encType == enTypeNone) {
             //mark = @"👁";
             [name setTextColor:[UIColor grayColor]];
             [name setText:nameString];
             //[name setText:[NSString stringWithFormat:@"%@%@",mark,nameString]];
             [name setTextAlignment:NSTextAlignmentLeft];
         }else if(item.encType == enTypeOTC){
#if !LITE
             if (@available(iOS 13.0, *)) {
                 [name setTextColor:[UIColor labelColor]];
             } else {
                 // Fallback on earlier versions
                 [name setTextColor:[UIColor blackColor]];
             }
             if (item.expireOTCon == nil || [item.expireOTCon isEqualToString:@""]) {
                 [self setStringWithIcon:nameString icon:[UIImage imageNamed:@"doubleLock"] toLabel:name];
             }else{
                 if([[OneTimeCert getDateForString:item.expireOTCon] compare:[NSDate date]] == NSOrderedAscending){
                     
                     if (item.flags & mfNew) {
                         [self setStringWithIcon:nameString icon:[UIImage imageNamed:@"doubleLockOffRed"] toLabel:name];
                     }else{
                         [self setStringWithIcon:nameString icon:[UIImage imageNamed:@"doubleLockOff"] toLabel:name];
                     }
                     
                     //[self setStringWithIcon:nameString icon:[UIImage imageNamed:@"doubleLockOff"] toLabel:name];
                 }else{
                     // Not expired yet
                    [self setStringWithIcon:nameString icon:[UIImage imageNamed:@"doubleLockExp"] toLabel:name];
                 }
             }
#endif
         }else{
             //mark = @"🔒 ";
             //[name setTextColor:[UIColor blackColor]];
             if (@available(iOS 13.0, *)) {
                 [name setTextColor:[UIColor labelColor]];
             } else {
                 // Fallback on earlier versions
                 [name setTextColor:[UIColor blackColor]];
             }
             if(nameString){
                 if(item.expireOTCon && ![item.expireOTCon isEqualToString:@""]){
                     [self setStringWithIcon:nameString icon:[UIImage imageNamed:@"lockExp"] toLabel:name];
                 }else{
                     [self setStringWithIcon:nameString icon:[UIImage imageNamed:@"lock"] toLabel:name];
                 }
             }
         }
         //[name setText:[NSString stringWithFormat:@"%@%@",mark,nameString]];
         if(largeFont){
             [name setFont:[UIFont systemFontOfSize:18 weight:UIFontWeightSemibold]];
         }else{
             [name setFont:[UIFont systemFontOfSize:13 weight:UIFontWeightSemibold]];
         }
         
         UILabel *subj = (UILabel *)[cell.contentView viewWithTag:11];
         [subj setText:item.subject];
         if(largeFont){
             [self.tableView setRowHeight:130];
             [subj setFont:[UIFont systemFontOfSize:18 weight:UIFontWeightSemibold]];
         }else{
             [self.tableView setRowHeight:90];
             [subj setFont:[UIFont systemFontOfSize:14 weight:UIFontWeightSemibold]];
         }
         //subj.numberOfLines = 0;
         //[subj sizeToFit];
         
         UILabel *addrr = (UILabel *)[cell.contentView viewWithTag:12];
         NSString* addrText = [NSString stringWithFormat:@"to %@ from %@", item.settingsID, item.fromAddress];
         [addrr setText:addrText];
         if(largeFont){
             [addrr setFont:[UIFont systemFontOfSize:16]];
         }else{
             [addrr setFont:[UIFont systemFontOfSize:13]];
         }
         //[cell setBackgroundColor:[self.presenter.boxColors objectForKey:item.settingsID]];
         
         UILabel *dateLbl = (UILabel *)[cell.contentView viewWithTag:13];
         /*
         NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
         [dateFormatter setDateFormat:@"dd.MM.YY HH:mm"];
         NSString *dateString = [dateFormatter stringFromDate:item.date];
         */
         // Make date-time string as a user preffer
         static NSDateFormatter *dateFormatter = nil;
         if(dateFormatter == nil){
             dateFormatter = [[NSDateFormatter alloc] init];
             [dateFormatter setDateStyle:NSDateFormatterShortStyle];
             [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
         }
         NSString *dateString = [dateFormatter stringFromDate:item.date];
         
         [dateLbl setText:dateString];
         if(largeFont){
             [dateLbl setFont:[UIFont systemFontOfSize:16]];
         }else{
             [dateLbl setFont:[UIFont systemFontOfSize:12]];
         }
         
         UILabel *sizeLbl = (UILabel *)[cell.contentView viewWithTag:14];
         /*
         NSString* sizeStr;
         if (item.size > 1024*1024) {
             sizeStr = [NSString stringWithFormat:@"%uM", (unsigned int)(item.size/1048576)];
         }else{
             sizeStr = [NSString stringWithFormat:@"%uK", (unsigned int)(item.size/1024)];
         }*/
         [sizeLbl setText:[CommonProcs getSizeRep:item.size]]; //sizeStr];
         
         if(!(item.flags & mfHasAttachment)){
             UIImageView* att = (UIImageView*)[cell.contentView viewWithTag:2];
             att.hidden = YES;
         }
         
         if(!(item.flags & mfNew)){
             UIImageView* att = (UIImageView*)[cell.contentView viewWithTag:1];
             att.hidden = YES;
         }else{
             UIImageView* att = (UIImageView*)[cell.contentView viewWithTag:1];
             att.image = [UIImage imageNamed:@"BlueDot"];
             att.hidden = NO;
         }
         
         if(item.flags & mfImportant){
             UIImageView* att = (UIImageView*)[cell.contentView viewWithTag:1];
             if(item.flags & mfNew){
                 att.image = [UIImage imageNamed:@"RedBlueDot"];
             }else{
                 att.image = [UIImage imageNamed:@"RedDot"];
             }
             att.hidden = NO;
         }
         
         if(item.flags & mfFavourite){
             UIButton* fav = (UIButton*)[cell.contentView viewWithTag:3];
             [fav setImage:[UIImage imageNamed:@"starYellow"] forState:UIControlStateNormal];
             fav.alpha = 1.0;
         }else{
             UIButton* fav = (UIButton*)[cell.contentView viewWithTag:3];
             [fav setImage:[UIImage imageNamed:@"starLight"] forState:UIControlStateNormal];
             fav.alpha = 0.5;
         }
         
         if((item.flags & mfAnswered)){
             UIImageView* att = (UIImageView*)[cell.contentView viewWithTag:21];
             att.hidden = NO;
             //[att setImage:[UIImage imageNamed:@"repliedArrow"]];
         }else{
             UIImageView* att = (UIImageView*)[cell.contentView viewWithTag:21];
             att.hidden = YES;
         }

         /*
         if ([indexPath isEqual:self.currentIndex]) {
             [cell openCell];
         }
         */
         //[cell.contentView setBackgroundColor:[UIColor whiteColor]];
         //[cell setBackgroundColor:[UIColor whiteColor]];
         UIColor* bgCol = [self.presenter.boxColors objectForKey:item.settingsID];
         [cell setBackgroundColor:bgCol];
         
     }else if (indexPath.section == 1){
         cell = [tableView dequeueReusableCellWithIdentifier:@"BottomCell"];
         
         if (cell == nil) {
             cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"BottomCell"];
         }
         
         UILabel *lbl = (UILabel *)[cell.contentView viewWithTag:11];
         if (updating) {
             lbl.text = @"";
             loadingCell = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(self.tableView.frame.size.width/2-15, cell.frame.size.height/2-15, 30, 30)];
             if (@available(iOS 13.0, *)) {
                 loadingCell.color = [UIColor systemGrayColor];
             } else {
                 // Fallback on earlier versions
                 loadingCell.color = [UIColor darkGrayColor];
             }
             [cell addSubview:loadingCell];
             [loadingCell startAnimating];
         }else{
             if (loadingCell) {
                 [loadingCell stopAnimating];
                 [loadingCell removeFromSuperview];
                 loadingCell = nil;
             }
             if(self.presenter.noNeedForMore){
                 lbl.text = NSLocalizedString(@"No more messages", nil);
             }else{
                 if (listItems.count == 0) {
                     lbl.text = NSLocalizedString(@"Load messages", nil);
                 }else{
                     lbl.text = NSLocalizedString(@"Load more messages", nil);
                 }
             }
         }
     }
     
     // Load more messages automatically
     // EXPERIMENTAL, need to test
     // We need to check if everything is on the screen so that the code is not called recursevely
     if((indexPath.section == 0 && self.listItems && self.listItems.count > /*self.tableView.visibleCells.count+1*/indexPath.row-1) && /*!updating*/ ![self.presenter isFetching]){ // one is for the last row
         //ShortMessageEntity *data = [self.listItems objectAtIndex:indexPath.row];
         //BOOL lastItemReached = [data isEqual:[self.listItems lastObject]]; // WTF???
         if (/*lastItemReached*/!self.presenter.updateRequested && indexPath.row == [self.listItems count] - 1 && [self.tableView indexPathsForVisibleRows].count < listItems.count)
         {
             if(!self.presenter.noNeedForMore){
                 NSLog(@"Requested next messages");
                 [self.presenter needMoreMessages];
                 updating = YES;
                 //[self updateLastCell]; // No need for
             }
         }
     }
     
     /*
      - (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
      
      CGFloat currentOffset = scrollView.contentOffset.y;
      CGFloat maximumOffset = scrollView.contentSize.height - scrollView.frame.size.height;
      
      // Change 10.0 to adjust the distance from bottom
      if (maximumOffset - currentOffset <= 10.0) {
        [self loadOneMorePage];
        }
      }
      */
     
     return cell;
 
 //return cell;
 }

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        return NO;
    }
    return YES;//NO;//YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
     if (editingStyle == UITableViewCellEditingStyleDelete) {
         
         // Delete the row from the data source
         ShortMessageEntity* toRemove = (ShortMessageEntity*)[self.listItems objectAtIndex:indexPath.row];

         //GlobalRouter* gr = (GlobalRouter*)[GlobalRouter sharedManager];
         if([self.presenter deleteItem:toRemove]){
             [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
             [GlobalRouter sharedManager].totalMessages--;
         }
     }
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete; //eNone;
}

-(BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (NSString*)getBoxName
{
    NSString* header;
    switch ([GlobalRouter sharedManager].currentBox) {
        case btInbox:
            header = NSLocalizedString(@"Inbox", nil);
            break;
        
        case btEmpty:
            // Assume we need INBOX
            //header = @"";
            header = NSLocalizedString(@"Inbox", nil);
            break;
            
        case btSent:
            header = NSLocalizedString(@"Sent", nil);
            break;
            
        case btFavourites:
            header = NSLocalizedString(@"Starred", nil);
            break;
            
        case btSpam:
            header = NSLocalizedString(@"Spam", nil);
            break;
            
        case btUseName:
        {
            //NSArray* temp = [[[GlobalRouter sharedManager].otherFolders valueForKey:[GlobalRouter sharedManager].currentAccount] allKeysForObject:[GlobalRouter sharedManager].currentBoxPath];
            //header = [temp lastObject];
            
            //NSDictionary* folderDict = [[GlobalRouter sharedManager].otherFolders valueForKey:[GlobalRouter sharedManager].currentAccount];
            NSDictionary* folderDict = [[GlobalRouter sharedManager].otherFolders objectForKey:[GlobalRouter sharedManager].currentAccount];
                for (FolderInfo* fi in [folderDict allValues]) {
                    if ([fi.folderPath isEqualToString:[GlobalRouter sharedManager].currentBoxPath]) {
                        header = [[folderDict allKeysForObject:fi] lastObject];
                        break;
                    }
                }
            if (!header) {
                // Try getting account name
                NSString* accName = [[GlobalRouter sharedManager].accountsNames valueForKey:[GlobalRouter sharedManager].currentAccount];
                if(accName){
                    NSDictionary* folderDict = [[GlobalRouter sharedManager].otherFolders objectForKey:accName];
                    for (FolderInfo* fi in [folderDict allValues]) {
                        if ([fi.folderPath isEqualToString:[GlobalRouter sharedManager].currentBoxPath]) {
                            header = [[folderDict allKeysForObject:fi] lastObject];
                            break;
                        }
                    }
                }
            }
        
            break;
        }
        default:
            //header = @"";
            header = NSLocalizedString(@"Inbox", nil);
            break;
    }
    return header;
}


#define headerHight 20
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat ret;
    if (section == 0) {
        ret = headerHight;//16;
    }else{
        ret = 0;
    }
    
    return ret;
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    // Needs to be fixed. Returning from BG via notification, GR is not inited
    if ([GlobalRouter notInited]) {
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    }
    UIView *view;
    if (section != 0) {
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    }
    view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, headerHight)];
    view.tag = 8007;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(headerHight, 1, tableView.frame.size.width, headerHight-2)];
    [label setFont:[UIFont boldSystemFontOfSize:12]];
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.3;
    label.tag = 8008;
    
    NSString* boxName = [self getBoxName];
    if (![boxName isEqualToString:@""]) {
        if ([self.filterFrom isEqualToString:@""]) {
            if([GlobalRouter sharedManager].loadedMessages == 0){
                [label setText:[NSString stringWithFormat:@"%@ (%d)",boxName, [GlobalRouter sharedManager].totalMessages]];
            }else{
                [label setText:[NSString stringWithFormat:@"%@ %d of %d",boxName, [GlobalRouter sharedManager].loadedMessages, [GlobalRouter sharedManager].totalMessages]];
            }
        }else{
            [label setText:[NSString stringWithFormat:@"%@ '%@' (%d)",boxName, [self.presenter getFilterString], [GlobalRouter sharedManager].totalMessages]];
        }
        
    }else{
        [label setText:@""];
    }
    [view addSubview:label];
    
    if (@available(iOS 13.0, *)) {
        [view setBackgroundColor:[UIColor systemGroupedBackgroundColor]];
    } else {
        // Fallback on earlier versions
        [view setBackgroundColor:[UIColor colorWithRed:239/255.0 green:239/255.0 blue:244/255.0 alpha:1.0]]; // Match bottom cell and make it brighter
    }
    
    UIImageView* sortImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"downArrow"]];
    [sortImage setFrame:CGRectMake(1,2,headerHight-4,headerHight-4)];
    sortImage.tag = 8009;
    [view addSubview:sortImage];
    
    UITapGestureRecognizer* headerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headerTap:)];
    [view addGestureRecognizer:headerTap];
    
    return view;
}

-(void)headerTap:(id)sender
{
    //NSLog(@"HEADER TAP!");
    [self.presenter sortListbyDate];
}

-(void)stopRefreshing
{
    // End the refreshing
    if (self.refreshControl) {
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"dd MMMM, HH:mm"];
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Last update: %@",nil), [formatter stringFromDate:[NSDate date]]];
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor darkGrayColor]
                                                                    forKey:NSForegroundColorAttributeName];
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
        self.refreshControl.attributedTitle = attributedTitle;
        
        [self.refreshControl endRefreshing];
    }
    
    updating = NO;
}

#pragma mark - Tool bar items
//// ToolBar
-(IBAction)exitApp:(id)sender
{
    //[[[GlobalRouter sharedManager] getListPresenter] exitPressed];
    
    [self.presenter exitPressed];
}

-(IBAction)markFavourite:(id)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    //[[[GlobalRouter sharedManager] getListPresenter] markMessageFavourite:[self.listItems objectAtIndex:indexPath.row]];
    [self.presenter markMessageFavourite:[self.listItems objectAtIndex:indexPath.row]];
}

-(IBAction)filterSender:(id)sender
{
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    ShortMessageEntity* item2 = [self.listItems objectAtIndex:indexPath.row];
    [self.presenter doSearchWithString:item2.fromAddress];
}

-(IBAction)checkMail:(id)sender
{
    //[self.presenter checkMail];
    [CommonProcs spawnProc:@selector(checkMail) object:self.presenter withParam:nil];
}

-(IBAction)newMessage:(id)sender
{
    [self.presenter newMessage];
}

-(IBAction)showSettings:(id)sender
{
    [CommonProcs spawnProcWithProgress:@selector(showSettings) object:self.presenter withParam:nil];
    //[self.presenter showSettings];
}

-(IBAction)showHelp:(id)sender
{
    [self.presenter showHelp];
}

/*
-(IBAction)showMoreActions:(id)sender
{
    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select action",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Settings", nil), NSLocalizedString(@"Search messages", nil), NSLocalizedString(@"Privacy policy", nil), NSLocalizedString(@"Info", nil),
                            nil];
    
    // *
    [popup addButtonWithTitle:NSLocalizedString(@"Settings", nil)];
    [popup addButtonWithTitle:NSLocalizedString(@"Search messages", nil)];
    
    [popup addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
    [popup setCancelButtonIndex:2];
    //[popup addButtonWithTitle:NSLocalizedString(@"Reset all", nil)];
    // * /
    
    popup.tag = 202;
    //[popup showInView:[UIApplication sharedApplication].keyWindow];
    [popup showFromBarButtonItem:self.moreButton animated:YES];
}*/

-(void)showMaster
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if ([GlobalRouter sharedManager].detailVC != nil) {
            [[GlobalRouter sharedManager].detailVC performSelectorOnMainThread:@selector(hideMaster) withObject:nil waitUntilDone:NO];
        }

    }
}

#pragma mark - Tabbar items
// Tab bar

-(IBAction)showInbox:(id)sender
{
    [GlobalRouter sharedManager].currentAccount = @"";
    [GlobalRouter sharedManager].currentFilter = @"";
    self.filterFrom = @"";
    
    [CommonProcs spawnProcWithProgress:@selector(needShowInbox) object:self.presenter withParam:nil];
    //[CommonProcs spawnProc:@selector(checkMail) object:self.presenter withParam:nil];
}

-(IBAction)showSent:(id)sender
{
    [CommonProcs spawnProcWithProgress:@selector(needShowSent) object:self.presenter withParam:nil];
    //[self.presenter needShowSent];
}

-(IBAction)showFavs:(id)sender
{
    //[GlobalRouter sharedManager].currentAccount = @"";
    //[CommonProcs spawnProcWithProgress:@selector(needShowFavs) object:self.presenter withParam:nil];
    
    //////// DEBUG TEST
    
    /* // Cert exchange demo
    [GlobalRouter sharedManager].oneTimeCertInteractor = [[OneTimeCertInteractor alloc] init];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[GlobalRouter sharedManager].oneTimeCertInteractor presentViewInNavController:[[GlobalRouter sharedManager] getDetailNavController]];
    });
    */
    
    [self.presenter needEditList];
}

-(IBAction)showSpam:(id)sender
{
    [CommonProcs spawnProcWithProgress:@selector(needShowSpam) object:self.presenter withParam:nil];
    //[self.presenter needShowSpam];
}

-(IBAction)sos:(id)sender
{
    [self.presenter sos];
}

-(IBAction)search:(id)sender
{
    //[self.presenter search];
    [[GlobalRouter sharedManager] needAdvancedSearch];
}

-(IBAction)showBook:(id)sender
{
    [CommonProcs spawnProcWithProgress:@selector(needShowAddressBook) object:[GlobalRouter sharedManager] withParam:nil onMain:YES];
    //[[GlobalRouter sharedManager] needShowAddressBook];
}

-(IBAction)showGallery:(id)sender
{
    [CommonProcs spawnProcWithProgress:@selector(needShowGallery) object:[GlobalRouter sharedManager] withParam:nil];
    //[[GlobalRouter sharedManager] needShowGallery];
}

-(IBAction)showNotes:(id)sender
{
    
    [CommonProcs spawnProcWithProgress:@selector(needShowNotes) object:[GlobalRouter sharedManager] withParam:nil];
    
    // DEBUG
    //[GlobalRouter sharedManager].oneTimeCertInteractor = [[OneTimeCertInteractor alloc] init];
    //[[GlobalRouter sharedManager].oneTimeCertInteractor startReceiving];
}

-(void) showPP
{
    [self.presenter showPP];
}

-(IBAction)otherFolders:(id)sender
{
    [self.presenter needShowMenu];
    
    /*
    UIStoryboard * sb = [UIStoryboard storyboardWithName:@"SelectStoryboard" bundle:nil];
    TableSelectViewController * vc = [sb instantiateViewControllerWithIdentifier:@"AccountSelect"];
    vc.caller = self;
    vc.items = [[GlobalRouter sharedManager].otherFolders allKeys];
    //[self.navigationController pushViewController:vc animated:true];
    */
    
    //FoldersTableViewController *fvc = [[FoldersTableViewController alloc] init];
    //fvc.caller = self;
    
    /*
    // this looks better, but it flashes black bg instead of previous view
    CATransition* transition = [CATransition animation];
    transition.duration = .3;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    transition.type = kCATransitionMoveIn;
    transition.subtype= kCATransitionFromLeft;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    [self.navigationController pushViewController:fvc animated:NO];
    */
    
    //[self.navigationController pushViewController:fvc animated:YES];
    
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
    [self.presenter menuWasDismissed];
}

// need to move to presenter or even to interactor
-(void)didSelectItem:(NSString *)item title:(NSString *)title
{
    //[self.navigationController popViewControllerAnimated:YES];
    //NSLog(@"%@-%@",title, item);
    
    [GlobalRouter sharedManager].currentBoxPath = [NSString stringWithString: item];
    [GlobalRouter sharedManager].currentBox = btUseName;
    [GlobalRouter sharedManager].currentAccount = title;
    [CommonProcs spawnProcWithProgress:@selector(needShowOtherBox) object:self.presenter withParam:nil];
    //[CommonProcs hideProgress]; // !!!!
}

/*
- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Who knows cancel button index?
    if (buttonIndex == -1) {
        return;
    }
    NSString* buttonPressed = [popup buttonTitleAtIndex:buttonIndex];
    if ([buttonPressed isEqualToString:NSLocalizedString(@"Cancel",nil)]) {
        return;
    }
    
    if(popup.tag == 201){
        //[GlobalRouter sharedManager].currentBoxPath = [[GlobalRouter sharedManager].otherFolders valueForKey:buttonPressed];
        [GlobalRouter sharedManager].currentBoxPath = [[GlobalRouter sharedManager].otherFolders objectForKey:buttonPressed];
        [GlobalRouter sharedManager].currentBox = btUseName;
        [CommonProcs spawnProcWithProgress:@selector(needShowOtherBox) object:self.presenter withParam:nil];
        //[self.presenter needShowOtherBox];
    }else{
        if ([buttonPressed isEqualToString:NSLocalizedString(@"Settings",nil)]) {
            [self showSettings:nil];
        }else if([buttonPressed isEqualToString:NSLocalizedString(@"Search messages",nil)]){
            [self search:nil];
        }else if([buttonPressed isEqualToString:NSLocalizedString(@"Privacy policy",nil)]){
            [self showPP];
        }else if([buttonPressed isEqualToString:NSLocalizedString(@"Reset all",nil)]){
            [self search:nil];
        }else if([buttonPressed isEqualToString:NSLocalizedString(@"Info",nil)]){
            [self showHelp:nil];
        }

    }
}*/

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


// Call GlobalRouter for action "WannaReadMessage"
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     [detailViewController release];
     */
    if(![tableView isEditing])
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (!self.presenter) {
        NSLog(@"NO PRESENTER!");
        //[tableView deselectRowAtIndexPath:indexPath animated:YES];
        // Need pin
        if([GlobalRouter sharedManager].pin)return;
        else return;
    }
    if (self.tableView.isEditing) {
        return;
    }
    
    if(indexPath.section == 0){
        //[tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        [self.presenter showMessageItem:(ShortMessageEntity*)[self.listItems objectAtIndex:indexPath.row]];
    }else if (indexPath.section == 1){
        if (self.presenter.updateRequested) {
            return;
        }
        if (updating) {
            ///////////////////return;
        }
        updating = YES;
        if (listItems.count == 0) {
            [CommonProcs spawnProc:@selector(checkMail) object:self.presenter withParam:nil];
            //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                //[self.presenter checkMail];
            //});
        }else if(!self.presenter.noNeedForMore && !loadingCell)
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                [self.presenter needMoreMessages];
            });
    }
    //NSLog(@"Touch!");
}

-(void)showError:(NSString*)error
{
    [CommonProcs showMessage:@"" title:error];
    
    //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:error message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
    //alert.tag = 10000;
    //[alert show];
}

/*
-(void)askAndDoWithTitle:(NSString*)title text:(NSString*)alertText block:(dispatch_block_t)block
{
    alertBlock = block;
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:alertText
                                 preferredStyle:UIAlertControllerStyleAlert];
    __weak __typeof__(self) weakSelf = self;
    UIAlertAction* ok = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"OK", nil)
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
                                   __strong __typeof__(self) strongSelf = weakSelf;
                                   strongSelf->alertBlock();
                               }];
    [alert addAction:ok];
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"Cancel",nil)
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 
                             }];
    [alert addAction:cancel];
    
    UIView* pView = self.view;// [[GlobalRouter sharedManager] getCurrentView];
    alert.popoverPresentationController.sourceView = pView;
    alert.popoverPresentationController.sourceRect = pView.frame;
    [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
}*/

/*
-(void)askAndDoWithTitle:(NSString*)title text:(NSString*)alertText block:(dispatch_block_t)block showInput:(BOOL)showInput
{
    if ([GlobalRouter sharedManager].goingToBG || [UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:alertText delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"OK",nil), nil];
    if(showInput){
        alert.tag = 101;
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    }else{
        alert.tag = 102;
    }
    alertBlock = block;
    [alert show];
}
*/
/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 101)
    {
        if (buttonIndex == 0)
        {
            
        }else{
            self.filterFrom = [[alertView textFieldAtIndex:0] text];
            [GlobalRouter sharedManager].currentFilter = self.filterFrom;
            
            //if (![self.filterFrom isEqualToString:@""]) {
                alertBlock();
            //}
        }
    }else if (alertView.tag == 102)
    {
        if (buttonIndex == 0)
        {
            
        }else{
            alertBlock();
        }
    }
}
*/
-(void)updateLastCell
{
    return;
    
    /* // That couses error since it tries to update the cell while updating the others
     // The second point - there's no need to call it anymore
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    NSArray *indexPaths = [[NSArray alloc] initWithObjects:indexPath, nil];
    @try {
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    } @catch (NSException *exception) {
        NSLog(@"Exception %@", exception);
    } @finally {
        
    }*/
}

@end
