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
#import "TableSelectViewController.h"
#import "FolderInfo.h"

@interface MessageListViewController ()

@end

@implementation MessageListViewController

@synthesize listItems, refreshControl, filterFrom;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationController.toolbarHidden = NO;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    
    // Initialize the refresh control (via table view controller)
    self.tableController = [[UITableViewController alloc] init];
    [self addChildViewController:self.tableController];
    self.tableController.tableView = self.tableView;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor whiteColor];
    self.refreshControl.tintColor = [UIColor colorWithRed:166/255.0 green:177/255.0 blue:186/255.0 alpha:1.0];//[UIColor  blueColor];
    [self.refreshControl addTarget:self
                            action:@selector(checkMail:)
                  forControlEvents:UIControlEventValueChanged];
    self.tableController.refreshControl = refreshControl;
    
    self.filterFrom = @"";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    // There's a strange bug - sometimes refresh control doesn't dissapear when a view appears
    [self.refreshControl endRefreshing];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

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


 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
 //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:<#@"reuseIdentifier"#> forIndexPath:indexPath];
 
 // Configure the cell...
     UITableViewCell *cell;
     if (indexPath.section == 0){

         static NSString *CellIdentifier = @"MessageListTableViewCell";
         
         cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
         if (cell == nil) {
             cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
         }
         
         // Reset cell
         UIImageView* att = (UIImageView*)[cell.contentView viewWithTag:2];
         att.hidden = NO;
         att = (UIImageView*)[cell.contentView viewWithTag:1];
         att.hidden = NO;
         
         ShortMessageEntity* item = (ShortMessageEntity*)[self.listItems objectAtIndex:indexPath.row];
         
         UILabel *name = (UILabel *)[cell.contentView viewWithTag:10];
         [name setText:item.fromName];
         UILabel *subj = (UILabel *)[cell.contentView viewWithTag:11];
         [subj setText:item.subject];
         //subj.numberOfLines = 0;
         //[subj sizeToFit];
         
         UILabel *addrr = (UILabel *)[cell.contentView viewWithTag:12];
         NSString* addrText = [NSString stringWithFormat:@"%@: %@", item.settingsID, item.fromAddress];
         [addrr setText:addrText];
         //[addrr setText:item.fromAddress];
         
         UILabel *dateLbl = (UILabel *)[cell.contentView viewWithTag:13];
         NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
         [dateFormatter setDateFormat:@"dd.MM.YY HH:mm"];
         NSString *dateString = [dateFormatter stringFromDate:item.date];
         [dateLbl setText:dateString];
         
         UILabel *sizeLbl = (UILabel *)[cell.contentView viewWithTag:14];
         NSString* sizeStr;
         if (item.size > 1000000) {
             sizeStr = [NSString stringWithFormat:@"%uM", (unsigned int)(item.size/1000000)];
         }else{
             sizeStr = [NSString stringWithFormat:@"%uK", (unsigned int)(item.size/1000)];
         }
         [sizeLbl setText:sizeStr];
         
         if(!(item.flags & mfHasAttachment)){
             UIImageView* att = (UIImageView*)[cell.contentView viewWithTag:2];
             att.hidden = YES;
         }
         
         if(!(item.flags & mfNew)){
             UIImageView* att = (UIImageView*)[cell.contentView viewWithTag:1];
             att.hidden = YES;
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
     }else if (indexPath.section == 1){
         cell = [tableView dequeueReusableCellWithIdentifier:@"BottomCell"];
         if (cell == nil) {
             cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"BottomCell"];
         }
         
         UILabel *lbl = (UILabel *)[cell.contentView viewWithTag:11];
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
     
     return cell;
 
 return cell;
 }

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
     if (editingStyle == UITableViewCellEditingStyleDelete) {
         
         // Delete the row from the data source
         ShortMessageEntity* toRemove = (ShortMessageEntity*)[self.listItems objectAtIndex:indexPath.row];

         //GlobalRouter* gr = (GlobalRouter*)[GlobalRouter sharedManager];
         if([self.presenter deleteItem:toRemove])
             [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
     }
}

- (NSString*)getBoxName
{
    NSString* header;
    switch ([GlobalRouter sharedManager].currentBox) {
        case btInbox:
            header = NSLocalizedString(@"Inbox", nil);
            break;
        
        case btEmpty:
            header = @"";
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
            
            NSDictionary* folderDict = [[GlobalRouter sharedManager].otherFolders valueForKey:[GlobalRouter sharedManager].currentAccount];
                for (FolderInfo* fi in [folderDict allValues]) {
                    if ([fi.folderPath isEqualToString:[GlobalRouter sharedManager].currentBoxPath]) {
                        header = [[folderDict allKeysForObject:fi] lastObject];
                        break;
                    }
                }
        
            break;
        }
        default:
            header = @"";
            break;
    }
    return header;
}



-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat ret;
    if (section == 0) {
        ret = 16;
    }else{
        ret = 0;
    }
    
    return ret;
}

-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view;
    if (section != 0) {
        return [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    }
    
    view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 16)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 1, tableView.frame.size.width, 14)];
    [label setFont:[UIFont boldSystemFontOfSize:12]];
    
    NSString* boxName = [self getBoxName];
    if (![boxName isEqualToString:@""]) {
        if ([self.filterFrom isEqualToString:@""]) {
            [label setText:[NSString stringWithFormat:@"%@ (%d)",boxName, [GlobalRouter sharedManager].totalMessages]];
        }else{
            [label setText:[NSString stringWithFormat:@"%@ '%@' (%d)",boxName, self.filterFrom, [GlobalRouter sharedManager].totalMessages]];
        }
        
    }else{
        [label setText:@""];
    }
    [view addSubview:label];
    [view setBackgroundColor:[UIColor colorWithRed:166/255.0 green:177/255.0 blue:186/255.0 alpha:1.0]];
    
    return view;
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

-(IBAction)showMoreActions:(id)sender
{
    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select action",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Settings", nil), NSLocalizedString(@"Search messages", nil), NSLocalizedString(@"Privacy policy", nil),
                            nil];
    
    /*
    [popup addButtonWithTitle:NSLocalizedString(@"Settings", nil)];
    [popup addButtonWithTitle:NSLocalizedString(@"Search messages", nil)];
    
    [popup addButtonWithTitle:NSLocalizedString(@"Cancel",nil)];
    [popup setCancelButtonIndex:2];
    //[popup addButtonWithTitle:NSLocalizedString(@"Reset all", nil)];
    */
    
    popup.tag = 202;
    //[popup showInView:[UIApplication sharedApplication].keyWindow];
    [popup showFromBarButtonItem:self.moreButton animated:YES];
}

#pragma mark - Tabbar items
// Tab bar

-(IBAction)showInbox:(id)sender
{
    [GlobalRouter sharedManager].currentAccount = @"";
    [CommonProcs spawnProcWithProgress:@selector(needShowInbox) object:self.presenter withParam:nil];
    //[self.presenter needShowInbox];
}

-(IBAction)showSent:(id)sender
{
    [CommonProcs spawnProcWithProgress:@selector(needShowSent) object:self.presenter withParam:nil];
    //[self.presenter needShowSent];
}

-(IBAction)showFavs:(id)sender
{
    [GlobalRouter sharedManager].currentAccount = @"";
    [CommonProcs spawnProcWithProgress:@selector(needShowFavs) object:self.presenter withParam:nil];
    //[self.presenter needShowFavs];
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
    [self.presenter search];
}

-(IBAction)showBook:(id)sender
{
    [CommonProcs spawnProcWithProgress:@selector(needShowAddressBook) object:[GlobalRouter sharedManager] withParam:nil];
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
}

-(void) showPP
{
    [self.presenter showPP];
}

-(IBAction)otherFolders:(id)sender
{
    UIStoryboard * sb = [UIStoryboard storyboardWithName:@"SelectStoryboard" bundle:nil];
    TableSelectViewController * vc = [sb instantiateViewControllerWithIdentifier:@"AccountSelect"];
    vc.caller = self;
    vc.items = [[GlobalRouter sharedManager].otherFolders allKeys];
    [self.navigationController pushViewController:vc animated:true];
    
    /*
    
    // show menu - view, edit, delete
    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select folder",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) destructiveButtonTitle:nil otherButtonTitles:
                            nil];
    if ([GlobalRouter sharedManager].otherFolders.count == 0) {
        popup.title = NSLocalizedString(@"Not loaded yet...",nil);
    }else{
        for (NSString* str in [GlobalRouter sharedManager].otherFolders) {
            [popup addButtonWithTitle:str];
        }
    }
    popup.tag = 201;
    //[popup showInView:[UIApplication sharedApplication].keyWindow];
    [popup showFromBarButtonItem:self.moreFolders animated:YES];
     
     */
}

-(void)didSelectItem:(NSString *)item title:(NSString *)title
{
    [self.navigationController popViewControllerAnimated:YES];
    //NSLog(@"%@-%@",title, item);
    
    [GlobalRouter sharedManager].currentBoxPath = item;
    [GlobalRouter sharedManager].currentBox = btUseName;
    [GlobalRouter sharedManager].currentAccount = title;
    [CommonProcs spawnProcWithProgress:@selector(needShowOtherBox) object:self.presenter withParam:nil];
    [CommonProcs hideProgress]; // !!!!
}

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
        [GlobalRouter sharedManager].currentBoxPath = [[GlobalRouter sharedManager].otherFolders valueForKey:buttonPressed];
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
        }

    }
}

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
    
    if(indexPath.section == 0){
        [self.presenter showMessageItem:(ShortMessageEntity*)[self.listItems objectAtIndex:indexPath.row]];
    }else if (indexPath.section == 1){
        if (listItems.count == 0) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                [self.presenter checkMail];
            });
        }else if(!self.presenter.noNeedForMore)
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                [self.presenter needMoreMessages];
            });
    }
    //NSLog(@"Touch!");
}

-(void)showError:(NSString*)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:error message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
    alert.tag = 10000;
    [alert show];
}

-(void)askAndDoWithTitle:(NSString*)title text:(NSString*)alertText block:(dispatch_block_t)block
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:alertText delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"OK",nil), nil];
    alert.tag = 101;
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alertBlock = block;
    [alert show];
}

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
    }
}

@end
