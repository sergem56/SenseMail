//
//  SecondViewController.m
//  SenseMail2
//
//  Created by Sergey on 05.02.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "Settings2ViewController.h"
#import "Settings2Interactor.h"
#import "GlobalRouter.h"
#import "SettingsEntity.h"
#import "DataManager.h"
#import "ModalDialogViewController.h"

@interface Settings2ViewController (){
    NSString* temp1;
}

@end

@implementation Settings2ViewController

@synthesize settings;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save and close",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needSaveSettings)];
    //UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel",nil) style:UIBarButtonItemStylePlain target:self action:@selector(closeSettings)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeSettings)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:button1, flexibleItem, button2, nil]];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    // prevents the scroll view from swallowing up the touch event of child buttons
    //tapGesture.cancelsTouchesInView = NO;
    tapGesture.delegate = self;
    [self.contentView addGestureRecognizer:tapGesture];
    //[self.contentViewApp addGestureRecognizer:tapGesture];
    
    //self.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"settingsBg"]];
    //self.scroll.di
    
    [self registerForKeyboardNotifications];
    
    // AccessoryView toolbar
    UIBarButtonItem* button20 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needSaveSettings)];
    UIBarButtonItem *flexibleItem22 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button22 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeSettings)];
    UIBarButtonItem* button23 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hideKeyboard"] style:UIBarButtonItemStylePlain target:self action:@selector(hideKeyboard)];
    
    self.inputAccessoryToolbar = [[UIToolbar alloc] init];//self.navigationController.toolbar;
    self.inputAccessoryToolbar.frame = CGRectMake(0,0,250,44);
    self.inputAccessoryToolbar.items = [NSArray arrayWithObjects:button20, flexibleItem22, button22, button23, nil];
    self.settingsName.inputAccessoryView = self.inputAccessoryToolbar;
    self.userName.inputAccessoryView = self.inputAccessoryToolbar;
    self.password.inputAccessoryView = self.inputAccessoryToolbar;
    self.nickName.inputAccessoryView = self.inputAccessoryToolbar;
    
    self.imap.inputAccessoryView = self.inputAccessoryToolbar;
    self.smtp.inputAccessoryView = self.inputAccessoryToolbar;
    self.smtpPort.inputAccessoryView = self.inputAccessoryToolbar;
    //self.nickName.inputAccessoryView = self.inputAccessoryToolbar;
    self.imapPort.inputAccessoryView = self.inputAccessoryToolbar;//self.inputAccessoryView;
    self.connectionTypeSMTP.inputAccessoryView = self.inputAccessoryToolbar;//self.inputAccessoryView;
    self.connectionTypeIMAP.inputAccessoryView = self.inputAccessoryToolbar;//self.inputAccessoryView;
    self.signature.inputAccessoryView = self.inputAccessoryToolbar;//self.inputAccessoryView;
    self.bgColorTextField.inputAccessoryView = self.inputAccessoryToolbar;
    self.authType.inputAccessoryView = self.inputAccessoryView;
    
    UIPickerView *picker = [[UIPickerView alloc] init];
    picker.dataSource = self;
    picker.delegate = self;
    self.connectionTypeIMAP.inputView = picker;
    self.connectionTypeSMTP.inputView = picker;
    
    colors = [[UIPickerView alloc] init];
    //colors.backgroundColor = [UIColor whiteColor];
    colors.dataSource = self;
    colors.delegate = self;
    self.bgColorTextField.inputView = colors;
    
    aPicker = [[UIPickerView alloc] init];
    aPicker.dataSource = self;
    aPicker.delegate = self;
    self.authType.inputView = aPicker;
    
    [[self.signature layer] setCornerRadius:6.0f];
    [[self.signature layer] setMasksToBounds:YES];
    [[self.signature layer] setBorderWidth:0.25f];
    [[self.signature layer] setBorderColor:[UIColor lightGrayColor].CGColor];
    
    colorNames = [CommonProcs getColorNames];
    colorValues = [CommonProcs getColorValues];
    
    if (@available(iOS 13.0, *)) {
        [self.signatureLabel setTextColor:[UIColor labelColor]];
    } else {
        // Fallback on earlier versions
        [self.signatureLabel setTextColor:[UIColor blackColor]];
    }
    
    // Populate text fields
    [self setCurrentSettings];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UIControl class]]) {
        // we touched a button, slider, or other UIControl
        return NO; // ignore the touch
    }
    return YES; // handle the touch
}

-(void)hideKeyboard
{
    [self.view endEditing:YES];
}

-(void)adjustForSettings
{
}

-(void)setCurrentSettings
{
    //[self.settingsName setText:settings.settingsName];
    [self.settingsName setText:settings.settingsName];
    [self.userName setText:settings.userName];
    [self.nickName setText:settings.userNick];
    [self.password setText:settings.password];
    
    [self.imap setText:settings.imapServer];
    [self.imapPrefix setText:settings.imapPrefix];
    [self.smtp setText:settings.smtpServer];
    [self.smtpPort setText:[NSString stringWithFormat:@"%li", (long)settings.smtpPort]];
    [self.imapPort setText:[NSString stringWithFormat:@"%li", (long)settings.imapPort]];
    
    [self.connectionTypeIMAP setText:settings.connectionTypeIMAP == SMConnectionTypeStartTLS?@"StartTLS":@"TLS"];
    [self.connectionTypeSMTP setText:settings.connectionTypeSMTP == SMConnectionTypeStartTLS?@"StartTLS":@"TLS"];
    [self.signature setText:settings.signature];
    
    if (!([settings.settingsName isEqualToString:@""] || settings.settingsName == nil)) {
        [self.titleLabel setText:settings.settingsName];
    }else if (!([settings.userName isEqualToString:@""] || settings.userName == nil)) {
        [self.titleLabel setText:settings.userName];
    }
    
    if([self.settings.userName containsString:@"@gmail.com"]/* || [self.settings.userName containsString:@"@outlook.com"]*/){
        BOOL loggedIn = [[[GlobalRouter sharedManager] getListRouter].manager isAddressLoggedIn:self.settings.userName];
        if (loggedIn) {
            [self.logoutButton setEnabled:YES];
        }else{
            [self.logoutButton setTitle:NSLocalizedString(@"Log in", nil) forState:UIControlStateNormal];
            [self.logoutButton setEnabled:YES];
        }
    }else{
        [self.logoutButton setEnabled:NO];
    }
    
    self.bgColorTextField.backgroundColor = colorValues[settings.bgColor];
    self.bgColorTextField.text = colorNames[settings.bgColor];
    
    self.authType.text = [SettingsEntity getStringFromAuthType:settings.SMTPAuthType];
}

-(void)gatherSettings
{
    // Get settings from text fields and put them into settings object
    settings.settingsName = [self.settingsName text];
    settings.userName = [self.userName text];
    settings.userNick = [self.nickName text];
    settings.password = [self.password text];
    
    settings.imapServer = [self.imap text];
    settings.imapPrefix = [self.imapPrefix text];
    settings.smtpServer = [self.smtp text];
    settings.smtpPort =[[self.smtpPort text] integerValue];
    settings.imapPort =[[self.imapPort text] integerValue];
    
    settings.connectionTypeIMAP = [self.connectionTypeIMAP.text isEqualToString:@"StartTLS"]?SMConnectionTypeStartTLS:SMConnectionTypeTLS;
    settings.connectionTypeSMTP = [self.connectionTypeSMTP.text isEqualToString:@"StartTLS"]?SMConnectionTypeStartTLS:SMConnectionTypeTLS;
    
    settings.signature = [self.signature text];
    
    settings.SMTPAuthType = [settings getAuthTypeFromString:self.authType.text];
}

-(BOOL)needSaveSettings
{
    [self gatherSettings];
    
    if ([settings.userName isEqualToString:@""]){// || [settings.password isEqualToString:@""]) {
        [CommonProcs showMessage:NSLocalizedString(@"User name or password is empty",nil) title:NSLocalizedString(@"Error saving settings",nil)];
        return NO;
    }
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        BOOL res = [self.interactor saveSettings:[strongSelf->settings copy] :[GlobalRouter sharedManager].pin];
        if(res){
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.thisIsNew) {
                    // Add a setting to the list
                    [self.interactor addToTheList:strongSelf->settings];
                }
                [self finished];
                self.interactor.reloadMessagesOnExit = YES;
            });
        }else{
            // Shouldn't get here, but who knows
            //dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs showMessage:@"" title:NSLocalizedString(@"Error saving settings",nil)];
            //});
        }
    });
    
    return YES;
}

-(void)finished
{
    [[[GlobalRouter sharedManager] getDetailNavController] popViewControllerAnimated:YES];
}

-(BOOL)checkIfChanged
{
    if (!([self.settings.userName isEqualToString:[self.userName text]]||(self.settings.userName == nil && [[self.userName text] isEqualToString:@""]))) {
        return YES;
    }else if (!([self.settings.userNick isEqualToString:[self.nickName text]]||(self.settings.userNick == nil && [[self.nickName text] isEqualToString:@""]))) {
        return YES;
    }else if (!([self.settings.password isEqualToString:[self.password text]]||(self.settings.password == nil && [[self.password text] isEqualToString:@""]))) {
        return YES;
    }else if (!([self.settings.imapServer isEqualToString:[self.imap text]]||(self.settings.imapServer == nil && [[self.imap text] isEqualToString:@""]))) {
        return YES;
    }else if (!([self.settings.smtpServer isEqualToString:[self.smtp text]]||(self.settings.smtpServer == nil && [[self.smtp text] isEqualToString:@""]))) {
        return YES;
    }else if (self.settings.smtpPort !=[[self.smtpPort text] integerValue]) {
        return YES;
    }else if (self.settings.imapPort !=[[self.imapPort text] integerValue]) {
        return YES;
    }else if (!([self.settings.settingsName isEqualToString:[self.settingsName text]]||(self.settings.settingsName == nil && [[self.settingsName text] isEqualToString:@""]))) {
        return YES;
    }else if (!([self.settings.signature isEqualToString:[self.signature text]]||(self.settings.signature == nil && [[self.signature text] isEqualToString:@""]))) {
        return YES;
    }

    return NO;
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)userNameDoneEdit:(id)sender
{
    //if ([[self.imap text] isEqualToString:@""]) {
    NSArray* ret = [Settings2Interactor getMailSettingsForAddress:[self.userName text]];
        if (ret != nil) {
            [self setMailSettings:ret];
        }
    
    if ([[self.userName text] containsString:@"@gmail.com"]) {
        // Disable password field
        [self.password setText:NSLocalizedString(@"Use web-authorization", nil)];
        [self.password setEnabled:NO];
    }
    //}
}

-(void)setMailSettings:(NSArray*)mailSettings
{
    [self.imap setText:[mailSettings firstObject]];
    [self.imapPort setText:[mailSettings objectAtIndex:1]];
    [self.connectionTypeIMAP setText:[mailSettings objectAtIndex:2]];
    [self.smtp setText:[mailSettings objectAtIndex:3]];
    [self.smtpPort setText:[mailSettings objectAtIndex:4]];
    [self.connectionTypeSMTP setText:[mailSettings lastObject]];
    //[self.smtpPort setText:@"465"];
    [self.authType setText:[SettingsEntity authTypeTitles][0]];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    int toAdd = 32;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scroll.contentInset.top, self.scroll.contentInset.left, kbSize.height+toAdd, 0.0);
    self.scroll.contentInset = contentInsets;
    self.scroll.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= (kbSize.height+toAdd);
    UIView* activeField;
    for (UIView *subView in self.contentView.subviews) {
        if ([subView isFirstResponder]) {
            activeField = subView;
        }
    }
    
    if (activeField != nil && !CGRectContainsPoint(aRect, activeField.frame.origin) ) {
        //CGPoint scrollPoint = CGPointMake(0.0, activeField.frame.origin.y-kbSize.height);
        CGPoint scrollPoint = CGPointMake(0.0, activeField.frame.origin.y - aRect.size.height + toAdd);
        [self.scroll setContentOffset:scrollPoint animated:YES];
    }
    
    if ([self.bgColorTextField isFirstResponder]) {
        [colors selectRow:self.settings.bgColor inComponent:0 animated:YES];
    }
    
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    //UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scroll.contentInset.top, 0.0, 32, 0.0);
    self.scroll.contentInset = contentInsets;
    self.scroll.scrollIndicatorInsets = contentInsets;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

-(IBAction)logout:(id)sender
{
    if ([self.logoutButton.titleLabel.text isEqualToString:NSLocalizedString(@"Log in", nil)]) {
        [[GlobalRouter sharedManager] checkConnection:settings completion:^(BOOL res){
            dispatch_async(dispatch_get_main_queue(), ^{
                if (res) {
                    [self.logoutButton setTitle:NSLocalizedString(@"Log out", nil) forState:UIControlStateNormal];
                }
            });
        }];
    }else{
        [[[GlobalRouter sharedManager] getListRouter].manager logoutForAddress:settings.userName];
        [self.logoutButton setTitle:NSLocalizedString(@"Log in", nil) forState:UIControlStateNormal];
        //[self.logoutButton setEnabled:NO];//[[[GlobalRouter sharedManager] getListRouter].manager isAddressLoggedIn:self.settings.userName]];
    }
}

-(IBAction)togglePassword:(id)sender
{
    self.password.secureTextEntry = !self.password.secureTextEntry;
    NSString* imageName = self.password.secureTextEntry?@"eye":@"eye-close";
    [self.togglePwdButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if ([pickerView isEqual:colors]) {
        return colorNames.count;
    }else if ([pickerView isEqual:aPicker]) {
        return 2;
    }
    return 2;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return  1;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if ([self.connectionTypeIMAP isFirstResponder]) {
        [self.connectionTypeIMAP setText:row==0?@"TLS":@"StartTLS"];
        [self.connectionTypeIMAP resignFirstResponder];
    }else if([self.connectionTypeSMTP isFirstResponder]) {
        [self.connectionTypeSMTP setText:row==0?@"TLS":@"StartTLS"];
        [self.connectionTypeSMTP resignFirstResponder];
    }else if ([self.bgColorTextField isFirstResponder]){
        self.bgColorTextField.backgroundColor = colorValues[row];
        self.bgColorTextField.text = colorNames[row];
        self.settings.bgColor = row;
        //[self.bgColorTextField resignFirstResponder];
    }else if ([self.authType isFirstResponder]){
        //self.settings.SMTPAuthType = [settings getAuthTypeFromString:[SettingsEntity authTypeTitles][row]];
        [self.authType setText:[SettingsEntity authTypeTitles][row]];
        [self.authType resignFirstResponder];
    }
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {

    UILabel* label = nil;
    if (view == nil) {
        view = [[UIView alloc] init];
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, pickerView.frame.size.width-20, 32)];
        label.textAlignment = NSTextAlignmentCenter;
        [view addSubview:label];
    }
    
    if ([pickerView isEqual:colors]) {
        view.backgroundColor = colorValues[row];
        label.text = colorNames[row];
    }else if ([pickerView isEqual:aPicker]){
        label.text = [SettingsEntity authTypeTitles][row];
    }else{
        if (row == 0) {
            label.text = @"TLS";
        }else
            label.text = @"StartTLS";
    }
    return view;
}

@end
