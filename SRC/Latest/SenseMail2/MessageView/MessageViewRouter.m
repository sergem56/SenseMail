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

@synthesize interactor;//, manager,dataStore;

-(id)init
{
    if (self = [super init]) {
        presenter = [[MessageViewPresenter alloc] init];
        interactor = [[MessageViewInteractor alloc] init];
        //self.manager = [[DataManager alloc] init];
        //self.dataStore = [[DataStorage alloc] init];
        needUpdateOnExit = NO;
    }
    return self;
}

-(MessageViewController*)getViewControllerForEmptyMessage
{
    return [presenter showMessageFor:nil PIN:nil];
}

-(MessageViewPresenter*)getPresenter
{
    return presenter;
}

-(void)openMessageInNavController:(UINavigationController*)vc message:(ShortMessageEntity*)message withPIN:(NSMutableString*)pin
{
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [CommonProcs hideProgress];
        UIViewController* ret = [strongSelf->presenter showMessageFor:message PIN:pin];
        
        strongSelf->nav = vc;
        
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
    
    if (message.flags & mfNonEncrypted || message.encType == enTypeOTC) {
        // push message view
        [self openMessageInNavController:vc message:message withPIN:nil];
        
    }else{
        // request pin
        //[[GlobalRouter sharedManager] needPassword:message];
        NSString* mText;
        if (message.encType == enTypePasswordForCert) {
            mText = NSLocalizedString(@"This message contains certificate",nil);
        }else{
            mText = [NSString stringWithFormat:NSLocalizedString(@"Message from %@ is password-protected",nil), message.fromName?message.fromName:message.fromAddress];
        }
        __weak __typeof__(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof__(self) strongSelf = weakSelf;
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:NSLocalizedString(@"Enter PIN",nil)
                                         message:mText
                                         preferredStyle:UIAlertControllerStyleAlert];
            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = @"PIN-code";
                textField.textColor = [UIColor blueColor];
                textField.clearButtonMode = UITextFieldViewModeWhileEditing;
                textField.borderStyle = UITextBorderStyleRoundedRect;
                textField.secureTextEntry = YES;
            }];
            UIAlertAction* cancel = [UIAlertAction
                                     actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                     style:UIAlertActionStyleCancel
                                     handler:^(UIAlertAction * action)
                                     {
                                         
                                     }];
            [alert addAction:cancel];
            
            UIAlertAction* done = [UIAlertAction
                                     actionWithTitle:NSLocalizedString(@"OK",nil)
                                     style:UIAlertActionStyleDefault
                                     handler:^(UIAlertAction * action)
            {
                NSArray * textfields = alert.textFields;
                UITextField * passw = textfields[0];
                NSMutableString* pin = [NSMutableString stringWithString: [passw text]];
                [self openMessageInNavController:strongSelf->nav message:strongSelf->curMessage withPIN:pin];
            }];
            [alert addAction:done];
            
            UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
            alert.popoverPresentationController.sourceView = pView;
            alert.popoverPresentationController.sourceRect = pView.frame;
            [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
        });
        
        /*
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof__(self) strongSelf = weakSelf;
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter PIN",nil) message:mText delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Done",nil),nil];
            alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
            
            UIBarButtonItem* button23 = [[UIBarButtonItem alloc] initWithTitle:@"ABC/123" style:UIBarButtonItemStylePlain target:self action:@selector(changeKeyboard)];
            
            UIToolbar* inputAccessoryToolbar = [[UIToolbar alloc] init];
            inputAccessoryToolbar.frame = CGRectMake(0,0,250,44);
            inputAccessoryToolbar.items = [NSArray arrayWithObjects: button23, nil];
            strongSelf->pinDialogField = [alert textFieldAtIndex:0];
            strongSelf->pinDialogField.inputAccessoryView = inputAccessoryToolbar;
            
            [alert setTag:100];
            [alert show];
        });*/
    }
}

-(void)changeKeyboard
{
    if (pinDialogField.keyboardType == UIKeyboardTypeNumberPad) {
        [pinDialogField setKeyboardType:UIKeyboardTypeAlphabet];
    }else{
        [pinDialogField setKeyboardType:UIKeyboardTypeNumberPad];
    }
    [pinDialogField reloadInputViews];
}

/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100)
    {
        if (buttonIndex == 0)
        {
            // No need to finish since we show the alert only
            //[self finished];
        }else{
            NSMutableString* pin = [NSMutableString stringWithString: [[alertView textFieldAtIndex:0] text]];
            [self openMessageInNavController:nav message:curMessage withPIN:pin];
        }
    }
}*/

// Move it to openMessageInNavController? What if the password is incorrect - mark as read anyway?
-(void)markAsRead
{
    if (presenter.currentItem.flags & mfNew) {
        [interactor markMessageAsRead:presenter.currentItem];
        
        /*
         if ([UIApplication sharedApplication].applicationIconBadgeNumber > 0) {
             [UIApplication sharedApplication].applicationIconBadgeNumber--;
         }
        */
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
            // Update now
            [[GlobalRouter sharedManager] updateCurrentList];
            needUpdateOnExit = NO;
            
            // Update the currently shown message
            [presenter setReadFlagForFullMessage];
        }else{
            needUpdateOnExit = YES;
        }
    }
}

-(void) finishedWithAnimation:(BOOL)animated
{
    //[GlobalRouter sharedManager].shouldCancel = YES;
    [[[GlobalRouter sharedManager] getListRouter].dataStore cancelCurrentFetch];
    
    [[GlobalRouter sharedManager] finishedWithDetailView:animated];// getNavController] popViewControllerAnimated:animated];
    
    [[GlobalRouter sharedManager]updateCurrentList];
    
    // Moved it to openMessage
    //[self markAsRead];
    
    // Read receipt
    [self.interactor checkReadReceipt:presenter.currentItem];
    
    [presenter finished];
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
    [[[GlobalRouter sharedManager] getListRouter].manager toggleStarForMessage:(ShortMessageEntity*)item];
    item.flags ^= mfFavourite;
    
    // Need to update list
    [[[GlobalRouter sharedManager] getListRouter] updateItemsFlags:item];
    //needUpdateOnExit = YES;
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        // Update now
        //[[GlobalRouter sharedManager] updateCurrentList];
    }else{
        needUpdateOnExit = YES;
    }
}

-(void)wantDeleteMessage:(FullMessageEntity*)item
{
    [[[GlobalRouter sharedManager] getListRouter].manager deleteMessage:(ShortMessageEntity *)item];
    [[[GlobalRouter sharedManager] getListRouter] removeItemFromList:(ShortMessageEntity *)item];
    
    needUpdateOnExit = YES;
    [self finished];
}

-(void)wantShowAttachment:(NSObject*)item atIndex:(int)index
{
    //NSLog(@"Showing attachment");
    [[GlobalRouter sharedManager] needShowAttachment:item atIndex:(int)index showSaveButton:YES];
}

// Not used yet
-(void)wantShowNextAttachment:(BOOL)nextOrPrev
{
    //[presenter wantShowNextAttachment:nextOrPrev];
}

-(void)messageReceivedCallback:(FullMessageEntity*)message error:(NSString*)error
{
    if (message == nil && (error == nil || [error isEqualToString:@""])) {
        return;
    }
    if([error isEqualToString:NSLocalizedString(@"Cancelled",nil)]){ // test
        dispatch_async(dispatch_get_main_queue(), ^{
            CGRect screenRect = [[UIScreen mainScreen] bounds];
            CGFloat screenWidth = screenRect.size.width;
            [CommonProcs showVanishingMessage:error inView:[[GlobalRouter sharedManager] getCurrentView] inRect:CGRectMake(screenWidth/2-100, screenRect.size.height/2+14, 200, 40) timeToShow:1];
            [[GlobalRouter sharedManager] finishedWithDetailView:YES];
        });
        
        return;
    }
    dispatch_queue_t setMsgQueue = dispatch_queue_create("Set Queue",NULL);
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^{
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(setMsgQueue, ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [strongSelf->presenter setMessage:message error:error];
    });
    
    // Mark as read
    if(!error){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self markAsRead];
        });
    }
    
}

-(void)wantCopyMessage:(FullMessageEntity *)item to:(NSString *)folderPath
{
    [[[GlobalRouter sharedManager] getListRouter].manager copyMessage:item to:folderPath];
}

-(void)wantMoveMessage:(FullMessageEntity *)item to:(NSString *)folderPath
{
    [[[GlobalRouter sharedManager] getListRouter].manager moveMessage:item to:folderPath];
}

-(void)wantReEncryptMessage:(FullMessageEntity *)message
{
    [self.interactor reEncryptMessage:message];
}

@end
