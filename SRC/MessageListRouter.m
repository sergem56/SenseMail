//
//  MessageListRouter.m
//  SenseMail2
//
//  Created by Sergey on 23.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "MessageListRouter.h"
#import "ListPresenter.h"
#import "MessageListViewController.h"
#import "ListInteractor.h"
#import "DataManager.h"
#import "DataStorage.h"
#import "ModalDialogViewController.h"
#import "GlobalRouter.h"

@implementation MessageListRouter

@synthesize manager, interactor, dataStore;

-(id)init
{
    if (self = [super init]) {
        self.presenter = [[ListPresenter alloc] init];
        self.interactor = [[ListInteractor alloc] init];
        self.manager = [[DataManager alloc] init];
        self.dataStore = [[DataStorage alloc] init];
    }
    return self;
}

-(void)noNeedForMore :(BOOL)value
{
    self.presenter.noNeedForMore = value;
}

-(void)showListInNavController:(UINavigationController*)navController forBox:(boxTypes)boxType
{
    nav = navController;
        
    MessageListViewController* ret = [self.presenter showListOfType:boxType];
    BOOL onStack = NO;
    //NSLog(@"Controllers = %i", nav.viewControllers.count);
    
    for (UIViewController* item in nav.viewControllers) {
        if ([ret isEqual:item]) {
            onStack = YES;
            break;
        }
    }
    
    if (onStack) {
        [nav popToViewController:ret animated:YES];
    }else{
    
        @try {
            [nav pushViewController:ret animated:YES];
        }
        @catch (NSException *exception) {
            [nav popToViewController:ret animated:YES];
        }
    }
}

-(void)listReceivedCallback:(NSArray*) list error:(NSString*)error
{
    [self.presenter setList:list error:error];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [UIApplication sharedApplication].applicationIconBadgeNumber = [[GlobalRouter sharedManager] getNewMessagesCount];
    });
}

-(void)needUpdateList
{
    [self.presenter updateList];
}

-(void)clearList
{
    [self.presenter clearList];
}

-(void)updateItemsFlags:(ShortMessageEntity*)item
{
    [self.presenter updateItemsFlags:item];
}

-(void)removeItemFromList:(ShortMessageEntity*)item
{
    [self.presenter deleteItemFromList:item];
}

@end
