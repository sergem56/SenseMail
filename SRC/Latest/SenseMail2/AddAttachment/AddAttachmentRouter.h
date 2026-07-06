//
//  AddAttachmentRouter.h
//  SenseMail2
//
//  Created by Sergey on 20.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CommonStuff.h"

@class  AddAttachmentPresenter;

@interface AddAttachmentRouter : NSObject{
    AddAttachmentPresenter* presenter;
    UINavigationController* nav;
}

@property (nonatomic, weak) id<AddAttachmentReceiver> caller;

-(void)showViewInNavController:(UINavigationController*)navigationController;
-(void)showViewInCurrentNavController:(UIViewController*)ret;
-(void)finished;

@end
