//
//  AddViewController.m
//  SenseMail2
//
//  Created by Sergey on 15.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "AddViewController.h"
#import "GlobalRouter.h"
#import "AddressBookEntity.h"
#import "AddressBookPresenter.h"
#import "FullMessageEntity.h"
#import "CommonProcs.h"

@interface AddViewController ()

@end

@implementation AddViewController

@synthesize item;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationController.toolbarHidden = NO;
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(needSaveItem)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeAdd)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:button1,flexibleItem,button2, nil]];
    
    [self updateItem];
}

-(void)updateItem
{
    if (item != nil) {
        self.name.text = item.name;
        self.email.text = item.address;
        self.note.text = item.note;
        //self.isGroupSwitch.on = item.isGroup;
        self.groupName.text = item.groupID;
        if (item.key) {
            self.certLabel.text = NSLocalizedString(@"There is a certificate for this contact", nil);
            self.resendButton.enabled = YES;
            self.deleteButton.enabled = YES;
        }else{
            self.certLabel.text = NSLocalizedString(@"This contact has no certificate", nil);
            self.resendButton.enabled = NO;
            self.deleteButton.enabled = NO;
        }
    }else{
        self.name.text = @"";
        self.email.text = @"";
        self.note.text = @"";
        //self.isGroupSwitch.on = NO;
        self.groupName.text = @"";
        self.certLabel.text = NSLocalizedString(@"This contact has no certificate", nil);
    }
}

-(BOOL)checkIfChanged
{
    BOOL ret = NO;
    if(item == nil){
        if(![self.name.text isEqual: @""] || ![self.email.text isEqual: @""] || ![self.note.text isEqual: @""] || ![self.groupName.text isEqualToString:@""]) ret = YES;
    }else{
        if(![self.name.text isEqual: item.name] || ![self.email.text isEqual: item.address] || ![self.note.text isEqual: item.note] || ![self.groupName.text isEqual:item.groupID]) ret = YES;
    }
    
    return ret;
}

-(void)closeAdd
{
    [self closeAdd:YES];
}

-(void)closeAdd:(BOOL)needCheck
{
    if (needCheck && [self checkIfChanged]) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Item changed",nil) message:NSLocalizedString(@"Save changes?",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"No",nil) otherButtonTitles:NSLocalizedString(@"Yes",nil),nil];
        //alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
        [alert setTag:100];
        [alert show];
    }else
        [[[GlobalRouter sharedManager] getSettingsRouter] finished];
    
    [self.presenter needUpdateList];
}

-(void)needSaveItem
{
    //AddressBookEntity* itemTemp = [[AddressBookEntity alloc]init];
    if(item == nil){
        item = [[AddressBookEntity alloc] init];
        item.uid = [[NSUUID UUID] UUIDString];
    }
    
    item.name = self.name.text;
    item.address = self.email.text;
    item.note = self.note.text;
    //item.isGroup = self.isGroupSwitch.isOn;
    item.groupID = self.groupName.text;
    if([item.uid isEqualToString:@""])
        item.uid = [[NSUUID UUID] UUIDString];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [self.presenter needAddItemToBook:item];
    });
    //item = nil;
    [self updateItem];
    
    [self closeAdd:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.view endEditing:YES];
}

-(IBAction)writeMail:(id)sender
{
    if(![self.email.text isEqualToString:@""]){
        [self.presenter needNewMailTo:item];
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"E-mail is empty",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
        alert.tag = 10000;
        [alert show];
    }
}

-(IBAction)sendCertificate:(id)sender
{
    if(![self.email.text isEqualToString:@""]){
        [self.presenter needToSendCertTo:self.email.text existing:NO];
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"E-mail is empty",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
        alert.tag = 10000;
        [alert show];
    }
}

-(IBAction)reSendCertificate:(id)sender
{
    if(![self.email.text isEqualToString:@""]){
        [self.presenter needToSendCertTo:self.email.text existing:YES];
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"E-mail is empty",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
        alert.tag = 10000;
        [alert show];
    }
}

-(IBAction)deleteCertificate:(id)sender
{
    [CommonProcs spawnProcWithProgress:@selector(needDeleteCertFor:) object:self.presenter withParam:self.email.text.lowercaseString];
    [CommonProcs setMessageInProgress:NSLocalizedString(@"Deleting...",nil)];
    item.key = NO;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100)
    {
        if (buttonIndex == 0)
        {
            [self closeAdd:NO];
            
        }else{
            [self needSaveItem];
        }
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
