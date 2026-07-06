//
//  EasySetupInteractor.m
//  SenseMailShare
//
//  Created by Sergey on 18.05.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

#import "EasySetupInteractor.h"
#import "EasySetupViewController.h"
#import "SettingsEntity.h"
#import "SettingsPresenter.h"
#import "SessionConnectorNew.h"
#import "GlobalRouter.h"

@implementation EasySetupInteractor

-(void)showMasterInNC:(UINavigationController *)nav
{
    EasySetupViewController* vc = [[EasySetupViewController alloc] initWithNibName:@"EasySetupViewController" bundle:nil];
    vc.interactor = self;
    self.vc = vc;
    navi = nav;
    //[nav presentViewController:vc animated:YES completion:^{
    [nav pushViewController:vc animated:YES];
        // vc is dead here...
        //NSLog(@"returned %@",vc.emailSettings.imapServer);
    //}];
}

-(void)emailEntered:(NSString *)email
{
    // Check the email validity
    if([CommonProcs isEmailValid:email]){
        
    }else{
        [CommonProcs showMessage:[NSString stringWithFormat:NSLocalizedString(@"Invalid e-mail address", nil),email] title:NSLocalizedString(@"Error",nil)];
        return;
    }
    
    self.vc.checkButton.enabled = NO;
    
    NSArray* settings = [SettingsPresenter getMailSettingsForAddress:email];
    if(![settings[0] isEqualToString:@""]){
        SettingsEntity* newSettings = [[SettingsEntity alloc] init];
        newSettings.userName = email;
        newSettings.imapServer = settings[0];
        newSettings.imapPort = [(NSString*)settings[1] intValue];
        newSettings.connectionTypeIMAP = [newSettings getTypeFromString:settings[2]];
        newSettings.smtpServer = settings[3];
        newSettings.smtpPort = [(NSString*)settings[4] intValue];
        newSettings.connectionTypeSMTP = [newSettings getTypeFromString:settings[5]];
        NSLog(@"imap=%@:%@, smtp=%@:%@", settings[0],settings[1], settings[3],settings[4]);
        newSettings.password = self.vc.password.text;
        
        // Start a wheel
        self.vc.checkView.hidden = NO;
        [self resetWheels];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.vc.activityOutgoing.hidden = NO;
            [self.vc.activityOutgoing startAnimating];
        });
        [[GlobalRouter sharedManager] checkSMTPConnection:newSettings completion:^(int res){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.vc.activityOutgoing stopAnimating];
                [self showResInWheel:self.vc.activityOutgoing res:res==0];
            });
            if(res != 0){
                // Error checking SMTP connection
                if (res == ERROR_NO_SUCH_USER) { // user not found, cancel checks
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.vc.checkButton.enabled = YES;
                        self.vc.checkView.hidden = YES;
                        [self resetWheels];
                        [CommonProcs showMessage:NSLocalizedString(@"The user not found", nil) title:NSLocalizedString(@"Error", nil)];
                    });
                    return;
                }else if(res == ERROR_CANCELLED){
                    // Cancel silently
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.vc.checkButton.enabled = YES;
                        self.vc.checkView.hidden = YES;
                        [self resetWheels];
                    });
                    return;
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                self.vc.activityIncoming.hidden = NO;
                [self.vc.activityIncoming startAnimating];
            });
            [[GlobalRouter sharedManager] checkConnection:newSettings completion:^(BOOL res){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.vc.activityIncoming stopAnimating];
                    [self showResInWheel:self.vc.activityIncoming res:res];
                    self.vc.checkButton.enabled = YES;
                });
                if(!res){
                    // Error checking IMAP...
                    
                }else{
                    // Everything os OK, save these settings, name them first
                    newSettings.settingsName = email;
                    newSettings.userNick = email;
                    // Check if exists...
                    SettingsEntity* found = [[GlobalRouter sharedManager] getSettingForAddress:email];
                    if (found != nil) {
                        //NSLog(@"Settings already exists");
                        // Show message to user?
                        [CommonProcs showMessage:[NSString stringWithFormat:NSLocalizedString(@"Settings for %@ already exist", nil),email] title:NSLocalizedString(@"No need to save",nil)];
                    }else{
                        // Save
                        // NEED to add and save General settings as well, otherwise it won't be read properly
                        if (![[GlobalRouter sharedManager] getSettingForAddress:GENERAL_SETTINGS]){
                            SettingsEntity* general = [[SettingsEntity alloc] initWithGenericGeneral];
                            [[GlobalRouter sharedManager] needSaveSettings:general];
                        }
                        
                        [[GlobalRouter sharedManager] needSaveSettings:newSettings];
                        [CommonProcs showMessage:NSLocalizedString(@"Settings saved", nil) title:NSLocalizedString(@"Success",nil)];
                        // Update menu and load messages
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                            [[GlobalRouter sharedManager] checkSessions];
                        });
                    }
                    //dispatch_async(dispatch_get_main_queue(), ^{
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[GlobalRouter sharedManager] finishedWithCurrentView:YES]; //finishedWithDetailView:YES];
                    });
                        //self.vc.checkButton.enabled = YES;
                        //[self.vc dismissViewControllerAnimated:YES completion:nil];
                        //[[GlobalRouter sharedManager] finishedWithDetailView:YES];
                    //});
                    
                }
                
            }];
        }];
        
            //[self.vc dismissViewControllerAnimated:YES completion:nil];
        
        /*
        SessionConnectorNew* checker = [[SessionConnectorNew alloc] initWithSettings:newSettings];
        [checker connectIMAPSessionWithCompletionHandler:^(NSError * _Nonnull error) {
            if(error){
                NSLog(@"Error: %@",error.localizedDescription);
            }else{
                NSLog(@"Settings OK");
            }
        }];
         */
    }else{
        // Not found, open settings page
        [[GlobalRouter sharedManager] finishedWithCurrentView:YES];
        //[self.vc dismissViewControllerAnimated:YES completion:^{
            [[GlobalRouter sharedManager] needSettingsWithNew:email password:self.vc.password.text];
            [CommonProcs showMessage:[NSString stringWithFormat:NSLocalizedString(@"We could not find servers for %@ and we opened a settings page to enter them manually", nil), email] title:NSLocalizedString(@"Error",nil)];
        //}];
        self.vc.checkButton.enabled = YES;
        //NSLog(@"Not found");
    }
    
}

-(void)showResInWheel:(UIActivityIndicatorView*)wheel res:(BOOL)res
{
    dispatch_async(dispatch_get_main_queue(), ^{
        wheel.hidden = YES;
        if (wheel == self.vc.activityIncoming) {
            self.vc.wheelIncomingImage.hidden = NO;
            [self.vc.wheelIncomingImage setImage:[UIImage imageNamed:res?@"OK2":@"NO2"]];
        }else{
            self.vc.wheelOutgoingImage.hidden = NO;
            [self.vc.wheelOutgoingImage setImage:[UIImage imageNamed:res?@"OK2":@"NO2"]];
        }
    });
}

-(void)resetWheels
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.vc.wheelIncomingImage.hidden = YES;
        self.vc.wheelOutgoingImage.hidden = YES;
        self.vc.activityIncoming.hidden = YES;
        self.vc.activityOutgoing.hidden = YES;
    });
}

@end
