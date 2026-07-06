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
    
    for (UIViewController* vc in nav.viewControllers) {
        if ([vc isKindOfClass:[AddressBookViewController class]]) {
            __weak __typeof__(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong __typeof__(self) strongSelf = weakSelf;
                [CommonProcs hideProgress];
                [strongSelf->nav popToViewController:vc animated:YES];
            });
            return;
        }
    }
    
    AddressBookViewController* ret = [presenter showBook:[GlobalRouter sharedManager].pin];
    ret.caller = self.caller;
    ret.presenter = presenter;
    [ret enableButtons];
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [CommonProcs hideProgress];
        @try {
            [strongSelf->nav pushViewController:ret animated:YES];
        }
        @catch (NSException *exception) {
            AddressBookPresenter* newPresenter = [[AddressBookPresenter alloc] init];
            AddressBookViewController* ret2 = [newPresenter showBook:[GlobalRouter sharedManager].pin];
            ret2.caller = self.caller;
            ret2.presenter = strongSelf->presenter;
            [ret2 enableButtons];
            
            [strongSelf->nav pushViewController:ret2 animated:YES];
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
    vc.presenter = presenter;
    
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
        nav = [[GlobalRouter sharedManager] getDetailNavController];
    }
    
    @try{
        if(![nav.viewControllers containsObject:ret])
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
    [[GlobalRouter sharedManager] finishedWithDetailView:YES];// getNavController] popViewControllerAnimated:YES];
}

@end
