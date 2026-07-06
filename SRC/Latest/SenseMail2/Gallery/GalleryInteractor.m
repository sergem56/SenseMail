//
//  GalleryInteractor.m
//  SenseMail2
//
//  Created by Sergey on 02.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "GalleryInteractor.h"
#import "UserInfoDataManager.h"
#import "GlobalRouter.h"
#import "CommonProcs.h"

@implementation GalleryInteractor

-(void)requestGallery
{
    // Load gallery async
    //[CommonProcs showProgress:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    [CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Loading...", nil) stopButton:NO];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        UserInfoDataManager* man = [[UserInfoDataManager alloc] init];
        NSMutableDictionary* ret = [man getGalleryThumbnails:[GlobalRouter sharedManager].pin];
        dispatch_async(dispatch_get_main_queue(), ^{
            // update gallery
            [[[GlobalRouter sharedManager] getGalleryRouter] galleryReady:ret];
            [CommonProcs hideProgress];
            //[CommonProcs showProgress:10 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
        });
    });
}

-(void)needShowImageAtPath:(NSString *)path
{
    //[CommonProcs showProgressWithTitle:1 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Loading...",nil) stopButton:NO];
    
    //dispatch_queue_t newQ = dispatch_queue_create("my.q", NULL);
    //dispatch_async(newQ, ^{ //dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0), ^{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        UserInfoDataManager* man = [[UserInfoDataManager alloc] init];
        man.receiver = self;
        UIImage* image = [man getFullImage:path pin:[GlobalRouter sharedManager].pin];
        if(image){
            // On main thread!
            dispatch_async(dispatch_get_main_queue(), ^{
                [[GlobalRouter sharedManager] needShowSecureImage:image];
            });
        }else{
            NSData* dt = [man getFullData:path pin:[GlobalRouter sharedManager].pin]; // Here is double decryption that was already done above...
            NSString* pth = [CommonProcs getTempPathForDoc:path.pathExtension];
            [dt writeToFile:pth atomically:NO];
            // On main thread!
            dispatch_async(dispatch_get_main_queue(), ^{
                [[GlobalRouter sharedManager] needShowAttachment:pth atIndex:0 showSaveButton:NO];
            });
        }
    });
}

-(void)userInfoFinishedTask:(BOOL)res
{
    //[CommonProcs showProgress:10 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    [CommonProcs hideProgress];
}

@end
