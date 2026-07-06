//
//  CertExchangeRouter.m
//  SenseMailShare
//
//  Created by Sergey on 06.04.16.
//  Copyright © 2016 Sergey. All rights reserved.
//

#import "CertExchangeRouter.h"
#import "CertExchangeViewController.h"
#import "CertExchangePresenter.h"
#import "AddressBookEntity.h"

@implementation CertExchangeRouter

-(id)init
{
    if (self = [super init]) {
        self.presenter = [[CertExchangePresenter alloc] init];
    }
    return self;
}


-(void)showViewInNavController:(UINavigationController*)navController forAddress:(AddressBookEntity*)addr
{
    nav = navController;
    
    CertExchangeViewController* ret = [self.presenter getCertView:addr];
    
    
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
}

@end
