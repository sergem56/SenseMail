//
//  VPNTableViewController.h
//  SenseMailShare
//
//  Created by Sergey on 17.03.2020.
//  Copyright © 2020 Sergey. All rights reserved.
//
#if USESEC


#import <UIKit/UIKit.h>
#import <NetworkExtension/NetworkExtension.h>

NS_ASSUME_NONNULL_BEGIN

@class Settings2Interactor;
@class SettingsEntity;

@interface VPNTableViewController : UITableViewController <UIPickerViewDelegate, UIPickerViewDataSource>
{
    BOOL enableVPN;
    NSString* username;
    NSString* password;
    NSString* vpnServer;
    NSString* remoteID;
    NSString* localID;
    NSString* sharedSecret;
    NSString* protocol;
    NEVPNIKEAuthenticationMethod authMethod;
    BOOL useExtAuth;
    UIPickerView* protocolPicker;
    UIPickerView* authMethodPicker;
    
    dispatch_semaphore_t vpnSemaphore;
    UIToolbar* inputTB;
    BOOL vpnTestInProgress;
}

@property (nonatomic, strong) SettingsEntity* settings;
@property (nonatomic, weak) Settings2Interactor* interactor;

// IKEv2:
// username
// password
// server
// authenticationMethod
// remote ID
// local ID ?
// useExtendedAuthentication

@property (nonatomic, strong) UISwitch* enableVPNSwitch;
@property (nonatomic, strong) UITextField* protocolTF; // IKEv2 or IPSec
@property (nonatomic, strong) UITextField* usernameTF;
@property (nonatomic, strong) UITextField* passwordTF;
@property (nonatomic, strong) UITextField* vpnServerTF;
@property (nonatomic, strong) UITextField* remoteIDTF;
@property (nonatomic, strong) UITextField* localIDTF;
@property (nonatomic, strong) UITextField* authMethodTF;
@property (nonatomic, strong) UISwitch* useExtAuthSwitch;
@property (nonatomic, strong) UITextField* sharedSecretTF;

@property (nonatomic, assign) BOOL tested;

-(void)setUp;

@end

NS_ASSUME_NONNULL_END

#endif
