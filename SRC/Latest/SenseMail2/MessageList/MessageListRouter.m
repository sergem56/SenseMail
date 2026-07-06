//
//  MessageListRouter.m
//  SenseMail2
//
//  Created by Sergey on 23.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "MessageListRouter.h"
#import "ListPresenter.h"
#import "MessageListViewController.h"
#import "ListInteractor.h"
#import "DataManager.h"
#import "DataStorage.h"
#import "ModalDialogViewController.h"
#import "GlobalRouter.h"

@implementation MessageListRouter

@synthesize manager, interactor, dataStore;

-(id)init
{
    if (self = [super init]) {
        self.presenter = [[ListPresenter alloc] init];
        self.interactor = [[ListInteractor alloc] init];
        self.manager = [[DataManager alloc] init];
        self.dataStore = [[DataStorage alloc] init];
        gettingNewCount = NO;
        
        /*
        self.largeFont = [[[NSUserDefaults standardUserDefaults] objectForKey:@"largeFont"] boolValue];
        
        id val = [[NSUserDefaults standardUserDefaults] objectForKey:@"sortByDate"];
        if(val != nil){
            self.sortByDate = [val boolValue];
        }else{
            // Set the default on
            self.sortByDate = YES;
            //[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"sortByDate"];
        }
        //self.sortByDate = [[[NSUserDefaults standardUserDefaults] objectForKey:@"sortByDate"] boolValue];
         */
    }
    return self;
}

-(void)noNeedForMore:(BOOL)value
{
    //self.presenter.noNeedForMore = value;
    [self.presenter setNoNeed:value];
}

-(void)showListInNavController:(UINavigationController*)navController forBox:(boxTypes)boxType
{
    nav = navController;
        
    MessageListViewController* ret = [self.presenter showListOfType:boxType];
    BOOL onStack = NO;
    //NSLog(@"Controllers = %i", nav.viewControllers.count);
    
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
            [nav pushViewController:ret animated:NO];
        }
        @catch (NSException *exception) {
            [nav popToViewController:ret animated:YES];
        }
    }
}

-(void)listReceivedCallback:(NSArray*) list error:(NSString*)error
{
    self.presenter.updateRequested = NO;
    
    if ([GlobalRouter notInited]) {
        NSLog(@"No global router");
        return;
    }
    
    if([GlobalRouter sharedManager].goingToBG) return;
    BOOL isAc = [[[GlobalRouter sharedManager] getListRouter] isActive];
    if (!isAc) {
        return;
    }
    //if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)return;
    
    [self.presenter setList:list error:error];
    
    __weak __typeof__(self) weakSelf = self;
    //TODO: for inbox we dont need to ask for each box, once is enough
    if (!error && !gettingNewCount){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            __strong __typeof__(self) strongSelf = weakSelf;
            NSString* emailAddr = @"";
            
            if(![[[GlobalRouter sharedManager] getListRouter] isActive])return;
            
            if ([GlobalRouter sharedManager].currentAccount == nil || [[GlobalRouter sharedManager].currentAccount isEqualToString:@""]) {
                
            }else{
                if([GlobalRouter sharedManager].accountsNames.count > 0){
                    /*NSArray* tmp = [[GlobalRouter sharedManager].accountsNames allKeysForObject:[GlobalRouter sharedManager].currentAccount];
                    if(tmp.count > 0){
                        emailAddr = tmp[0];
                    }*/
                    emailAddr = [DataStorage getEmailAddressFromCurrentAccount];
                }
            }
            if (!emailAddr || [emailAddr isEqualToString:@""]) {
                strongSelf->gettingNewCount = YES;
            }
            //if([UIApplication sharedApplication].applicationState == UIApplicationStateActive){
                int newms = [[GlobalRouter sharedManager] getNewMessagesCountForFolder:[GlobalRouter sharedManager].currentBoxPath address:emailAddr];
                [GlobalRouter sharedManager].newMessagesTotal = newms;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [GlobalRouter sharedManager].newMessagesTotal = newms;
                    if (newms < [GlobalRouter sharedManager].newMessages) {
                        // ERROR!
                        [GlobalRouter sharedManager].newMessages = [self.presenter getNewMessagesOnTheList];
                    }
                    [strongSelf.presenter refreshTableHeaderAnimated:NO];
                    strongSelf->gettingNewCount = NO;
                    if ([GlobalRouter sharedManager].currentBox == btInbox) {
                        // Set the badge in case it was corrupted or out of sync
    #if DEBUG
                        NSLog(@"New messages on the badge: %i", [GlobalRouter sharedManager].newMessagesTotal);
    #endif
                        [UIApplication sharedApplication].applicationIconBadgeNumber = newms;
                    }
                });
           //}
            
            //NSLog(@"New messages for %@ at %@ = %i/%i", [GlobalRouter sharedManager].currentBoxPath, emailAddr, newms, [GlobalRouter sharedManager].newMessages);
            
        });
    }
    
    /*
    if(error == nil){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            int nm = [[GlobalRouter sharedManager] getNewMessagesCount];
            //[UIApplication sharedApplication].applicationIconBadgeNumber = nm;
        });
    }
    */
}

-(void)needUpdateList
{
    [self.presenter updateList];
}

-(void)clearList
{
    //dispatch_async(dispatch_get_main_queue(), ^{
        [self.presenter clearList];
    //});
}

-(void)clearFilter
{
    [self.presenter clearFilter];
}

-(void)updateItemsFlags:(ShortMessageEntity*)item
{
    [self.presenter updateItemsFlags:item];
}

-(void)removeItemFromList:(ShortMessageEntity*)item
{
    [self.presenter deleteItemFromList:item];
}

-(void)needHideRefreshControl
{
    [self.presenter stopRefreshing];
}

-(void)needSearch
{
    [self.presenter search];
}

-(void)needSearchWithString:(NSString *)searchStr
{
    [self.presenter doSearchWithString:searchStr];
}

-(ShortMessageEntity*)getNextShortMessageFor:(ShortMessageEntity*)item
{
    return [self.presenter getNextShortMessageFor:item];
}

-(ShortMessageEntity*)getPrevShortMessageFor:(ShortMessageEntity*)item
{
    return [self.presenter getPrevShortMessageFor:item];
}

-(BOOL)isFetching
{
    return [dataStore isFetching];
}

-(void)cleanUp
{
    [self.presenter cleanUp];
}

-(BOOL)isActive
{
    return nav != nil;
}

-(BOOL)isShowingMenu
{
    return [self.presenter isShowingMenu];
}

-(void)dismissMenu
{
    [self.presenter dismissMenu];
}

-(BOOL)isFullyLoaded
{
    return [self.presenter isVCPresent];
}

-(void)showShortcutBar
{
    [self.presenter showShortcutBar];
}
@end
