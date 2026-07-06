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

@interface UpdatingWatch : NSObject
{
    NSMutableDictionary* updating;
}

-(void)addUpdating:(NSString*)sessionName;
-(void)removeUpdating:(NSString*)sessionName;
-(BOOL)isUpdating;
-(void)reset;

@end

@implementation UpdatingWatch

-(void)addUpdating:(NSString*)sessionName
{
    if (!sessionName) {
        return;
    }
    if (!updating) {
        updating = [[NSMutableDictionary alloc] init];
    }
    [updating setValue:@"YES" forKey:sessionName];
}

-(void)removeUpdating:(NSString *)sessionName
{
    if(sessionName && updating){
        [updating removeObjectForKey:sessionName];
    }
}

-(BOOL)isUpdating
{
    return updating.count > 0;
}

-(void)reset
{
    updating = nil;
}

@end

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
    [GlobalRouter sharedManager].totalMessages = 0;
    
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
    
    [GlobalRouter sharedManager].loadedMessages = 0;
    [GlobalRouter sharedManager].newMessages = 0;
    
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
    BOOL act = [[[GlobalRouter sharedManager] getListRouter] isActive];
    if(!act)return;
    if(![[GlobalRouter sharedManager] isCancelled] && ![GlobalRouter sharedManager].goingToBG){
        [[[GlobalRouter sharedManager] getListRouter] listReceivedCallback:data error:error];
    }
}

-(void)needDeleteMessage:(ShortMessageEntity*)message
{
    [[[GlobalRouter sharedManager] getListRouter].manager deleteMessage:message];
}

-(void)needDeleteMessages:(NSArray*)messages
{
    [[[GlobalRouter sharedManager] getListRouter].manager deleteMessages:messages];
}

-(void)needDeleteAllMessagesFromFolder
{
    [[[GlobalRouter sharedManager] getListRouter].manager deleteAllMessagesFromFolder:[GlobalRouter sharedManager].currentBoxPath];
}

-(void)needSetUnreadForMessages:(NSArray*)messages
{
    [[[GlobalRouter sharedManager] getListRouter].manager setFlagForMessages:messages flag:!MCOMessageFlagSeen];
}

-(void)needSetReadForMessages:(NSArray*)messages
{
    [[[GlobalRouter sharedManager] getListRouter].manager setFlagForMessages:messages flag:MCOMessageFlagSeen];
}

-(void)needSetStarForMessages:(NSArray*)messages
{
    [[[GlobalRouter sharedManager] getListRouter].manager setFlagForMessages:messages flag:MCOMessageFlagFlagged];
}

-(void)needCopyMessages:(NSArray*)messages
{
    selectedMessages = messages;
    copyOnly = YES;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SelectStoryboard" bundle: nil];
    SelectFolderViewController* sFolder = [storyboard instantiateViewControllerWithIdentifier:@"FolderSelect"];
    if(((ShortMessageEntity*)(messages[0])).toAddress != nil){
        sFolder.accountName = [[GlobalRouter sharedManager].accountsNames valueForKey:((ShortMessageEntity*)(messages[0])).toAddress];
        sFolder.parent = self;
        sFolder.items = [[[GlobalRouter sharedManager].otherFolders objectForKey:sFolder.accountName] allKeys];
        [[[GlobalRouter sharedManager] getDetailNavController] pushViewController:sFolder animated:YES];
    }
}

-(void)needMoveMessages:(NSArray*)messages
{
    selectedMessages = messages;
    copyOnly = NO;
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SelectStoryboard" bundle: nil];
    SelectFolderViewController* sFolder = [storyboard instantiateViewControllerWithIdentifier:@"FolderSelect"];
    if(((ShortMessageEntity*)(messages[0])).toAddress != nil){
        sFolder.accountName = [[GlobalRouter sharedManager].accountsNames valueForKey:((ShortMessageEntity*)(messages[0])).toAddress];
        sFolder.parent = self;
        sFolder.items = [[[GlobalRouter sharedManager].otherFolders objectForKey:sFolder.accountName] allKeys];
        [[[GlobalRouter sharedManager] getDetailNavController] pushViewController:sFolder animated:YES];
    }
}

-(void)itemSelected:(NSString*)itemPath title:(NSString*)title
{
    if(copyOnly){
        [[[GlobalRouter sharedManager] getListRouter].manager copyMessages:selectedMessages to:itemPath];
    }else{
        [[[GlobalRouter sharedManager] getListRouter].manager moveMessages:selectedMessages to:itemPath];
        
    }
}

-(void)needStarForMessage:(ShortMessageEntity *)message
{
    [[[GlobalRouter sharedManager] getListRouter].manager toggleStarForMessage:message];
}

/*
-(void)itemSelected:(NSString*)itemPath title:(NSString*)title
{
    if(isMoving){
        [[[GlobalRouter sharedManager] getMessageRouter] wantMoveMessage:currentMessage to:itemPath];
    }else{
        [[[GlobalRouter sharedManager] getMessageRouter] wantCopyMessage:currentMessage to:itemPath];
    }
}

-(void)askWhereToPutItems:(NSArray*)items
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SelectStoryboard" bundle: nil];
    SelectFolderViewController* sFolder = [storyboard instantiateViewControllerWithIdentifier:@"FolderSelect"];
    if(items[0].toAddress != nil){
        sFolder.accountName = [[GlobalRouter sharedManager].accountsNames valueForKey:item.toAddress];
        sFolder.parent = self;
        sFolder.items = [[[GlobalRouter sharedManager].otherFolders objectForKey:sFolder.accountName] allKeys];
        [[[GlobalRouter sharedManager] getDetailNavController] pushViewController:sFolder animated:YES];
    }
}
*/

@end
