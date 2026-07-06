//
//  SettingsRouter.m
//  SenseMail2
//
//  Created by Sergey on 02.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "SettingsRouter.h"
#import "SettingsPresenter.h"
#import "SettingsViewController.h"
#import "GlobalRouter.h"
#import "CommonProcs.h"
#import "SettingsInteractor.h"
#import "SettingsPager.h"

@implementation SettingsRouter

-(id)init
{
    if (self = [super init]) {
        presenter = [[SettingsPresenter alloc] init];
    }
    return self;
}

-(void)showSettingsInNavController:(UINavigationController*)navigationController
{
    [self showSettingsInNavController:navigationController addNew:NO];
}

-(void)showSettingsInNavController:(UINavigationController*)navigationController addNew:(BOOL)addNew
{
    nav = navigationController;
    
    /*UIViewController*/SettingsPager* ret = (SettingsPager*)[presenter showSettings :[GlobalRouter sharedManager].pin];
    ret.needAddAccount = addNew;
    
    BOOL onStack = NO;
    
    for (UIViewController* item in nav.viewControllers) {
        if ([ret isEqual:item]) {
            onStack = YES;
            break;
        }
    }
    
    if (onStack) {
        [nav popToViewController:ret animated:YES];
    }else{
        
        @try {
            [nav pushViewController:ret animated:YES];
        }
        @catch (NSException *exception) {
        }
    }
    
    /*
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs hideProgress];
        @try {
            [nav pushViewController:ret animated:YES];
        }
        @catch (NSException *exception) {
            [nav popToViewController:ret animated:YES];
        }
    });
     
     */
    
    if (![self.email isEqualToString:@""]) {
        ret.email = self.email;
        self.email = @"";
    }
    if (![self.password isEqualToString:@""]) {
        ret.password = self.password;
        self.password = @"";
    }
}

/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100)
    {*/
        /*
        if (buttonIndex == 0)
        {
            [self finished];
        }else{
            NSString* pin = [[alertView textFieldAtIndex:0] text];
            UIViewController* ret = [presenter showSettings :pin];
            
            @try {
                [nav pushViewController:ret animated:YES];
            }
            @catch (NSException *exception) {
                [nav popToViewController:ret animated:YES];
            }
            @finally {
            }

        }
         */
//    }
//}

-(void)finished
{
    [[GlobalRouter sharedManager] finishedWithDetailView:YES]; //finishedWithCurrentView];
}

-(void)showBusy:(int)value :(int)maxValue
{
    [presenter showBusy:value :maxValue];
}

-(void)addNewSetting
{
    [presenter needAddSetting];
}

-(void)saveSettings:(SettingsEntity*)settings
{
    SettingsInteractor* settIn = [[SettingsInteractor alloc] init];
    [settIn saveSettings:settings :[GlobalRouter sharedManager].pin];
}

-(BOOL)deleteSetting:(id)settings
{
    [presenter needDeleteSetting:settings];
    
    return YES;
}

-(BOOL)doDeleteSetting:(SettingsEntity*)settings
{
    SettingsInteractor* settIn = [[SettingsInteractor alloc] init];
    BOOL ret = [settIn deleteSetting:settings];
    [presenter settingsDeleted];
    
    return ret;
}

-(void)clearMemory
{
    [presenter cleanUp];
}

@end
