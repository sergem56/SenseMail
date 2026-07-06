//
//  AddAttachmentPresenter.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "AddAttachmentPresenter.h"
#import "AddAttachmentViewController.h"
#import "GlobalRouter.h"
#import "DataManager.h"
#import "CommonProcs.h"

@implementation AddAttachmentPresenter

-(AddAttachmentViewController*)showView
{
    if(viewController == nil)
    {
        viewController = [[AddAttachmentViewController alloc] initWithNibName:@"AddAttachmentViewController" bundle:nil];
    }
    
    /*
    [CommonProcs showProgress:1 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    //dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
    dispatch_async([[GlobalRouter sharedManager] getQ], ^{
        
        [[GlobalRouter sharedManager] setAssets: [DataManager defaultAssetsLibrary]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs showProgress:10 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
        });
        
    });
     */
    
    viewController.presenter = self;
    [viewController resetSelection];
    return viewController;

}

@end
