//
//  AttachmentViewPresenter.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "AttachmentViewPresenter.h"
#import "AttachmentViewController.h"
#import "AttachmentViewInteractor.h"
#import "CommonProcs.h"
#import "GlobalRouter.h"

@implementation AttachmentViewPresenter

-(AttachmentViewController*)showAttachment :(UIImage*)att
{
    //AttachmentViewInteractor* attIn = [[AttachmentViewInteractor alloc] init];
    
    if(viewController == nil)
    {
        viewController = [[AttachmentViewController alloc] initWithNibName:@"AttachmentViewController" bundle:nil];
    }
    
    viewController.presenter = self;
    [viewController.image setImage:att];
    
    return viewController;
}

-(BOOL)needSaveImage:(UIImage *)image
{
    AttachmentViewInteractor* attIn = [[AttachmentViewInteractor alloc] init];
    return [attIn saveImage:image];
}

-(BOOL)needSaveImageSecure:(UIImage *)image
{
    [CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Saving...",nil) stopButton:NO];
    
    AttachmentViewInteractor* attIn = [[AttachmentViewInteractor alloc] init];
    [attIn performSelectorInBackground:@selector(saveImageSecure:) withObject:image];
    
    return YES;
}

@end
