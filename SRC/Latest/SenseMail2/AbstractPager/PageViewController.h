//
//  PageSettingsViewController.h
//  SenseMailShare
//
//  Created by Sergey on 07.07.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PageViewController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic, retain) NSMutableArray* viewControllersT;
@property (nonatomic, retain) UIPageViewController* pageController;
//@property (nonatomic, retain) IBOutlet UIPageControl* pageControl;

-(void)reset;
-(void)delayToNo;

@end
