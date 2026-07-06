//
//  MessageViewRouter.m
//  SenseMail2
//
//  Created by Sergey on 31.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "MessageViewRouter.h"
#import "ShortMessageEntity.h"
#import "MessageViewPresenter.h"
#import "GlobalRouter.h"
#import "MessageViewInteractor.h"
#import "AppDelegate.h"
#import "DataManager.h"
#import "DataStorage.h"
#import "CommonProcs.h"

@implementation MessageViewRouter

@synthesize interactor, manager,dataStore;

-(id)init
{
    if (self = [super init]) {
        presenter = [[MessageViewPresenter alloc] init];
        interactor = [[MessageViewInteractor alloc] init];
        self.manager = [[DataManager alloc] init];
        self.dataStore = [[DataStorage alloc] init];
        needUpdateOnExit = NO;
    }
    return self;
}

-(void)openMessageInNavController:(UINavigationController*)vc message:(ShortMessageEntity*)message withPIN:(NSString*)pin
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs hideProgress];
        UIViewController* ret = [presenter showMessageFor:message PIN:pin];
        
        nav = vc;
        
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
            }
        }
    });
    
    /*
    @try {
        //[[GlobalRouter sharedManager] pushView:ret];
        [vc pushViewController:ret animated:YES];
    }
    @catch (NSException *exception) {
        [vc popToViewController:ret animated:YES];
    }
    @finally {
    }
     */
}

-(void)showMessageInNavController:(UINavigationController*)vc message:(ShortMessageEntity*)message
{
    nav = vc;
    curMessage = message;
    
    if (message.flags & mfNonEncrypted) {
        // push message view
        [self openMessageInNavController:vc message:message withPIN:nil];
        
    }else{
        // request pin
        //[[GlobalRouter sharedManager] needPassword:message];
        NSString* mText;
        if (message.encType == enTypePasswordForCert) {
            mText = NSLocalizedString(@"This message contains certificate",nil);
        }else{
            mText = NSLocalizedString(@"This message is password-protected",nil);
        }
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter PIN",nil) message:mText delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Done",nil),nil];
        alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
        [alert setTag:100];
        [alert show];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100)
    {
        if (buttonIndex == 0)
        {
            [self finished];
        }else{
            NSString* pin = [[alertView textFieldAtIndex:0] text];
            [self openMessageInNavController:nav message:curMessage withPIN:pin];
        }
    }
}

-(void) finishedWithAnimation:(BOOL)animated
{
    [[GlobalRouter sharedManager] finishedWithCurrentView];// getNavController] popViewControllerAnimated:animated];
    
    [[GlobalRouter sharedManager]updateCurrentList];
    
    if (presenter.currentItem.flags & mfNew) {
        //MessageViewInteractor* mvIn = [[MessageViewInteractor alloc] init];
        [interactor markMessageAsRead:presenter.currentItem];
        [manager markAsRead:presenter.currentItem];
        
        if ([UIApplication sharedApplication].applicationIconBadgeNumber > 0) {
            [UIApplication sharedApplication].applicationIconBadgeNumber--;
        }
        
        needUpdateOnExit = YES;
    }
}

-(void)finished
{
    [self finishedWithAnimation:YES];
    if (needUpdateOnExit) {
        [[GlobalRouter sharedManager] updateCurrentList];
        needUpdateOnExit = NO;
    }
    /*
    [[[GlobalRouter sharedManager] getNavController] popViewControllerAnimated:YES];
    
    [[GlobalRouter sharedManager]updateCurrentList];
    
    if (presenter.currentItem.flags & mfNew) {
        MessageViewInteractor* mvIn = [[MessageViewInteractor alloc] init];
        [mvIn markMessageAsRead:presenter.currentItem];
    }
     */
}

-(void)wantReplyToMessage:(FullMessageEntity*)item
{
    //NSLog(@"Reply!");
    [self finishedWithAnimation:NO];
    [[GlobalRouter sharedManager] needShowComposeMessage:item includeAttachments:NO forward:NO];
}

-(void)wantForwardMessage:(FullMessageEntity*)item
{
    //NSLog(@"Forward!");
    [self finishedWithAnimation:NO];
    [[GlobalRouter sharedManager] needShowComposeMessage:item includeAttachments:YES forward:YES];
}

-(void)wantMarkMessage:(FullMessageEntity*)item
{
    //NSLog(@"Mark!");
    [self.manager toggleStarForMessage:(ShortMessageEntity*)item];
    item.flags ^= mfFavourite;
    
    // Need to update list
    [[[GlobalRouter sharedManager] getListRouter] updateItemsFlags:item];
    needUpdateOnExit = YES;
}

-(void)wantDeleteMessage:(FullMessageEntity*)item
{
    [self.manager deleteMessage:(ShortMessageEntity *)item];
    [[[GlobalRouter sharedManager] getListRouter] removeItemFromList:(ShortMessageEntity *)item];
    
    needUpdateOnExit = YES;
    [self finished];
}

-(void)wantShowAttachment:(NSObject*)item
{
    //NSLog(@"Showing attachment");
    [[GlobalRouter sharedManager] needShowAttachment:item];
}

-(void)messageReceivedCallback:(FullMessageEntity*)message error:(NSString*)error
{
    dispatch_queue_t setMsgQueue = dispatch_queue_create("Set Queue",NULL);
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^{
    dispatch_async(setMsgQueue, ^{
        [presenter setMessage:message error:error];
    });
    
}

@end
