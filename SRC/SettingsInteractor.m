//
//  SettingsInteractor.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "SettingsInteractor.h"
#import "SettingsEntity.h"
#import "UserInfoDataManager.h"
#import "GlobalRouter.h"
#import "CommonProcs.h"

@implementation SettingsInteractor

-(NSArray*)getSettings:(NSString*)pin
{
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    
    //[dataMan saveKeyForAddress:@"ebox1357@gmail.com" yourPin:@"22" otherPin:@"222" key:[@"fucking long password - 12&^KJ09*!bde)=+" dataUsingEncoding:NSUTF8StringEncoding]];
    
    return [dataMan getSettings:pin];
}

-(BOOL)saveSettings:(SettingsEntity *)settings :(NSString*)pin
{
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    
    return [dataMan saveSettings:settings :pin];
}

-(BOOL)deleteSetting:(SettingsEntity *)settings
{
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    return [dataMan deleteSetting:settings];
}

-(BOOL)resetKey
{
    NSLog(@"Key reset");
    return YES;
}

-(BOOL)updateKey:(NSString*)key
{
    NSLog(@"Key updated");
    return YES;
}

-(BOOL)setupPin
{
    // Here we need to:
    // 1. Re-encrypt settings
    // 2. Re-encrypt address book
    // 3. Re-encrypt secure gallery
    // 4. Re-encrypt notes
    
    [[[GlobalRouter sharedManager] getSettingsRouter] showBusy:0 :10];
    [[GlobalRouter sharedManager]restartQ];
    
    //dispatch_queue_t pinQueue = dispatch_queue_create("PinChange Queue",NULL);
    
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    dispatch_async([[GlobalRouter sharedManager] getQ], ^{
        
        UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
        
        NSArray* allSettings = [dataMan getSettings:[GlobalRouter sharedManager].oldPin];
        //SettingsEntity* sett = [[dataMan getSettings:[GlobalRouter sharedManager].oldPin] firstObject];
        for (SettingsEntity* sett in allSettings) {
            [dataMan saveSettings:sett :[GlobalRouter sharedManager].pin];
        }
        
        // Address book
        NSArray* book = [dataMan getAddressBook:[GlobalRouter sharedManager].oldPin groupsOnly:NO];
        [dataMan saveAddressBook:book pin:[GlobalRouter sharedManager].pin];
        
        // Gallery
        [dataMan saveGalleryWithNewPin:[GlobalRouter sharedManager].pin oldPin:[GlobalRouter sharedManager].oldPin];
        
        // Notes
        [dataMan saveNotesWithNewPin:[GlobalRouter sharedManager].pin oldPin:[GlobalRouter sharedManager].oldPin];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(![[GlobalRouter sharedManager] isCancelled]){
                //[[[GlobalRouter sharedManager] getSettingsRouter] showBusy:10 :10];
                [CommonProcs hideProgress];
            }else{
                [[GlobalRouter sharedManager]restartQ];
            }
        });
        
    });
    
    return YES;
}

@end
