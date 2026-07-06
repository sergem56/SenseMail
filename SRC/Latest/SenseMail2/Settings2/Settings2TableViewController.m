//
//  Settings2TableViewController.m
//  SenseMailShare
//
//  Created by Sergey on 06.12.2019.
//  Copyright © 2019 Sergey. All rights reserved.
//

#import "Settings2TableViewController.h"
#import "Settings2ViewController.h"
#import "SettingsEntity.h"
#import "Settings2Interactor.h"
#import "SecurityTableViewController.h"
#import "AppearanceTableViewController.h"
#import "ShortcutsTableViewController.h"

#if USESEC
#import "VPNTableViewController.h"
#endif

@interface Settings2TableViewController ()

@end

@implementation Settings2TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINib *nib = [UINib nibWithNibName:@"Settings2GeneralCell" bundle:nil];
    [[self tableView] registerNib:nib forCellReuseIdentifier:@"GeneralCell"];
    
#if USESEC
    self.generalItems = @[NSLocalizedString(@"Security",nil), NSLocalizedString(@"Appearance",nil), NSLocalizedString(@"Shortcuts",nil), NSLocalizedString(@"Clear all",nil), NSLocalizedString(@"VPN",nil)];
    self.generalItemsDetails = @[NSLocalizedString(@"PIN, Background mode, Bio ID",nil), NSLocalizedString(@"Sorting, Number of messages",nil), NSLocalizedString(@"Shortcut bar settings",nil), NSLocalizedString(@"Delete all user data",nil), NSLocalizedString(@"Connect to VPN before checking mail",nil)];
    self.generalItemsImages = @[@"importantCircle", @"markCircle", @"shortcut", @"deletedCircle", @"vpnCircle"];
#else
    self.generalItems = @[NSLocalizedString(@"Security",nil), NSLocalizedString(@"Appearance",nil), NSLocalizedString(@"Shortcuts",nil), NSLocalizedString(@"Clear all",nil)];
    self.generalItemsDetails = @[NSLocalizedString(@"PIN, Background mode, Bio ID",nil), NSLocalizedString(@"Sorting, Number of messages",nil), NSLocalizedString(@"Shortcut bar settings",nil), NSLocalizedString(@"Delete all user data",nil)];
    self.generalItemsImages = @[@"importantCircle", @"markCircle", @"shortcut", @"deletedCircle"];
#endif
    
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
    //UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save and close",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needSaveSettings)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeSettings)];
    UIBarButtonItem* buttonAdd = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"addEmailAcc"] style:UIBarButtonItemStylePlain target:self action:@selector(needAddItem)];
    // No save here as saving is in the individual pages
    [self setToolbarItems:[NSArray arrayWithObjects:buttonAdd, flexibleItem, /*button1,*/ button2, nil]];
    
    if (@available(iOS 11.0, *)) {
        
    }else{
        self.tableView.rowHeight = 64;
    }
    //[self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"pinScrollBg2"]]];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)closeSettings
{
    [self.interactor closeSettings];
}

-(void)needAddItem
{
    [self.interactor needAddSettings];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.generalItems.count;
    }else{
        return self.accountItems.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"GeneralCell" forIndexPath:indexPath];
        cell.textLabel.text = self.generalItems[indexPath.row];
        cell.detailTextLabel.text = self.generalItemsDetails[indexPath.row];
        [cell.imageView setImage:[UIImage imageNamed:self.generalItemsImages[indexPath.row]]];
        if ([cell.textLabel.text isEqualToString:NSLocalizedString(@"Clear all",nil)]) {
            cell.textLabel.textColor = [UIColor redColor];
        }else{
            if (@available(iOS 13.0, *)) {
                cell.backgroundColor = [UIColor systemBackgroundColor];
            } else {
                cell.backgroundColor = [UIColor whiteColor];
            }
        }
    }else{
        cell = [tableView dequeueReusableCellWithIdentifier:@"GeneralCell" forIndexPath:indexPath];
        cell.textLabel.text = ((SettingsEntity*)self.accountItems[indexPath.row]).settingsName;
        cell.detailTextLabel.text = ((SettingsEntity*)self.accountItems[indexPath.row]).userName;
        
    }
    
    return cell;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return NSLocalizedString(@"General settings", nil);
    }else{
        return NSLocalizedString(@"Account settings", nil);
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"";
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    if (indexPath.section == 0) {
        return NO;
    }
    return YES;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self.interactor deleteSetting:[self.accountItems[indexPath.row] copy]];
        
        [self.accountItems removeObjectAtIndex:indexPath.row];
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
    // Navigation logic may go here, for example:
    // Create the next view controller.
    if(indexPath.section == 1){
        Settings2ViewController *detailViewController = [[Settings2ViewController alloc] initWithNibName:@"Settings2View" bundle:nil];
        detailViewController.settings = self.accountItems[indexPath.row];
        //[detailViewController setCurrentSettings];
        detailViewController.interactor = self.interactor;
        
        // Push the view controller.
        [self.navigationController pushViewController:detailViewController animated:YES];
    }else if(indexPath.section == 0){
        if (indexPath.row == 0) {
            SecurityTableViewController* secVC = [[SecurityTableViewController alloc] initWithNibName:@"SecurityTableViewController" bundle:nil];
            secVC.interactor = self.interactor;
            secVC.settings = self.generalSettings;
            [secVC setUp];
            
            [self.navigationController pushViewController:secVC animated:YES];
        }else if(indexPath.row == 1){
            AppearanceTableViewController* appVC = [[AppearanceTableViewController alloc] initWithNibName:@"AppearanceTableViewController" bundle:nil];
            appVC.interactor = self.interactor;
            appVC.settings = self.generalSettings;
            [appVC setUp];
            
            [self.navigationController pushViewController:appVC animated:YES];
        }else if(indexPath.row == 2){ // Shortcuts
            ShortcutsTableViewController* shVC = [[ShortcutsTableViewController alloc] initWithNibName:@"ShortcutsTableViewController" bundle:nil];
            shVC.interactor = self.interactor;
            shVC.settings = self.generalSettings;
            [shVC setUp];
            
            [self.navigationController pushViewController:shVC animated:YES];
        }else if(indexPath.row == 3){
            [self.interactor wantSOS];
            
        }else if(indexPath.row == 4){
#if USESEC
            // VPN settings
            VPNTableViewController* vpnVC = [[VPNTableViewController alloc] initWithNibName:@"VPNTableViewController" bundle:nil];
            vpnVC.interactor = self.interactor;
            vpnVC.settings = self.generalSettings;
            [vpnVC setUp];
            
            [self.navigationController pushViewController:vpnVC animated:YES];
#endif
        }else{
            
        }
    }
}

/*
- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}*/

@end
