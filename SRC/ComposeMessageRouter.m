//
//  ComposeMessageRouter.m
//  SenseMail2
//
//  Created by Sergey on 15.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "ComposeMessageRouter.h"
#import "ComposeMessagePresenter.h"
#import "ComposeMessageViewController.h"
#import "GlobalRouter.h"
#import "FullMessageEntity.h"
#import "DataManager.h"
#import "DataStorage.h"

@implementation ComposeMessageRouter

@synthesize currentMessage, dataStore, manager;

-(id)init
{
    if (self = [super init]) {
        presenter = [[ComposeMessagePresenter alloc] init];
        self.manager = [[DataManager alloc] init];
        self.dataStore = [[DataStorage alloc] init];
    }
    return self;
}

-(void)showCertComposerInNavController:(UINavigationController*)navController message:(FullMessageEntity*)message
{
    nav = navController;
    if (message == nil) {
        message = [[FullMessageEntity alloc] init];
    }
    currentMessage = message; // copy message or close everything after reply or forward
    currentMessage.encType = enTypePasswordForCert;
    
    ComposeMessageViewController* ret = [presenter showMessage: currentMessage];
    ret.message = currentMessage;
    [ret setupMessage:NO forward:NO];
    
    BOOL onStack = NO;
    
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
        }
    }
    
    /*
    @try {
        [nav pushViewController:ret animated:YES];
    }
    @catch (NSException *exception) {
        [nav popToViewController:ret animated:YES];
    }
    @finally {
    }
     */
}


-(void)showComposerInNavController:(UINavigationController*)navController message:(FullMessageEntity*)message includeAttachments:(BOOL)includeAttachments forward:(BOOL)forward
{
    nav = navController;
    if (message == nil) {
        message = [[FullMessageEntity alloc] init];
    }
    currentMessage = message; // copy message or close everything after reply or forward
    
    ComposeMessageViewController* ret = [presenter showMessage: currentMessage];
    ret.message = currentMessage;
    [ret setupMessage:includeAttachments forward:forward];
    
    BOOL onStack = NO;
    
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
        }
    }
    
    /*
    @try {
        [nav pushViewController:ret animated:YES];
    }
    @catch (NSException *exception) {
        [nav popToViewController:ret animated:YES];
    }
    @finally {
    }
     */
}

-(void)needAddressBook
{
    [[GlobalRouter sharedManager] needShowAddressBookWithCaller:presenter];
}

-(void)needAttachment
{
    [[GlobalRouter sharedManager] needAddAttachmentWithCaller:presenter];
}

-(void)sendingResult:(NSString*)result
{
    [presenter sendingResult:result];
}

@end
