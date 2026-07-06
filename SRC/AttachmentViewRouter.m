//
//  AttachmentViewRouter.m
//  SenseMail2
//
//  Created by Sergey on 03.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "AttachmentViewRouter.h"
#import "AttachmentViewPresenter.h"
#import "GlobalRouter.h"
#import "AttachmentViewController.h"
#import "CommonProcs.h"

@implementation AttachmentViewRouter

-(id)init
{
    if (self = [super init]) {
        presenter = [[AttachmentViewPresenter alloc] init];
    }
    return self;
}

-(void)showAttachmentInNavController:(UINavigationController*)navigationController :(UIImage*)att
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs hideProgress];
        
        nav = navigationController;
        
        AttachmentViewController* ret = [presenter showAttachment:att];
        ret.attachment = att;
        [ret initImage];
        
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
            //dispatch_async(dispatch_get_main_queue(), ^{
                [nav pushViewController:ret animated:YES];
            //});
        }
        @catch (NSException *exception) {
            //dispatch_async(dispatch_get_main_queue(), ^{
                [nav popToViewController:ret animated:YES];
            //});
        }
        @finally {
        }
         */
    });
}

-(void)finished
{
    [[GlobalRouter sharedManager] finishedWithCurrentView];// getNavController] popViewControllerAnimated:YES];
}

@end
