//
//  GalleryInteractor.h
//  SenseMail2
//
//  Created by Sergey on 02.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonStuff.h"

@interface GalleryInteractor : NSObject <userInfoNotificationReceiver>

-(void)requestGallery;

-(void)needShowImageAtPath:(NSString*)path;

@end
