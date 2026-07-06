//
//  ComposeMessagePresenter.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "ComposeMessagePresenter.h"
#import "ComposeMessageViewController.h"
#import "ComposeMessageInteractor.h"
#import "FullMessageEntity.h"
#import "AddressBookEntity.h"
#import "GlobalRouter.h"
#import "AttCollectionViewCell.h"
#import "CommonProcs.h"
#import "WindowMinimizer.h"
//#import <AssetsLibrary/AssetsLibrary.h>


#import "DataManager.h"
#if !LITE
#import "OneTimeCert.h"
#import "OneTimeCertInteractor.h"
#endif

@implementation ComposeMessagePresenter

-(ComposeMessageViewController*)showMessage:(FullMessageEntity *)message
{
    
    if(viewController == nil)
    {
        viewController = [[ComposeMessageViewController alloc] initWithNibName:@"ComposeView" bundle:nil];
    }
    
    /*
    if (message.encType == enTypePasswordForCert) {
        viewController = [[ComposeMessageViewController alloc] initWithNibName:@"SendCertificateView" bundle:nil];
    }else{
        viewController = [[ComposeMessageViewController alloc] initWithNibName:@"ComposeView" bundle:nil];
    }
    */
    
    viewController.presenter = self;
    
    //[viewController updateCurrentMessage];
    
    return viewController;
}

-(void)attachmentTapped:(int)ind
{
    // hide keyboard
    [viewController hideKeyboard];
    
    // show menu - view, edit, delete
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Select action",nil) message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *viewAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"View",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
            long tagg = ind-1000;
            __weak __typeof__(self) weakSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                __strong __typeof__(self) strongSelf = weakSelf;
                [[GlobalRouter sharedManager] needShowAttachment:[strongSelf->viewController.message.attachments objectAtIndex:tagg] atIndex:0 showSaveButton:YES];
            });
    }];
    
    UIAlertAction *removeAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Remove",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action){
        [self removeAttachment:ind-1000];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action){
        // Other action
    }];
    [alert addAction:viewAction];
    [alert addAction:removeAction];
    [alert addAction:cancelAction];
    
    UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
    popPresenter.sourceView = [viewController.view viewWithTag:ind];
    //popPresenter.sourceRect = button.bounds;
    
    [viewController presentViewController:alert animated:YES completion:nil];
}

/*
- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
        {
            long tagg = popup.tag;
            __weak __typeof__(self) weakSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                __strong __typeof__(self) strongSelf = weakSelf;
                [[GlobalRouter sharedManager] needShowAttachment:[strongSelf->viewController.message.attachments objectAtIndex:tagg] atIndex:0 showSaveButton:YES];
            });
            break;
        }
        case 1:
            [self removeAttachment:(int)popup.tag];
            break;
        default:
            break;
    }
}
*/
-(void)removeAttachment:(int)ind
{
    NSString* path = viewController.message.attachments[ind];
    [viewController.message.attachments removeObjectAtIndex:ind];
    [viewController setupAttachmentIcons];
    // remove temp file
    if ([path rangeOfString:@"tmp"].location != NSNotFound) {
        [DataManager rewriteFileAtPath:path];
    }
}

-(BOOL)needSendMessage:(FullMessageEntity*)message pin:(NSMutableString*)pin
{
    ComposeMessageInteractor* cmIn = [[ComposeMessageInteractor alloc] init];
    //return [cmIn sendMessage:message pin:pin];
    [cmIn requestSendMessageFor:message PIN:pin];
    return YES;
}

-(void)setToAddress:(AddressBookEntity*)address
{
    if(viewController.message == nil)
        viewController.message = [[FullMessageEntity alloc] init];
    
    viewController.message.fromAddress = address.address;
    [viewController setupAddress];
}

-(void)setAttachments:(NSArray*)attachments
{
    if(viewController.message == nil)
        viewController.message = [[FullMessageEntity alloc] init];
    if (viewController.message.attachments == nil) {
        viewController.message.attachments = [[NSMutableArray alloc] initWithCapacity:attachments.count];
    }
    
#ifdef DEMO
    if (viewController.message.attachments.count + attachments.count > 1) {
        [CommonProcs thisFeatureIsInFull:@"Unlimited attachments feature"];
        if(viewController.message.attachments.count == 0){
            attachments = [NSArray arrayWithObjects:attachments[0], nil];
        }else{
            attachments = [[NSArray alloc] init];
        }
    }
#endif
    
    //for (AttCollectionViewCell* cell in attachments) {
    // TODO: if it's called on main thread, it works OK, but the indicator is not updating
    // if we move it to BG, it's called ones and adds only one image...
    for (/*ALAsset**/id cell in attachments) {
        //ALAssetRepresentation *defaultRep = [cell.asset defaultRepresentation];
        //UIImage *image = [UIImage imageWithCGImage:[defaultRep fullScreenImage] scale:[defaultRep scale] orientation:0];
        if([cell isKindOfClass:[PHAsset class]]){
            //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                //[CommonProcs fullImageFromPHAsset:cell];
                // save image and set a path?
            NSString* path = [CommonProcs saveImageForPHAssetToTempFile:cell];
            if (!path || [path isEqualToString:@""]) {
                continue;
            }
            //cell = path;
            //NSLog(@"Path = %@", path);
            [viewController.message.attachments addObject:path];
            __weak __typeof__(self) weakSelf = self;
            /*
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                __strong __typeof__(self) strongSelf = weakSelf;
                [strongSelf->viewController setupAttachmentIcons];
            });
             */
            
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong __typeof__(self) strongSelf = weakSelf;
                [strongSelf->viewController setupAttachmentIcons];
            });
             
            //});
        }else{
            if(cell)
                [viewController.message.attachments addObject:cell];// cell.asset];
        }
    }
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [strongSelf->viewController setupAttachmentIcons];
    });
}

-(void)needToAddAttachment
{
    // Need to add attachment - show dialog
    [[[GlobalRouter sharedManager] getComposeRouter] needAttachment];
}

-(void)needAddress
{
    [[[GlobalRouter sharedManager] getComposeRouter] needAddressBook];
}

-(void)sendingResult:(NSString*)result
{
    //[CommonProcs showProgress:10 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    [CommonProcs hideProgress];
    
    if(!viewController)return; //If sending a message from the outside, for example read receipt
    
    if (result == nil || [result isEqualToString:@""]) {
        [viewController closeMessageWithSentAnimation];
#if !LITE
        OneTimeCertInteractor* otcint = [[OneTimeCertInteractor alloc] init];
        if(cert){
            cert.dateUsed = [OneTimeCert getStringForDate:[NSDate date]];
            [otcint setExpirationTimeForCert:cert.certID expiration:[cert getExpirationDate] dateUsed:[NSDate date] from:viewController.message.fromAddress];
        }
#endif
        // Set answered flag?
        // TMP
        // There's a bug - if we are sending a new message, no need to set a flag - FIXED
        if(viewController.answering){
            [[[GlobalRouter sharedManager] getListRouter].manager markAsAnswered:viewController.message];
            //[[GlobalRouter sharedManager] getListRouter].presenter.
            viewController.message.flags |= mfAnswered;
            [[[GlobalRouter sharedManager] getListRouter] updateItemsFlags:viewController.message];
            [[GlobalRouter sharedManager] updateCurrentList];
        }
        viewController.message = nil;
        [[GlobalRouter sharedManager] getComposeRouter].currentMessage = nil;
    }else{
        if ([result isEqualToString:@"The certificate for this server is invalid."]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController * alert = [UIAlertController
                                             alertControllerWithTitle:NSLocalizedString(@"The certificate for this server is invalid", nil)
                                             message:NSLocalizedString(@"Send it anyway?", nil)
                                             preferredStyle:UIAlertControllerStyleAlert];
                
                __weak __typeof__(self) weakSelf = self;
                UIAlertAction* sendIt = [UIAlertAction
                                        actionWithTitle:NSLocalizedString(@"Yes",nil)
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * action)
                                        {
                                            __strong __typeof__(self) strongSelf = weakSelf;
                                            [CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Sending...", nil) stopButton:NO];
                                            strongSelf->viewController.message.doNotCheckServerCertificate = YES;
                                            [strongSelf needSendMessage:strongSelf->viewController.message pin:strongSelf->viewController.pinCode];
                                        }];
                [alert addAction:sendIt];
                
                UIAlertAction* cancel = [UIAlertAction
                                         actionWithTitle:NSLocalizedString(@"No",nil)
                                         style:UIAlertActionStyleCancel
                                         handler:^(UIAlertAction * action)
                                         {
                                             
                                         }];
                [alert addAction:cancel];
                
                UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
                alert.popoverPresentationController.sourceView = pView;
                alert.popoverPresentationController.sourceRect = pView.frame;
                [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
            });
            
        }else{
            [viewController showError:result];
        }
    }
}

-(void)minimizeComposerAnimated:(BOOL)animated
{
    //[viewController closeMessage];
    viewController.minimizer = [[WindowMinimizer alloc] init];
    [viewController.minimizer minimizeWindow:viewController animated:animated];
}

-(BOOL)isMinimized
{
    return viewController.view.frame.size.width == 60;
}

#if !LITE
-(OneTimeCert*)checkForOTC:(FullMessageEntity*)message
{
    /*
    OneTimeCertInteractor* otcint = [[OneTimeCertInteractor alloc] init];
    [otcint showUseOTCDialog:nil completion:^{
        [[GlobalRouter sharedManager] finishedWithDetailView:YES];
        if (self->cert == nil) {
            NSLog(@"Cert is nil");
            // ask for a PIN
            [self->viewController needPINOnly];
        }else{
            message.keyID = @"QQQ";
            self->viewController.pinCode = @"QQQQQ";
            [self->viewController setPinColor];
            if (self.sending) {
                [self->viewController needSend];
            }
        }
    }];
    */
    
    ComposeMessageInteractor* inter = [[ComposeMessageInteractor alloc] init];
    cert = [inter checkForOTC:message];
    if (cert) {
        // Cert found, ask to use it. If no, remove certID and encType from the message
        // After use, set expiration date and used mark
        __weak __typeof__(self) weakSelf = self;
        OneTimeCertInteractor* otcint = [[OneTimeCertInteractor alloc] init];
        [otcint showUseOTCDialog:cert completion:^{
            [[GlobalRouter sharedManager] finishedWithDetailView:YES];
            __strong __typeof__(self) strongSelf = weakSelf;
            if (strongSelf->cert.yourEmail == nil) {
                // ask for a PIN
                message.encType = enTypePassword;
                [strongSelf->viewController needPINOnly];
            }else{
                message.encType = enTypeOTC;
                message.keyID = strongSelf->cert.certID;
                strongSelf->viewController.pinCode = [strongSelf->cert getCertString];
                [strongSelf->viewController setPinColor];
                strongSelf->viewController.message.expireOTCon = strongSelf->cert.expirationDate;
                if (strongSelf.sending) {
                    [strongSelf->viewController needSend];
                }
                // Set used cert in sendingResult
            }
        }];
    }
    return cert;
}
#endif

-(BOOL)checkFromAndReplyTo:(NSString*)from replyTo:(NSString*)replyTo
{
    BOOL ret = YES;
    if(!from && !replyTo)return YES;
    if(!replyTo)return YES;
    if (![from.lowercaseString isEqualToString:replyTo.lowercaseString]) {
        ret = NO;
        
        [CommonProcs showMessage:[NSString stringWithFormat:NSLocalizedString(@"The \"Reply-To\" address (%@) \nis different from the\n\"From\" address (%@)\n\nUsing the \"Reply-To\"", nil),replyTo, from] title:NSLocalizedString(@"Warning", nil)];
    }
    return ret;
}

-(void)restoreVC:(ComposeMessageViewController *)vc
{
    viewController = vc;
}

-(void)checkAttachmentsValidity
{
    BOOL valid = YES;
    for (NSString* path in viewController.message.attachments) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:path]) {
            valid = NO;
            break;
        }
    }
    if (!valid) {
        // Remove all attachments
        [viewController.message.attachments removeAllObjects];
        __weak __typeof__(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof__(self) strongSelf = weakSelf;
            [strongSelf->viewController setupAttachmentIcons];
        });
    }
}

@end
