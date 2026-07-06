//
//  ShortcutsTableViewController.m
//  SenseMailShare
//
//  Created by Sergey on 29.01.2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

#import "ShortcutsTableViewController.h"

#import "GlobalRouter.h"
#import "SettingsEntity.h"
#import "Settings2Interactor.h"
#import "UserInfoDataManager.h"
#import "ShortcutEntity.h"
#import "EditShortcutTableViewController.h"

@interface ShortcutsTableViewController ()

@end

@implementation ShortcutsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    button1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save and close",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needSaveSettings)];
    buttonR = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit",nil) style:UIBarButtonItemStylePlain target:self action:@selector(editMode:)];
    //buttonR = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editMode:)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeSettings)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:button1, buttonR, flexibleItem, button2, nil]];
    
    buttonR.enabled = self.items.count > 0;
    
    if (@available(iOS 11.0, *)) {
        
    }else{
        self.tableView.rowHeight = 64;
    }
    
    /*
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    tapGesture.delegate = self;
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
     */
}

-(void)setUp
{
    UserInfoDataManager* man = [[UserInfoDataManager alloc] init];
    self.items = [man getShortcuts:[GlobalRouter sharedManager].pin];
    barEnabled = _settings.useShortcuts;
}

-(void)viewDidAppear:(BOOL)animated
{
    buttonR.enabled = self.items.count > 0;
}

-(void)hideKeyboard
{
    [self.view endEditing:YES];
}

-(void)editMode:(id)sender
{
    [self.tableView setEditing:!self.tableView.isEditing];
    if (self.tableView.isEditing) {
        [buttonR setTitle:NSLocalizedString(@"Done",nil)];
        button1.enabled = NO;
        button2.enabled = NO;
    }else{
        [buttonR setTitle:NSLocalizedString(@"Edit",nil)];
        button1.enabled = YES;
        button2.enabled = YES;
        if (self.items.count == 0) {
            buttonR.enabled = NO;
        }else{
            buttonR.enabled = YES;
        }
    }
}

-(void)needSaveSettings
{
    self.settings.useShortcuts = enableBarSwitch.on;
    for (int i=0;i<self.items.count; i++) {
        ((ShortcutEntity*)self.items[i]).shortcutPosition = i;
    }
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        BOOL res = [self.interactor saveShortcuts:self.items pin:[GlobalRouter sharedManager].pin];
        if (!res) {
            [CommonProcs showMessage:@"" title:NSLocalizedString(@"Error saving shortcuts",nil)];
        }
        res = [self.interactor saveSettings:[self.settings copy] :[GlobalRouter sharedManager].pin];
        if (strongSelf->toDelete) {
            for (ShortcutEntity* ent in strongSelf->toDelete) {
                [self.interactor deleteShortcut:ent];
            }
            strongSelf->toDelete = nil;
        }
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
    });
}

-(void)finished
{
    [[[GlobalRouter sharedManager] getDetailNavController] popViewControllerAnimated:YES];
}

-(BOOL)checkIfChanged
{
    return  self.settings.useShortcuts != enableBarSwitch.on;
}

-(void)closeSettings
{
    BOOL changed = [self checkIfChanged];
    if (changed) {
        [CommonProcs askYesNoAndDoWithTitle:NSLocalizedString(@"Warning", nil) text:NSLocalizedString(@"There are unsaved changes. Save before closing.", nil) blockYes:^{
            [self needSaveSettings];
        } blockNo:^{
            [self finished];
        }];
    }else{
        [self finished];
    }
}

-(void)itemChanged:(ShortcutEntity*)item
{
    ShortcutEntity* found = nil;
    for (ShortcutEntity* sitem in self.items) {
        if([sitem.shortcutID isEqualToString:item.shortcutID]){
            found = sitem;
            break;
        }
    }
    if(found){
        found.shortcutName = item.shortcutName;
        found.shortcutCommand = item.shortcutCommand;
    }else{
        [self.items addObject:item];
    }
    item.shortcutPosition = (int)[self.items indexOfObject:item];
    NSLog(@"Item %@ position is %i", item.shortcutName, item.shortcutPosition);
    [self.tableView reloadData];
}

-(void)enableBarChanged:(UISwitch*)sender
{
    barEnabled = sender.isOn;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    long ret = 0;
    if (section == 0) {
        ret = 1;
    }else if(section == 1){
        ret = self.items.count;
    }else if(section == 2){
        ret = 1;
    }
    return ret;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* cellID = @"ShortcutCell";
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    switch (indexPath.section) {
        case 0:
            if (indexPath.row == 0) {
                cell.textLabel.text = NSLocalizedString(@"Enable Bar",nil);
                cell.detailTextLabel.numberOfLines = 0;
                cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
                cell.detailTextLabel.text = NSLocalizedString(@"Show the shortcuts bar above the message list", nil);
                if (@available(iOS 13.0, *)) {
                    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
                } else {
                    // Fallback on earlier versions
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                }
                UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 60, 30)];
                enableBarSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(10,0, 50, 30)];
                [enableBarSwitch setOn:barEnabled];//self.settings.useShortcuts];
                [enableBarSwitch addTarget:self action:@selector(enableBarChanged:) forControlEvents:UIControlEventValueChanged];
                //barEnabled = self.settings.useShortcuts;
                [wrapper addSubview:enableBarSwitch];
                cell.accessoryView = wrapper;
            }
            break;
        case 1:
        {
            ShortcutEntity* shc = self.items[indexPath.row];
            cell.textLabel.text = shc.shortcutName;
            NSArray* desc = [EditShortcutTableViewController getCommandDescription:shc.shortcutCommand];
            if (desc.count == 2) {
                cell.detailTextLabel.text = desc[0];
            }else{
                cell.detailTextLabel.text = @"Unrecognized command";
            }
            cell.detailTextLabel.numberOfLines = 0;
            cell.accessoryView = nil;
            break;
        }
        case 2:
            cell.textLabel.text = @"Add shortcut...";
            cell.detailTextLabel.text = @"";
            cell.accessoryView = nil;
            [cell.imageView setImage:[UIImage imageNamed:@"addEmailAcc"]];
            break;
            
        default:
            cell.textLabel.text = @"";
            cell.detailTextLabel.text = @"";
            cell.accessoryView = nil;
            break;
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        return NSLocalizedString(@"Shortcut List",nil);
    }else{
        return @"";
    }
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        return YES;
    }
    return NO;
}



// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        if (!toDelete) {
            toDelete = [[NSMutableArray alloc] init];
        }
        [toDelete addObject:self.items[indexPath.row]];
        //[self.interactor deleteShortcut:self.items[indexPath.row]];
        [self.items removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}



// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    
    id item = self.items[fromIndexPath.row];
    [self.items removeObjectAtIndex:fromIndexPath.row];
    [self.items insertObject:item atIndex:toIndexPath.row];
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    if (indexPath.section == 1) {
        return YES;
    }
    return NO;
}


#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here, for example:
    // Create the next view controller.
    if (indexPath.section == 2 && indexPath.row == 0) {
        EditShortcutTableViewController *detailViewController = [[EditShortcutTableViewController alloc] initWithNibName:@"EditShortcutTableViewController" bundle:nil];
        detailViewController.parentVC = self;
        detailViewController.item = nil;
        // Push the view controller.
        [self.navigationController pushViewController:detailViewController animated:YES];
    }else if(indexPath.section == 1){
        EditShortcutTableViewController *detailViewController = [[EditShortcutTableViewController alloc] initWithNibName:@"EditShortcutTableViewController" bundle:nil];
        detailViewController.parentVC = self;
        detailViewController.item = self.items[indexPath.row];
        // Push the view controller.
        [self.navigationController pushViewController:detailViewController animated:YES];
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
