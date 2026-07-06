//
//  Settings2Interactor.m
//  SenseMailShare
//
//  Created by Sergey on 06.12.2019.
//  Copyright © 2019 Sergey. All rights reserved.
//

#import "Settings2Interactor.h"
#import "Settings2TableViewController.h"
#import "UserInfoDataManager.h"
#import "GlobalRouter.h"
#import "SettingsEntity.h"
#import "Encryptor.h"
#import "Settings2ViewController.h"
#import "ModalDialogViewController.h"

#import <MailCore/MailCore.h>

@implementation Settings2Interactor

-(void)showSettingsInNavController:(id)navigationController addNew:(BOOL)addNew
{
    self.reloadMessagesOnExit = NO;
    vc = [[Settings2TableViewController alloc] initWithNibName:@"Settings2TableViewController" bundle:nil];
    vc.accountItems = [NSMutableArray arrayWithArray:[self getSettings]];
    vc.generalSettings = nil;
    for (SettingsEntity* sett in vc.accountItems) {
        if ([sett.settingsName isEqualToString:GENERAL_SETTINGS]) {
            vc.generalSettings = sett;
        }
    }
    if (vc.generalSettings) {
        [vc.accountItems removeObject:vc.generalSettings];
    }else{
        vc.generalSettings = [[SettingsEntity alloc] initWithGenericGeneral];
        //[[GlobalRouter sharedManager] needSaveSettings:vc.generalSettings];
    }
    vc.interactor = self;
    
    [navigationController pushViewController:vc animated:YES];
    nav = navigationController;
}

-(NSArray*)getSettings
{
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    
    return [dataMan getSettings:[GlobalRouter sharedManager].pin];
}

-(void)closeSettings
{
    [nav popViewControllerAnimated:YES];
    vc = nil;
    
    if (self.reloadMessagesOnExit) {
        self.reloadMessagesOnExit = NO;
        // Need to wait until writing is done
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            [[GlobalRouter sharedManager] checkSessions];
        });
    }
}

-(BOOL)saveSettings:(SettingsEntity*)settings :(NSMutableString*)pin
{
    if (!settings) {
        [CommonProcs showMessage:NSLocalizedString(@"No settings",nil) title:NSLocalizedString(@"Error",nil)];
        return NO;
    }
    
    if([settings.userName isEqualToString:GENERAL_SETTINGS]){
        // Save pin to keychain if touchID or FaceID is needed
        NSString* toSave;
        if (settings.useBioID) {
            NSString* kkk = [[UIDevice currentDevice].identifierForVendor UUIDString];
            Encryptor* cryptor = [[Encryptor alloc] initWithSimpleKey:kkk];
            toSave = [cryptor encryptToBase64:[GlobalRouter sharedManager].pin];
        }else{
            toSave = @"";
        }
        // First delete the key
        NSMutableDictionary *returnDictionary0 = [[NSMutableDictionary alloc] init];
        
        [returnDictionary0 setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [returnDictionary0 setObject:@"SMService" forKey:(__bridge id)kSecAttrService];
        [returnDictionary0 setObject:@"SMAccount" forKey:(__bridge id)kSecAttrAccount];
        /*OSStatus err0 = */SecItemDelete((__bridge CFDictionaryRef)returnDictionary0);
        
        if(settings.useBioID){
            SecAccessControlRef access = SecAccessControlCreateWithFlags(NULL,  // Use the default allocator.
                                                            //kSecAttrAccessibleWhenUnlocked,
                                                            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                            kSecAccessControlUserPresence,
                                                            NULL);
            
            NSMutableDictionary *returnDictionary = [[NSMutableDictionary alloc] init];
            
            [returnDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
            [returnDictionary setObject:[toSave dataUsingEncoding:NSUTF8StringEncoding]
                                 forKey:(__bridge id)kSecValueData];
            [returnDictionary setObject:(__bridge id _Nonnull)(access) forKey:(__bridge id)kSecAttrAccessControl];
            [returnDictionary setObject:@"SMService" forKey:(__bridge id)kSecAttrService];
            [returnDictionary setObject:@"SMAccount" forKey:(__bridge id)kSecAttrAccount];
            OSStatus err = SecItemAdd((__bridge CFDictionaryRef)returnDictionary, nil);
            //let status = SecItemAdd(query, nil)
            if(err != errSecSuccess) {
                //We check the error code
                NSLog(@"%@", [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil].localizedDescription);
            }
        }
        
        if (settings.enableVPN) {
            // Save password and secret to keychain
            [CommonProcs saveToKeychainAlways:settings.vpnPassword account:@"VPNPassword" service:@"SM-VPN"];
            [CommonProcs saveToKeychainAlways:settings.vpnSharedSecret account:@"VPNSS" service:@"SM-VPN"];
        }
        
        // Save erase PIN - use keychain to save it since user defaults sometimes fail...
        if (settings.erasePIN && ![settings.erasePIN isEqualToString:@""]) {
            //[[NSUserDefaults standardUserDefaults] setObject:[Encryptor getHashForString:settings.erasePIN] forKey: SOSPINSIG];
            [CommonProcs saveToKeychainAlways:[Encryptor getHashForString:settings.erasePIN] account:SOSPINSIG service:@"SM"];
        }
        //vc.generalSettings = [settings copy];
    }
    
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    
    return [dataMan saveSettings:settings :pin];
}

-(BOOL)saveShortcuts:(NSArray *)items pin:(NSMutableString *)pin
{
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    
    return [dataMan saveShortcuts:items pin:pin];
}

-(BOOL)deleteShortcut:(id)item
{
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    
    return [dataMan deleteShortcut:item pin:[GlobalRouter sharedManager].pin];
}

-(void)wantChangePin
{
    //__weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        //__strong __typeof__(self) strongSelf = weakSelf;
        [ModalDialogViewController runWithHeader:NSLocalizedString(@"Change PIN",nil) text1:NSLocalizedString(@"PIN-code is never stored anywhere, so REMEMBER IT!",nil) text2:NSLocalizedString(@"Re-enter PIN to confirm",nil) block:^{
                //NSLog(@"Changing pin to %@", [ModalDialogViewController getText1]);
                NSMutableString* pin = [ModalDialogViewController getText1];
                if(pin){
                    [GlobalRouter sharedManager].oldPin = [GlobalRouter sharedManager].pin;
                    [GlobalRouter sharedManager].pin = pin;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self setupPin];
                    });
                }
        } isPassword:YES];
    });
}
-(BOOL)setupPin
{
    // Here we need to:
    // 1. Re-encrypt settings
    // 2. Re-encrypt address book
    // 3. Re-encrypt secure gallery
    // 4. Re-encrypt notes
    // 5. Re-encrypt certificates
    // 6. Re-encrypt One-Time Certs
    
    [[[GlobalRouter sharedManager] getSettingsRouter] showBusy:0 :10];
    [[GlobalRouter sharedManager]restartQ];
    
    //dispatch_queue_t pinQueue = dispatch_queue_create("PinChange Queue",NULL);
    
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    dispatch_async([[GlobalRouter sharedManager] getQ], ^{
        
        UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
        
        NSArray* allSettings = [dataMan getSettings:[GlobalRouter sharedManager].oldPin];
        //SettingsEntity* sett = [[dataMan getSettings:[GlobalRouter sharedManager].oldPin] firstObject];
        for (SettingsEntity* sett in allSettings){
            if(sett)
                [dataMan saveSettings:sett :[GlobalRouter sharedManager].pin];
        }
        
        // Address book
        NSArray* book = [dataMan getAddressBook:[GlobalRouter sharedManager].oldPin groupsOnly:NO];
        [dataMan saveAddressBook:book pin:[GlobalRouter sharedManager].pin];
        
        // Gallery
        [dataMan saveGalleryWithNewPin:[GlobalRouter sharedManager].pin oldPin:[GlobalRouter sharedManager].oldPin];
        
        // Notes
        [dataMan saveNotesWithNewPin:[GlobalRouter sharedManager].pin oldPin:[GlobalRouter sharedManager].oldPin];
        
#if !LITE
        // Certs
        [dataMan saveAllKeysWithNewPin:[GlobalRouter sharedManager].pin oldPin:[GlobalRouter sharedManager].oldPin];
        
        // One-Time Certs
        [dataMan saveOTCsWithNewPIN:[GlobalRouter sharedManager].pin oldPIN:[GlobalRouter sharedManager].oldPin];
#endif
        dispatch_async(dispatch_get_main_queue(), ^{
            if(![[GlobalRouter sharedManager] isCancelled]){
                //[[[GlobalRouter sharedManager] getSettingsRouter] showBusy:10 :10];
                [CommonProcs hideProgress];
            }else{
                [[GlobalRouter sharedManager]restartQ];
            }
        });
        
    });
    
    return YES;
}

+(NSArray*)getMailSettingsForAddress:(NSString*)address
{
    NSArray* ret = nil;
    
    MCOMailProvider *accountProvider = [MCOMailProvidersManager.sharedManager providerForEmail:address];
    if (accountProvider) {
        NSString* imap = @"";
        NSString* imapPort = @"";
        NSString* ctypeIMAP = @"";
        for (MCONetService* tmp in accountProvider.imapServices) {
            if (tmp.connectionType == MCOConnectionTypeTLS) {
                imap = tmp.hostname;
                imapPort = [NSString stringWithFormat:@"%i", tmp.port];
                ctypeIMAP = @"TLS";
                break;
            }
        }
        // Try StartTLS if not found
        if ([imap isEqualToString:@""]) {
            for (MCONetService* tmp in accountProvider.imapServices) {
                if (tmp.connectionType == MCOConnectionTypeStartTLS) {
                    imap = tmp.hostname;
                    imapPort = [NSString stringWithFormat:@"%i", tmp.port];
                    ctypeIMAP = @"StartTLS";
                    break;
                }
            }
        }

        NSString* smtp = @"";
        NSString* port = @"";
        NSString* ctypeSMTP = @"";
        // Search for TLS connection and if not found, try StartTLS, don't use plain
        for (MCONetService* tmp2 in accountProvider.smtpServices) {
            if (tmp2.connectionType == MCOConnectionTypeTLS) {
                smtp = tmp2.hostname;
                port = [NSString stringWithFormat:@"%i", tmp2.port];
                ctypeSMTP = @"TLS";
                break;
            }/*else if (tmp2.connectionType == MCOConnectionTypeStartTLS) {
                smtp = tmp2.hostname;
                port = [NSString stringWithFormat:@"%i", tmp2.port];
                ctypeSMTP = @"StartTLS";
            }*/
        }
        
        if ([smtp isEqualToString:@""]) {
            for (MCONetService* tmp2 in accountProvider.smtpServices) {
                if (tmp2.connectionType == MCOConnectionTypeStartTLS) {
                    smtp = tmp2.hostname;
                    port = [NSString stringWithFormat:@"%i", tmp2.port];
                    ctypeSMTP = @"StartTLS";
                    break;
                }
            }
        }
        
        ret = @[imap, imapPort, ctypeIMAP, smtp, port, ctypeSMTP];
    }else{
        ret = @[@"",@"",@"", @"", @"", @""];
    }

    return ret;
}

-(void)needAddSettingsWithEmail:(NSString*)email password:(NSString*)password
{
    Settings2ViewController *detailViewController = [[Settings2ViewController alloc] initWithNibName:@"Settings2View" bundle:nil];
    detailViewController.settings = [[SettingsEntity alloc] init];
    detailViewController.interactor = self;
    detailViewController.thisIsNew = YES;
    detailViewController.settings.SMTPAuthType = MCOAuthTypeSASLLogin;
    detailViewController.settings.userName = email;
    detailViewController.settings.password = password;
    
    // Push the view controller.
    [vc.navigationController pushViewController:detailViewController animated:YES];
}

-(void)needAddSettings
{
    Settings2ViewController *detailViewController = [[Settings2ViewController alloc] initWithNibName:@"Settings2View" bundle:nil];
    detailViewController.settings = [[SettingsEntity alloc] init];
    detailViewController.interactor = self;
    detailViewController.thisIsNew = YES;
    detailViewController.settings.SMTPAuthType = MCOAuthTypeSASLLogin;
    
    // Push the view controller.
    [vc.navigationController pushViewController:detailViewController animated:YES];
}

-(void)addToTheList:(SettingsEntity *)sett
{
    [vc.accountItems addObject:sett];
    [vc.tableView reloadData];
    
    // Test the connection
    [[GlobalRouter sharedManager] checkConnection:sett completion:^(BOOL res) {
        if (!res) {
            [CommonProcs showMessage:NSLocalizedString(@"Please, check the settings", nil) title:NSLocalizedString(@"Connection error", nil)];
        }else{
            // OK
        }
    }];
}

-(void)deleteSetting:(SettingsEntity *)sett
{
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    [dataMan deleteSetting:sett];
}

-(void)wantSOS
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
