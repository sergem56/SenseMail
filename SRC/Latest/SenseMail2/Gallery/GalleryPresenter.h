//
//  GalleryPresenter.h
//  SenseMail2
//
//  Created by Sergey on 02.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GalleryCollectionViewController;

@interface GalleryPresenter : NSObject
{
    GalleryCollectionViewController* viewController;
}

-(GalleryCollectionViewController*)showGallery;
-(void)setGallery:(NSMutableDictionary*)gallery;
-(BOOL)wantToDeleteImage:(NSString*)path;
-(void)needShowImageAtPath:(NSString*)path;

@end
