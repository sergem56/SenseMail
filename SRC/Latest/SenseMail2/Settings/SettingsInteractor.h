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

-(NSArray*)getSettings :(NSMutableString*)pin;
-(BOOL)saveSettings:(SettingsEntity*)settings :(NSMutableString*)pin;
-(BOOL)deleteSetting:(SettingsEntity*)settings;

-(BOOL)updateKey:(NSString*)key;
-(BOOL)resetKey;

-(BOOL)setupPin;

@end
