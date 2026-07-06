//
//  AttachmentViewInteractor.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CommonStuff.h"

@interface AttachmentViewInteractor : NSObject <userInfoNotificationReceiver>

-(BOOL)saveImage:(UIImage*)image;
-(BOOL)saveImageSecure:(UIImage*)image;

@end
