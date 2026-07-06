//
//  AttachmentViewPresenter.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AttachmentViewController;

@interface AttachmentViewPresenter : NSObject{
    AttachmentViewController* viewController;
}

-(AttachmentViewController*)showAttachment:(UIImage*)att;
-(BOOL)needSaveImage:(UIImage*)image;
-(BOOL)needSaveImageSecure:(UIImage*)image;

@end
