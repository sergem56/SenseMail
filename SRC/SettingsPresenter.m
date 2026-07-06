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

-(UIViewController*)showSettings :(NSString*)pin
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
        [settings addObject:gen];
        
        //[settings addObject:[[SettingsEntity alloc] init]];
    }
    [pv.viewControllersT removeAllObjects];
    [pv reset];

    SettingsViewController* firstC;
    SettingsEntity* firstEnt;
    for (int i = 0; i<settings.count; i++) {
        SettingsEntity* sent = [settings objectAtIndex:i];
        SettingsViewController* viewControllerTmp;
        if ([sent.userName isEqualToString:GENERAL_SETTINGS]) {
            viewControllerTmp = [[SettingsViewController alloc] initWithNibName:@"AppSettings" bundle:nil];
            firstC = viewControllerTmp;
            firstEnt = sent;
        }else{
            viewControllerTmp = [[SettingsViewController alloc] initWithNibName:@"SettingsView" bundle:nil];
        }
        viewControllerTmp.presenter = self;
        viewControllerTmp.settings = sent;
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        int i = 0;
        for (SettingsViewController* vc in pv.viewControllersT) {
            vc.settings = [settings objectAtIndex:i++];
            [vc setCurrentSettings];
        }
        viewController = [pv.viewControllersT firstObject];
        NSArray* vcc = @[viewController];
        //[CommonProcs hideProgress];
        __weak SettingsPager* weakPv = pv;
        [pv.pageController setViewControllers:vcc direction: UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished){
            if(finished)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakPv.pageController setViewControllers:vcc direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];// bug fix for uipageview controller
                });
            }
        }];
    });
    return pv;//viewController;
}

-(BOOL)needSaveSettings:(SettingsEntity *)settings :(NSString*)pin
{
    SettingsInteractor* settIn = [[SettingsInteractor alloc] init];
    return [settIn saveSettings:settings :pin];
}

-(BOOL)needAddSetting
{
    SettingsEntity* sent =[[SettingsEntity alloc] init];
    SettingsViewController* viewControllerTmp = [[SettingsViewController alloc] initWithNibName:@"SettingsView" bundle:nil];
    viewControllerTmp.presenter = self;
    viewControllerTmp.settings = sent;
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
    // Ask to delete
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?",nil) message:NSLocalizedString(@"Settings will be permanently deleted",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"OK",nil), nil];
    alert.tag = 101;
    [alert show];
    return YES;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 101)
    {
        if (buttonIndex == 0)
        {
            
        }else{
            [[[GlobalRouter sharedManager] getSettingsRouter] doDeleteSetting:currentSettings];
        }
    }
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

-(void)showBusy:(int)value :(int)maxValue
{
    //[viewController showProgress:value max:maxValue];
    [CommonProcs showProgress:value max:maxValue inView:viewController.view];
}

-(NSArray*)getMailSettingsForAddress:(NSString*)address
{
    NSArray* ret = nil;
    
    MCOMailProvider *accountProvider = [MCOMailProvidersManager.sharedManager providerForEmail:address];
    if (accountProvider) {
        MCONetService* tmp = [accountProvider.imapServices firstObject];
        NSString* imap = tmp.hostname;
        
        MCONetService* tmp2 = [accountProvider.smtpServices firstObject];
        NSString* smtp = tmp2.hostname;
        NSString* port = [NSString stringWithFormat:@"%i", tmp2.port];
        
        ret = @[imap, smtp, port];
    }

    
    return ret;
}

@end
