//
//  AddressBookRouter.m
//  SenseMail2
//
//  Created by Sergey on 09.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "AddressBookRouter.h"
#import "AddressBookPresenter.h"
#import "GlobalRouter.h"
#import "AddressBookViewController.h"
#import "AddViewController.h"
#import "CommonProcs.h"

@implementation AddressBookRouter

@synthesize caller;

-(id)init
{
    if (self = [super init]) {
        presenter = [[AddressBookPresenter alloc] init];
    }
    return self;
}

-(void)showBookInNavController:(UINavigationController *)navigationController
{
    nav = navigationController;
    
    AddressBookViewController* ret = [presenter showBook:[GlobalRouter sharedManager].pin];
    ret.caller = self.caller;
    [ret enableButtons];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs hideProgress];
        @try {
            [nav pushViewController:ret animated:YES];
        }
        @catch (NSException *exception) {
            AddressBookPresenter* newPresenter = [[AddressBookPresenter alloc] init];
            AddressBookViewController* ret2 = [newPresenter showBook:[GlobalRouter sharedManager].pin];
            ret2.caller = self.caller;
            [ret2 enableButtons];
            
            [nav pushViewController:ret2 animated:YES];
        }
        
    });
}

-(void)showGroupBook:(AddressBookViewController*)vc toGroup:(id<CanGetAddressFromBook>)callerGroup
{
    if (callerGroup == nil) {
        vc.caller = self.caller;
    }else{
        vc.caller = callerGroup;
    }
    [vc enableButtons];
    
    @try {
        [nav pushViewController:vc animated:YES];
    }
    @catch (NSException *exception) {
        [nav popToViewController:vc animated:YES];
    }
    @finally {
    }
}

-(void)showAddItem:(AddressBookEntity*)item
{
    UIViewController* ret = [presenter showAddItem:item];
    
    if (nav == nil) {
        nav = [[GlobalRouter sharedManager] getNavController];
    }
    
    @try{
        [nav pushViewController:ret animated:YES];
    }
    @catch (NSException *exception) {
        [nav popToViewController:ret animated:YES];
    }
    @finally {
    }

}

-(void)finished
{
    [[GlobalRouter sharedManager] finishedWithCurrentView];// getNavController] popViewControllerAnimated:YES];
}

@end
