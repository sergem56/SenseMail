//
//  SettingsRouter.h
//  SenseMail2
//
//  Created by Sergey on 02.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class GlobalRouter;
@class SettingsPresenter;
@class SettingsEntity;

@interface SettingsRouter : NSObject{
    SettingsPresenter* presenter;
    UINavigationController* nav;
}

-(void)showSettingsInNavController:(UINavigationController*)navigationController;
-(void)finished;

-(void)showBusy:(int)value :(int)maxValue;
-(void)addNewSetting;
-(BOOL)deleteSetting:(SettingsEntity*)settings;
-(BOOL)doDeleteSetting:(SettingsEntity*)settings;

@end
