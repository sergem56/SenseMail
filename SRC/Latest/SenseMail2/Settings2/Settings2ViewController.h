//
//  SecondViewController.h
//  SenseMail2
//
//  Created by Sergey on 05.02.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Settings2Interactor;
@class SettingsEntity;
//@class SettingsPager;

@interface Settings2ViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UIGestureRecognizerDelegate, UITextFieldDelegate>
{
    UIPickerView* colors;
    NSArray* colorValues;
    NSArray* colorNames;
    NSArray* authTypesValues;
    UIPickerView* aPicker;
}

@property (nonatomic, weak) Settings2Interactor* interactor;

@property (nonatomic, retain) SettingsEntity* settings;
@property (nonatomic, assign) BOOL thisIsNew;

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
@property (nonatomic) IBOutlet UILabel* titleLabel;
@property (nonatomic) IBOutlet UILabel* signatureLabel;
@property (nonatomic) IBOutlet UITextField* authType;

@property (nonatomic) IBOutlet UIScrollView* scroll;
@property (nonatomic) IBOutlet UIView* contentView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* topClearAllConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* topNoCheckConstraint;

@property (strong, nonatomic) UIToolbar *inputAccessoryToolbar;

@property (nonatomic, weak) IBOutlet UIButton* logoutButton;
@property (nonatomic, weak) IBOutlet UIButton* togglePwdButton;

@property (nonatomic) IBOutlet UITextView* signature;

-(IBAction)userNameDoneEdit:(id)sender;
-(void)setMailSettings:(NSArray*)mailSettings;

-(IBAction)logout:(id)sender;

-(IBAction)togglePassword:(id)sender;

-(void)setCurrentSettings;

-(BOOL)needSaveSettings;
-(BOOL)checkIfChanged;
-(void)closeSettings;
-(void)adjustForSettings;

@end

