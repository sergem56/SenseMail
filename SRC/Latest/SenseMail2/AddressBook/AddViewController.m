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

#if !LITE
#import "OneTimeCertInteractor.h"
#import "OTCsListViewController.h"
#endif

#import "ComposeMessageViewController.h"

@interface AddViewController ()
{
    BOOL keyboardIsShown;
}

@end

@implementation AddViewController

@synthesize item;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
    
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(needSaveItem)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeAdd)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:button1,flexibleItem,button2, nil]];
    
    [self updateItem];
    
    // AccessoryView toolbar
    UIBarButtonItem* button11 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(needSaveItem)];
    UIBarButtonItem *flexibleItem1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button21 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeAdd)];
    self.inputAccessoryToolbar = [[UIToolbar alloc] init];
    self.inputAccessoryToolbar.frame = CGRectMake(0,0,250,44);
    self.inputAccessoryToolbar.items = [NSArray arrayWithObjects:button11, flexibleItem1, button21, nil];
    self.name.inputAccessoryView = self.inputAccessoryToolbar;
    self.email.inputAccessoryView = self.inputAccessoryToolbar;
    self.note.inputAccessoryView = self.inputAccessoryToolbar;
    self.groupName.inputAccessoryView = self.inputAccessoryToolbar;
    
    [self.scroll setContentInset:UIEdgeInsetsMake(0,0,60,0)];// make room for a bottom bar
    
    // Do any additional setup after loading the view.
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    // prevents the scroll view from swallowing up the touch event of child buttons
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
    
#if LITE
    [self.nonLiteView removeFromSuperview];// .hidden = YES;
#else
    //self.nonLiteView.hidden = NO;
#endif
}

-(void)hideKeyboard
{
    [self.view endEditing:YES];
    keyboardIsShown = NO;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.writeButton setHidden:NO];
    
    // Hide write button if compose view controller is already on stack
    for (UIViewController* vcItem in self.navigationController.viewControllers) {
        if ([vcItem isMemberOfClass:[ComposeMessageViewController class]]) {
            [self.writeButton setHidden:YES];
            break;
        }
    }
    
    //////////////
    if (item.key) {
        self.certLabel.text = NSLocalizedString(@"There is a certificate for this contact", nil);
        self.resendButton.enabled = YES;
        self.deleteButton.enabled = YES;
    }else{
        self.certLabel.text = NSLocalizedString(@"This contact has no certificate", nil);
        self.resendButton.enabled = NO;
        self.deleteButton.enabled = NO;
    }//////////////////
    
    
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

-(void)keyboardWillShow:(NSNotification *)notification
{
    if (keyboardIsShown) {
        return;
    }
    CGRect kbFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGSize keyboardSize = kbFrame.size;
    
    [UIView animateWithDuration:0.3 animations:^{
        // 48 is for accessory view
        [self.scroll setContentInset:UIEdgeInsetsMake(0,0,self.scroll.contentInset.bottom+keyboardSize.height-48,0)];
    }];
    
    keyboardIsShown = YES;
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    CGRect kbFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGSize keyboardSize = kbFrame.size;
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.scroll setContentInset:UIEdgeInsetsMake(0,0,self.scroll.contentInset.bottom-keyboardSize.height+60,0)];
    }];
    
    keyboardIsShown = NO;
}

#pragma --------------

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
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:NSLocalizedString(@"Item changed",nil)
                                     message:NSLocalizedString(@"Save changes?",nil)
                                     preferredStyle:UIAlertControllerStyleAlert];
        //__weak __typeof__(self) weakSelf = self;
        UIAlertAction* deleteIt = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Yes", nil)
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action)
                                   {
                                       //__strong __typeof__(self) strongSelf = weakSelf;
                                       [self needSaveItem];
                                   }];
        [alert addAction:deleteIt];
        
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"No",nil)
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction * action)
                                 {
                                     [self closeAdd:NO];
                                 }];
        [alert addAction:cancel];
        
        UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
        alert.popoverPresentationController.sourceView = pView;
        alert.popoverPresentationController.sourceRect = pView.frame;
        [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
    }else
        [[GlobalRouter sharedManager] finishedWithDetailView:YES]; // getSettingsRouter] finished];
    
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
    if([item.uid isEqualToString:@""] || item.uid == nil)
        item.uid = [[NSUUID UUID] UUIDString];
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [self.presenter needAddItemToBook:strongSelf->item];
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
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:NSLocalizedString(@"E-mail is empty",nil)
                                     message:@""
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"OK",nil)
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction * action)
                                 {
                                 }];
        [alert addAction:cancel];
        
        UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
        alert.popoverPresentationController.sourceView = pView;
        alert.popoverPresentationController.sourceRect = pView.frame;
        [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
    }
}

-(IBAction)sendCertificate:(id)sender
{
#if !LITE
    if(![self.email.text isEqualToString:@""]){
        [self.presenter needToSendCertTo:self.email.text existing:NO];
    }else{
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:NSLocalizedString(@"E-mail is empty",nil)
                                     message:@""
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"OK",nil)
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction * action)
                                 {
                                 }];
        [alert addAction:cancel];
        
        UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
        alert.popoverPresentationController.sourceView = pView;
        alert.popoverPresentationController.sourceRect = pView.frame;
        [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
    }
#endif
}

-(IBAction)reSendCertificate:(id)sender
{
#if !LITE
    if(![self.email.text isEqualToString:@""]){
        [self.presenter needToSendCertTo:self.email.text existing:YES];
    }else{
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:NSLocalizedString(@"E-mail is empty",nil)
                                     message:@""
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"OK",nil)
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction * action)
                                 {
                                 }];
        [alert addAction:cancel];
        
        UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
        alert.popoverPresentationController.sourceView = pView;
        alert.popoverPresentationController.sourceRect = pView.frame;
        [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
    }
#endif
}

-(IBAction)deleteCertificate:(id)sender
{
#if !LITE
    [CommonProcs spawnProcWithProgress:@selector(needDeleteCertFor:) object:self.presenter withParam:self.email.text.lowercaseString];
#endif
}

-(IBAction)exchangeOTC:(id)sender
{
#if !LITE
    [GlobalRouter sharedManager].oneTimeCertInteractor = [[OneTimeCertInteractor alloc] init];
    [GlobalRouter sharedManager].oneTimeCertInteractor.otherEmail = self.email.text;
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[GlobalRouter sharedManager].oneTimeCertInteractor presentViewInNavController:[[GlobalRouter sharedManager] getDetailNavController]];
    });
#endif
}

-(IBAction)deleteAllOTCs:(id)sender
{
#if !LITE
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:NSLocalizedString(@"Are you sure?",nil)
                                 message:NSLocalizedString(@"All certificates for this recipient will be permanently deleted",nil)
                                 preferredStyle:UIAlertControllerStyleAlert];
    //__weak __typeof__(self) weakSelf = self;
    UIAlertAction* deleteIt = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"Delete", nil)
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
                                   //__strong __typeof__(self) strongSelf = weakSelf;
                                   [GlobalRouter sharedManager].oneTimeCertInteractor = [[OneTimeCertInteractor alloc] init];
                                   [[GlobalRouter sharedManager].oneTimeCertInteractor deleteAllForAddress:self.email.text from:@""];
                               }];
    [alert addAction:deleteIt];
    
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
#endif
}

-(IBAction)manageOTCs:(id)sender
{
#if !LITE
    [[GlobalRouter sharedManager].oneTimeCertInteractor showManageOTCs];
#endif
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
