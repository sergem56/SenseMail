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
    [self showAttachmentInNavController:navigationController :att secure:NO];
}

-(void)showAttachmentInNavController:(UINavigationController*)navigationController :(UIImage*)att secure:(BOOL)secure
{
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [CommonProcs hideProgress];
        
        strongSelf->nav = navigationController;
        
        AttachmentViewController* ret = [strongSelf->presenter showAttachment:att];
        ret.attachment = att;
        ret.isSecure = secure;
        
        [ret initImage];
        
        BOOL onStack = NO;
        
        for (UIViewController* item in strongSelf->nav.viewControllers) {
            if ([ret isEqual:item]) {
                onStack = YES;
                break;
            }
        }
        
        if (onStack) {
            [strongSelf->nav popToViewController:ret animated:YES];
        }else{
            
            @try {
                [strongSelf->nav pushViewController:ret animated:YES];
            }
            @catch (NSException *exception) {
                [strongSelf->nav popToViewController:ret animated:YES];
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
    [presenter reset];
    [[GlobalRouter sharedManager] finishedWithDetailView:YES];// getNavController] popViewControllerAnimated:YES];
}

@end
