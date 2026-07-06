//
//  PageSettingsViewController.m
//  SenseMailShare
//
//  Created by Sergey on 07.07.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "PageViewController.h"
#import "GlobalRouter.h"
#import "SettingsViewController.h"

@interface PageViewController ()

@end

@implementation PageViewController

@synthesize viewControllersT, pageController;

-(id)init
{
    if (self = [super init]) {
        pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    }
    
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    if(previousTraitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        NSLog(@"User has rotated to landscape");
    }else if(previousTraitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        NSLog(@"User has rotated to portrait");
    }
    
    self.pageController.view.frame = CGRectMake(0, 0, self.view.frame.size.width,  self.view.frame.size.height - self.navigationController.navigationBar.frame.size.height+10);
}

/*
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    if (fromInterfaceOrientation == UIInterfaceOrientationLandscapeLeft || fromInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
        self.pageController.view.frame = CGRectMake(0, 0, self.view.frame.size.width,  self.view.frame.size.height - self.navigationController.navigationBar.frame.size.height+10);
    }else{
        self.pageController.view.frame = CGRectMake(0, 0, self.view.frame.size.width,  self.view.frame.size.height - self.navigationController.navigationBar.frame.size.height+10);
    }
}
*/

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        // Fallback on earlier versions
        self.view.backgroundColor = [UIColor whiteColor];
    }
    
    self.pageController.view.frame = CGRectMake(0, 0, self.view.frame.size.width,  self.view.frame.size.height - self.navigationController.navigationBar.frame.size.height+10);
    self.pageController.dataSource = self;
    self.pageController.delegate = self;
    
    UIPageControl *pageControl1 = [UIPageControl appearance];
    pageControl1.pageIndicatorTintColor = [UIColor lightGrayColor];
    pageControl1.currentPageIndicatorTintColor = [UIColor blueColor];
    //pageControl1.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"settingsBg"]];// [UIColor whiteColor];
    
    [self addChildViewController:self.pageController];
    [[self view] addSubview:[self.pageController view]];
    [self.pageController didMoveToParentViewController:self];
    self.pageController.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"settingsBg"]];
    
}

-(void)delayToNo
{
    for (UIView *view in self.pageController.view.subviews) {
        if ([view isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)view;
            scrollView.delaysContentTouches = NO;
            //scrollView.canCancelContentTouches = NO;
        }
    }
    //pageController.dataSource = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController
                   spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    pageController.doubleSided = NO;
    return UIPageViewControllerSpineLocationMin;
}


- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSInteger i = [viewControllersT indexOfObject:viewController];
    if (i == NSNotFound) {
        return nil;
    }
    if (i > 0){
        i = i - 1;
        //pageControl.currentPage = i+1;
        return viewControllersT[i];
    }else{
        //pageControl.currentPage = i;
    }
    return nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSInteger i = [viewControllersT indexOfObject:viewController];
    if (i < ([viewControllersT count] - 1)){
        i = i + 1;
        //pageControl.currentPage = i-1;
        return viewControllersT[i];
    }else{
        //pageControl.currentPage = i;
    }
    return nil;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    //pageControl.numberOfPages = viewControllers.count;
    return viewControllersT.count;
    
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    NSInteger ind = [viewControllersT indexOfObject:[pageViewController.viewControllers lastObject]];
    if (ind == NSNotFound) {
        ind = 0;
    }
    return ind;
    //return 0;//pageControl.currentPage;
    
}

-(void)reset
{
    pageController.dataSource = nil;
    pageController.dataSource = self;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
