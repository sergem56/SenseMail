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
#import "WindowMinimizer.h"
#import "Encryptor.h"

@implementation ComposeMessageRouter

@synthesize currentMessage;//, dataStore, manager;

-(id)init
{
    if (self = [super init]) {
        presenter = [[ComposeMessagePresenter alloc] init];
        //self.manager = [[DataManager alloc] init];
        //self.dataStore = [[DataStorage alloc] init];
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
    ComposeMessageViewController* ret = [presenter showMessage: currentMessage];
    if (ret.minimizer != nil && [ret checkRestore:[Encryptor getSlowHashForString:[GlobalRouter sharedManager].pin]] && [ret.minimizer showIfExistsMinimized] ) {
        return;
    }
    currentMessage = message; // copy message or close everything after reply or forward
    ret.message = currentMessage;
    __block BOOL cancelled = NO;
    if (currentMessage.messageBody) {
        [CommonProcs showWheelinView:navController.view message:NSLocalizedString(@"Loading...", nil) stopButtonVisible:YES withBlock:^{
            [CommonProcs hideProgressAlways];
            cancelled = YES;
            return;
        }];
    }
    [ret setupMessage:includeAttachments forward:forward];
    if (currentMessage.messageBody) {
        [CommonProcs hideProgressAlways];
    }
    
    if (cancelled) {
        return;
    }
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

-(void)finished
{
    [[GlobalRouter sharedManager] finishedWithDetailView:YES];
    // Delete attachments
    [DataManager deleteTempFilesFromMessage:self.currentMessage];
    self.currentMessage = nil;
}

-(void)minimizeComposer
{
    [presenter minimizeComposerAnimated:NO];
}

-(BOOL)isMinimized
{
    return [presenter isMinimized];
}

-(ComposeMessagePresenter*)getPresenter
{
    return presenter;
}

@end
