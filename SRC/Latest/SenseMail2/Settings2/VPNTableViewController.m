//
//  VPNTableViewController.m
//  SenseMailShare
//
//  Created by Sergey on 17.03.2020.
//  Copyright © 2020 Sergey. All rights reserved.
//
#if USESEC

#import "VPNTableViewController.h"
#import "GlobalRouter.h"
#import "Settings2Interactor.h"
#import "SettingsEntity.h"
#import <NetworkExtension/NetworkExtension.h>

@interface VPNTableViewController ()

@end

@implementation VPNTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save and close",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needSaveSettings)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeSettings)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:button1, flexibleItem, button2, nil]];
    
    
    UIBarButtonItem* button12 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save and close",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needSaveSettings)];
    UIBarButtonItem *flexibleItem2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button22 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeSettings)];
    inputTB = [[UIToolbar alloc] init];
    inputTB.frame = CGRectMake(0,0,250,44);
    inputTB.items = [NSArray arrayWithObjects:button12, flexibleItem2, button22, nil];
    
    // Dismiss keyboard tapping outside the text field
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)]];
    
    protocolPicker = [[UIPickerView alloc] init];
    protocolPicker.dataSource = self;
    protocolPicker.delegate = self;
    
    authMethodPicker = [[UIPickerView alloc] init];
    authMethodPicker.dataSource = self;
    authMethodPicker.delegate = self;
    
    if (@available(iOS 11.0, *)) {
        
    }else{
        self.tableView.rowHeight = 96;
    }
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)setUp
{
    if (!_settings) {
        _settings = [[SettingsEntity alloc] initWithGenericGeneral];
        //[[GlobalRouter sharedManager] needSaveSettings:_settings];
    }
    enableVPN = _settings.enableVPN;
    username = _settings.vpnUsername;
    password = _settings.vpnPassword;
    vpnServer = _settings.vpnServer;
    remoteID = _settings.vpnRemoteID;
    localID = _settings.vpnLocalID;
    sharedSecret = _settings.vpnSharedSecret;
    protocol = _settings.vpnProtocol;
    useExtAuth = _settings.vpnUseExtAuth;
    authMethod = _settings.vpnAuthMethod;
    
    self.tested = YES;
}

-(BOOL)checkIfEmpty
{
    return [self.usernameTF.text isEqualToString:@""] || [self.vpnServerTF.text isEqualToString:@""];
}

-(void)needSaveSettings
{
    if ([self checkIfEmpty]) {
        [CommonProcs showVanishingErrorMessage:NSLocalizedString(@"Settings empty", nil)];
        return;
    }
    
    self.tested = ![self checkIfChanged];
    
    _settings.enableVPN = enableVPN;
    _settings.vpnUsername = self.usernameTF.text;
    _settings.vpnPassword = self.passwordTF.text;
    _settings.vpnServer = self.vpnServerTF.text;
    _settings.vpnRemoteID = self.remoteIDTF.text;
    _settings.vpnLocalID = self.localIDTF.text;
    _settings.vpnSharedSecret = self.sharedSecretTF.text;
    _settings.vpnProtocol = self.protocolTF.text;
    _settings.vpnUseExtAuth = self.useExtAuthSwitch.on;
    _settings.vpnAuthMethod = [self.authMethodTF.text isEqualToString:@"Username"]?NEVPNIKEAuthenticationMethodNone:NEVPNIKEAuthenticationMethodSharedSecret;
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        BOOL res = [self.interactor saveSettings:[strongSelf->_settings copy] :[GlobalRouter sharedManager].pin];
        if(res){
            if (!self.tested) {
                // Test first as the changed will not be saved to the existing config
                NSLog(@"!!!!! Settings need to be tested!!!!");
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self finished];
            });
        }else{
            // Shouldn't get here, but who knows
            //dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs showMessage:@"" title:NSLocalizedString(@"Error saving settings",nil)];
            //});
        }
    });
}

-(void)finished
{
    [[[GlobalRouter sharedManager] getDetailNavController] popViewControllerAnimated:YES];
}

-(BOOL)checkIfChanged
{
    // Finish all editing since if we didn't leave the text field, the changes are not registered
    [self.view endEditing:YES];
    
    return _settings.vpnUsername != username || _settings.vpnPassword != password || _settings.vpnServer != vpnServer || _settings.vpnRemoteID != remoteID || _settings.vpnLocalID != localID || _settings.vpnSharedSecret != sharedSecret || _settings.enableVPN != enableVPN || _settings.vpnUseExtAuth != useExtAuth || _settings.vpnAuthMethod != authMethod || _settings.vpnProtocol != protocol;
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
        if (!self.tested) {
            // Test first as the changed will not be saved to the existing config
            NSLog(@"!!!!! Settings need to be tested!!!!");
        }
        [self finished];
    }
}

-(void)enableVPNChanged:(UISwitch*)sender
{
    enableVPN = sender.on;
}

-(void)useExtAuthChanged:(UISwitch*)sender
{
    useExtAuth = sender.on;
}

-(void)didChangeVPNStatus
{
    NEVPNManager * vpnManager = [NEVPNManager sharedManager];
    switch (vpnManager.connection.status) {
        case NEVPNStatusInvalid:
            dispatch_semaphore_signal(vpnSemaphore);
            break;
        case NEVPNStatusDisconnected:
            dispatch_semaphore_signal(vpnSemaphore);
            break;
        case NEVPNStatusConnecting:
            break;
        case NEVPNStatusConnected:
            dispatch_semaphore_signal(vpnSemaphore);
            break;
        case NEVPNStatusReasserting:
            break;
        case NEVPNStatusDisconnecting:
            break;
    }
}

-(void)testVPN:(id)sender
{
    if ([self checkIfEmpty]) {
        [CommonProcs showVanishingErrorMessage:NSLocalizedString(@"Settings empty", nil)];
        return;
    }
    // Disconnect VPN first
    if([NEVPNManager sharedManager].connection.status == NEVPNStatusConnected){
        [[NEVPNManager sharedManager].connection stopVPNTunnel];
        [NEVPNManager sharedManager].enabled = NO;
    }
    
    [self needSaveSettings];
    
    // Save password and secret to keychain
    [CommonProcs saveToKeychainAlways:self.passwordTF.text account:@"VPNPassword" service:@"SM-VPN"];
    [CommonProcs saveToKeychainAlways:self.sharedSecretTF.text account:@"VPNSS" service:@"SM-VPN"];
    //__weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        //__strong typeof(self) strongSelf = weakSelf;
        //strongSelf->vpnTestInProgress = YES;
        [self doTestVPN];
    });
}

-(void)doTestVPN
{
    if (vpnTestInProgress && vpnSemaphore) {
        return;
    }
    vpnTestInProgress = YES;
    vpnSemaphore = dispatch_semaphore_create(0);
    __block BOOL ret = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        NEVPNManager* manager = [NEVPNManager sharedManager];
        __weak typeof(self) weakSelf = self;
        [manager loadFromPreferencesWithCompletionHandler:^(NSError *error) {
            if(error) {
                NSLog(@"Load error: %@", error);
                ret = NO;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                    __strong typeof(self) strongSelf = weakSelf;
                    dispatch_semaphore_signal(strongSelf->vpnSemaphore);
                });
            }else{
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeVPNStatus) name:NEVPNStatusDidChangeNotification object:nil];
                //if (!manager.protocolConfiguration) {
                    NSLog(@"No config");
                    manager.enabled = YES;
                    
                    if ([self.protocolTF.text isEqualToString:@"IKEv2"]) {
                        NEVPNProtocolIKEv2* p = [[NEVPNProtocolIKEv2 alloc] init];
                        
                        p.username = self.usernameTF.text;
                        p.passwordReference = (__bridge NSData * _Nullable)([CommonProcs getPersistentDataFromKeychain:@"VPNPassword" service:@"SM-VPN"]);
                        //p.sharedSecretReference = (__bridge NSData * _Nullable)([CommonProcs getPersistentDataFromKeychain:@"VPNSS" service:@"SM-VPN"]);
                        p.serverAddress = self.vpnServerTF.text;
                        p.authenticationMethod = [self.authMethodTF.text isEqualToString:@"Username"]?NEVPNIKEAuthenticationMethodNone:NEVPNIKEAuthenticationMethodSharedSecret;
                        p.remoteIdentifier = self.remoteIDTF.text;
                        p.useExtendedAuthentication = self.useExtAuthSwitch.on;
                        p.disconnectOnSleep = YES;
                        
                        [manager setProtocolConfiguration:p];
                    }else{
                        NEVPNProtocolIPSec* p = [[NEVPNProtocolIPSec alloc] init];
                        p.username = self.usernameTF.text;
                        p.passwordReference = (__bridge NSData * _Nullable)([CommonProcs getPersistentDataFromKeychain:@"VPNPassword" service:@"SM-VPN"]);
                        p.sharedSecretReference = (__bridge NSData * _Nullable)([CommonProcs getPersistentDataFromKeychain:@"VPNSS" service:@"SM-VPN"]);
                        p.serverAddress = self.vpnServerTF.text;
                        p.authenticationMethod = [self.authMethodTF.text isEqualToString:@"Username"]?NEVPNIKEAuthenticationMethodNone:NEVPNIKEAuthenticationMethodSharedSecret;
                        p.remoteIdentifier = self.remoteIDTF.text;
                        p.useExtendedAuthentication = self.useExtAuthSwitch.on;
                        p.disconnectOnSleep = YES;
                        
                        [manager setProtocolConfiguration:p];
                    }
                    
                    [manager setOnDemandEnabled:NO];
                /*
                    NEOnDemandRuleConnect* rules = [[NEOnDemandRuleConnect alloc] init];
                    rules.interfaceTypeMatch = NEOnDemandRuleInterfaceTypeAny;
                    manager.onDemandRules = @[rules];
                    */
                    [manager setLocalizedDescription:@"SM VPN"];
                    NSLog(@"Connection desciption: %@", manager.localizedDescription);
                    [manager saveToPreferencesWithCompletionHandler:^(NSError *error) {
                       if(error) {
                          NSLog(@"Save error: %@", error);
                       }
                        NSError *startError;
                        [manager.connection startVPNTunnelAndReturnError:&startError];
                        if(startError) {
                           NSLog(@"Start error: %@", startError.localizedDescription);
                        }
                    }];
                /*}else{
                    NSError *startError;
                    manager.enabled = YES;
                    [manager.connection startVPNTunnelAndReturnError:&startError];
                    if(startError) {
                        NSLog(@"Start error: %@", startError.localizedDescription);
                    }
                    if(manager.connection.status == NEVPNStatusConnected){
                        [self didChangeVPNStatus];
                    }
                }*/
            }
        }];
    });
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs showWheelinView:[[GlobalRouter sharedManager] getCurrentView] message:NSLocalizedString(@"Connecting to VPN", nil) stopButtonVisible:YES withBlock:^{
            __strong typeof(self) strongSelf = weakSelf;
            dispatch_semaphore_signal(strongSelf->vpnSemaphore);
        }];
    });
    //__strong typeof(self) strongSelf = weakSelf;
    dispatch_semaphore_wait(vpnSemaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(50 * NSEC_PER_SEC)));
    [NSThread sleepForTimeInterval:0.600];
    if ([NEVPNManager sharedManager].connection.status == NEVPNStatusConnected) {
        ret = YES;
    }
    [CommonProcs hideProgressAlways];
    
    if(!ret){
        //__weak typeof(self) weakSelf = self;
        dispatch_semaphore_t askSem = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs showMessage:NSLocalizedString(@"Cannot connect to VPN. Please, check the settings", nil) title:@""];
            //int i = 0; i++;
            dispatch_semaphore_signal(askSem);
        });
        
        dispatch_semaphore_wait(askSem, DISPATCH_TIME_FOREVER);
        NSLog(@"Semaphore signalled");
    }
    vpnTestInProgress = NO;
    self.tested = YES;
    vpnSemaphore = nil;
    //return ret;
}

-(void)textFieldDidChange:(UITextField*)sender
{
    if (sender == self.usernameTF) {
        username = self.usernameTF.text;
    }else if (sender == self.passwordTF) {
        password = self.passwordTF.text;
    }else if (sender == self.vpnServerTF) {
        vpnServer = self.vpnServerTF.text;
    }else if (sender == self.remoteIDTF) {
        remoteID = self.remoteIDTF.text;
    }else if (sender == self.localIDTF) {
        localID = self.localIDTF.text;
    }else if (sender == self.sharedSecretTF) {
        sharedSecret = self.sharedSecretTF.text;
    }else if (sender == self.authMethodTF) {
        authMethod = [self.authMethodTF.text isEqualToString:@"Username"]?NEVPNIKEAuthenticationMethodNone:NEVPNIKEAuthenticationMethodSharedSecret;
        if(authMethod == NEVPNIKEAuthenticationMethodNone){
            // If use None, when extended auth is normally used
            useExtAuth = YES;
            [self.useExtAuthSwitch setOn:YES];
        }else{
            // Normally, extended auth is not used with the shared secret
            useExtAuth = NO;
            [self.useExtAuthSwitch setOn:NO];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }else{
        return 11;
    }
}

-(void)setRoundedFrameWithIndent:(UITextField*)cview
{
    [[cview layer] setCornerRadius:6.0f];
    [[cview layer] setMasksToBounds:YES];
    [[cview layer] setBorderWidth:0.35f];
    [[cview layer] setBorderColor:[UIColor lightGrayColor].CGColor];
    
    // Make the text indent
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, cview.frame.size.height)];
    leftView.backgroundColor = cview.backgroundColor;
    cview.leftView = leftView;
    cview.leftViewMode = UITextFieldViewModeAlways;
    
    cview.autocapitalizationType = UITextAutocapitalizationTypeNone;
    cview.autocorrectionType = UITextAutocorrectionTypeNo;
    [cview setFont:[UIFont systemFontOfSize:12]];
    
    cview.inputAccessoryView = inputTB;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"VPNCell"];
    
#define txtWidth 180
    
    // Configure the cell...
    if(indexPath.section == 0){
        if (indexPath.row == 0) {
            cell.textLabel.numberOfLines = 0;
            //cell.textLabel.text = NSLocalizedString(@"Note:",nil);
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
            cell.detailTextLabel.text = NSLocalizedString(@"- VPN connection is not supported in the background mode, so if you use BG mail check, disable it first unless you are OK with a SSL connection without VPN to check the number of new messages.",nil);
            if (@available(iOS 13.0, *)) {
                cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
            } else {
                // Fallback on earlier versions
                cell.detailTextLabel.textColor = [UIColor grayColor];
            }
        }
    }else{
        if (indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"Enable VPN",nil);
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
            cell.detailTextLabel.text = NSLocalizedString(@"Connect to VPN before checking mail", nil);
            if (@available(iOS 13.0, *)) {
                cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
            } else {
                // Fallback on earlier versions
                cell.detailTextLabel.textColor = [UIColor grayColor];
            }
            UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 60, 30)];
            self.enableVPNSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(10,0, 50, 30)];
            [self.enableVPNSwitch setOn:enableVPN];
            //clearBG = self.settings.clearOnBG;
            [self.enableVPNSwitch addTarget:self action:@selector(enableVPNChanged:) forControlEvents:UIControlEventValueChanged];
            [wrapper addSubview:self.enableVPNSwitch];
            cell.accessoryView = self.enableVPNSwitch;
        }else if(indexPath.row == 1){
            cell.textLabel.text = NSLocalizedString(@"Protocol",nil);
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
            cell.detailTextLabel.text = NSLocalizedString(@"IKEv2 or IPSec are supported",nil);
            if (@available(iOS 13.0, *)) {
                cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
            } else {
                // Fallback on earlier versions
                cell.detailTextLabel.textColor = [UIColor grayColor];
            }
            UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 120, 30)];
            self.protocolTF = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, 110, 30)];
            
            [self setRoundedFrameWithIndent:self.protocolTF];
            [self.protocolTF setText:protocol];
            self.protocolTF.inputView = protocolPicker;
            [wrapper addSubview:self.protocolTF];
            cell.accessoryView = wrapper;
        }else if(indexPath.row == 2){
            cell.textLabel.text = NSLocalizedString(@"User Name",nil);
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
            cell.detailTextLabel.text = NSLocalizedString(@"User name to login to the VPN Server",nil);
            if (@available(iOS 13.0, *)) {
                cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
            } else {
                // Fallback on earlier versions
                cell.detailTextLabel.textColor = [UIColor grayColor];
            }
            UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, txtWidth, 30)];
            self.usernameTF = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, txtWidth-10, 30)];
            
            [self setRoundedFrameWithIndent:self.usernameTF];
            [self.usernameTF setText:username];
            [self.usernameTF setPlaceholder:NSLocalizedString(@"Required",nil)];
            [self.usernameTF addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingDidEnd];
            
            [wrapper addSubview:self.usernameTF];
            cell.accessoryView = wrapper;
        }else if(indexPath.row == 3){
            cell.textLabel.text = NSLocalizedString(@"Password",nil);
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
            cell.detailTextLabel.text = NSLocalizedString(@"Password to login to the VPN Server",nil);
            if (@available(iOS 13.0, *)) {
                cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
            } else {
                // Fallback on earlier versions
                cell.detailTextLabel.textColor = [UIColor grayColor];
            }
            UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, txtWidth, 30)];
            self.passwordTF = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, txtWidth-10, 30)];
            
            [self setRoundedFrameWithIndent:self.passwordTF];
            [self.passwordTF setText:password];
            [self.passwordTF setPlaceholder:NSLocalizedString(@"Required",nil)];
            [self.passwordTF addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingDidEnd];
            [wrapper addSubview:self.passwordTF];
            cell.accessoryView = wrapper;
        }else if(indexPath.row == 4){
            cell.textLabel.text = NSLocalizedString(@"VPN Server",nil);
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
            cell.detailTextLabel.text = NSLocalizedString(@"Address of the VPN Server",nil);
            if (@available(iOS 13.0, *)) {
                cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
            } else {
                // Fallback on earlier versions
                cell.detailTextLabel.textColor = [UIColor grayColor];
            }
            UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, txtWidth, 30)];
            self.vpnServerTF = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, txtWidth-10, 30)];
            
            [self setRoundedFrameWithIndent:self.vpnServerTF];
            [self.vpnServerTF setText:vpnServer];
            [self.vpnServerTF setPlaceholder:NSLocalizedString(@"Required",nil)];
            [self.vpnServerTF addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingDidEnd];
            [wrapper addSubview:self.vpnServerTF];
            cell.accessoryView = wrapper;
        }else if(indexPath.row == 5){
            cell.textLabel.text = NSLocalizedString(@"Remote ID",nil);
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
            cell.detailTextLabel.text = NSLocalizedString(@"Remote identifier to login to the VPN Server",nil);
            if (@available(iOS 13.0, *)) {
                cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
            } else {
                // Fallback on earlier versions
                cell.detailTextLabel.textColor = [UIColor grayColor];
            }
            UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, txtWidth, 30)];
            self.remoteIDTF = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, txtWidth-10, 30)];
            
            [self setRoundedFrameWithIndent:self.remoteIDTF];
            [self.remoteIDTF setText:remoteID];
            [self.remoteIDTF setPlaceholder:NSLocalizedString(@"Required",nil)];
            [self.remoteIDTF addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingDidEnd];
            [wrapper addSubview:self.remoteIDTF];
            cell.accessoryView = wrapper;
        }else if(indexPath.row == 6){
            cell.textLabel.text = NSLocalizedString(@"Local ID",nil);
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
            cell.detailTextLabel.text = NSLocalizedString(@"Local identifier to login to the VPN Server",nil);
            if (@available(iOS 13.0, *)) {
                cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
            } else {
                // Fallback on earlier versions
                cell.detailTextLabel.textColor = [UIColor grayColor];
            }
            UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, txtWidth, 30)];
            self.localIDTF = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, txtWidth-10, 30)];
            
            [self setRoundedFrameWithIndent:self.localIDTF];
            [self.localIDTF setText:localID];
            [self.localIDTF setPlaceholder:NSLocalizedString(@"Optional",nil)];
            [self.localIDTF addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingDidEnd];
            [wrapper addSubview:self.localIDTF];
            cell.accessoryView = wrapper;
        }else if(indexPath.row == 7){
            cell.textLabel.text = NSLocalizedString(@"Authentication Method",nil);
            cell.textLabel.numberOfLines = 0;
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
            cell.detailTextLabel.text = NSLocalizedString(@"Authentication method to login to the VPN Server",nil);
            if (@available(iOS 13.0, *)) {
                cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
            } else {
                // Fallback on earlier versions
                cell.detailTextLabel.textColor = [UIColor grayColor];
            }
            UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 120, 30)];
            self.authMethodTF = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, 110, 30)];
            
            [self setRoundedFrameWithIndent:self.authMethodTF];
            [self.authMethodTF setText:authMethod==NEVPNIKEAuthenticationMethodNone?@"Username":@"Shared secret"];
            self.authMethodTF.inputView = authMethodPicker;
            [self.authMethodTF addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingDidEnd];
            [wrapper addSubview:self.authMethodTF];
            cell.accessoryView = wrapper;
        }else if (indexPath.row == 8) {
            cell.textLabel.text = NSLocalizedString(@"Extended Authentication",nil);
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
            cell.detailTextLabel.text = NSLocalizedString(@"Use extended authentication to authorise", nil);
            if (@available(iOS 13.0, *)) {
                cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
            } else {
                // Fallback on earlier versions
                cell.detailTextLabel.textColor = [UIColor grayColor];
            }
            UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 60, 30)];
            self.useExtAuthSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(10,0, 50, 30)];
            [self.useExtAuthSwitch setOn:useExtAuth];
            [self.useExtAuthSwitch addTarget:self action:@selector(useExtAuthChanged:) forControlEvents:UIControlEventValueChanged];
            [wrapper addSubview:self.useExtAuthSwitch];
            cell.accessoryView = self.useExtAuthSwitch;
        }else if(indexPath.row == 9){
            cell.textLabel.text = NSLocalizedString(@"Shared secret",nil);
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
            cell.detailTextLabel.text = NSLocalizedString(@"Shared secret to login to the VPN Server",nil);
            if (@available(iOS 13.0, *)) {
                cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
            } else {
                // Fallback on earlier versions
                cell.detailTextLabel.textColor = [UIColor grayColor];
            }
            UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, txtWidth, 30)];
            self.sharedSecretTF = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, txtWidth-10, 30)];
            
            [self setRoundedFrameWithIndent:self.sharedSecretTF];
            [self.sharedSecretTF setText:sharedSecret];
            [self.sharedSecretTF addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingDidEnd];
            [wrapper addSubview:self.sharedSecretTF];
            cell.accessoryView = wrapper;
        }else if(indexPath.row == 10){
            cell.textLabel.text = NSLocalizedString(@"Check connection",nil);
            cell.detailTextLabel.numberOfLines = 0;
            cell.detailTextLabel.textAlignment = NSTextAlignmentJustified;
            cell.detailTextLabel.text = NSLocalizedString(@"Try to connect to the VPN server",nil);
            if (@available(iOS 13.0, *)) {
                cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
            } else {
                // Fallback on earlier versions
                cell.detailTextLabel.textColor = [UIColor grayColor];
            }
            UIView* wrapper = [[UIView alloc] initWithFrame:CGRectMake(0,0, 120, 30)];
            UIButton* testButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
            [testButton setTitle:NSLocalizedString(@"Check",nil) forState:UIControlStateNormal];
            [testButton setFrame:CGRectMake(10,0, 110, 30)];
            [testButton addTarget:self action:@selector(testVPN:) forControlEvents:UIControlEventTouchUpInside];
            [[testButton layer] setCornerRadius:6.0f];
            [[testButton layer] setMasksToBounds:YES];
            [[testButton layer] setBorderWidth:0.35f];
            [[testButton layer] setBorderColor:[UIColor lightGrayColor].CGColor];
            [wrapper addSubview:testButton];
            cell.accessoryView = wrapper;
        }
    }
    
    return cell;
}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return NSLocalizedString(@"Note", nil);
    }else{
        return NSLocalizedString(@"Connect to VPN first", nil);
    }
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if ([pickerView isEqual:protocolPicker]) {
        return 2;
    }else if ([pickerView isEqual:authMethodPicker]) {
        return 2;
    }
    return 2;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return  1;
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if ([self.protocolTF isFirstResponder]) {
        [self.protocolTF setText:row==0?@"IKEv2":@"IPSec"];
        protocol = row==0?@"IKEv2":@"IPSec";
        [self.protocolTF resignFirstResponder];
    }else if([self.authMethodTF isFirstResponder]) {
        [self.authMethodTF setText:row==0?@"Username":@"Shared secret"];
        authMethod = row==0?NEVPNIKEAuthenticationMethodNone:NEVPNIKEAuthenticationMethodSharedSecret;
        // If used none, set the extended on
        if (row == 0) {
            self.useExtAuthSwitch.on = YES;
            [self useExtAuthChanged:self.useExtAuthSwitch];
        }
        
        [self.authMethodTF resignFirstResponder];
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
    
    if ([pickerView isEqual:protocolPicker]) {
        if(row == 0) label.text = @"IKEv2";
        else label.text = @"IPSec";
    }else if ([pickerView isEqual:authMethodPicker]){
        if (row == 0) {
            label.text = @"Username";
        }else
            label.text = @"Shared secret";
    }
    return view;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here, for example:
    // Create the next view controller.
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:<#@"Nib name"#> bundle:nil];
    
    // Pass the selected object to the new view controller.
    
    // Push the view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

#endif
