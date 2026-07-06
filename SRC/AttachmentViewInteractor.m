//
//  AttachmentViewInteractor.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "AttachmentViewInteractor.h"
#import "UserInfoDataManager.h"
#import "GlobalRouter.h"
#import "CommonProcs.h"

@implementation AttachmentViewInteractor

-(BOOL)saveImage:(UIImage *)image
{
    UIImageWriteToSavedPhotosAlbum(image, nil,nil,nil);
    return YES;
}

-(BOOL)saveImageSecure:(UIImage *)image
{
    //[CommonProcs showProgressWithTitle:1 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Saving...",nil) stopButton:NO];

    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        UserInfoDataManager* man = [[UserInfoDataManager alloc] init];
        man.receiver = self;
        [man writeImageData:image pin:[GlobalRouter sharedManager].pin];
    //});
    return YES;
}

-(void)userInfoFinishedTask:(BOOL)res
{
    //[CommonProcs showProgress:10 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    [CommonProcs hideProgress];
    
    if(res)
    {
        [CommonProcs showMessage:@"" title:NSLocalizedString(@"Image saved to secure storage",nil)];
    }else{
        [CommonProcs showMessage:@"" title:NSLocalizedString(@"Error saving image",nil)];
    }
}

@end
