//
//  MessageVeiwPresenter.m
//  SenseMail2
//
//  Created by Sergey on 30.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "MessageViewPresenter.h"
#import "MessageViewInteractor.h"
#import "GlobalRouter.h"
#import "FullMessageEntity.h"
#import "ShortMessageEntity.h"
#import "MessageViewRouter.h"
#import "ModalDialogViewController.h"
#import "CommonProcs.h"
#import "SelectFolderViewController.h"

#import <MailCore/NSString+MCO.h>

@implementation MessageViewPresenter

@synthesize currentItem;

-(id)init
{
    if (self = [super init]) {
        //router = [[MessageViewRouter alloc] init];
    }
    
    return self;
}

-(MessageViewController*)showMessageFor:(ShortMessageEntity*)item PIN:(NSMutableString *)pin
{
    [CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Loading...", nil) stopButton:YES];
    
    MessageViewInteractor* mvIn = [[MessageViewInteractor alloc] init];
    //FullMessageEntity* fullMessage = [mvIn getFullMessageFor:item PIN:pin];
    
    if(item != nil){
        dispatch_async([[GlobalRouter sharedManager] getQ], ^{
            [mvIn requestFullMessageFor:item PIN:pin];
        });
    }
    
    if(messageViewController == nil)
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        messageViewController = [storyboard instantiateViewControllerWithIdentifier:@"MessageView"];
    }
    
    messageViewController.presenter = self;
    //messageViewController.currentMessage = fullMessage;
    
    messageViewController.currentMessage = nil;
    [messageViewController updateMessageView];
    currentItem = item;
    
    return messageViewController;

}

// Works in background
-(void)setMessage:(FullMessageEntity *)message error:(NSString*)error
{
    if (([error isEqualToString:@""] || error == nil) && message != nil) {
        if (message.encType == enTypePasswordForCert) {
            /*
            // save cert, delete message and close view
            //dispatch_async(dispatch_get_main_queue(), ^{
            [ModalDialogViewController runWithHeader:NSLocalizedString(@"Enter pins",nil)
                                               text1:NSLocalizedString(@"Need pin for your sent messages TO this address",nil)
                                               text2:NSLocalizedString(@"Need pin for received messages FROM this address",nil)
            block:^{
                // Save cert
                NSString* text = [message.messageBody mco_flattenHTML];
                
                if (!(text == nil || [text isEqualToString:@""])) {
                    [CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Saving certificate...", nil) stopButton:NO];
                    
                    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
                    if([dataMan saveKeyForAddress:message.fromAddress yourPin:[ModalDialogViewController getText1] otherPin:[ModalDialogViewController getText2] key:[text dataUsingEncoding:NSUTF8StringEncoding] forDate:message.date]){
                        //[self wantDeleteMessage:message]; // Ask
                        //__unsafe_unretained MessageViewController* weakMC = messageViewController;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [messageViewController askAndDoWithTitle:NSLocalizedString(@"Warning",nil) text:NSLocalizedString(@"Certificate saved. However, for security reasons",nil) block:^{
                                [self wantDeleteMessage:message];
                            }];
                        });
                    }else{
                        //Error
                        [messageViewController showError:NSLocalizedString(@"Error saving certificate", nil)];
                    }
                    [CommonProcs hideProgress];
                }else{
                    [messageViewController showError:NSLocalizedString(@"Error decoding certificate", nil)];
                }
            }];
            //});
             */

        }
        __weak __typeof__(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof__(self) strongSelf = weakSelf;
            strongSelf->messageViewController.currentMessage = message;
            [strongSelf->messageViewController updateMessageView];
        });
    
    }else{
        __weak __typeof__(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof__(self) strongSelf = weakSelf;
            [[GlobalRouter sharedManager] finishedWithDetailView:YES];
            [strongSelf->messageViewController showError:error];
        });
    }
}

-(void)wantReplyToMessage:(FullMessageEntity*)item
{
    [[[GlobalRouter sharedManager] getMessageRouter] wantReplyToMessage:item];
}

-(void)wantForwardMessage:(FullMessageEntity*)item
{
    [[[GlobalRouter sharedManager] getMessageRouter] wantForwardMessage:item];
}

-(void)wantMarkMessage:(FullMessageEntity*)item
{
    [[[GlobalRouter sharedManager] getMessageRouter] wantMarkMessage:item];
}

-(void)wantShowAttachment:(NSObject*)item atIndex:(int)index
{
    showingAttIndex = index;
    [[[GlobalRouter sharedManager] getMessageRouter]wantShowAttachment:item atIndex:(int)index];
}

// Not used yet
/*
-(void)wantShowNextAttachment:(BOOL)nextOrPrev
{
    if(messageViewController.currentMessage.attachments == nil || messageViewController.currentMessage.attachments.count == 0) return;
    
    id item;
    if (nextOrPrev) {
        showingAttIndex++;
        if(showingAttIndex >= messageViewController.currentMessage.attachments.count) showingAttIndex = (int)messageViewController.currentMessage.attachments.count-1;
    }else{
        showingAttIndex--;
        if(showingAttIndex < 0)showingAttIndex = 0;
    }
    item = messageViewController.currentMessage.attachments[showingAttIndex];
    
    [[[GlobalRouter sharedManager] getMessageRouter]wantShowAttachment:item];
}
*/
-(BOOL)wantSaveAll:(FullMessageEntity *)item
{
    [CommonProcs showProgressWithTitle:0 max: (int)item.attachments.count inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Saving attachment", nil) stopButton:NO];
    savedAttchments = 0;
    MessageViewInteractor* mvIn = [[MessageViewInteractor alloc] init];
    return [mvIn saveAllAttachments:item caller:self];
}

-(void)itemSaved:(UIImage*)image didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo
{
    savedAttchments++;
    if (savedAttchments == messageViewController.currentMessage.attachments.count) {
        savedAttchments = 0;
        [CommonProcs hideProgress];
    }else{
        [CommonProcs setProgress:savedAttchments max:(int)messageViewController.currentMessage.attachments.count title:NSLocalizedString(@"Saving attachment", nil)];
    }
}

-(void)wantDeleteMessage:(FullMessageEntity*)item
{
    [[[GlobalRouter sharedManager] getMessageRouter] wantDeleteMessage:item];
}

-(void)wantToAddContactFor:(NSString*)name address:(NSString*)address
{
    MessageViewInteractor* mvIn = [[MessageViewInteractor alloc] init];
    return [mvIn addContactFor:name address:address];
}

-(void)wantShowNextMessageFor:(ShortMessageEntity*)item
{
    ShortMessageEntity* ret = [[GlobalRouter sharedManager] getNextShortMessageFor:item];
    if (ret == nil) {
        // end of the list, load more
        [CommonProcs showMessage:NSLocalizedString(@"This is the last loaded message", nil) title:NSLocalizedString(@"No more messages", nil)];
    }else{
        [[[GlobalRouter sharedManager] getMessageRouter] finished];
        [[GlobalRouter sharedManager] needShowMessage:ret];
        //[[[GlobalRouter sharedManager] getMessageRouter] showMessageInNavController:[[GlobalRouter sharedManager] getDetailNavController] message:ret];
    }
}

-(void)wantShowPrevMessageFor:(ShortMessageEntity*)item
{
    ShortMessageEntity* ret = [[GlobalRouter sharedManager] getPrevShortMessageFor:item];
    if (ret == nil) {
        // beginning of the list, no more
        [CommonProcs showMessage:NSLocalizedString(@"This is the first message", nil) title:NSLocalizedString(@"No more messages", nil)];
        
    }else{
        [[[GlobalRouter sharedManager] getMessageRouter] finished];
        [[GlobalRouter sharedManager] needShowMessage:ret];
        //[[[GlobalRouter sharedManager] getMessageRouter] showMessageInNavController:[[GlobalRouter sharedManager] getDetailNavController] message:ret];
    }
}

-(void)finished
{
    messageViewController.textWK = nil;
    messageViewController = nil;
    currentItem = nil;
}

-(FullMessageEntity*)getFullMessage
{
    return messageViewController.currentMessage;
}

-(void)setReadFlagForFullMessage
{
    if(messageViewController.currentMessage != nil)
        messageViewController.currentMessage.flags &= ~mfNew;
}

-(void)wantOpenURL:(NSURLRequest*)request
{
    [CommonProcs askAndDoWithTitle:NSLocalizedString(@"Open link in external browser?", nil) text:request.URL.absoluteString block:^{
            [[UIApplication sharedApplication] openURL:request.URL];
    }];
}

/*
-(void)askAndDoWithTitle:(NSString*)title text:(NSString*)alertText block:(dispatch_block_t)block
{
    alertBlock = block;
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:alertText
                                 preferredStyle:UIAlertControllerStyleAlert];
    __weak __typeof__(self) weakSelf = self;
    UIAlertAction* ok = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"OK", nil)
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
                                   __strong __typeof__(self) strongSelf = weakSelf;
                                   strongSelf->alertBlock();
                               }];
    [alert addAction:ok];
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"Cancel",nil)
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 
                             }];
    [alert addAction:cancel];
    
    UIView* pView = messageViewController.view;// [[GlobalRouter sharedManager] getCurrentView];
    alert.popoverPresentationController.sourceView = pView;
    alert.popoverPresentationController.sourceRect = pView.frame;
    [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
    
}*/

-(void)switchView
{
    [messageViewController textHtmlView:nil];
}

/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 101)
    {
        if (buttonIndex == 0)
        {
            
        }else{
            alertBlock();
        }
    }
}
*/

@end
