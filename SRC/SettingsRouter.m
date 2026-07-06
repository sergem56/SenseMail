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
    nav = navigationController;
    
    UIViewController* ret = [presenter showSettings :[GlobalRouter sharedManager].pin];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs hideProgress];
        @try {
            [nav pushViewController:ret animated:YES];
        }
        @catch (NSException *exception) {
            [nav popToViewController:ret animated:YES];
        }
    });
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100)
    {
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
    }
}

-(void)finished
{
    [[GlobalRouter sharedManager] finishedWithCurrentView]; //getNavController] popViewControllerAnimated:YES];
}

-(void)showBusy:(int)value :(int)maxValue
{
    [presenter showBusy:value :maxValue];
}

-(void)addNewSetting
{
    [presenter needAddSetting];
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

@end
