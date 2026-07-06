//
//  SecondViewController.h
//  SenseMail2
//
//  Created by Sergey on 05.02.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SettingsPresenter;
@class SettingsEntity;
@class SettingsPager;

@interface SettingsViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate>
{
    //SettingsEntity* settings;
    BOOL showingWheel;
    UIActivityIndicatorView *indicator;
    UIView* dimView;
    UIPickerView* colors;
    NSArray* colorValues;
    NSArray* colorNames;
}

@property (nonatomic, weak) SettingsPresenter* presenter;

@property (nonatomic, retain) SettingsEntity* settings;

@property (nonatomic) IBOutlet UITextField* settingsName;
@property (nonatomic) IBOutlet UITextField* userName;
@property (nonatomic) IBOutlet UITextField* password;
@property (nonatomic) IBOutlet UITextField* nickName;

@property (nonatomic) IBOutlet UITextField* bgColorTextField;

@property (nonatomic) IBOutlet UITextField* imap;
@property (nonatomic) IBOutlet UITextField* smtp;
@property (nonatomic) IBOutlet UITextField* smtpPort;
@property (nonatomic) IBOutlet UITextField* imapPrefix;
@property (nonatomic) IBOutlet UITextField* imapPort;
@property (nonatomic) IBOutlet UITextField* connectionTypeSMTP;
@property (nonatomic) IBOutlet UITextField* connectionTypeIMAP;

//@property (nonatomic) IBOutlet UITextField* pinCode;
@property (nonatomic) IBOutlet UISlider* compression;
@property (nonatomic) IBOutlet UILabel* compressionLabel;
@property (nonatomic) IBOutlet UILabel* keyLabel;
@property (nonatomic) IBOutlet UILabel* titleLabel;

@property (nonatomic) IBOutlet UIScrollView* scroll;
@property (nonatomic) IBOutlet UIView* contentView;
@property (nonatomic) IBOutlet UIScrollView* scrollApp;
@property (nonatomic) IBOutlet UIView* contentViewApp;
@property (nonatomic, weak) SettingsPager* pageControl;

@property (nonatomic) IBOutlet UILabel* checkDescriptionLabel;
@property (nonatomic) IBOutlet UITextField* checkPeriod;
@property (nonatomic) IBOutlet UISwitch* keepInBg;
@property (nonatomic) IBOutlet UILabel* checkPeriodLabel;
@property (nonatomic) IBOutlet UILabel* keepInBgLabel;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* topClearAllConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* topNoCheckConstraint;

@property (strong, nonatomic) UIToolbar *inputAccessoryToolbar;

@property (nonatomic, weak) IBOutlet UIButton* logoutButton;
@property (nonatomic, weak) IBOutlet UIButton* togglePwdButton;

@property (nonatomic) IBOutlet UITextView* signature;
@property (nonatomic) IBOutlet UISwitch* largeFontSwitch;
@property (nonatomic) IBOutlet UITextField* nMessages;
@property (nonatomic) IBOutlet UISwitch* sortByDateSwitch;
@property (nonatomic) IBOutlet UISwitch* allowBioIDSwitch;
@property (nonatomic, weak) IBOutlet UIButton* changePinButton;
@property (nonatomic, weak) IBOutlet UITextField* erasePinText;

-(IBAction)keepInBgChanged:(id)sender;
-(IBAction)resetKey:(id)sender;
-(IBAction)updateKey:(id)sender;
-(IBAction)setupPin:(id)sender;
-(IBAction)largeFontChanged:(id)sender;
-(IBAction)sortByDateChanged:(id)sender;

-(IBAction)userNameDoneEdit:(id)sender;
-(void)setMailSettings:(NSArray*)mailSettings;

-(IBAction)compressionChanged:(id)sender;

-(IBAction)logout:(id)sender;

-(IBAction)togglePassword:(id)sender;

-(void)setCurrentSettings;

-(void)showProgress:(int)progress max:(int)maxValue;

-(BOOL)needSaveSettings;
-(BOOL)checkIfChanged;
-(void)closeSettings;
-(void)adjustForSettings;

-(IBAction)testButtonPress:(id)sender;

@end

