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
        
    @try {
        dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs hideProgress];
            [nav pushViewController:ret animated:YES];
        });
    }
    @catch (NSException *exception) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs hideProgress];
            [nav popToViewController:ret animated:YES];
        });
    }
}

-(void)showAddItem:(NoteEntity*)item
{
    UIViewController* ret = (UIViewController*)[presenter showAddItem:item];
    
    if (nav == nil) {
        nav = [[GlobalRouter sharedManager] getNavController];
    }
    
    @try{
        dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs hideProgress];
            [nav pushViewController:ret animated:YES];
        });
    }
    @catch (NSException *exception) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs hideProgress];
            [nav popToViewController:ret animated:YES];
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
    
    [[GlobalRouter sharedManager] finishedWithCurrentView];// getNavController] popViewControllerAnimated:YES];
}

@end
