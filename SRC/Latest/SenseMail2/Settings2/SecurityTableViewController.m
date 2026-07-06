//
//  SecurityTableViewController.m
//  SenseMailShare
//
//  Created by Sergey on 10.12.2019.
//  Copyright © 2019 Sergey. All rights reserved.
//

#import "SecurityTableViewController.h"
#import "GlobalRouter.h"
#import "Settings2Interactor.h"
#import "SettingsEntity.h"

@interface SecurityTableViewController ()

@end

@implementation SecurityTableViewController

@synthesize settings;

static NSString* cellID = @"secCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save and close",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needSaveSettings)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeSettings)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:button1, flexibleItem, button2, nil]];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    //self.tableView.estimatedRowHeight
    if (@available(iOS 11.0, *)) {
        
    }else{
        self.tableView.rowHeight = 96;
    }
}

-(void)setUp{
    if (self.settings) {
        bioSet = settings.useBioID;
        bgCheck = settings.keepInBg;
        clearBG = settings.clearOnBG;
        doNotHide = settings.doNotHideAccount;
    }
}
    

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int ret = 0;
    switch (section) {
        case 0:
            ret = 5;
            break;
        case 1:
            ret = 1;
            break;
        case 2:
            ret = 1;
            break;
        default:
            break;
    }
    return ret;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    switch (indexPath.section) {
        case 0:
            if (indexPath.row == 0) {
                cell.textLabel.text = NSLocalizedString(@"Data Encryption",nil);
                cell.detailTextLabel.numberOfLines = 0;
                cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
                cell.detailTextLabel.text = NSLocalizedString(@"PIN code is never stored and can’t be recovered if you forget it.",nil);
                if (@available(iOS 13.0, *)) {
                    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
                } else {
                    // Fallback on earlier versions
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                }
                UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 120, 30)];
                UIButton* changePinButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                [changePinButton setTitle:NSLocalizedString(@"Change PIN",nil) forState:UIControlStateNormal];
                [changePinButton setFrame:CGRectMake(10,0, 110, 30)];
                [changePinButton addTarget:self action:@selector(changePin) forControlEvents:UIControlEventTouchUpInside];
                [[changePinButton layer] setCornerRadius:6.0f];
                [[changePinButton layer] setMasksToBounds:YES];
                [[changePinButton layer] setBorderWidth:0.35f];
                [[changePinButton layer] setBorderColor:[UIColor lightGrayColor].CGColor];
                [wrapper addSubview:changePinButton];
                cell.accessoryView = wrapper;// changePinButton;
            }else if(indexPath.row == 1){
                cell.textLabel.text = NSLocalizedString(@"Emergency PIN",nil);
                cell.detailTextLabel.numberOfLines = 0;
                cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
                cell.detailTextLabel.text = NSLocalizedString(@"The PIN will permanently delete all user data once entered. The code is not shown here, set the new one if you forgot it.",nil);
                if (@available(iOS 13.0, *)) {
                    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
                } else {
                    // Fallback on earlier versions
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                }
                UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 120, 30)];
                erasePin = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, 110, 30)];
                //NSString* testPIN = [[NSUserDefaults standardUserDefaults] stringForKey:SOSPINSIG];
                NSString* testPIN = [CommonProcs getStringFromKeychain:SOSPINSIG service:@"SM"];
                if (testPIN && ![testPIN isEqualToString:@""]) {
                    erasePin.placeholder = NSLocalizedString(@"Erase PIN is set",nil);
                }else{
                    erasePin.placeholder = NSLocalizedString(@"No Erase PIN",nil);
                }
                [erasePin setFont:[UIFont systemFontOfSize:12]];
                
                [[erasePin layer] setCornerRadius:6.0f];
                [[erasePin layer] setMasksToBounds:YES];
                [[erasePin layer] setBorderWidth:0.35f];
                [[erasePin layer] setBorderColor:[UIColor lightGrayColor].CGColor];
                
                // Make the text indent
                UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, erasePin.frame.size.height)];
                leftView.backgroundColor = erasePin.backgroundColor;
                erasePin.leftView = leftView;
                erasePin.leftViewMode = UITextFieldViewModeAlways;
                
                // Dismiss keyboard tapping outside the text field
                [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)]];
                
                [wrapper addSubview:erasePin];
                cell.accessoryView = wrapper;
            }else if(indexPath.row == 2){
                cell.textLabel.text = NSLocalizedString(@"Erase All Data Now",nil);
                cell.detailTextLabel.numberOfLines = 0;
                cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
                cell.detailTextLabel.text = NSLocalizedString(@"Permanently delete all user data right now",nil);
                if (@available(iOS 13.0, *)) {
                    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
                } else {
                    // Fallback on earlier versions
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                }
                UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 120, 30)];
                UIButton* eraseButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
                [eraseButton setTitle:NSLocalizedString(@"Erase all",nil) forState:UIControlStateNormal];
                [eraseButton setFrame:CGRectMake(10,0, 110, 30)];
                [eraseButton setBackgroundColor:[UIColor redColor]];
                [eraseButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [eraseButton addTarget:self action:@selector(clearAll) forControlEvents:UIControlEventTouchUpInside];
                [[eraseButton layer] setCornerRadius:6.0f];
                [[eraseButton layer] setMasksToBounds:YES];
                [[eraseButton layer] setBorderWidth:0.35f];
                [[eraseButton layer] setBorderColor:[UIColor lightGrayColor].CGColor];
                [wrapper addSubview:eraseButton];
                cell.accessoryView = wrapper;
            }else if(indexPath.row == 3){
                cell.textLabel.text = NSLocalizedString(@"Safe BG",nil);
                cell.detailTextLabel.numberOfLines = 0;
                cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
                cell.detailTextLabel.text = NSLocalizedString(@"Reset the app state when going to background, so that there's no user data remains loaded.\nIMPORTANT: if it is off, you can restore the app without a PIN, unless you quit it.", nil);
                if (@available(iOS 13.0, *)) {
                    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
                } else {
                    // Fallback on earlier versions
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                }
                UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 60, 30)];
                UISwitch* bg = [[UISwitch alloc] initWithFrame:CGRectMake(10,0, 50, 30)];
                [bg setOn:self.settings.clearOnBG];
                clearBG = self.settings.clearOnBG;
                [bg addTarget:self action:@selector(clearOnBGChanged:) forControlEvents:UIControlEventValueChanged];
                [wrapper addSubview:bg];
                cell.accessoryView = wrapper;
            }else if(indexPath.row == 4){
                cell.textLabel.text = NSLocalizedString(@"Show account",nil);
                cell.detailTextLabel.numberOfLines = 0;
                cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
                cell.detailTextLabel.text = NSLocalizedString(@"Notifications will show the email account that is changed. Otherwise the notification won't disclose the email address, which is considered more secure.", nil);
                if (@available(iOS 13.0, *)) {
                    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
                } else {
                    // Fallback on earlier versions
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                }
                UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 60, 30)];
                UISwitch* sh = [[UISwitch alloc] initWithFrame:CGRectMake(10,0, 50, 30)];
                [sh setOn:self.settings.doNotHideAccount];
                doNotHide = self.settings.doNotHideAccount;
                [sh addTarget:self action:@selector(doNotHideChanged:) forControlEvents:UIControlEventValueChanged];
                [wrapper addSubview:sh];
                cell.accessoryView = wrapper;
            }
            break;
        case 1:
            if(indexPath.row == 0){
                cell.textLabel.text = NSLocalizedString(@"Biometrics",nil);
                cell.detailTextLabel.numberOfLines = 0;
                cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
                cell.detailTextLabel.text = NSLocalizedString(@"Set biometric authentication for this account only", nil);
                if (@available(iOS 13.0, *)) {
                    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
                } else {
                    // Fallback on earlier versions
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                }
                UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 60, 30)];
                UISwitch* bio = [[UISwitch alloc] initWithFrame:CGRectMake(10,0, 50, 30)];
                if([CommonProcs checkBioIDAvailable]){
                    [bio setOn:self.settings.useBioID];
                    bioSet = self.settings.useBioID;
                }else{
                    bio.enabled = NO;
                }
                [bio addTarget:self action:@selector(bioChanged:) forControlEvents:UIControlEventValueChanged];
                [wrapper addSubview:bio];
                cell.accessoryView = wrapper;
            }
            break;
        case 2:
            if(indexPath.row == 0){
                cell.textLabel.text = NSLocalizedString(@"Background mode",nil);
                cell.detailTextLabel.numberOfLines = 0;
                cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
                cell.detailTextLabel.text = NSLocalizedString(@"The system will schedule a mail check depending on the app usage. You cannot set the check interval.", nil);
                if (@available(iOS 13.0, *)) {
                    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
                } else {
                    // Fallback on earlier versions
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                }
                UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 60, 30)];
                UISwitch* bg = [[UISwitch alloc] initWithFrame:CGRectMake(10,0, 50, 30)];
                [bg setOn:self.settings.keepInBg];
                bgCheck = self.settings.keepInBg;
                [bg addTarget:self action:@selector(bgChanged:) forControlEvents:UIControlEventValueChanged];
                [wrapper addSubview:bg];
                cell.accessoryView = wrapper;
            }
            break;
        default:
            cell.textLabel.text = @"";
            cell.detailTextLabel.text = @"";
            cell.accessoryView = nil;
            break;
    }
    
    return cell;
}

-(void)changePin
{
    [self.interactor wantChangePin];
    //NSLog(@"Change pin pressed");
}

-(void)clearAll
{
    [self.interactor wantSOS];
}

-(void)bioChanged:(UISwitch*)sender
{
    bioSet = [sender isOn];
    //NSLog(@"Bio is %i", bioSet);
}

-(void)bgChanged:(UISwitch*)sender
{
    if ([sender isOn]) {
        [CommonProcs askYesNoAndDoWithTitle:NSLocalizedString(@"Warning",nil) text:NSLocalizedString(@"Setting background mode on makes it possible to reverse-engineer the app's pin-code if an adversary gains a physical access to your device. Are you sure you want to turn it on?",nil) blockYes:^{
            
        } blockNo:^{
            [sender setOn:NO];
        }];
    }
    bgCheck = [sender isOn];
    //NSLog(@"BG is %i", bgCheck);
}

-(void)clearOnBGChanged:(UISwitch*)sender
{
    clearBG = sender.on;
    [GlobalRouter sharedManager].clearOnBGSetting = clearBG;
}

-(void)doNotHideChanged:(UISwitch*)sender
{
    doNotHide = [sender isOn];
}

-(void)needSaveSettings
{
    settings.keepInBg = bgCheck;
    settings.useBioID = bioSet;
    if(erasePin)settings.erasePIN = erasePin.text;
    settings.clearOnBG = clearBG;
    settings.doNotHideAccount = doNotHide;
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        BOOL res = [self.interactor saveSettings:[strongSelf->settings copy] :[GlobalRouter sharedManager].pin];
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
    return settings.keepInBg != bgCheck || settings.useBioID != bioSet || ![erasePin.text isEqualToString:@""] || settings.clearOnBG != clearBG || settings.doNotHideAccount != doNotHide;
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

/*
#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here, for example:
    // Create the next view controller.
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:<#@"Nib name"#> bundle:nil];
    
    // Pass the selected object to the new view controller.
    
    // Push the view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
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

@end
