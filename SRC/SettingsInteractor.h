//
//  SettingsInteractor.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SettingsEntity;

@interface SettingsInteractor : NSObject

-(NSArray*)getSettings :(NSString*)pin;
-(BOOL)saveSettings:(SettingsEntity*)settings :(NSString*)pin;
-(BOOL)deleteSetting:(SettingsEntity*)settings;

-(BOOL)updateKey:(NSString*)key;
-(BOOL)resetKey;

-(BOOL)setupPin;

@end
