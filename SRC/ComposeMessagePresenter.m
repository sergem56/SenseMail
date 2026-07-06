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
//#import <AssetsLibrary/AssetsLibrary.h>

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
    // show menu - view, edit, delete
    UIActionSheet *popup = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select action",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) destructiveButtonTitle:nil otherButtonTitles:
                            NSLocalizedString(@"View",nil),
                            NSLocalizedString(@"Remove",nil),
                            nil];
    popup.tag = ind;
    [popup showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
        {
            [[GlobalRouter sharedManager] needShowAttachment:[viewController.message.attachments objectAtIndex:popup.tag]];
            break;
        }
        case 1:
            [self removeAttachment:(int)popup.tag];
            break;
        default:
            break;
    }
}

-(void)removeAttachment:(int)ind
{
    [viewController.message.attachments removeObjectAtIndex:ind];
    [viewController setupAttachmentIcons];
}

-(BOOL)needSendMessage:(FullMessageEntity*)message  pin:(NSString*)pin
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

-(void)setAttachments:(NSArray *)attachments
{
    if(viewController.message == nil)
        viewController.message = [[FullMessageEntity alloc] init];
    if (viewController.message.attachments == nil) {
        viewController.message.attachments = [[NSMutableArray alloc] initWithCapacity:attachments.count];
    }
    for (AttCollectionViewCell* cell in attachments) {
        //ALAssetRepresentation *defaultRep = [cell.asset defaultRepresentation];
        //UIImage *image = [UIImage imageWithCGImage:[defaultRep fullScreenImage] scale:[defaultRep scale] orientation:0];
        [viewController.message.attachments addObject:cell.asset];
    }
    
    [viewController setupAttachmentIcons];
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
    
    if (result == nil || [result isEqualToString:@""]) {
        [viewController closeMessage];
    }else{
        [viewController showError:result];
    }
}

@end
