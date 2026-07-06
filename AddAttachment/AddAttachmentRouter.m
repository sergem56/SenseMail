//
//  AddAttachmentRouter.m
//  SenseMail2
//
//  Created by Sergey on 20.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "AddAttachmentRouter.h"
#import "AddAttachmentPresenter.h"
#import "AddAttachmentViewController.h"
#import "GlobalRouter.h"

@implementation AddAttachmentRouter

-(id)init
{
    if (self = [super init]) {
        presenter = [[AddAttachmentPresenter alloc] init];
    }
    return self;
}

-(void)showViewInNavController:(UINavigationController*)navigationController
{
    nav = navigationController;
    
    AddAttachmentViewController* ret = [presenter showView];
    ret.caller = self.caller;
    
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
            [nav popToViewController:ret animated:YES];
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

-(void)finished
{
    [[GlobalRouter sharedManager] finishedWithCurrentView]; //getNavController] popViewControllerAnimated:YES];
}

@end
