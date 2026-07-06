//
//  NotesRouter.m
//  SenseMail2
//
//  Created by Sergey on 08.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "NotesRouter.h"
#import "NotesPresenter.h"
#import "NotesViewController.h"
#import "CommonProcs.h"
#import "GlobalRouter.h"

@implementation NotesRouter

-(id)init
{
    if (self = [super init]) {
        presenter = [[NotesPresenter alloc] init];
    }
    return self;
}

-(void)showNotesInNavController:(UINavigationController *)navigationController
{
    nav = navigationController;
    
    NotesViewController* ret = [presenter showNotes:[GlobalRouter sharedManager].pin];
    __weak __typeof__(self) weakSelf = self;
    @try {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof__(self) strongSelf = weakSelf;
            [CommonProcs hideProgress];
            [strongSelf->nav pushViewController:ret animated:YES];
        });
    }
    @catch (NSException *exception) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof__(self) strongSelf = weakSelf;
            [CommonProcs hideProgress];
            [strongSelf->nav popToViewController:ret animated:YES];
        });
    }
}

-(void)showAddItem:(NoteEntity*)item
{
    UIViewController* ret = (UIViewController*)[presenter showAddItem:item];
    
    if (nav == nil) {
        nav = [[GlobalRouter sharedManager] getDetailNavController];
    }
    __weak __typeof__(self) weakSelf = self;
    @try{
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof__(self) strongSelf = weakSelf;
            [CommonProcs hideProgress];
            [strongSelf->nav pushViewController:ret animated:YES];
        });
    }
    @catch (NSException *exception) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof__(self) strongSelf = weakSelf;
            [CommonProcs hideProgress];
            [strongSelf->nav popToViewController:ret animated:YES];
        });
    }
    @finally {
    }
    
}

-(void)finished
{
    
    if (presenter.needUpdateList){
        [presenter updateList];
        presenter.needUpdateList = NO;
    }
    
    [[GlobalRouter sharedManager] finishedWithDetailView:YES];// getNavController] popViewControllerAnimated:YES];
    [presenter clearVC];
}

-(void)appWillGoToBG
{
    [presenter saveCurrentItem];
}

@end
