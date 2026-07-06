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

@interface SettingsViewController : UIViewController
{
    //SettingsEntity* settings;
    BOOL showingWheel;
    UIActivityIndicatorView *indicator;
    UIView* dimView;
}

@property (nonatomic, weak) SettingsPresenter* presenter;

@property (nonatomic, retain) SettingsEntity* settings;

@property (nonatomic) IBOutlet UITextField* settingsName;
@property (nonatomic) IBOutlet UITextField* userName;
@property (nonatomic) IBOutlet UITextField* password;
@property (nonatomic) IBOutlet UITextField* nickName;

@property (nonatomic) IBOutlet UITextField* imap;
@property (nonatomic) IBOutlet UITextField* smtp;
@property (nonatomic) IBOutlet UITextField* smtpPort;
@property (nonatomic) IBOutlet UITextField* imapPrefix;

//@property (nonatomic) IBOutlet UITextField* pinCode;
@property (nonatomic) IBOutlet UISlider* compression;
@property (nonatomic) IBOutlet UILabel* compressionLabel;
@property (nonatomic) IBOutlet UILabel* keyLabel;
@property (nonatomic) IBOutlet UILabel* titleLabel;

@property (nonatomic) IBOutlet UIScrollView* scroll;
@property (nonatomic) IBOutlet UIView* contentView;
@property (nonatomic, strong) UIPageControl* pageControl;

@property (nonatomic) IBOutlet UITextField* checkPeriod;
@property (nonatomic) IBOutlet UISwitch* keepInBg;

-(IBAction)keepInBgChanged:(id)sender;
-(IBAction)resetKey:(id)sender;
-(IBAction)updateKey:(id)sender;
-(IBAction)setupPin:(id)sender;

-(IBAction)userNameDoneEdit:(id)sender;
-(void)setMailSettings:(NSArray*)mailSettings;

-(IBAction)compressionChanged:(id)sender;

-(void)setCurrentSettings;

-(void)showProgress:(int)progress max:(int)maxValue;

-(void)needSaveSettings;

@end

