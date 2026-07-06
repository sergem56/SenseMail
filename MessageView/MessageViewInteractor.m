//
//  MessageViewInteractor.m
//  SenseMail2
//
//  Created by Sergey on 30.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "MessageViewInteractor.h"
#import <UIKit/UIKit.h>
#import "DataManager.h"
#import "CommonProcs.h"
#import "GlobalRouter.h"
#import "AddressBookEntity.h"
#import "UserInfoDataManager.h"

@implementation MessageViewInteractor

-(void)markMessageAsRead:(ShortMessageEntity*)item
{
    item.flags &= ~mfNew;
}

-(FullMessageEntity*)getFullMessageFor:(ShortMessageEntity*)item PIN:(NSString *)pin
{
    //DataManager* dataMan = [[DataManager alloc] init];
    //return [dataMan getFullMessageFor:item PIN:pin];
    
    [[GlobalRouter sharedManager]restartQ];
    [CommonProcs showProgress:1 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    dispatch_async([[GlobalRouter sharedManager] getQ], ^{
        
        DataManager* dataMan = [[DataManager alloc] init];
        NSString* error = @"";
        FullMessageEntity* ret = [dataMan getFullMessageFor:item PIN:pin forBox:[GlobalRouter sharedManager].currentBox];
        if(!ret)
        {
            error = NSLocalizedString(@"Error loading message", nil);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(![[GlobalRouter sharedManager] isCancelled]){
                [[[GlobalRouter sharedManager] getMessageRouter] messageReceivedCallback:ret error:error];
                //[CommonProcs showProgress:10 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
                [CommonProcs hideProgress];
            }else{
                [[GlobalRouter sharedManager]restartQ];
                [[GlobalRouter sharedManager]finishedWithCurrentView];
            }
        });
        
    });
    
    return nil;

}

-(void)requestFullMessageFor:(ShortMessageEntity*)item PIN:(NSString*)pin
{
    //DataManager* dataMan = [[DataManager alloc] init];
    
    [[GlobalRouter sharedManager] restartQ];
    [[[GlobalRouter sharedManager] getMessageRouter].manager getFullMessageFor:item PIN:pin forBox:[GlobalRouter sharedManager].currentBox];
}

-(BOOL)saveAllAttachments:(FullMessageEntity *)item
{
    for (NSObject* im in item.attachments) {
        UIImageWriteToSavedPhotosAlbum([CommonProcs getFullImage:im], nil,nil,nil);
    }
    
    return YES;
}

// AsyncLoader protocol
-(void)setProgress:(int)progress max:(int)max
{
    //[CommonProcs showProgress:progress max:max inView:[[GlobalRouter sharedManager] getCurrentView]];
    [CommonProcs setProgress:progress max:max title:NSLocalizedString(@"Loading...", nil)];
}

-(void)dataReady:(NSArray *)data error:(NSString *)error
{
    //[CommonProcs showProgress:10 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    [CommonProcs hideProgress];
    if(![[GlobalRouter sharedManager] isCancelled]){
        [[[GlobalRouter sharedManager] getMessageRouter] messageReceivedCallback:[data objectAtIndex:0] error:error];
    }else{
        [[GlobalRouter sharedManager] finishedWithCurrentView];
    }
}

-(void)addContactFor:(NSString *)name address:(NSString *)address
{
    UserInfoDataManager* userMan = [[UserInfoDataManager alloc] init];
    AddressBookEntity* item = [userMan findInAddressBook:name address:address pin:[GlobalRouter sharedManager].pin];
    if (item == nil) {
        item = [[AddressBookEntity alloc] init];
        item.name = name;
        item.address = address;
    }
    [[[GlobalRouter sharedManager] getBookRouter] showAddItem:item];
}

@end
