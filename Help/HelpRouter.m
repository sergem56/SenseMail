//
//  HelpRouter.m
//  SenseMail2
//
//  Created by Sergey on 04.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "HelpRouter.h"
#import "HelpViewController.h"
#import "GlobalRouter.h"

@implementation HelpRouter

@synthesize viewController;

-(id)init
{
    if (self = [super init]) {
        viewController = [[HelpViewController alloc] init];
    }
    return self;
}

-(void)showHelpInNavController:(UINavigationController*)navigationController
{
    nav = navigationController;
    viewController.helpFile = NSLocalizedString(@"helpFile",nil);
    [viewController updateFile];
    
    @try {
        [nav pushViewController:viewController animated:YES];
    }
    @catch (NSException *exception) {
        [nav popToViewController:viewController animated:YES];
    }
    @finally {
    }
}

-(void)showHelpInNavController:(UINavigationController*)navigationController file:(NSString*)file
{
    nav = navigationController;
    viewController.helpFile = file;//NSLocalizedString(@"helpFile",nil);
    [viewController updateFile];
    
    @try {
        [nav pushViewController:viewController animated:YES];
    }
    @catch (NSException *exception) {
        [nav popToViewController:viewController animated:YES];
    }
    @finally {
    }
}

-(void)finished
{
    [[[GlobalRouter sharedManager] getNavController] popViewControllerAnimated:YES];
}

@end
