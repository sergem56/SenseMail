//
//  GalleryPresenter.m
//  SenseMail2
//
//  Created by Sergey on 02.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "GalleryPresenter.h"
#import "GalleryCollectionViewController.h"
#import "GlobalRouter.h"
#import "CommonProcs.h"

@implementation GalleryPresenter

-(GalleryCollectionViewController*)showGallery
{
    
    if(viewController == nil)
    {
        viewController = [[GalleryCollectionViewController alloc] initWithNibName:@"GalleryCollectionViewController" bundle:nil];
    }
    
    viewController.presenter = self;
    
    return viewController;
}

-(void)setGallery:(NSMutableDictionary*)gallery
{
    [CommonProcs hideProgress];
    viewController.items = gallery;
    [viewController.collectionView reloadData];
}

-(BOOL)wantToDeleteImage:(NSString *)path
{
    return [[[GlobalRouter sharedManager] getGalleryRouter] needToDeleteImage:path];
}

-(void)needShowImageAtPath:(NSString *)path
{
    [[[GlobalRouter sharedManager] getGalleryRouter] showImageAtPath:path];
    //[[[GlobalRouter sharedManager] getGalleryRouter] performSelectorInBackground:@selector(showImageAtPath:) withObject:path];
    //[[GlobalRouter sharedManager] needShowSecureImage:path];
}

@end
