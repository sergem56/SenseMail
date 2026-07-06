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
    
}

@property (nonatomic, weak) AttachmentViewPresenter* presenter;

@property (nonatomic) IBOutlet UIImageView* image;
@property (nonatomic) IBOutlet UIScrollView* scroll;

@property (nonatomic) UIImage* attachment;

-(void)initImage;

@end
