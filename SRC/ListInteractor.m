//
//  ListInteractor.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "ListInteractor.h"
#import "ShortMessageEntity.h"
#import "DataManager.h"
#import "GlobalRouter.h"
#import "CommonProcs.h"
#import "DataStorage.h"

@implementation ListInteractor

-(id)init
{
    if (self = [super init]) {
        //_dataManager = [[DataManager alloc] initWithInteractor:self];
    }
    return self;
}

-(NSArray*)getMessagesForBox:(int)boxType
{
    /*
    if (boxType == btEmpty) {
        [[[GlobalRouter sharedManager] getListRouter] listReceivedCallback:nil error:@""];
        return nil;
    }
    
    //DataManager* dataMan = [[DataManager alloc] init];
    [CommonProcs showProgress:1 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    [[GlobalRouter sharedManager]restartQ];
    
    //dispatch_queue_t getQueue = dispatch_queue_create("Network Queue",NULL);
    
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    dispatch_async([[GlobalRouter sharedManager] getQ], ^{
        
        DataManager* dataMan = [[DataManager alloc] init];
        NSString* error = @"";
        NSArray* ret = [dataMan getShortMessagesForBox:boxType];
        if(!ret)
        {
            error = NSLocalizedString(@"Error loading messages", nil);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(![[GlobalRouter sharedManager] isCancelled]){
                [[[GlobalRouter sharedManager] getListRouter] listReceivedCallback:ret error:error];
                [CommonProcs showProgress:10 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
            }else{
                [[GlobalRouter sharedManager] restartQ];
            }
        });
        
    });
    */
    return nil;
}

-(void)requestMessagesForBox:(boxTypes)boxType
{
    if (boxType == btEmpty) {
        [[[GlobalRouter sharedManager] getListRouter] listReceivedCallback:nil error:@""];
        return;
    }
    
    if (![[GlobalRouter sharedManager].currentFilter isEqualToString:@""]) {
        return [self requestMessagesForBoxWithFilter:boxType filter:[GlobalRouter sharedManager].currentFilter];
    }
    
    [[[GlobalRouter sharedManager] getListRouter] noNeedForMore:NO];
    [[[GlobalRouter sharedManager] getListRouter].dataStore resetMessages];
    [[GlobalRouter sharedManager] restartQ];
    
    //DataManager* dataMan = [[DataManager alloc] init];
    [[[GlobalRouter sharedManager] getListRouter].manager getShortMessagesForBox:boxType];
}

-(void)requestNextMessagesForBox:(boxTypes)boxType
{
    if (boxType == btEmpty) {
        [[[GlobalRouter sharedManager] getListRouter] listReceivedCallback:nil error:@""];
        return;
    }
    
    if (![[GlobalRouter sharedManager].currentFilter isEqualToString:@""]) {
        return [self requestMessagesForBoxWithFilter:boxType filter:[GlobalRouter sharedManager].currentFilter];
    }
    
    [[GlobalRouter sharedManager] restartQ];
    [[[GlobalRouter sharedManager] getListRouter].manager getNextShortMessagesForBox:boxType];

}

-(void)requestMessagesForBoxWithFilter:(boxTypes)boxType filter:(NSString*)filterFrom
{
    if ([filterFrom isEqualToString:@""]) {
        return [self requestMessagesForBox:boxType];
    }
    
    if (boxType == btEmpty) {
        //[[[GlobalRouter sharedManager] getListRouter] listReceivedCallback:nil error:@""];
        //return;
        [GlobalRouter sharedManager].currentBox = btInbox;
        boxType = btInbox;
    }
    [[[GlobalRouter sharedManager] getListRouter] noNeedForMore:NO];
    [[[GlobalRouter sharedManager] getListRouter].dataStore resetMessages];
    [[GlobalRouter sharedManager] restartQ];
    
    [[[GlobalRouter sharedManager] getListRouter].manager getShortMessagesForBoxWithFilter:boxType filter:filterFrom];
}

-(void)requestNextMessagesForBoxWithFilter:(boxTypes)boxType filter:(NSString*)filterFrom
{
    if ([filterFrom isEqualToString:@""]) {
        return [self requestMessagesForBox:boxType];
    }
    
    if (boxType == btEmpty) {
        [[[GlobalRouter sharedManager] getListRouter] listReceivedCallback:nil error:@""];
        return;
    }
    [[GlobalRouter sharedManager] restartQ];
    
    [[[GlobalRouter sharedManager] getListRouter].manager getShortMessagesForBoxWithFilter:boxType filter:filterFrom];
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
    //[CommonProcs hideProgress];
    if(![[GlobalRouter sharedManager] isCancelled]){
        [[[GlobalRouter sharedManager] getListRouter] listReceivedCallback:data error:error];
    }
}

-(void)needDeleteMessage:(ShortMessageEntity*)message
{
    [[[GlobalRouter sharedManager] getListRouter].manager deleteMessage:message];
}

-(void)needStarForMessage:(ShortMessageEntity *)message
{
    [[[GlobalRouter sharedManager] getListRouter].manager toggleStarForMessage:message];
}


@end
