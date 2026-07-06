//
//  EasySetupViewController.h
//  SenseMailShare
//
//  Created by Sergey on 18.05.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//


// Easy setup aims to make adding a new account easier
// For now we have gmail accounts with OAuth authorisation
// Others accounts we try to auto-detect
// If fails, we need to ask for servers and so on
//
// So, we start asking an e-mail address and see if it's a gmail's one
// If so, bring up authorisation window, save and finish
// If not, try to connect with autodetected settings. If it's OK, save and finish.
// If not, bring up a settings page asking a user to enter settings. That is a worst case...
//

#import <UIKit/UIKit.h>

@class SettingsEntity;
@class EasySetupInteractor;

@interface EasySetupViewController : UIViewController

@property (nonatomic, strong) EasySetupInteractor* interactor;
@property (nonatomic, strong) SettingsEntity* emailSettings;

@property (nonatomic, strong) IBOutlet UITextField* address;
@property (nonatomic, strong) IBOutlet UITextField* password;
@property (nonatomic, strong) IBOutlet UILabel* labelPassword;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView* activityOutgoing;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView* activityIncoming;
@property (nonatomic, strong) IBOutlet UIButton* checkButton;
@property (nonatomic, strong) IBOutlet UILabel* labelOutgoing;
@property (nonatomic, strong) IBOutlet UILabel* labelIncoming;
@property (nonatomic, strong) IBOutlet UIView* checkView;
@property (nonatomic, strong) IBOutlet UIImageView* wheelIncomingImage;
@property (nonatomic, strong) IBOutlet UIImageView* wheelOutgoingImage;

-(IBAction)checkConnection:(id)sender;
-(IBAction)cancel:(id)sender;

@end
