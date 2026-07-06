//
//  AttachmentViewController.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AttachmentViewPresenter;

@interface AttachmentViewController : UIViewController <UIScrollViewDelegate>{
    float nonZoomed;
}

@property (nonatomic, weak) AttachmentViewPresenter* presenter;

@property (nonatomic, weak) IBOutlet UIImageView* image;
@property (nonatomic, weak) IBOutlet UIScrollView* scroll;

@property (nonatomic) UIImage* attachment;
@property (nonatomic, assign) BOOL isSecure;

-(void)initImage;

@end
