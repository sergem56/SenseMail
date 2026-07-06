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
    dispatch_async(dispatch_get_main_queue(), ^{
        [presenter setGallery:gallery];
    });
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

@end
