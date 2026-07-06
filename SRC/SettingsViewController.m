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
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save and close",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(needSaveSettings)];
    //UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(closeSettings)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeSettings)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:button1, flexibleItem, button2, nil]];
    
    // Populate text fields
    [self setCurrentSettings];
    
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:0
                                                                         toItem:self.view
                                                                      attribute:NSLayoutAttributeLeft
                                                                     multiplier:1.0
                                                                       constant:0];
    [self.view addConstraint:leftConstraint];
    
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:0
                                                                          toItem:self.view
                                                                       attribute:NSLayoutAttributeRight
                                                                      multiplier:1.0
                                                                        constant:0];
    [self.view addConstraint:rightConstraint];

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    // prevents the scroll view from swallowing up the touch event of child buttons
    tapGesture.cancelsTouchesInView = NO;
    [self.scroll addGestureRecognizer:tapGesture];
    
}

-(void)hideKeyboard
{
    [self.view endEditing:YES];
}

-(void)setCurrentSettings
{
    if(self.view.tag == 2){
        [self.settingsName setText:settings.settingsName];
        [self.userName setText:settings.userName];
        [self.nickName setText:settings.userNick];
        [self.password setText:settings.password];
        
        [self.imap setText:settings.imapServer];
        [self.imapPrefix setText:settings.imapPrefix];
        [self.smtp setText:settings.smtpServer];
        [self.smtpPort setText:[NSString stringWithFormat:@"%li", (long)settings.smtpPort]];
        if (!([settings.userName isEqualToString:@""] || settings.userName == nil)) {
            [self.titleLabel setText:settings.userName];
        }
    }else{
        //[self.pinCode setText:settings.pinCode];
        self.compression.value = settings.compression;
        [self compressionChanged:nil];
        
        CGSize fittingSize = [self.contentView sizeThatFits:CGSizeZero];
        fittingSize.height += 50;
        //CGSize sz = [self.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
        [self.scroll setContentSize:fittingSize];
        
        [self.keepInBg setOn:settings.keepInBg];
        [self.checkPeriod setText:[NSString stringWithFormat:@"%li", (long)settings.checkPeriod]];
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
    }else{
        settings.userName = GENERAL_SETTINGS;
        settings.password = GENERAL_SETTINGS;
        settings.checkPeriod =[[self.checkPeriod text] integerValue];
        if (settings.checkPeriod == 0) {
            settings.checkPeriod = 60;
        }
        settings.keepInBg = [self.keepInBg isOn];
        
        //settings.pinCode = [self.pinCode text];
        settings.compression = [self.compression value];
    }
}

-(void)needSaveSettings
{
    [self gatherSettings];
    
    if ([settings.userName isEqualToString:@""] || [settings.password isEqualToString:@""]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error saving settings",nil) message:NSLocalizedString(@"User name or password is empty",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
        alert.tag = 10000;
        [alert show];
        
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        BOOL res = [self.presenter needSaveSettings:settings :[GlobalRouter sharedManager].pin];
        if(res){
            [self closeSettings];
            [GlobalRouter sharedManager].keepInBg = settings.keepInBg;
            [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:settings.checkPeriod*60];
        }else{
            // Shouldn't get here, but who knows
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error saving settings",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
                alert.tag = 10000;
                [alert show];
            });
        }
    });

    /*
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter PIN",nil) message:NSLocalizedString(@"Protection is needed for the settings",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Done",nil),nil];
    alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [alert setTag:100];
    [alert show];
     */
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100)
    {
        /*
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
         */
    }else if (alertView.tag == 101)
    {
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

        NSString* pin = [[alertView textFieldAtIndex:0] text];
        if ([pin isEqualToString:temp1]) {
            [GlobalRouter sharedManager].oldPin = [GlobalRouter sharedManager].pin;
            [GlobalRouter sharedManager].pin = pin;
            [presenter needSetupPin];
        }else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"PINs do not match",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
            alert.tag = 10000;
            [alert show];
        }
        
    }else if (alertView.tag == 103){
        if (buttonIndex == 0)
        {
            [self.keepInBg setOn:NO];
        }else{
            
        }
    }
}

-(void)finished
{
    [[[GlobalRouter sharedManager] getNavController] popViewControllerAnimated:YES];
}

-(void)closeSettings
{
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
    // Ask for pin and pass it to presenter-interactor
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter PIN",nil) message:NSLocalizedString(@"PIN-code is never stored anywhere, so REMEMBER IT!",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Done",nil),nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;// UIAlertViewStyleSecureTextInput;
    [alert setTag:101];
    [alert show];
}

-(IBAction)userNameDoneEdit:(id)sender
{
    if ([[self.imap text] isEqualToString:@""]) {
        NSArray* ret = [presenter getMailSettingsForAddress:[self.userName text]];
        if (ret != nil) {
            [self setMailSettings:ret];
        }
    }
}

-(void)setMailSettings:(NSArray*)mailSettings
{
    [self.imap setText:[mailSettings firstObject]];
    [self.smtp setText:[mailSettings objectAtIndex:1]];
    //[self.smtpPort setText:[mailSettings lastObject]];
    [self.smtpPort setText:@"465"];
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
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",nil) message:NSLocalizedString(@"Setting background mode on makes it possible to reverse-ingeneer the app's pin-code if an adversary gains a physical access to your device. Are you sure you want to turn it on?",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"No",nil) otherButtonTitles:NSLocalizedString(@"Yes",nil),nil];
        //alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert setTag:103];
        [alert show];
    }
}

@end
