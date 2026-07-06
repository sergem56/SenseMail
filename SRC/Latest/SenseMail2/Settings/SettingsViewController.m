//
//  SecondViewController.m
//  SenseMail2
//
//  Created by Sergey on 05.02.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "SettingsViewController.h"
#import "GlobalRouter.h"
#import "SettingsPresenter.h"
#import "SettingsEntity.h"
#import "DataManager.h"
#import "ModalDialogViewController.h"

@interface SettingsViewController (){
    NSString* temp1;
}

@end

@implementation SettingsViewController

@synthesize presenter,settings, pageControl;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    //NSLog(@"Settings view is %fx%f", self.view.frame.size.width, self.view.frame.size.height);
    //CGRect screenRect = [[UIScreen mainScreen] bounds];
    //CGFloat screenWidth = screenRect.size.width;
    
    //[self.view setFrame:CGRectMake(0, 0, screenWidth, self.view.frame.size.height)];
    //self.scroll.contentSize = CGSizeMake(screenWidth, self.scroll.contentSize.height);
    //[self.view setNeedsLayout];
    //[self.view layoutIfNeeded];
    
    
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save and close",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needSaveSettings)];
    //UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel",nil) style:UIBarButtonItemStylePlain target:self action:@selector(closeSettings)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeSettings)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:button1, flexibleItem, button2, nil]];
    
    // Populate text fields
    [self setCurrentSettings];
    
    /*
    if(self.view.tag == 2){
        NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                          attribute:NSLayoutAttributeLeading
                                                                          relatedBy:0
                                                                             toItem:self.view
                                                                          attribute:NSLayoutAttributeLeading
                                                                         multiplier:1.0
                                                                           constant:0];
        [self.view addConstraint:leftConstraint];
        
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                           attribute:NSLayoutAttributeTrailing
                                                                           relatedBy:0
                                                                              toItem:self.view
                                                                           attribute:NSLayoutAttributeTrailing
                                                                          multiplier:1.0
                                                                            constant:0];
        [self.view addConstraint:rightConstraint];
    }else{
        NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.contentViewApp
                                                                          attribute:NSLayoutAttributeLeading
                                                                          relatedBy:0
                                                                             toItem:self.view
                                                                          attribute:NSLayoutAttributeLeading
                                                                         multiplier:1.0
                                                                           constant:0];
        [self.view addConstraint:leftConstraint];
        
        NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.contentViewApp
                                                                           attribute:NSLayoutAttributeTrailing
                                                                           relatedBy:0
                                                                              toItem:self.view
                                                                           attribute:NSLayoutAttributeTrailing
                                                                          multiplier:1.0
                                                                            constant:0];
        [self.view addConstraint:rightConstraint];
    }
    */
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    // prevents the scroll view from swallowing up the touch event of child buttons
    //tapGesture.cancelsTouchesInView = NO;
    tapGesture.delegate = self;
    [self.contentView addGestureRecognizer:tapGesture];
    [self.contentViewApp addGestureRecognizer:tapGesture];
    
    //self.contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"settingsBg"]];
    //self.scroll.di
    
    [self registerForKeyboardNotifications];
    
    // AccessoryView toolbar
    UIBarButtonItem* button20 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save",nil) style:UIBarButtonItemStylePlain target:self.pageControl action:@selector(needSaveSettings)];
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
    
    self.nMessages.inputAccessoryView = self.inputAccessoryToolbar;
    self.erasePinText.inputAccessoryView = self.inputAccessoryToolbar;
    
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
    
    //[self.contentView sizeToFit];
    
    /*
    float sizeOfContent = 0;
    UIView *lLast = [self.scroll.subviews lastObject];
    NSInteger wd = lLast.frame.origin.y;
    NSInteger ht = lLast.frame.size.height;
    
    sizeOfContent = wd+ht;
    
    self.scroll.contentSize = CGSizeMake(self.scroll.frame.size.width, sizeOfContent);
    */
    [[self.signature layer] setCornerRadius:6.0f];
    [[self.signature layer] setMasksToBounds:YES];
    [[self.signature layer] setBorderWidth:0.25f];
    [[self.signature layer] setBorderColor:[UIColor lightGrayColor].CGColor];
    
    [[self.changePinButton layer] setCornerRadius:6.0f];
    [[self.changePinButton layer] setMasksToBounds:YES];
    [[self.changePinButton layer] setBorderWidth:0.35f];
    [[self.changePinButton layer] setBorderColor:[UIColor lightGrayColor].CGColor];
    
#if !PERIODIC_CHECK
    self.checkPeriod.hidden = YES;
    self.checkPeriodLabel.hidden = YES;
    self.keepInBg.hidden = YES;
    self.keepInBgLabel.hidden = YES;
    self.checkDescriptionLabel.hidden = YES;
    [self.view removeConstraint:self.topClearAllConstraint];
    self.topNoCheckConstraint.constant = 12;
    [self.checkPeriodLabel removeFromSuperview];
    [self.checkPeriod removeFromSuperview];
    [self.keepInBgLabel removeFromSuperview];
    [self.keepInBg removeFromSuperview];
    [self.checkDescriptionLabel removeFromSuperview];
#endif
    
#if PERIODIC_CHECK
    // For now
    self.checkPeriod.hidden = YES;
    self.checkPeriodLabel.hidden = YES;
    
    [self.view removeConstraint:self.topNoCheckConstraint];
    self.checkDescriptionLabel.numberOfLines = 0;
    [self.view layoutIfNeeded];
#endif

    //self.scrollApp.canCancelContentTouches = NO;
    
    self.nMessages.delegate = self;
    
    colorNames = [CommonProcs getColorNames];
    colorValues = [CommonProcs getColorValues];
    
    //self.bgColorTextField.backgroundColor = colorValues[i];
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

/*
-(void)viewDidLayoutSubviews
{
    //[super viewDidLayoutSubviews];
    
    // Now contentView is equal to visible screen.
    
    if(self.view.tag == 2){
        //[super viewDidAppear:animated];
        //int yy = self.contentView.frame.size.height;
        
        //CGSize fittingSize = [self.contentView sizeThatFits:CGSizeZero];
        //fittingSize.height += 180+40;
        //[self.scroll setContentSize:fittingSize];
        
        //[self.scroll setContentSize:CGSizeMake(320,1000)];
        //[self.contentView setFrame:CGRectMake(0, 0, fittingSize.width, fittingSize.height)];
        
        //NSLog(@"Height = %f/%f",self.scroll.contentSize.height, self.contentView.frame.size.height);
    }
}
 */

-(void)adjustForSettings
{
    /*
    if(self.view.tag == 22){//2){
        float sizeOfContent = 0;
        UIView *lLast = self.signature;
        NSInteger wd = lLast.frame.origin.y;
        NSInteger ht = lLast.frame.size.height;
        
        sizeOfContent = wd+ht+130;
        
        self.scroll.contentSize = CGSizeMake(self.scroll.frame.size.width, sizeOfContent);
        //[self.contentView setFrame:CGRectMake(0, 0, self.scroll.frame.size.width, sizeOfContent)];
        //[self.view layoutIfNeeded];
        NSLog(@"Height adj = %f/%f",self.scroll.contentSize.height, self.scroll.frame.size.height);
    }
     */
}

-(void)setCurrentSettings
{
    if(self.view.tag == 2){
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
            //[self.logoutButton setEnabled:[[[GlobalRouter sharedManager] getListRouter].manager isAddressLoggedIn:self.settings.userName]];
        }else{
            [self.logoutButton setEnabled:NO];
        }
        
        self.bgColorTextField.backgroundColor = colorValues[settings.bgColor];
        self.bgColorTextField.text = colorNames[settings.bgColor];
        
        /*
        CGSize fittingSize = [self.contentView sizeThatFits:CGSizeZero];
        fittingSize.height += 250;
        //CGSize sz = [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
        [self.scroll setContentSize:fittingSize];
        */
        
    }else{
        //[self.pinCode setText:settings.pinCode];
        self.compression.value = settings.compression;
        [self compressionChanged:nil];
        
        [self.largeFontSwitch setOn:settings.largeFont];
        [self.sortByDateSwitch setOn:settings.sortAll];
        /*
        // Read from the defaults
        [self.largeFontSwitch setOn:[[[NSUserDefaults standardUserDefaults] objectForKey:@"largeFont"] boolValue]];
        id val = [[NSUserDefaults standardUserDefaults] objectForKey:@"sortByDate"];
        if(val != nil){
            [self.sortByDateSwitch setOn:[val boolValue]];
        }else{
            // No such setting, set the default on
            [self.sortByDateSwitch setOn:YES];
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"sortByDate"];
        }
        */
        
        if([CommonProcs checkBioIDAvailable]){
            [self.allowBioIDSwitch setOn:settings.useBioID];
        }else{
            self.allowBioIDSwitch.enabled = NO;
        }
        //self.keepInBg.hidden = YES;
        //self.checkPeriod.hidden = YES;
        
        /*
        CGSize fittingSize = [self.contentView sizeThatFits:CGSizeZero];
        fittingSize.height += 50;
        //CGSize sz = [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
        [self.scroll setContentSize:fittingSize];
        */
        
        [self.keepInBg setOn:settings.keepInBg];
        [self.checkPeriod setText:[NSString stringWithFormat:@"%li", (long)settings.checkPeriod]];
        
        [self.nMessages setText:[NSString stringWithFormat:@"%li", (long)settings.nMessages]];
        
        /*
        NSString* testPIN = [[NSUserDefaults standardUserDefaults] stringForKey:SOSPINSIG];
        if (testPIN && ![testPIN isEqualToString:@""]) {
            self.erasePinText.placeholder = @"Erase PIN is set";
        }*/
    }
}

-(void)gatherSettings
{
    // Get settings from text fields and put them into settings object
    if(self.view.tag == 2){
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
        
    }else{
        settings.userName = GENERAL_SETTINGS;
        settings.password = GENERAL_SETTINGS;
        settings.checkPeriod =[[self.checkPeriod text] integerValue];
        if (settings.checkPeriod == 0) {
            settings.checkPeriod = 60;
            //[self.checkPeriod setText:@"60"];
        }
        settings.keepInBg = [self.keepInBg isOn];
        
        //settings.pinCode = [self.pinCode text];
        settings.compression = [self.compression value];
        
        settings.nMessages =[[self.nMessages text] integerValue];
        settings.useBioID = self.allowBioIDSwitch.isOn;
        
        settings.largeFont = self.largeFontSwitch.isOn;
        settings.sortAll = self.sortByDateSwitch.isOn;
        settings.erasePIN = self.erasePinText.text;
    }
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
        BOOL res = [self.presenter needSaveSettings:[strongSelf->settings copy] :[GlobalRouter sharedManager].pin];
        if(res){
            //[self closeSettings];
            if ([strongSelf->settings.userName isEqualToString:GENERAL_SETTINGS]) {
                /*
                [GlobalRouter sharedManager].keepInBg = settings.keepInBg;
                if(settings.keepInBg){
                    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:settings.checkPeriod*60];
                }else{
                    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
                }
                */
            }
        }else{
            // Shouldn't get here, but who knows
            //dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs showMessage:@"" title:NSLocalizedString(@"Error saving settings",nil)];
            //});
        }
    });
    
    // Save largeFont to user defaults - moved it to where it should be, to userinfodatastorage
    /*
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.largeFontSwitch.isOn] forKey:@"largeFont"];
    [[GlobalRouter sharedManager] getListRouter].largeFont = self.largeFontSwitch.isOn;
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.sortByDateSwitch.isOn] forKey:@"sortByDate"];
    [[GlobalRouter sharedManager] getListRouter].sortByDate = self.sortByDateSwitch.isOn;
     */
    
    return YES;
    
    /*
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter PIN",nil) message:NSLocalizedString(@"Protection is needed for the settings",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Done",nil),nil];
    alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [alert setTag:100];
    [alert show];
     */
}

/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100)
    {
        / *
        if (buttonIndex == 0)
        {
            [self finished];
            
        }else{
            NSString* pin = [[alertView textFieldAtIndex:0] text];
            BOOL res = [self.presenter needSaveSettings:settings :pin];
            if(res){
                [self closeSettings];
            }else{
                // Shouldn't get here, but who knows
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error saving settings",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
                alert.tag = 10000;
                [alert show];
            }
        }
         * /
    }else if (alertView.tag == 101){
        if (buttonIndex == 0)
        {
            return;
        }
        // Confirm PIN
        temp1 = [[alertView textFieldAtIndex:0] text];
        
        // Ask for pin and pass it to presenter-interactor
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter PIN",nil) message:NSLocalizedString(@"Re-enter PIN to confirm",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Done",nil),nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;// UIAlertViewStyleSecureTextInput;
        [alert setTag:102];
        [alert show];
    }else if (alertView.tag == 102){
        if (buttonIndex == 0)
        {
            return;
        }

        NSMutableString* pin = [NSMutableString stringWithString: [[alertView textFieldAtIndex:0] text]];
        if ([pin isEqualToString:temp1]) {
            [GlobalRouter sharedManager].oldPin = [GlobalRouter sharedManager].pin;
            [GlobalRouter sharedManager].pin = pin;
            [presenter needSetupPin];
        }else{
            [CommonProcs showMessage:@"" title:NSLocalizedString(@"PINs do not match",nil)];
            //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PINs do not match",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
            //alert.tag = 10000;
            //[alert show];
        }
        
    }/ *else if (alertView.tag == 103){
        if (buttonIndex == 0)
        {
            [self.keepInBg setOn:NO];
        }else{
            
        }
    }else if (alertView.tag == 104){
        if (buttonIndex == 0)
        {
            [[[GlobalRouter sharedManager] getSettingsRouter] finished];
        }else{
            [self needSaveSettings];
        }
    }* /
}*/

-(void)finished
{
    [[[GlobalRouter sharedManager] getNavController] popViewControllerAnimated:YES];
}

-(BOOL)checkIfChanged
{
    if ([self.settings.userName isEqualToString:GENERAL_SETTINGS]) {
        return settings.keepInBg != [self.keepInBg isOn] || settings.compression != [self.compression value] || settings.checkPeriod != [[self.checkPeriod text] integerValue] || settings.nMessages != [[self.nMessages text] integerValue] || settings.useBioID != self.allowBioIDSwitch.isOn || settings.largeFont != self.largeFontSwitch.isOn || settings.sortAll != self.sortByDateSwitch.isOn;
        //return settings.compression != [self.compression value];
        
    }else{
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
    }

    return NO;

}

-(void)closeSettings
{
    /*
    //TODO: Check if changed!
    if ([self checkIfChanged]) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",nil) message:NSLocalizedString(@"Save changes?",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Close",nil) otherButtonTitles:NSLocalizedString(@"Save",nil),nil];
        [alert setTag:104];
        [alert show];
    }else{
        [[[GlobalRouter sharedManager] getSettingsRouter] finished];
    }
     */
    
    [[[GlobalRouter sharedManager] getSettingsRouter] finished];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)resetKey:(id)sender
{
    [presenter needResetKey];
}

-(IBAction)updateKey:(id)sender
{
    [presenter needUpdateKey:nil];
}

-(IBAction)compressionChanged:(id)sender
{
    [self.compressionLabel setText:[NSString stringWithFormat:@"%1.01f", self.compression.value]];
}

-(IBAction)setupPin:(id)sender
{
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [ModalDialogViewController runWithHeader:NSLocalizedString(@"Change PIN",nil) text1:NSLocalizedString(@"PIN-code is never stored anywhere, so REMEMBER IT!",nil) text2:NSLocalizedString(@"Re-enter PIN to confirm",nil) block:^{
                //NSLog(@"Changing pin to %@", [ModalDialogViewController getText1]);
                NSMutableString* pin = [ModalDialogViewController getText1];
                if(pin){
                    [GlobalRouter sharedManager].oldPin = [GlobalRouter sharedManager].pin;
                    [GlobalRouter sharedManager].pin = pin;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [strongSelf->presenter needSetupPin];
                    });
                }
        } isPassword:YES];
    });
    
    /*
    // Ask for pin and pass it to presenter-interactor
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter PIN",nil) message:NSLocalizedString(@"PIN-code is never stored anywhere, so REMEMBER IT!",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Done",nil),nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;// UIAlertViewStyleSecureTextInput;
    [alert setTag:101];
    [alert show];
     */
}

-(IBAction)userNameDoneEdit:(id)sender
{
    //if ([[self.imap text] isEqualToString:@""]) {
        NSArray* ret = [SettingsPresenter getMailSettingsForAddress:[self.userName text]];
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
}

-(void)showWheel
{
    showingWheel = YES;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    dimView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    dimView.backgroundColor = [UIColor blackColor];
    dimView.alpha = 0.5f;
    dimView.userInteractionEnabled = NO;
    [self.view addSubview:dimView];
    
    indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
    indicator.center = CGPointMake(self.view.bounds.size.width / 2, self.view.bounds.size.height/2 - 45);
    [self.view addSubview:indicator];
    [indicator startAnimating];
}

-(void)showProgress:(int)progress max:(int)maxValue
{
    if (progress == maxValue && showingWheel) {
        [indicator stopAnimating];
        [indicator removeFromSuperview];
        [dimView removeFromSuperview];
        dimView = nil;
        indicator = nil;
        showingWheel = NO;
        
    }else if(!showingWheel)
    {
        [self showWheel];
    }
}

-(IBAction)keepInBgChanged:(id)sender
{
    if ([self.keepInBg isOn]) {
        [CommonProcs askYesNoAndDoWithTitle:NSLocalizedString(@"Warning",nil) text:NSLocalizedString(@"Setting background mode on makes it possible to reverse-engineer the app's pin-code if an adversary gains a physical access to your device. Are you sure you want to turn it on?",nil) blockYes:^{
            
        } blockNo:^{
            [self.keepInBg setOn:NO];
        }];
        /*
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",nil) message:NSLocalizedString(@"Setting background mode on makes it possible to reverse-engineer the app's pin-code if an adversary gains a physical access to your device. Are you sure you want to turn it on?",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"No",nil) otherButtonTitles:NSLocalizedString(@"Yes",nil),nil];
        //alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert setTag:103];
        [alert show];*/
    }
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
    if (self.view.tag == 1) {
        self.scrollApp.contentInset = contentInsets;
        self.scrollApp.scrollIndicatorInsets = contentInsets;
    }else{
        self.scroll.contentInset = contentInsets;
        self.scroll.scrollIndicatorInsets = contentInsets;
    }
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= (kbSize.height+toAdd);
    UIView* activeField;
    for (UIView *subView in self.view.tag==1?self.contentViewApp.subviews:self.contentView.subviews) {
        if ([subView isFirstResponder]) {
            activeField = subView;
        }
    }
    
    if (activeField != nil && !CGRectContainsPoint(aRect, activeField.frame.origin) ) {
        //CGPoint scrollPoint = CGPointMake(0.0, activeField.frame.origin.y-kbSize.height);
        CGPoint scrollPoint = CGPointMake(0.0, activeField.frame.origin.y - aRect.size.height + toAdd);
        if (self.view.tag == 1) {
            [self.scrollApp setContentOffset:scrollPoint animated:YES];
        }else{
            [self.scroll setContentOffset:scrollPoint animated:YES];
        }
    }
    
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    //UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scroll.contentInset.top, 0.0, 32, 0.0);
    if (self.view.tag == 1) {
        self.scrollApp.contentInset = contentInsets;
        self.scrollApp.scrollIndicatorInsets = contentInsets;
    }else{
        self.scroll.contentInset = contentInsets;
        self.scroll.scrollIndicatorInsets = contentInsets;
    }
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
    }
    return 2;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return  1;
}

/*
-(NSAttributedString*)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString* title;
    UIColor* color;
    if ([pickerView isEqual:colors]) {
        color = colorValues[row];
        title = colorNames[row];
    }else{
        color = [UIColor whiteColor];
        if (row == 0) {
            title = @"TLS";
        }else
            title = @"StartTLS";
    }
    
    NSAttributedString *attString =
    [[NSAttributedString alloc] initWithString:title attributes:@{NSBackgroundColorAttributeName:color}];
    
    return attString;
}
 
 */

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
    }else{
        if (row == 0) {
            label.text = @"TLS";
        }else
            label.text = @"StartTLS";
    }
    return view;
}

-(IBAction)largeFontChanged:(id)sender
{
    //[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.largeFontSwitch.isOn] forKey:@"largeFont"];
    //self.settings.largeFont = self.largeFontSwitch.isOn;
    //[[GlobalRouter sharedManager] getListRouter].largeFont = ((UISwitch*)sender).isOn;
    [[[GlobalRouter sharedManager] getListRouter].presenter refreshList];
}

-(IBAction)sortByDateChanged:(id)sender
{
    //[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:self.sortByDateSwitch.isOn] forKey:@"sortByDate"];
    //self.settings.sortAll = self.sortByDateSwitch.isOn;
    //[[GlobalRouter sharedManager] getListRouter].sortByDate = ((UISwitch*)sender).isOn;
    //[[[GlobalRouter sharedManager] getListRouter].presenter refreshList];
}

-(IBAction)testButtonPress:(id)sender
{
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:NSLocalizedString(@"Warning", nil)
                                 message:NSLocalizedString(@"All data will be wiped out. Continue?", nil)
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"No",nil)
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 
                             }];
    [alert addAction:cancel];
    
    UIAlertAction* yesDoIt = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"Yes",nil)
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction * action)
                             {
                                 [[GlobalRouter sharedManager] sos];
                             }];
    [alert addAction:yesDoIt];
    
    UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
    alert.popoverPresentationController.sourceView = pView;
    alert.popoverPresentationController.sourceRect = pView.frame;
    [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
}

@end
