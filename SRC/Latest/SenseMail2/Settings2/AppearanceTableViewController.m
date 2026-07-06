//
//  AppearanceTableViewController.m
//  SenseMailShare
//
//  Created by Sergey on 10.12.2019.
//  Copyright © 2019 Sergey. All rights reserved.
//

#import "AppearanceTableViewController.h"
#import "SettingsEntity.h"
#import "GlobalRouter.h"
#import "CommonProcs.h"
#import "Settings2Interactor.h"

@interface AppearanceTableViewController ()

@end

@implementation AppearanceTableViewController

@synthesize settings;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save and close",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needSaveSettings)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeSettings)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:button1, flexibleItem, button2, nil]];
    
    sorting = settings.sortOrder;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    tapGesture.delegate = self;
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
    
    if (@available(iOS 11.0, *)) {
        
    }else{
        self.tableView.rowHeight = 96;
    }
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)setUp
{
    if (self.settings) {
        nToLoad = (int)settings.nMessages;
        dFrom = settings.silentFrom;
        dTo = settings.silentTo;
        sorting = settings.sortOrder;
        
        //settings.nMessages != [nToLoadTF.text intValue] || (largeFontSwitch && settings.largeFont != largeFontSwitch.on) || (compressionSlider && settings.compression != compressionSlider.value) || settings.sortOrder != sorting || dFrom != settings.silentFrom || dTo != settings.silentTo
    }
}

-(void)hideKeyboard
{
    [self.view endEditing:YES];
}

-(void)needSaveSettings
{
    if ((largeFontSwitch && settings.largeFont != largeFontSwitch.on) || (nToLoadTF && settings.nMessages != [nToLoadTF.text intValue]) || (sorting && settings.sortOrder != sorting)) {
        self.interactor.reloadMessagesOnExit = YES;
    }
    settings.nMessages = [nToLoadTF.text intValue];
    if(largeFontSwitch)settings.largeFont = largeFontSwitch.on;
    if(compressionSlider)settings.compression = compressionSlider.value;
    settings.sortOrder = sorting;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    //dateFormatter.dateFormat = @"k:mm";
    dFrom = [dateFormatter dateFromString:silentFrom.text];
    dTo = [dateFormatter dateFromString:silentTo.text];
    
    if(dTo){
        settings.silentTo = dTo;
        settings.silentFrom = dFrom;
    }else{
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        //dateFormatter.dateFormat = @"k:mm";
        settings.silentFrom = [dateFormatter dateFromString:silentFrom.text];
        settings.silentTo = [dateFormatter dateFromString:silentTo.text];
    }
    
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
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    //dateFormatter.dateFormat = @"k:mm";
    dFrom = [dateFormatter dateFromString:silentFrom.text];
    dTo = [dateFormatter dateFromString:silentTo.text];
    
    return settings.nMessages != [nToLoadTF.text intValue] || (largeFontSwitch && settings.largeFont != largeFontSwitch.on) || (compressionSlider && settings.compression != compressionSlider.value) || settings.sortOrder != sorting || (dFrom && dFrom != settings.silentFrom) || (dTo && dTo != settings.silentTo);
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int ret = 0;
    switch (section) {
        case 0:
            ret = 1;
            break;
        case 1:
            ret = 5;
            break;
        case 2:
            ret = 1;
            break;
        case 3:
            ret = 1;
            break;
        case 4:
            ret = 2;
            break;
        default:
            break;
    }
    return ret;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString* cellID = @"AppearanceCell";
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellID];
    switch (indexPath.section) {
        case 0:
            if (indexPath.row == 0) {
                cell.textLabel.text = NSLocalizedString(@"Messages to load",nil);
                cell.detailTextLabel.numberOfLines = 0;
                cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
                cell.detailTextLabel.text = NSLocalizedString(@"Number of messages to load from each account for one set",nil);
                if (@available(iOS 13.0, *)) {
                    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
                } else {
                    // Fallback on earlier versions
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                }
                UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 80, 30)];
                nToLoadTF = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, 70, 30)];
                [nToLoadTF setFont:[UIFont systemFontOfSize:14]];
                [nToLoadTF setText:[[NSNumber numberWithInt:(int)settings.nMessages] stringValue]];
                [[nToLoadTF layer] setCornerRadius:6.0f];
                [[nToLoadTF layer] setMasksToBounds:YES];
                [[nToLoadTF layer] setBorderWidth:0.35f];
                [[nToLoadTF layer] setBorderColor:[UIColor lightGrayColor].CGColor];
                
                // Make the text indent
                UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, nToLoadTF.frame.size.height)];
                leftView.backgroundColor = nToLoadTF.backgroundColor;
                nToLoadTF.leftView = leftView;
                nToLoadTF.leftViewMode = UITextFieldViewModeAlways;
                nToLoad = (int)settings.nMessages;
                
                [wrapper addSubview:nToLoadTF];
                cell.accessoryView = wrapper;
            }
            break;
        case 1:
            if(indexPath.row == 0){
                cell.textLabel.text = NSLocalizedString(@"Date",nil);
                cell.detailTextLabel.numberOfLines = 0;
                cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
                cell.detailTextLabel.text = NSLocalizedString(@"Sort emails by date within the loaded set",nil);
                if (@available(iOS 13.0, *)) {
                    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
                } else {
                    // Fallback on earlier versions
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                }
                //UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 30, 30)];
                
                //cell.accessoryView = wrapper;
                //cell.tintColor = [UIColor grayColor];
                if (settings.sortOrder == 0) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
            }else if(indexPath.row == 1){
                cell.textLabel.text = NSLocalizedString(@"Date, Unread on top",nil);
                cell.detailTextLabel.numberOfLines = 0;
                cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
                cell.detailTextLabel.text = NSLocalizedString(@"Sort emails by date within the loaded set. Bring unread on top",nil);
                if (@available(iOS 13.0, *)) {
                    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
                } else {
                    // Fallback on earlier versions
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                }
                //UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 30, 30)];
                
                //cell.accessoryView = wrapper;
                if (settings.sortOrder == 1) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
            }else if(indexPath.row == 2){
                cell.textLabel.text = NSLocalizedString(@"Account, Date",nil);
                cell.detailTextLabel.numberOfLines = 0;
                cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
                cell.detailTextLabel.text = NSLocalizedString(@"Emails from one account go together, sorted by date",nil);
                if (@available(iOS 13.0, *)) {
                    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
                } else {
                    // Fallback on earlier versions
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                }
                //UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 30, 30)];
                //cell.accessoryView = wrapper;
                if (settings.sortOrder == 2) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
            }else if(indexPath.row == 3){
                cell.textLabel.text = NSLocalizedString(@"Account, Date, Unread on top",nil);
                cell.detailTextLabel.numberOfLines = 0;
                cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
                cell.detailTextLabel.text = NSLocalizedString(@"Emails from one account go together, sorted by date, unread on top",nil);
                if (@available(iOS 13.0, *)) {
                    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
                } else {
                    // Fallback on earlier versions
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                }
                //UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 30, 30)];
                
                //cell.accessoryView = wrapper;
                if (settings.sortOrder == 3) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
            }else if(indexPath.row == 4){
                cell.textLabel.text = NSLocalizedString(@"Date, entire list",nil);
                cell.detailTextLabel.numberOfLines = 0;
                cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
                cell.detailTextLabel.text = NSLocalizedString(@"Sort emails by date withing the entire loaded list. May result in messages from a new set go up (offscreen) in the list.",nil);
                if (@available(iOS 13.0, *)) {
                    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
                } else {
                    // Fallback on earlier versions
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                }
                //UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 30, 30)];
                
                //cell.accessoryView = wrapper;
                if (settings.sortOrder == 4) {
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;
                }
            }
            break;
        case 2:
            if(indexPath.row == 0){
                cell.textLabel.text = NSLocalizedString(@"Large font",nil);
                cell.detailTextLabel.numberOfLines = 0;
                cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
                cell.detailTextLabel.text = NSLocalizedString(@"Set large font in the message list", nil);
                if (@available(iOS 13.0, *)) {
                    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
                } else {
                    // Fallback on earlier versions
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                }
                UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 60, 30)];
                largeFontSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(10,0, 50, 30)];
                [largeFontSwitch setOn:settings.largeFont];
                largeFont = settings.largeFont;
                [wrapper addSubview:largeFontSwitch];
                cell.accessoryView = wrapper;
            }
            break;
        case 3:
            if(indexPath.row == 0){
                cell.textLabel.text = NSLocalizedString(@"Compression",nil);
                cell.detailTextLabel.numberOfLines = 0;
                cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
                cell.detailTextLabel.text = NSLocalizedString(@"Set the compression ratio for image attachments. No compression means large file size and the best image quality. Maximum compression makes the smallest file size but the lowest quality", nil);
                if (@available(iOS 13.0, *)) {
                    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
                } else {
                    // Fallback on earlier versions
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                }
                UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 120, 30)];
                compressionSlider = [[UISlider alloc] initWithFrame:CGRectMake(10,0, 110, 30)];
                compressionSlider.value = settings.compression;
                [compressionSlider addTarget:self action:@selector(compChanged:) forControlEvents:UIControlEventValueChanged];
                JPEGCompression = settings.compression;
                [wrapper addSubview:compressionSlider];
                compressionValue = [[UILabel alloc] initWithFrame:CGRectMake(10,30, 110, 16)];
                //compressionValue.text = [NSString stringWithFormat:@"%0.1f", compressionSlider.value];
                compressionValue.font = [UIFont systemFontOfSize:12];
                compressionValue.textAlignment = NSTextAlignmentCenter;
                compressionValue.adjustsFontSizeToFitWidth = YES;
                compressionValue.minimumScaleFactor = 0.5;
                [self compChanged:nil];
                [wrapper addSubview:compressionValue];
                cell.accessoryView = wrapper;
            }
            break;
        case 4:
            if(indexPath.row == 0) {
                cell.textLabel.text = NSLocalizedString(@"From:",nil);
                cell.detailTextLabel.numberOfLines = 0;
                cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
                cell.detailTextLabel.text = NSLocalizedString(@"Mute notification from that time",nil);
                if (@available(iOS 13.0, *)) {
                    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
                } else {
                    // Fallback on earlier versions
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                }
                UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 90, 30)];
                silentFrom = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, 80, 30)];
                [silentFrom setFont:[UIFont systemFontOfSize:14]];
                NSDateFormatter *dateFormatter0 = [[NSDateFormatter alloc] init];
                [dateFormatter0 setTimeStyle:NSDateFormatterShortStyle];// setDateFormat:@"hh:mm a"];
                NSString *textFrom = [dateFormatter0 stringFromDate:settings.silentFrom];
                [silentFrom setText:textFrom];
                [[silentFrom layer] setCornerRadius:6.0f];
                [[silentFrom layer] setMasksToBounds:YES];
                [[silentFrom layer] setBorderWidth:0.35f];
                [[silentFrom layer] setBorderColor:[UIColor lightGrayColor].CGColor];
                
                // Make the text indent
                UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, silentFrom.frame.size.height)];
                leftView.backgroundColor = nToLoadTF.backgroundColor;
                silentFrom.leftView = leftView;
                silentFrom.leftViewMode = UITextFieldViewModeAlways;
                
                pickerFrom = [[UIDatePicker alloc] init];
                pickerFrom.datePickerMode = UIDatePickerModeTime;
                [pickerFrom addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
                dateFormatter.dateFormat = @"k:mm";
                NSDate* dttt = settings.silentFrom; //[dateFormatter dateFromString:silentFrom.text];
                if(dttt)[pickerFrom setDate:dttt];
                
                silentFrom.inputView = pickerFrom;
                
                [wrapper addSubview:silentFrom];
                cell.accessoryView = wrapper;
            }else if(indexPath.row == 1) {
                cell.textLabel.text = NSLocalizedString(@"To:",nil);
                cell.detailTextLabel.numberOfLines = 0;
                cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
                cell.detailTextLabel.text = NSLocalizedString(@"Mute notification to that time",nil);
                if (@available(iOS 13.0, *)) {
                    cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
                } else {
                    // Fallback on earlier versions
                    cell.detailTextLabel.textColor = [UIColor grayColor];
                }
                UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 90, 30)];
                silentTo = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, 80, 30)];
                [silentTo setFont:[UIFont systemFontOfSize:14]];
                NSDateFormatter *dateFormatter0 = [[NSDateFormatter alloc] init];
                [dateFormatter0 setTimeStyle:NSDateFormatterShortStyle];// setDateFormat:@"hh:mm a"];
                NSString *textTo = [dateFormatter0 stringFromDate:settings.silentTo];
                [silentTo setText:textTo];
                [[silentTo layer] setCornerRadius:6.0f];
                [[silentTo layer] setMasksToBounds:YES];
                [[silentTo layer] setBorderWidth:0.35f];
                [[silentTo layer] setBorderColor:[UIColor lightGrayColor].CGColor];
                
                // Make the text indent
                UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, silentTo.frame.size.height)];
                leftView.backgroundColor = nToLoadTF.backgroundColor;
                silentTo.leftView = leftView;
                silentTo.leftViewMode = UITextFieldViewModeAlways;
                
                pickerTo = [[UIDatePicker alloc] init];
                pickerTo.datePickerMode = UIDatePickerModeTime;
                [pickerTo addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
                
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
                dateFormatter.dateFormat = @"k:mm";
                NSDate* dttt = settings.silentTo;//[dateFormatter dateFromString:silentTo.text];
                if(dttt)[pickerTo setDate:dttt];
                
                silentTo.inputView = pickerTo;
                
                [wrapper addSubview:silentTo];
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

-(void)dateChanged:(id)sender
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];// setDateFormat:@"hh:mm a"];
    if (sender == pickerTo) {
        NSString *currentTime = [dateFormatter stringFromDate:pickerTo.date];
        [silentTo setText:currentTime];
    }else{
        NSString *currentTime = [dateFormatter stringFromDate:pickerFrom.date];
        [silentFrom setText:currentTime];
    }
    //NSLog(@"%@", currentTime);
}

-(void)compChanged:(id)sender
{
    if (compressionSlider.value == 0) {
        compressionValue.text = NSLocalizedString(@"Max compression",nil);
    }else if (compressionSlider.value == 1) {
        compressionValue.text = NSLocalizedString(@"No compression",nil);
    }else if(compressionSlider.value > 0.7){
        compressionValue.text = NSLocalizedString(@"Low compression",nil);
    }else if(compressionSlider.value > 0.3){
        compressionValue.text = NSLocalizedString(@"Medium compression",nil);
    }else{
        compressionValue.text = NSLocalizedString(@"High compression",nil);
    }
        //compressionValue.text = [NSString stringWithFormat:@"%0.1f", compressionSlider.value];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1) {
        return NSLocalizedString(@"Sort order. This will be applied to every set of loaded messages.",nil);
    }else if(section == 4){
        return NSLocalizedString(@"Notification silent hours",nil);
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

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == 1;
}

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        [self removeCheckMark];
        sorting = indexPath.row;
        [self.tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

-(void)removeCheckMark
{
    for(int i=0;i<5;i++){
        [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:1]].accessoryType = UITableViewCellAccessoryNone;
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
