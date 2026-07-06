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

@property (nonatomic, strong) NSString* email;
@property (nonatomic, strong) NSString* password;

-(void)showSettingsInNavController:(UINavigationController*)navigationController;
-(void)showSettingsInNavController:(UINavigationController*)navigationController addNew:(BOOL)addNew;
-(void)finished;

-(void)showBusy:(int)value :(int)maxValue;
-(void)addNewSetting;
-(void)saveSettings:(SettingsEntity*)settings;
-(BOOL)deleteSetting:(SettingsEntity*)settings;
-(BOOL)doDeleteSetting:(SettingsEntity*)settings;
-(void)clearMemory;
//-(void)saveSettings;

@end
