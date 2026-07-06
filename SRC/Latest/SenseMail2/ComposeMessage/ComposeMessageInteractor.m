//
//  ComposeMessageInteractor.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "ComposeMessageInteractor.h"
#import "FullMessageEntity.h"
#import "DataManager.h"
#import "GlobalRouter.h"
#import "CommonProcs.h"
#import "ModalDialogViewController.h"
#import <MailCore/NSString+MCO.h>
#if !LITE
#import "OneTimeCertInteractor.h"
#endif

#import "OneTimeCert.h"

@implementation ComposeMessageInteractor

-(void)requestSendMessageFor:(FullMessageEntity*)item PIN:(NSMutableString*)pin
{
    //[CommonProcs showProgress:1 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    [CommonProcs setMessageInProgress:NSLocalizedString(@"Sending...", nil)];
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs addStopButtonInView:[CommonProcs getDimView]];
    });
    
    [[GlobalRouter sharedManager]restartQ];
    //__block NSString* originalBody = [item.messageBody mco_flattenHTML];
    
    [[[GlobalRouter sharedManager] getListRouter].manager sendMessage:item pin:pin];
    
    /*
    // If sending cert, save it!
    if (item.encType == enTypePasswordForCert) {
        //dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_async([[GlobalRouter sharedManager] getQ], ^{
            [ModalDialogViewController runWithHeader:NSLocalizedString(@"Enter pins",nil)
                                           text1:NSLocalizedString(@"Need pin for your sent messages TO this address",nil)
                                           text2:NSLocalizedString(@"Need pin for received messages FROM this address",nil)
                                           block:^{
                                               // Save cert
                                               NSString* text = originalBody;//[item.messageBody mco_flattenHTML];
                                               if (!(text == nil || [text isEqualToString:@""])) {
                                                   UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
                                                   if([dataMan saveKeyForAddress:item.toAddress yourPin:[ModalDialogViewController getText1] otherPin:[ModalDialogViewController getText2] key:[text dataUsingEncoding:NSUTF8StringEncoding] forDate:item.date]){
                                                       //[self wantDeleteMessage:message]; // Ask
                                                    }else{
                                                       //Error
                                                       //[messageViewController showError:NSLocalizedString(@"Error saving certificate", nil)];
                                                   }
                                               }
                                           }];
        });
    }
     */
}

-(BOOL)sendMessage:(FullMessageEntity*)message pin:(NSMutableString*)pin
{
    [CommonProcs showProgress:1 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    [[GlobalRouter sharedManager]restartQ];
    //[[[GlobalRouter sharedManager] getComposeRouter] getView];
    
    //dispatch_queue_t sendQueue = dispatch_queue_create("Network Queue",NULL);
    
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    dispatch_async([[GlobalRouter sharedManager] getQ], ^{
        
        DataManager* dataMan = [[DataManager alloc] init];
        NSString* error = @"";
        if(![dataMan sendMessage:message pin:pin])
        {
            error = NSLocalizedString(@"Error sending message", nil);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(![[GlobalRouter sharedManager] isCancelled]){
                [[[GlobalRouter sharedManager] getComposeRouter] sendingResult:error];
                //[CommonProcs showProgress:10 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
                [CommonProcs hideProgress];
            }else{
                [[GlobalRouter sharedManager]restartQ];
            }
        });
        
    });

    return YES;
}

-(void)removeAttachmentFromMessage:(FullMessageEntity*)message attachment:(UIImage*)att
{
    // I did it in presenter.
}

// AsyncLoader protocol
-(void)setProgress:(int)progress max:(int)max
{
    //[CommonProcs showProgress:progress max:max inView:[[GlobalRouter sharedManager] getCurrentView]];
    [CommonProcs setProgress:progress max:max title:NSLocalizedString(@"Sending...", nil)];
}

-(void)dataReady:(NSArray *)data error:(NSString *)error
{
    //[CommonProcs showProgress:10 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    [CommonProcs hideProgress];
    if(![[GlobalRouter sharedManager] isCancelled]){
        [[[GlobalRouter sharedManager] getComposeRouter] sendingResult:error];
        //
    }else{
        [[[GlobalRouter sharedManager] getComposeRouter] sendingResult:NSLocalizedString(@"Cancelled", nil)];
    }
}

#if !LITE
-(OneTimeCert*)checkForOTC:(FullMessageEntity*)message
{
    // Get the key ID and read that key
    // KeyID is stored... where? In the subject line, after the signature, 6 symbols
    OneTimeCert* otc = [[GlobalRouter sharedManager].oneTimeCertInteractor getNextCertForAddress:message.toAddress fromAddress:message.fromAddress];
    if(otc){
        //message.keyID = otc.certID;
        //message.encType = enTypeOTC;
    }
    
    return otc;
}
#endif

@end
