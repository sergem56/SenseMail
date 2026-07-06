//
//  EditShortcutTableViewController.m
//  SenseMailShare
//
//  Created by Sergey on 30.01.2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

#import "EditShortcutTableViewController.h"
#import "CommonStuff.h"
#import "GlobalRouter.h"
#import "ShortcutEntity.h"
#import "CommonProcs.h"
#import "ShortcutsTableViewController.h"

@interface EditShortcutTableViewController ()

@end

@implementation EditShortcutTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    // Dismiss keyboard tapping outside the text field
    UITapGestureRecognizer* cancel = [[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)];
    cancel.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:cancel];
    
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save and close",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needSaveSettings)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeSettings)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:button1, flexibleItem, button2, nil]];
    
    UIBarButtonItem* button12 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save and close",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needSaveSettings)];
    UIBarButtonItem *flexibleItem2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button22 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeSettings)];
    inputTB = [[UIToolbar alloc] init];
    inputTB.frame = CGRectMake(0,0,250,44);
    inputTB.items = [NSArray arrayWithObjects:button12, flexibleItem2, button22, nil];
    
    commandItems = [[NSMutableArray alloc] initWithArray:
    /*commandItems = */@[
        @{@"Name":NSLocalizedString(@"Search",nil),@"Command":[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stUserInput, @""]},
        @{@"Name":NSLocalizedString(@"Last week",nil), @"Command":[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stLastWeek, @""]},
        @{@"Name":NSLocalizedString(@"Last month",nil),@"Command":[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stLastMonth, @""]},
        @{@"Name":NSLocalizedString(@"Unread",nil),@"Command":[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stUnread, @""]},
        @{@"Name":NSLocalizedString(@"Important",nil),@"Command":[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stImportant, @""]},
        @{@"Name":NSLocalizedString(@"Large",nil),@"Command":[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stLarge, @""]},
        @{@"Name":NSLocalizedString(@"Larger than",nil),@"Command":[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stSizeMore, @""]},
        @{@"Name":NSLocalizedString(@"Smaller than",nil),@"Command":[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stSizeLess, @""]},
        @{@"Name":NSLocalizedString(@"Flagged",nil),@"Command":[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stFlagged, @""]},
        @{@"Name":NSLocalizedString(@"Protected",nil),@"Command":[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stProtected, @""]},
        @{@"Name":NSLocalizedString(@"Answered",nil),@"Command":[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stAnswered, @""]},
#if DEBUG
        @{@"Name":NSLocalizedString(@"With Attachments",nil),@"Command":[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stWithAttachments, @""]},
#endif
        @{@"Name":NSLocalizedString(@"Mail From",nil),@"Command":[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stFrom, @""]},
        @{@"Name":NSLocalizedString(@"Mail To",nil),@"Command":[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stTo, @""]},
        @{@"Name":NSLocalizedString(@"Received on",nil),@"Command":[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stDate, @""]},
        @{@"Name":NSLocalizedString(@"Received before",nil),@"Command":[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stDateBefore, @""]},
        @{@"Name":NSLocalizedString(@"Received after",nil),@"Command":[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stDateAfter, @""]},
        @{@"Name":NSLocalizedString(@"Received in month",nil),@"Command":[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stInTheMonth, @""]},
        @{@"Name":NSLocalizedString(@"Received between",nil),@"Command":[NSString stringWithFormat:@"%li%li\n%@", (long)scFilter, (long)stBwDates, @""]},
        @{@"Name":NSLocalizedString(@"Spam",nil), @"Command":[NSString stringWithFormat:@"%li", (long)scSpam]},
        @{@"Name":NSLocalizedString(@"Sent",nil), @"Command":[NSString stringWithFormat:@"%li", (long)scSent]}
        //@{@"Name":NSLocalizedString(@"Folder",nil), @"Command":[NSString stringWithFormat:@"%li%@\n%@", (long)scCustomFolder, @"--", @"--"]}
    ]];
    
    for (NSString* acc in [[GlobalRouter sharedManager].otherFolders allKeys]) {
        NSString* addr = @"";
        NSArray* tmp = [[GlobalRouter sharedManager].accountsNames allKeysForObject:acc];
        if(tmp && tmp.count > 0){
            addr = tmp[0];
        }
        [commandItems addObject:@{@"Name":NSLocalizedString(@"Folder",nil), @"Command":[NSString stringWithFormat:@"%li%@\n%@", (long)scCustomFolder, @"--",addr]}];
    }
    selectedCommand = -1;
    
    if (@available(iOS 11.0, *)) {
        
    }else{
        self.tableView.rowHeight = 64;
    }
}

-(void)finished
{
    [[[GlobalRouter sharedManager] getDetailNavController] popViewControllerAnimated:YES];
    self.item = nil;
}

-(void)closeSettings
{
    /*BOOL changed = [self checkIfChanged];
    if (changed) {
        [CommonProcs askYesNoAndDoWithTitle:NSLocalizedString(@"Warning", nil) text:NSLocalizedString(@"There are unsaved changes. Save before closing.", nil) blockYes:^{
            [self needSaveSettings];
        } blockNo:^{
            [self finished];
        }];
    }else{*/
        [self finished];
    //}
}

-(void)needSaveSettings
{
    if (!self.item) {
        self.item = [[ShortcutEntity alloc] init];
        self.item.shortcutID = [[NSUUID UUID] UUIDString];
    }else{
        if (!self.item.shortcutID || [self.item.shortcutID isEqualToString:@""]) {
            self.item.shortcutID = [[NSUUID UUID] UUIDString];
        }
    }
    NSString* cmd = [commandItems[selectedCommand] valueForKey:@"Command"];
    if (selectedCommand >=0) {
        if ([cmd substringToIndex:1].intValue == scCustomFolder) {
            // Get the command with selected folder
            NSRange pos = [cmd rangeOfString:@"\n"];
            NSString* addr = [cmd substringFromIndex:pos.location+1];
            self.item.shortcutCommand = [NSString stringWithFormat:@"%li%@\n%@",(long)scCustomFolder, customFolder, addr];
        }else{
            self.item.shortcutCommand = [commandItems[selectedCommand] valueForKey:@"Command"];
            // Get the user text
            UITableViewCell* selCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedCommand inSection:1]];
            UITextField* txt = [selCell viewWithTag:1001];
            if (txt) {
                self.item.shortcutCommand = [NSString stringWithFormat:@"%@%@", self.item.shortcutCommand, txt.text];
            }
        }
    }else{
        [CommonProcs showVanishingErrorMessage:NSLocalizedString(@"Command not selected", nil)];
        return;
    }
    if ([nameField.text isEqualToString:@""]) {
        [CommonProcs showVanishingErrorMessage:NSLocalizedString(@"Name is empty", nil)];
        return;
    }else{
        self.item.shortcutName = nameField.text;
    }
    
    [self.parentVC itemChanged:self.item];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self finished];
    });
    
    /*self.settings.useShortcuts = enableBarSwitch.on;
    
    //__weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        //__strong __typeof__(self) strongSelf = weakSelf;
        BOOL res = [self.interactor saveSettings:[self.settings copy] :[GlobalRouter sharedManager].pin];
        if(res){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self finished];
            });
        }else{
            // Shouldn't get here, but who knows
            //dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs showMessage:@"" title:NSLocalizedString(@"Error saving settings",nil)];
            //});
        }
    });*/
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    long ret = 1;
    if (section == 1) {
        ret = commandItems.count;
    }
    return ret;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* cellID = @"EditShortcutCell";
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    switch (indexPath.section) {
        case 0:
            if (indexPath.row == 0) {
                cell.textLabel.text = NSLocalizedString(@"Name",nil);
                cell.detailTextLabel.numberOfLines = 0;
                //cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
                cell.detailTextLabel.text = NSLocalizedString(@"Display name of the shortcut", nil);
                
                if (@available(iOS 13.0, *)) {
                    cell.detailTextLabel.textColor = [UIColor labelColor];
                } else {
                    // Fallback on earlier versions
                    cell.detailTextLabel.textColor = [UIColor blackColor];
                }
                UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 140, 30)];
                if(!nameField){
                    nameField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 124, 30)];
                    [nameField setFont:[UIFont systemFontOfSize:12]];
                    nameField.tag = 900;
                    
                    [[nameField layer] setCornerRadius:6.0f];
                    [[nameField layer] setMasksToBounds:YES];
                    [[nameField layer] setBorderWidth:0.35f];
                    [[nameField layer] setBorderColor:[UIColor lightGrayColor].CGColor];
                    
                    nameField.inputAccessoryView = inputTB;
                }
                [wrapper addSubview:nameField];
                if (self.item) {
                    [nameField setText:self.item.shortcutName];
                }
                cell.accessoryView = wrapper;
            }
            break;
        case 1:{
            cell.textLabel.text = [commandItems[indexPath.row] valueForKey:@"Name"];
            NSString* cmd = [commandItems[indexPath.row] valueForKey:@"Command"];
            
            NSArray* cmdD = [EditShortcutTableViewController getCommandDescription:cmd];
            cell.detailTextLabel.text = cmdD[0];
            cell.detailTextLabel.numberOfLines = 0;
            
            shortcutCommands commandS = [cmd substringToIndex:1].intValue;
            
            UIView* wrapper;
            UIImageView* checkMark;
            if(![(NSNumber*)cmdD[1] boolValue] || commandS == scCustomFolder){
                wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 140, 30)];
                checkMark = [[UIImageView alloc] initWithFrame:CGRectMake(126, 7, 16, 16)];
            }else{
                wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 20, 30)];
                checkMark = [[UIImageView alloc] initWithFrame:CGRectMake(2, 7, 16, 16)];
            }
            checkMark.tag = 1000;
            [wrapper addSubview:checkMark];
            
            // should ckeck for custom folder command as well since it's different inthe item
            if(selectedCommand == -1 && self.item && commandS == scCustomFolder){
                NSRange pos = [self.item.shortcutCommand rangeOfString:@"\n"];
                NSString* addrItem = [self.item.shortcutCommand substringFromIndex:pos.location+1];
                NSString* folderItem = [self.item.shortcutCommand substringToIndex:pos.location];
                folderItem = [folderItem substringFromIndex:1]; // Get rid of the command code
                
                pos = [cmd rangeOfString:@"\n"];
                NSString* addrCommand = [cmd substringFromIndex:pos.location+1];
                if ([addrItem isEqualToString:addrCommand]) {
                    [checkMark setImage:[UIImage imageNamed:@"OK2"]];
                    selectedCommand = (int)indexPath.row;
                    // Change the folder in the detailed text
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"Show %@ at %@", folderItem, addrItem];
                }
            }else if (selectedCommand == -1 && self.item && [self.item.shortcutCommand hasPrefix:cmd]/*[self.item.shortcutCommand isEqualToString:cmd]*/) {
                [checkMark setImage:[UIImage imageNamed:@"OK2"]];
                selectedCommand = (int)indexPath.row;
            }else if(selectedCommand == indexPath.row){
                [checkMark setImage:[UIImage imageNamed:@"OK2"]];
                if (indexPath.row == selectedCommand) {
                    NSString* cmd = [commandItems[selectedCommand] valueForKey:@"Command"];
                    NSRange pos = [cmd rangeOfString:@"\n"];
                    NSString* addr = [cmd substringFromIndex:pos.location+1];
                    cell.detailTextLabel.text = [NSString stringWithFormat:@"Show %@ at %@", customFolder, addr];
                }
            }
            
            if(![(NSNumber*)cmdD[1] boolValue]){
                UITextField* nameField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 124, 30)];
                [nameField setFont:[UIFont systemFontOfSize:12]];
                nameField.tag = 1001;
                [[nameField layer] setCornerRadius:6.0f];
                [[nameField layer] setMasksToBounds:YES];
                [[nameField layer] setBorderWidth:0.35f];
                [[nameField layer] setBorderColor:[UIColor lightGrayColor].CGColor];
                [nameField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
                nameField.inputAccessoryView = inputTB;
                [wrapper addSubview:nameField];
                if (self.item && [self.item.shortcutCommand hasPrefix:cmd]){
                    [nameField setText:[self.item.shortcutCommand substringFromIndex:cmd.length-1]];
                }else{
                    [nameField setText:@""];
                }
                if (alteredText) {
                    NSString* txt = [alteredText valueForKey:[NSString stringWithFormat:@"%ld",(long)indexPath.row]];
                    if (txt) {
                        [nameField setText:txt];
                    }
                }
            }else if(commandS == scCustomFolder){
                UIButton* selectB = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 124, 30)];
                [selectB addTarget:self action:@selector(customFolderPressed:) forControlEvents:UIControlEventTouchUpInside];
                [selectB setTitle:NSLocalizedString(@"Select...", nil) forState:UIControlStateNormal];
                [selectB.titleLabel setFont:[UIFont systemFontOfSize:12]];
                if (@available(iOS 13.0, *)) {
                    [selectB setTitleColor:[UIColor systemBlueColor] forState:UIControlStateNormal];
                } else {
                    // Fallback on earlier versions
                    [selectB setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
                }
                [[selectB layer] setCornerRadius:6.0f];
                [[selectB layer] setMasksToBounds:YES];
                [[selectB layer] setBorderWidth:0.35f];
                [[selectB layer] setBorderColor:[UIColor lightGrayColor].CGColor];
                [wrapper addSubview:selectB];
            }
            cell.accessoryView = wrapper;
            break;
        }
        default:
            cell.textLabel.text = @"";
            cell.detailTextLabel.text = @"";
            cell.accessoryView = nil;
            break;
    }
    
    return cell;
}

-(void)customFolderPressed:(UIButton*)sender
{
    //[CommonProcs showMessage:@"Not implemented" title:@""];
    CGRect position = [sender convertRect:sender.frame toView:self.tableView];
    // Ask the UITableView for all the rows in that rect, in this case it should be 1
    NSArray *indexPaths = [self.tableView indexPathsForRowsInRect:position];
    long row;
    if (indexPaths.count > 0) {
        row = ((NSIndexPath*)indexPaths[0]).row;
        NSString* cmd = [commandItems[row] valueForKey:@"Command"];
        NSRange pos = [cmd rangeOfString:@"\n"];
        NSString* addr = [cmd substringFromIndex:pos.location+1];
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SelectStoryboard" bundle: nil];
        SelectFolderViewController* sFolder = [storyboard instantiateViewControllerWithIdentifier:@"FolderSelect"];
        
        sFolder.accountName = [[GlobalRouter sharedManager].accountsNames valueForKey:addr];
        sFolder.parent = self;
        
        sFolder.items = [[[GlobalRouter sharedManager].otherFolders objectForKey:sFolder.accountName] allKeys];
        [[[GlobalRouter sharedManager] getDetailNavController] pushViewController:sFolder animated:YES];
        
        // Set the check mark
        if(selectedCommand != row){
            [self removeCheckMark];
            [[[self.tableView cellForRowAtIndexPath:indexPaths[0]] viewWithTag:1000] setImage:[UIImage imageNamed:@"OK2"]];
            selectedCommand = (int)row;
        }
    }
}

-(void)itemSelected:(NSString *)itemPath title:(NSString *)title
{
    NSLog(@"Address is %@", itemPath);
    //NSString* cmd = [commandItems[selectedCommand] valueForKey:@"Command"];
    customFolder = itemPath;
    
    // Change detailText to show the folder
    // Need to get the email address
    NSString* cmd = [commandItems[selectedCommand] valueForKey:@"Command"];
    NSRange pos = [cmd rangeOfString:@"\n"];
    NSString* addr = [cmd substringFromIndex:pos.location+1];
    
    UITableViewCell* ccell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:selectedCommand inSection:1]];
    ccell.detailTextLabel.text = [NSString stringWithFormat:@"Show %@ at %@", itemPath, addr];
    
}

-(void)textFieldDidChange:(UITextField*)caller
{
    CGRect position = [caller convertRect:caller.frame toView:self.tableView];
    // Ask the UITableView for all the rows in that rect, in this case it should be 1
    NSArray *indexPaths = [self.tableView indexPathsForRowsInRect:position];
    long row;
    if (indexPaths.count > 0) {
        row = ((NSIndexPath*)indexPaths[0]).row;
        if (!alteredText) {
            alteredText = [[NSMutableDictionary alloc] init];
        }
        [alteredText setValue:caller.text forKey:[NSString stringWithFormat:@"%lu",row]];
        // Set the check mark
        if(selectedCommand != row){
            [self removeCheckMark];
            [[[self.tableView cellForRowAtIndexPath:indexPaths[0]] viewWithTag:1000] setImage:[UIImage imageNamed:@"OK2"]];
            selectedCommand = (int)row;
        }
    }
}

+(NSArray*)getCommandDescription:(NSString*)command
{
    NSString* ret = @"";
    BOOL hideText = NO;
    // Search command format:
    // 1. Length = 1 - scFavs, scSent or scSpam - standard folders
    // 2. scFilter+stSearchType+\n+Search string - standard search types
    // 3. scFilter+Search string - search current box for a string - SHOULD NOT BE USED
    // 4. scCustomFolder+FolderName+\n+Email Address - any IMAP folder
    // For example search before 11/11/2011 = scFilter+stDateBefore+\n+@"11/11/2011"
    if (command.length == 1) {
        switch (command.intValue) {
            case scFavs:
                ret = NSLocalizedString(@"Favs folder. Not every provider supports that.", nil);
                hideText = YES;
                break;
                
            case scSent:
                ret = NSLocalizedString(@"Unified Sent folder", nil);
                hideText = YES;
                break;
                
            case scSpam:
                ret = NSLocalizedString(@"Unified Spam folder", nil);
                hideText = YES;
                break;
                
            default:
                break;
        }
    }else if ([command substringToIndex:1].intValue == scFilter){
        NSRange del = [command rangeOfString:@"\n"];
        if(del.location != NSNotFound){
            NSString* searchType = [command substringWithRange:NSMakeRange(1, del.location-1)];
            NSString* searchText = [command substringFromIndex:del.location+1];
            NSString* subCommand;
            switch (searchType.intValue) {
                case stLastWeek:
                    subCommand = NSLocalizedString(@"Messages for the last week", nil);
                    hideText = YES;
                    break;
                case stLastMonth:
                    subCommand = NSLocalizedString(@"Messages for the last month", nil);
                    hideText = YES;
                    break;
                case stUnread:
                    subCommand = NSLocalizedString(@"Unread messages", nil);
                    hideText = YES;
                    break;
                case stAnswered:
                    subCommand = NSLocalizedString(@"Answered messages", nil);
                    hideText = YES;
                    break;
                case stLarge:
                    subCommand = NSLocalizedString(@"Large messages (>200K)", nil);
                    hideText = YES;
                    break;
                case stWithAttachments:
                    subCommand = NSLocalizedString(@"Messages with the attachments", nil);
                    hideText = YES;
                    break;
                case stFlagged:
                    subCommand = NSLocalizedString(@"Flagged/Starred messages", nil);
                    hideText = YES;
                    break;
                case stProtected:
                    subCommand = NSLocalizedString(@"SenseMail encrypted messages", nil);
                    hideText = YES;
                    break;
                case stImportant:
                    subCommand = NSLocalizedString(@"Important messages", nil);
                    hideText = YES;
                    break;
                case stUserInput:
                    subCommand = NSLocalizedString(@"Search for the string", nil);
                    hideText = NO;
                    break;
                case stDate:
                    subCommand = NSLocalizedString(@"Received on", nil);
                    hideText = NO;
                    break;
                case stDateBefore:
                    subCommand = NSLocalizedString(@"Received before date", nil);
                    hideText = NO;
                    break;
                case stDateAfter:
                    subCommand = NSLocalizedString(@"Received after date", nil);
                    hideText = NO;
                    break;
                case stBwDates:
                    subCommand = NSLocalizedString(@"Received between Date1-Date2", nil);
                    hideText = NO;
                    break;
                case stInTheMonth:
                    subCommand = NSLocalizedString(@"Received in the month of the date, i.e. 1/12/2020 = December", nil);
                    hideText = NO;
                    break;
                case stTo:
                    subCommand = NSLocalizedString(@"Sent to the address", nil);
                    hideText = NO;
                    break;
                case stFrom:
                    subCommand = NSLocalizedString(@"Received from the address", nil);
                    hideText = NO;
                    break;
                case stSizeLess:
                    subCommand = NSLocalizedString(@"Message size is less than", nil);
                    hideText = NO;
                    break;
                case stSizeMore:
                    subCommand = NSLocalizedString(@"Message size is more than (i.e. 300K, 10M, etc)", nil);
                    hideText = NO;
                    break;
                default:
                    subCommand = NSLocalizedString(@"Unrecognized command", nil);
                    hideText = YES;
                    break;
            }
            //NSLog(@"Path & box = %@ at %@", searchType, searchText);
            if ([searchText isEqualToString:@""]) {
                ret = subCommand;//[NSString stringWithFormat:@"Show %@", subCommand];
                
            }else{
                ret = [NSString stringWithFormat:@"%@ %@", subCommand, searchText];
            }
        }else{
            // Search the string
            NSString* search = [command substringFromIndex:1];
            ret = [NSString stringWithFormat:@"Search %@", search];
        }
        
    }else if ([command substringToIndex:1].intValue == scCustomFolder){
        NSRange del = [command rangeOfString:@"\n"];
        if(del.location != NSNotFound){
            NSString* customPath = [command substringWithRange:NSMakeRange(1, del.location-1)];
            NSString* box = [command substringFromIndex:del.location+1];
            //NSLog(@"Path & box = %@ at %@", customPath, box);
            ret = [NSString stringWithFormat:@"Show %@ at %@", customPath, box];
            hideText = YES;
        }
    }
    return @[ret, [NSNumber numberWithBool:hideText]];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        return NSLocalizedString(@"Command type",nil);
    }else{
        return @"";
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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
    if (indexPath.section == 1) {
        [self removeCheckMark];
        selectedCommand = (int)indexPath.row;
        [[[self.tableView cellForRowAtIndexPath:indexPath] viewWithTag:1000] setImage:[UIImage imageNamed:@"OK2"]];
    }
}

-(void)removeCheckMark
{
    for(int i=0;i<commandItems.count;i++){
        [[[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:1]] viewWithTag:1000] setImage:nil];
    }
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
