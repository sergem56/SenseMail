//
//  SettingsPresenter.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class SettingsViewController;
@class SettingsEntity;
@class SettingsPager;

@interface SettingsPresenter : NSObject{
    SettingsViewController* viewController;
    SettingsViewController* viewController2;
    SettingsPager* pv;
    SettingsEntity* currentSettings;
}

-(UIViewController*)showSettings:(NSString*)pin;
-(BOOL)needSaveSettings:(SettingsEntity*)settings :(NSString*)pin;
-(BOOL)needAddSetting;
-(BOOL)needDeleteSetting:(SettingsEntity*)settings;
-(void)settingsDeleted;

-(BOOL)needResetKey;
-(BOOL)needUpdateKey:(NSString*)key;
-(BOOL)needSetupPin;

-(void)showBusy:(int)value :(int)maxValue;

-(NSArray*)getMailSettingsForAddress:(NSString*)address;

@end
