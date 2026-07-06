//
//  SettingsPresenter.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <MailCore/MailCore.h>

#import "SettingsPresenter.h"
#import "SettingsViewController.h"
#import "SettingsInteractor.h"
#import "SettingsEntity.h"
#import "CommonProcs.h"
#import "SettingsPager.h"
#import "GlobalRouter.h"

@implementation SettingsPresenter

-(id)init
{
    if (self = [super init]) {
        
    }
    
    return self;
}

-(UIViewController*)showSettings :(NSMutableString*)pin
{
    SettingsInteractor* settIn = [[SettingsInteractor alloc] init];
    NSMutableArray* settings = [NSMutableArray arrayWithArray:[settIn getSettings :pin]];
    //SettingsEntity* settings2 = [settIn getSettings :pin];
    
    if(pv == nil)
    {
        //pv = [[PageSettingsViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
        pv = [[SettingsPager alloc] init];
        pv.viewControllersT = [[NSMutableArray alloc] init];
        
    }
    if (settings.count == 0) {
        SettingsEntity* gen = [[SettingsEntity alloc] init];
        gen.userName = GENERAL_SETTINGS;
        gen.password = GENERAL_SETTINGS;
        gen.nMessages = 10;
        [settings addObject:gen];
        
        //[settings addObject:[[SettingsEntity alloc] init]];
    }
    [pv.viewControllersT removeAllObjects];
    [pv reset];

    SettingsViewController* firstC;
    SettingsEntity* firstEnt;
    BOOL gotGeneral = NO;
    for (int i = 0; i<settings.count; i++) {
        SettingsEntity* sent = [settings objectAtIndex:i];
        SettingsViewController* viewControllerTmp;
        if ([sent.userName isEqualToString:GENERAL_SETTINGS]) {
            // There can be situation when there are two general settings
            // for example if you changed pin to the already existing one
            // We need to leave only one general settings and to discard others
            if (gotGeneral) {
                // Delete it
                //[[[GlobalRouter sharedManager] getSettingsRouter] doDeleteSetting:sent];
                SettingsInteractor* interactor = [[SettingsInteractor alloc] init];
                [interactor deleteSetting:sent];
                continue;
            }else{
                gotGeneral = YES;
            }
            viewControllerTmp = [[SettingsViewController alloc] initWithNibName:@"AppSettings" bundle:nil];
            firstC = viewControllerTmp;
            firstEnt = sent;
#ifdef STRONG
            dispatch_async(dispatch_get_main_queue(), ^{
                UIButton* shuffle = (UIButton*)[viewControllerTmp.view viewWithTag:8008];
                shuffle.hidden = NO;
                [shuffle setTitle:NSLocalizedString(@"Make key file", nil) forState:UIControlStateNormal];
                [shuffle addTarget:self action:@selector(makeKeyFile:) forControlEvents:UIControlEventTouchUpInside];
            });
#endif
        }else{
            viewControllerTmp = [[SettingsViewController alloc] initWithNibName:@"SettingsView" bundle:nil];
        }
        viewControllerTmp.presenter = self;
        viewControllerTmp.settings = sent;
        viewControllerTmp.pageControl = pv;
        [pv.viewControllersT addObject:viewControllerTmp];
        
    }
    
    if(firstEnt != nil){
        [settings removeObject:firstEnt];
        [settings insertObject:firstEnt atIndex:0];
    }
    if(firstC != nil){
        [pv.viewControllersT removeObject:firstC];
        [pv.viewControllersT insertObject:firstC atIndex:0];
    }
    
    //viewController = [[SettingsViewController alloc] initWithNibName:@"SettingsView" bundle:nil];
    //viewController2 = [[SettingsViewController alloc] initWithNibName:@"SettingsView" bundle:nil];
    //[pv.viewControllers addObject:viewController];
    //[pv.viewControllers addObject:viewController2];
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        int i = 0;
        for (SettingsViewController* vc in strongSelf->pv.viewControllersT) {
            vc.settings = [settings objectAtIndex:i++];
            [vc setCurrentSettings];
        }
        strongSelf->viewController = [strongSelf->pv.viewControllersT firstObject];
        NSArray* vcc = @[strongSelf->viewController];
        //[CommonProcs hideProgress];
        __weak SettingsPager* weakPv = strongSelf->pv;
        [strongSelf->pv.pageController setViewControllers:vcc direction: UIPageViewControllerNavigationDirectionForward animated:NO completion:^(BOOL finished){
            if(finished)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakPv.pageController setViewControllers:vcc direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];// bug fix for uipageview controller
                });
            }
        }];
    });
    
    //[pv delayToNo];
    return pv;//viewController;
}

#ifdef STRONG
-(void)makeKeyFile:(id)sender
{
    //dispatch_async(dispatch_get_main_queue(), ^{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [CommonProcs askToMakeKeyFile];
    });
}
#endif

-(BOOL)needSaveSettings:(SettingsEntity *)settings :(NSMutableString*)pin
{
    SettingsInteractor* settIn = [[SettingsInteractor alloc] init];
    return [settIn saveSettings:settings :pin];
}

-(BOOL)needAddSetting
{
    SettingsEntity* sent =[[SettingsEntity alloc] init];
    SettingsViewController* viewControllerTmp = [[SettingsViewController alloc] initWithNibName:@"SettingsView" bundle:nil];
    if(![pv.email isEqualToString:@""]){
        sent.userName = pv.email;
        sent.password = pv.password;
        pv.password = @"";
        pv.email = @"";
    }
    viewControllerTmp.presenter = self;
    viewControllerTmp.settings = sent;
    viewControllerTmp.pageControl = pv;
    [pv.viewControllersT addObject:viewControllerTmp];
    [pv.pageController setViewControllers:@[viewControllerTmp] direction: UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    [pv reset];
    return YES;
}

-(BOOL)needDeleteSetting:(SettingsEntity *)settings
{
    currentSettings = settings;
    if (settings.checksum == nil) { // not saved yet
        return NO;
    }
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:NSLocalizedString(@"Are you sure?",nil)
                                 message:NSLocalizedString(@"Settings will be permanently deleted",nil)
                                 preferredStyle:UIAlertControllerStyleAlert];
    __weak __typeof__(self) weakSelf = self;
    UIAlertAction* deleteIt = [UIAlertAction
                              actionWithTitle:NSLocalizedString(@"Delete", nil)
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
                                  __strong __typeof__(self) strongSelf = weakSelf;
                                  [[[GlobalRouter sharedManager] getSettingsRouter] doDeleteSetting:strongSelf->currentSettings];
                              }];
    [alert addAction:deleteIt];
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"Cancel",nil)
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 
                             }];
    [alert addAction:cancel];
    
    UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
    alert.popoverPresentationController.sourceView = pView;
    alert.popoverPresentationController.sourceRect = pView.frame;
    [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
    return YES;
}

-(void)settingsDeleted
{
    SettingsViewController* entVC = (SettingsViewController*) [pv.pageController.viewControllers lastObject];
    [pv.viewControllersT removeObject:entVC];
    if (pv.viewControllersT.count == 0) {
        //[self closeSettings];
        [[[GlobalRouter sharedManager] getSettingsRouter] finished];
    }else{
        [pv.pageController setViewControllers:@[[pv.viewControllersT lastObject]] direction: UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
        [pv reset];
    }
}

-(BOOL)needResetKey
{
    SettingsInteractor* settIn = [[SettingsInteractor alloc] init];
    return [settIn resetKey];
}

-(BOOL)needUpdateKey:(NSString*)key
{
    SettingsInteractor* settIn = [[SettingsInteractor alloc] init];
    return [settIn updateKey:key];
}

-(BOOL)needSetupPin
{
    SettingsInteractor* settIn = [[SettingsInteractor alloc] init];
    return [settIn setupPin];
}


// Moved that to CommonProcs, need to tidy up the redundant call chain...
-(void)showBusy:(int)value :(int)maxValue
{
    //[viewController showProgress:value max:maxValue];
    //[CommonProcs showProgress:value max:maxValue inView:viewController.view];
    [CommonProcs showWheelinView:[[GlobalRouter sharedManager] getCurrentView] message:@"" stopButtonVisible:NO];
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

-(void)cleanUp
{
    viewController = nil;
    viewController2 = nil;
    pv = nil;
}

@end
