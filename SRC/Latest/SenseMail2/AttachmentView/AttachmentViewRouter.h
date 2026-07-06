//
//  AttachmentViewRouter.h
//  SenseMail2
//
//  Created by Sergey on 03.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AttachmentViewPresenter;

@interface AttachmentViewRouter : NSObject{
    AttachmentViewPresenter* presenter;
    UINavigationController* nav;
}

-(void)showAttachmentInNavController:(UINavigationController*)navigationController :(UIImage*)att;
-(void)showAttachmentInNavController:(UINavigationController*)navigationController :(UIImage*)att secure:(BOOL)secure;
-(void)finished;

@end
