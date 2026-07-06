//
//  FoldersTableViewController.m
//  SenseMailShare
//
//  Created by Sergey on 28.09.15.
//  Copyright © 2015 Sergey. All rights reserved.
//

#import "FoldersTableViewController.h"
#import "GlobalRouter.h"
#import "FolderInfo.h"
#import "MessageListViewController.h"

@interface FoldersTableViewController ()

@end

@implementation FoldersTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!expandedSections)
    {
        expandedSections = [[NSMutableIndexSet alloc] init];
    }
    
    if (!serviceItems) {
        serviceItems = [[NSMutableArray alloc] init];
        [serviceItems addObject:NSLocalizedString(@"Add email", nil)];
        [serviceItems addObject:NSLocalizedString(@"Settings", nil)];
        [serviceItems addObject:NSLocalizedString(@"Privacy policy", nil)];
        [serviceItems addObject:NSLocalizedString(@"About", nil)];
        [serviceItems addObject:NSLocalizedString(@"What's new?", nil)];
        //[serviceItems addObject:@""];//NSLocalizedString(@"Search messages", nil)];
        [serviceItems addObject:NSLocalizedString(@"Share", nil)];
    }
    //[self.navigationController setNavigationBarHidden:NO animated:NO];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeView)];
    
    oldToolbar = self.parentViewController.toolbarItems;
    [self.parentViewController setToolbarItems:[NSArray arrayWithObjects: flexibleItem, button2, nil]];
    //self.tableView.tintColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"settingsBg"]];
    
    UIBarButtonItem *flexibleItem22 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button23 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(hideKeyboard)];
    
    self.inputAccessoryToolbar = [[UIToolbar alloc] init];
    self.inputAccessoryToolbar.frame = CGRectMake(0,0,250,44);
    self.inputAccessoryToolbar.items = [NSArray arrayWithObjects:flexibleItem22, button23, nil];
    
    UISwipeGestureRecognizer* closeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(closeView)];
    closeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:closeGesture];
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(handleLongPress:)];
    lpgr.minimumPressDuration = 2.0; //seconds
    lpgr.delegate = self;
    [self.tableView addGestureRecognizer:lpgr];
}

-(void)hideKeyboard
{
    [self.view endEditing:YES];
}

-(IBAction)close:(id)sender
{
    [self closeView];
}

-(void)closeView
{
    //[[GlobalRouter sharedManager] finishedWithCurrentView:YES];
    __weak __typeof__(self) weakSelf = self;
    [UIView animateWithDuration:0.3 delay:0 options:(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut) animations:^{
        self.view.frame = CGRectMake(-self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height);
    }completion:^(BOOL finished) {
        __strong __typeof__(self) strongSelf = weakSelf;
         if (finished) {
             if ([self.parentViewController respondsToSelector:@selector(menuWasDismissed)]) {
                 [self.parentViewController performSelector:@selector(menuWasDismissed)];
             }
             [self.parentViewController setToolbarItems:strongSelf->oldToolbar];
             [self willMoveToParentViewController:nil];
             [self.view removeFromSuperview];
             [self removeFromParentViewController];
         }
     }];
    
    
}

/*
 -(void)closeBook
 {
 [[[GlobalRouter sharedManager] getBookRouter] finished];
 }
 */

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //[self.navigationController setNavigationBarHidden:YES animated:NO];
    
    
    // If there's only one account, expand it by default
    /*
     if ([items count] == 1) {
     [expandedSections addIndex:0];
     }
     */
}

-(void)updateFolderList
{
    if (![GlobalRouter sharedManager].otherFolders) {
        return;
    }
    items = [[GlobalRouter sharedManager].otherFolders copy];
    if (items.count == 0) {
        return;
    }
    sortedItems = [NSMutableArray arrayWithArray:[[items allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
    sortedFolders = [[NSMutableArray alloc] init];
    for (NSString* item in sortedItems) {
        NSMutableArray* tempFolders =  [NSMutableArray arrayWithArray:[[items[item] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
        if(tempFolders)
            [sortedFolders addObject:tempFolders];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    int num = (int)[items count];
    if(num == 0){
        num++;
        
        /*
         // Display a message when the table is empty
         noRecords = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
         noRecords.text = NSLocalizedString(@"Not loaded yet. Please, come back later.", nil);
         noRecords.textColor = [UIColor blackColor];
         noRecords.numberOfLines = 0;
         noRecords.textAlignment = NSTextAlignmentCenter;
         [noRecords sizeToFit];
         
         self.tableView.backgroundView = noRecords;
         self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
         */
    }else{
        self.tableView.backgroundView = nil;
    }
    
    num+=3;
    
    return num;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if ([expandedSections containsIndex:section])
    {
        return [[items objectForKey:[sortedItems objectAtIndex:section]] count]+1+1;// +1 for caption, +1 for add folder
        //[[items objectForKey:[[items allKeys] objectAtIndex:section]] count]+1+1;// +1 for caption, +1 for add folder
    }else if (items.count == 0 && section == 0){
        return 1;
    }else if(items.count == 0 && section == 1){// > items.count){
        return serviceItems.count-1;
    }else if(items.count == 0 && section == 2){// > items.count){
        return 1;
    }else if(items.count == 0 && section == 3){// > items.count){
        return 0;
    }else if(section == items.count){
        return serviceItems.count-1;
    }else if(section == items.count+1){
        return 1;
    }else if(section == items.count+2){
        return 0;
    }
    
    return 1; // only top row showing
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle/*Default*/ reuseIdentifier:CellIdentifier];
    }
    [[cell.contentView viewWithTag:1002] removeFromSuperview];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    cell.detailTextLabel.text = @"";
    [cell.detailTextLabel setFont:[UIFont systemFontOfSize:8]];
    
    if (items.count == 0 && indexPath.section == 0) {
        if([GlobalRouter sharedManager].allSettings.count == 0){
            cell.textLabel.text = NSLocalizedString(@"Add account", nil);
        }else{
            cell.textLabel.text = NSLocalizedString(@"Not loaded yet", nil);
        }
        [cell.imageView setImage:nil];
        return cell;
    }
    if ((items.count == 0 && indexPath.section == 1) || indexPath.section == items.count) {
        cell.textLabel.text = [serviceItems objectAtIndex:indexPath.row];
        [cell.imageView setImage:nil];
        if (indexPath.row == 0) {
            [cell.imageView setImage:[UIImage imageNamed:@"addEmailAcc"]];
        }else if (indexPath.row == 1) {
            [cell.imageView setImage:[UIImage imageNamed:@"gear"]];
        }else if (indexPath.row == 2) {
            [cell.imageView setImage:[UIImage imageNamed:@"pp"]];
        }else if (indexPath.row == 3) {
            [cell.imageView setImage:[UIImage imageNamed:@"infoButton"]];
        }else if (indexPath.row == 4000) { // There's a full search, no need to show it here
            //[cell.imageView setImage:[UIImage imageNamed:@"search"]];
            float width = cell.frame.size.width-10;
            //NSLog(@"Width = %f", width);
            UIView* cv = [[UIView alloc] initWithFrame:CGRectMake(5, cell.frame.size.height/2-13, width, 26)];
            cv.tag = 1002;
            self.searchText = [[UITextField alloc] initWithFrame:CGRectMake(12, 0, width-40, 26)];
            self.searchText.placeholder = NSLocalizedString(@" Find sender...*", nil);
            self.searchText.tag = 1001;
            self.searchText.clearButtonMode = UITextFieldViewModeWhileEditing;
            self.searchText.autocorrectionType = UITextAutocorrectionTypeNo;
            self.searchText.autocapitalizationType = UITextAutocapitalizationTypeNone;
            if (!([GlobalRouter sharedManager].currentFilter == nil || [[GlobalRouter sharedManager].currentFilter isEqualToString:@""])) {
                self.searchText.text = [GlobalRouter sharedManager].currentFilter;
            }
            [[self.searchText layer] setCornerRadius:3.0f];
            [[self.searchText layer] setMasksToBounds:YES];
            [[self.searchText layer] setBorderWidth:1.0f];
            [[self.searchText layer] setBorderColor:[UIColor grayColor].CGColor];
            if(self.inputAccessoryToolbar)
                self.searchText.inputAccessoryView = self.inputAccessoryToolbar;
            
            [cv addSubview:self.searchText];
            UIImageView* iv = [[UIImageView alloc] initWithFrame:CGRectMake(width-26, 0, 26, 26)];
            [iv setImage:[UIImage imageNamed:@"search"]];
            [cv addSubview:iv];
            [cell.contentView addSubview:cv];
        }else if (indexPath.row == 4) {
            [cell.imageView setImage:[UIImage imageNamed:@"whatsnew"]];
        }
        return cell;
    }
    
    if ((items.count == 0 && indexPath.section == 2) || indexPath.section == items.count+1) {
        cell.textLabel.text = [serviceItems objectAtIndex:serviceItems.count - 1 - indexPath.row];
        [cell.imageView setImage:nil];
        if (indexPath.row == 0) {
            [cell.imageView setImage:[UIImage imageNamed:@"share"]];
        }
        return cell;
    }
    if ((items.count == 0 && indexPath.section == 3) || indexPath.section == items.count+2) {
        return cell;
    }
    // Configure the cell...
    cell.detailTextLabel.text = @"";
    if (indexPath.row == 0){
        
        if (sortedItems.count < indexPath.section) {
            // Add account?
        }else{
            // first row
            NSString* acc = [sortedItems objectAtIndex:indexPath.section];
            NSString* addr = @"";
            NSArray* tmp = [[GlobalRouter sharedManager].accountsNames allKeysForObject:acc];
            if(tmp && tmp.count > 0){
                addr = tmp[0];
            }
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.minimumScaleFactor = 0.5;
            if([acc isEqualToString:addr] || [addr isEqualToString:@""]){
                cell.textLabel.text = acc; //[sortedItems objectAtIndex:indexPath.section];
            }else{
                cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)",acc,addr];
            }
            [cell.imageView setImage:[UIImage imageNamed:@"moreIcon"]];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            if ([expandedSections containsIndex:indexPath.section])
            {
                // Up arrow
                
            }else{
                // Down arrow
            }
        }
    }else{
        [cell.imageView setImage:nil];
        
        //NSString* key = [[items allKeys] objectAtIndex:indexPath.section];
        NSString* key = [sortedItems objectAtIndex:indexPath.section];
        NSArray* sortedF = [sortedFolders objectAtIndex:indexPath.section];
        //if (sortedF.count != [[[GlobalRouter sharedManager].otherFolders valueForKey:key] allKeys].count) {
        if (sortedF.count != [[[GlobalRouter sharedManager].otherFolders objectForKey:key] allKeys].count) {
            [self updateFolderList];
            sortedF = [sortedFolders objectAtIndex:indexPath.section];
        }
        if(indexPath.row == [[items objectForKey:key] allKeys].count+1){
            cell.textLabel.text = NSLocalizedString(@"Add folder...", nil);
            cell.accessoryView = nil;
            cell.detailTextLabel.text = @"";
        }else{
            NSDictionary* folders = [items valueForKey:key];
            FolderInfo* fi = [folders valueForKey:[sortedF objectAtIndex:indexPath.row-1]];//cell.textLabel.text];
            //NSString* mText = [NSString stringWithFormat:@"%@, %u", [sortedF objectAtIndex:indexPath.row-1], fi.totalCount];
            cell.textLabel.text = [sortedF objectAtIndex:indexPath.row-1]; //
            //cell.textLabel.text = [[[items objectForKey:key] allKeys] objectAtIndex:indexPath.row-1];
            
            if ([cell.textLabel.text isEqualToString:@"INBOX"]) {
                [cell.imageView setImage:[UIImage imageNamed:@"inboxCircle"]];
            }else if (fi.folderType == btFavourites){
                [cell.imageView setImage:[UIImage imageNamed:@"starCircle"]];
            }else if (fi.folderType == btSpam){
                [cell.imageView setImage:[UIImage imageNamed:@"spamCircle"]];
            }else if (fi.folderType == btSent){
                [cell.imageView setImage:[UIImage imageNamed:@"outboxCircle"]];
            }else if (fi.folderType == btAllMail){
                [cell.imageView setImage:[UIImage imageNamed:@"allMailCircle"]];
            }else if (fi.folderType == btDeleted){
                [cell.imageView setImage:[UIImage imageNamed:@"deletedCircle"]];
            }else if (fi.folderType == btDrafts){
                [cell.imageView setImage:[UIImage imageNamed:@"writeMail"]];
            }else if (fi.folderType == btImportant){
                [cell.imageView setImage:[UIImage imageNamed:@"importantCircle"]];
            }else{
                [cell.imageView setImage:[UIImage imageNamed:@"moreCircle"]];
                const char *stringAsChar = [fi.folderPath cStringUsingEncoding:[NSString defaultCStringEncoding]];
                NSString *str = [NSString stringWithCString:stringAsChar encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingUTF7_IMAP)];
                cell.detailTextLabel.text = str;
            }
            // Make the icon smaller as it takes all the height that is a bit too large
            // The op is quite slow, but there are not so many lines to draw. Ignore.
            CGSize itemSize = CGSizeMake(24, 24);
            UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
            CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
            [cell.imageView.image drawInRect:imageRect];
            cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            
            if (fi.unseenCount == 0 && fi.totalCount == 0) {
                cell.accessoryView = nil;
            }else{
//#warning NEED To UPDATE UNSEEN COUNT
                UILabel* newMessages = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 21)];
                if(fi.unseenCount > 0){
                    [newMessages setFont:[UIFont boldSystemFontOfSize:13]];
                }else{
                    [newMessages setFont:[UIFont systemFontOfSize:13]];
                }
                newMessages.textAlignment = NSTextAlignmentRight;
                newMessages.adjustsFontSizeToFitWidth = YES;
                newMessages.minimumScaleFactor = 0.5;
                newMessages.text = [NSString stringWithFormat:@"%u/%u", fi.unseenCount, fi.totalCount];
                //newMessages.textColor = [UIColor grayColor];
                cell.accessoryView = newMessages;
            }
        }
        
        //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0){// && items.count > 0) {
        return NSLocalizedString(@"Boxes & folders", nil);
    }else if ((items.count == 0 && section == 1) || section == items.count){
        return NSLocalizedString(@"Settings & other", nil);
    }else if ((items.count == 0 && section == 2) || section == items.count+1){
        return NSLocalizedString(@"Tell a friend", nil);
    }else if ((items.count == 0 && section == 3) || section == items.count+2){
        NSString* version = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
        NSString* build = NSBundle.mainBundle.infoDictionary[@"CFBundleVersion"];
        return [NSString stringWithFormat:@"Ver. %@ (build %@)", version, build];
    }else{
        return @"";
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0){// && items.count > 0) {
        
    }else if ((items.count == 0 && section == 1) || section == items.count){
        //return NSLocalizedString(@"*Search can only find a whole word in a sender's address - me@mymail.com will be found for 'me', 'mymail', 'mymail.com' but not for 'mail'", nil);
    }
    
    return @"";
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    NSString* account; //= [[items allKeys] objectAtIndex:indexPath.section];
    if (items.count > 0 && indexPath.section < items.count) {
        account = [sortedItems objectAtIndex:indexPath.section];
    }
    if (items.count == 0) {
        return NO;
    }else if(items.count > 0 && (indexPath.section == items.count || indexPath.row == 0 || indexPath.row == [[items objectForKey:account] allKeys].count+1)){
        return NO;
    }else{
        //NSString* folderName = [[[items objectForKey:account] allKeys] objectAtIndex:indexPath.row-1];
        NSString* folderName = [[sortedFolders objectAtIndex:indexPath.section] objectAtIndex:indexPath.row-1];
        if ([folderName isEqualToString:@"INBOX"]) {
            return NO;
        }
        NSDictionary* folders = [items valueForKey:account];
        FolderInfo* fi = [folders valueForKey:folderName];
        if (fi.folderType != btUnknown) {
            return NO;
        }
    }
    return YES;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        NSString* account = [sortedItems objectAtIndex:indexPath.section];
        //NSString* folderName = [[[items objectForKey:account] allKeys] objectAtIndex:indexPath.row-1];
        NSString* folderName = [[sortedFolders objectAtIndex:indexPath.section] objectAtIndex:indexPath.row-1];
        NSLog(@"Folder -%@", folderName);
        [[items objectForKey:account] removeObjectForKey:folderName];
        [sortedFolders[indexPath.section] removeObject:folderName];
        //[GlobalRouter sharedManager].otherFolders
        [GlobalRouter sharedManager].currentAccount = account;
        [[GlobalRouter sharedManager] requestDeleteFolder:folderName];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
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


#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (items.count == 0 && indexPath.section == 0) {
        if([GlobalRouter sharedManager].allSettings.count == 0){
            //[[GlobalRouter sharedManager] needSettingsWithNew];
            [[GlobalRouter sharedManager] showAddMaster];
            return;
        }else{
            return;
        }
    }
    if (indexPath.section == items.count || (items.count == 0 && indexPath.section == 1)) {
        // Settings and stuff
        [self.navigationController setNavigationBarHidden:YES animated:NO];
        if (indexPath.row == 0) {
            // Add account
            [[GlobalRouter sharedManager] showAddMaster];
        }else if (indexPath.row == 1) {
            // Settings
            [[GlobalRouter sharedManager] needSettings];
        }else if (indexPath.row == 2) {
            // PP
            [[GlobalRouter sharedManager] needShowPP];
        }else if (indexPath.row == 3) {
            // info
            [[GlobalRouter sharedManager] needShowHelp];
        }else if(indexPath.row == 4){
            // What's new?
            [[GlobalRouter sharedManager] needShowWhatsNew];
        }else if (indexPath.row == 4000) {
            // Search
            [self closeView];// closeBook];
            [[GlobalRouter sharedManager] needSearchWithString:self.searchText.text];
            //NSLog(self.searchText.text);
        }else if (indexPath.row == 5000) {
            // share
            //[[GlobalRouter sharedManager] needShare];
        }
        
    }else if (indexPath.section == items.count+1 || (items.count == 0 && indexPath.section == 2)) {
        // Settings and stuff
        [self.navigationController setNavigationBarHidden:YES animated:NO];
        if (indexPath.row == 0) {
            // Share
            [[GlobalRouter sharedManager] needShare];
        }
        
    }else{
        
        if (!indexPath.row){
            [self.tableView beginUpdates];
            
            // only first row toggles exapand/collapse
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            
            NSInteger section = indexPath.section;
            BOOL currentlyExpanded = [expandedSections containsIndex:section];
            NSInteger rows;
            
            NSMutableArray *tmpArray = [NSMutableArray array];
            
            if (currentlyExpanded){
                rows = [self tableView:tableView numberOfRowsInSection:section];
                [expandedSections removeIndex:section];
                
            }else{
                [expandedSections addIndex:section];
                rows = [self tableView:tableView numberOfRowsInSection:section];
            }
            
            for (int i=1; i<rows; i++){
                NSIndexPath *tmpIndexPath = [NSIndexPath indexPathForRow:i inSection:section];
                [tmpArray addObject:tmpIndexPath];
            }
            
            //UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            
            if (currentlyExpanded){
                [tableView deleteRowsAtIndexPaths:tmpArray
                                 withRowAnimation:UITableViewRowAnimationTop];
                
            }else{
                [tableView insertRowsAtIndexPaths:tmpArray
                                 withRowAnimation:UITableViewRowAnimationTop];
            }
            
            [self.tableView endUpdates];
        }else{
            NSString* account = [sortedItems objectAtIndex:indexPath.section]; //[[items allKeys] objectAtIndex:indexPath.section];
            if(indexPath.row == [[items objectForKey:account] allKeys].count+1){
                // Add folder...
                [GlobalRouter sharedManager].currentAccount = account;
                
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:NSLocalizedString(@"Folder name",nil)
                                             message:@""
                                             preferredStyle:UIAlertControllerStyleAlert];
                [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                    textField.placeholder = @"New folder";
                    textField.secureTextEntry = NO;
                }];
                UIAlertAction* canSend = [UIAlertAction
                                          actionWithTitle:NSLocalizedString(@"Create", nil)
                                          style:UIAlertActionStyleDefault
                                          handler:^(UIAlertAction * action)
                                          {
                                              [[GlobalRouter sharedManager] requestCreateFolder:[[alert textFields][0] text]];
                                              [self closeView];
                                          }];
                [alert addAction:canSend];
                
                UIAlertAction* cancel = [UIAlertAction
                                         actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                         style:UIAlertActionStyleCancel
                                         handler:^(UIAlertAction * action)
                                         {
                                             
                                         }];
                [alert addAction:cancel];
                
                UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
                alert.popoverPresentationController.sourceView = pView;
                alert.popoverPresentationController.sourceRect = pView.frame;
                [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
                /*
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Folder name",nil) message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Done",nil),nil];
                alert.alertViewStyle = UIAlertViewStylePlainTextInput;
                [alert setTag:100];
                [alert show];
                */
            }else{
                //NSString* folderName = [[[items objectForKey:account] allKeys] objectAtIndex:indexPath.row-1];
                NSString* folderName = [[sortedFolders objectAtIndex:indexPath.section] objectAtIndex:indexPath.row-1];
                if(folderName != nil){
                    NSDictionary* folders = [items valueForKey:account];
                    FolderInfo* fi = [folders valueForKey:folderName];
                    if ([self.caller respondsToSelector:@selector(didSelectItem:title:)]) {
                        [self closeView];
                        [self.caller didSelectItem:[NSString stringWithString:fi.folderPath] title:account];
                    }
                }
            }
            
        }
    }
    
    
}

/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100)
    {
        if (buttonIndex == 0)
        {
            
        }else{
            [[GlobalRouter sharedManager] requestCreateFolder:[[alertView textFieldAtIndex:0] text]];
            //[self.tableView reloadData];
            [self closeView];
        }
    }
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

- (IBAction)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        
        CGPoint p = [gestureRecognizer locationInView:self.tableView];
        
        NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:p];
        if (indexPath == nil) {
            NSLog(@"long press on table view but not on a row");
        }else{
            // Skip service items, we need only folders
            if(!(indexPath.section == items.count || (items.count == 0 && indexPath.section == 1))) {
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                if (cell.isHighlighted && indexPath.row > 0){ // we don't need to tap the first row-box name
                    NSString* account = [sortedItems objectAtIndex:indexPath.section];
                    if(indexPath.row != [[items objectForKey:account] allKeys].count+1){
                        // Can we rename that folder?
                        NSString* folderName = [[sortedFolders objectAtIndex:indexPath.section] objectAtIndex:indexPath.row-1];
                        boxTypes boxT = btUnknown;
                        if(folderName != nil){
                            NSDictionary* folders = [items valueForKey:account];
                            FolderInfo* fi = [folders valueForKey:folderName];
                            boxT = fi.folderType;
                        }
                        if (boxT == btUnknown) {
                            // Looks like we can edit it!
                            UIAlertController * alert = [UIAlertController
                                                         alertControllerWithTitle:NSLocalizedString(@"Rename folder",nil)
                                                         message:folderName
                                                         preferredStyle:UIAlertControllerStyleAlert];
                            [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                                textField.placeholder = @"New folder name";
                                textField.secureTextEntry = NO;
                            }];
                            
                            __weak __typeof__(self) weakSelf = self;
                            UIAlertAction* canSend = [UIAlertAction
                              actionWithTitle:NSLocalizedString(@"Rename", nil)
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
                                  __strong __typeof__(self) strongSelf = weakSelf;
                                  if([[[alert textFields][0] text] isEqualToString:@""]){
                                      
                                  }else{
                                      [GlobalRouter sharedManager].currentAccount = account;
                                      NSString* oldName = [strongSelf->sortedFolders objectAtIndex:indexPath.section][indexPath.row-1];
                                      // Rename on the server and change everywhere else
                                      [[GlobalRouter sharedManager] requestRenameFolder:oldName newName:[[alert textFields][0] text]];
                                      
                                      [strongSelf->sortedFolders objectAtIndex:indexPath.section][indexPath.row-1] = [[alert textFields][0] text];
                                      [self.tableView reloadData];
                                      
                                      NSMutableDictionary* folders = [strongSelf->items valueForKey:account];
                                      [folders setValue:[folders valueForKey:oldName] forKey:[[alert textFields][0] text]];
                                      [folders removeObjectForKey:oldName];
                                      //FolderInfo* fi = [folders valueForKey:folderName];
                                  }
                              }];
                            [alert addAction:canSend];
                            
                            UIAlertAction* cancel = [UIAlertAction
                                                     actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                                     style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction * action)
                                                     {
                                                         
                                                     }];
                            [alert addAction:cancel];
                            
                            UIView* pView = self.view;//[[GlobalRouter sharedManager] getCurrentView];
                            alert.popoverPresentationController.sourceView = pView;
                            alert.popoverPresentationController.sourceRect = pView.frame;
                            [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
                        }
                        NSLog(@"long press on %@ (%ld) at section %ld row %ld", folderName, (long)boxT, (long)indexPath.section, (long)indexPath.row);
                    }
                }
            }
        }
    }
}

@end

