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

-(MessageViewController*)showMessageFor:(ShortMessageEntity*)item PIN:(NSString *)pin
{
    [CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Loading...", nil) stopButton:YES];
    
    MessageViewInteractor* mvIn = [[MessageViewInteractor alloc] init];
    //FullMessageEntity* fullMessage = [mvIn getFullMessageFor:item PIN:pin];
    
    dispatch_async([[GlobalRouter sharedManager] getQ], ^{
        [mvIn requestFullMessageFor:item PIN:pin];
    });
    
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
    if ([error isEqualToString:@""] || error == nil) {
        if (message.encType == enTypePasswordForCert) {
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

        }
        dispatch_async(dispatch_get_main_queue(), ^{
            messageViewController.currentMessage = message;
            [messageViewController updateMessageView];
        });
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [[GlobalRouter sharedManager] finishedWithCurrentView];
            [messageViewController showError:error];
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

-(void)wantShowAttachment:(NSObject*)item
{
    [[[GlobalRouter sharedManager] getMessageRouter]wantShowAttachment:item];
}

-(BOOL)wantSaveAll:(FullMessageEntity *)item
{
    MessageViewInteractor* mvIn = [[MessageViewInteractor alloc] init];
    return [mvIn saveAllAttachments:item];
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

@end
