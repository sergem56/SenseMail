//
//  GalleryRouter.m
//  SenseMail2
//
//  Created by Sergey on 02.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "GalleryRouter.h"
#import "GalleryPresenter.h"
#import "GalleryInteractor.h"
#import "UserInfoDataManager.h"
#import "GalleryCollectionViewController.h"
#import "GlobalRouter.h"

@implementation GalleryRouter

-(id)init
{
    if (self = [super init]) {
        presenter = [[GalleryPresenter alloc] init];
        interactor = [[GalleryInteractor alloc] init];
    }
    return self;
}

-(void)openGalleryInNavController:(UINavigationController*)vc
{
    UIViewController* ret = (UIViewController*)[presenter showGallery];
    if (self.caller) {
        ((GalleryCollectionViewController*)ret).caller = self.caller;
        ((GalleryCollectionViewController*)ret).collectionView.allowsMultipleSelection = YES;
    }
    
    @try {
        dispatch_async(dispatch_get_main_queue(), ^{
            [vc pushViewController:ret animated:YES];
        });
        [interactor requestGallery];
    }
    @catch (NSException *exception) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [vc popToViewController:ret animated:YES];
        });
    }
}

-(void)galleryReady:(NSMutableDictionary *)gallery
{
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [strongSelf->presenter setGallery:gallery];
    });
}

-(void)reloadGallery
{
    [interactor requestGallery];
}

-(BOOL)needToDeleteImage:(NSString *)path
{
    UserInfoDataManager* man = [[UserInfoDataManager alloc] init];
    return [man deleteImage:path];
}

-(void)showImageAtPath:(NSString *)path
{
    [interactor needShowImageAtPath:path];
}

-(void)finished
{
    [[GlobalRouter sharedManager] finishedWithDetailView:YES];
    self.caller = nil;
}

@end
