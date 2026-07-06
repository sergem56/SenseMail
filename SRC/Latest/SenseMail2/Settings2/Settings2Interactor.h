//
//  Settings2Interactor.h
//  SenseMailShare
//
//  Created by Sergey on 06.12.2019.
//  Copyright © 2019 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@class Settings2TableViewController;
@class SettingsEntity;
@class ShortcutEntity;

@interface Settings2Interactor : NSObject
{
    Settings2TableViewController* vc;
    UINavigationController* nav;
}

@property (nonatomic, assign) BOOL reloadMessagesOnExit;

-(void)showSettingsInNavController:(UINavigationController*)navigationController addNew:(BOOL)addNew;
-(NSArray*)getSettings;

-(void)closeSettings;
-(BOOL)saveSettings:(SettingsEntity*)settings :(NSMutableString*)pin;
-(BOOL)saveShortcuts:(NSArray*)items pin:(NSMutableString*)pin;
-(BOOL)deleteShortcut:(ShortcutEntity*)item;
-(void)wantChangePin;
-(BOOL)setupPin;
+(NSArray*)getMailSettingsForAddress:(NSString*)address;

-(void)needAddSettings;
-(void)needAddSettingsWithEmail:(NSString*)email password:(NSString*)password;
-(void)addToTheList:(SettingsEntity*)sett;
-(void)deleteSetting:(SettingsEntity*)sett;
-(void)wantSOS;

@end

NS_ASSUME_NONNULL_END
