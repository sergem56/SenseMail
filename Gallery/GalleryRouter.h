//
//  GalleryRouter.h
//  SenseMail2
//
//  Created by Sergey on 02.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class GalleryPresenter;
@class GalleryInteractor;

@interface GalleryRouter : NSObject{
    GalleryPresenter* presenter;
    GalleryInteractor* interactor;
}

-(void)openGalleryInNavController:(UINavigationController*)vc;
-(void)galleryReady:(NSMutableDictionary*)gallery;

-(BOOL)needToDeleteImage:(NSString*)path;

-(void)showImageAtPath:(NSString*)path;

@end
