//
//  WindowMinimizer.m
//  SenseMailShare
//
//  Created by Sergey on 10.09.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

#import "WindowMinimizer.h"
#import "GlobalRouter.h"
#import "Encryptor.h"

@implementation WindowMinimizer{
    int tbH;
}

-(id)init
{
    if (self = [super init]) {
        tbH = [[GlobalRouter sharedManager] getDetailNavController].toolbar.frame.size.height + 60;
        if (@available(iOS 11.0, *)) {
            UIWindow *window = UIApplication.sharedApplication.keyWindow;
            tbH += window.safeAreaInsets.bottom;
        }
        if (tbH == 0) {
            tbH = 100;
        }
        button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button addTarget:self action:@selector(restoreVC:) forControlEvents:UIControlEventTouchUpInside];
        [button setImage:[UIImage imageNamed:@"writeMail"] forState:UIControlStateNormal];
        UIViewController* rootVC = [[GlobalRouter sharedManager] getRootVC];
        button.frame = CGRectMake(rootVC.view.frame.size.width-75, rootVC.view.frame.size.height-tbH, 60.0, 60.0);
        [rootVC.view addSubview:button];
        button.tag = 888888;
        button.hidden = YES;
        
        button.translatesAutoresizingMaskIntoConstraints = false;
        
        // Ancors are available since iOS 9, but anyway we are aiming at iOS 9 at least
        if(@available(iOS 9,*)){
            [button.widthAnchor constraintEqualToConstant:60].active = YES;
            [button.heightAnchor constraintEqualToConstant:60].active = YES;
            [button.rightAnchor constraintEqualToAnchor:rootVC.view.rightAnchor constant:-15].active = YES;
            [button.topAnchor constraintEqualToAnchor:rootVC.view.bottomAnchor constant:-tbH].active = YES;
        }
    }
    
    //NSLog(@"Toolbar height %d", tbH);
    return self;
}

-(void)minimizeWindow:(UIViewController<Minimized>*)toMinimize
{
    [self minimizeWindow:toMinimize animated:YES];
}

-(void)minimizeWindow:(UIViewController<Minimized>*)toMinimize animated:(BOOL)animated
{
    // Add a floating button
    // Hide VC
    // Store VC
    
    self.minimizedVC = toMinimize;
    if (toMinimize.view.frame.size.height == 60) {
        // already minimized
        savedRect = [[GlobalRouter sharedManager] getDetailNavController].view.frame;
    }else{
        savedRect = toMinimize.view.frame;
    }
    
    // Begin animation block
    UIView *thisViewTemp = toMinimize.view;
    
    // Add this view to the parent ViewControllers View
    [[[GlobalRouter sharedManager] getRootVC].view addSubview:thisViewTemp];
    
    // Pop the VC
    [[GlobalRouter sharedManager] finishedWithDetailView:NO]; //finishedWithCurrentView:NO];
    if(animated){
        CGRect moveTo = CGRectMake(button.frame.origin.x, button.frame.origin.y, 60, 60);
        //NSLog(@"%fx%f",moveTo.origin.x, moveTo.origin.y);
        
        thisViewTemp.layer.masksToBounds = NO;
        [thisViewTemp.layer setShadowColor:[UIColor grayColor].CGColor];
        [thisViewTemp.layer setShadowOpacity:0.5];
        [thisViewTemp.layer setShadowOffset:CGSizeMake(3, 3)];
        
        [UIView animateWithDuration:0.25 delay:0 options: UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             thisViewTemp.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.8, 0.8);
                         }
                         completion:^(BOOL fin){
                             if (fin) {
                             }
                         }];
        
        __weak __typeof__(self) weakSelf = self;
        [UIView animateWithDuration:0.35 delay:0.2 options: UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             thisViewTemp.frame = moveTo;
                             thisViewTemp.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.2, 0.2);
                         }
                         completion:^(BOOL fin){
                             if (fin) {
                                 __strong __typeof__(self) strongSelf = weakSelf;
                                 // finally display the new viewcontroller for real
                                 [thisViewTemp removeFromSuperview];
                                 strongSelf->button.hidden = NO;
                             }
                         }];
    }else{
        [toMinimize.view removeFromSuperview];
        button.hidden = NO;
        // Set the size and position of the window to get smooth restoration
        CGRect moveTo = CGRectMake(button.frame.origin.x, button.frame.origin.y, 60, 60);
        [toMinimize.view setFrame:moveTo];
    }
    /*
    CGRect moveTo = CGRectMake(button.frame.origin.x, button.frame.origin.y, 60, 60);
    [UIView animateWithDuration:0.4 animations:^{
        [toMinimize.view setFrame:moveTo];
        [[GlobalRouter sharedManager] finishedWithCurrentView:NO];
    }];
    */
}

-(void)restoreVC:(id)sender
{
    [button removeFromSuperview];
    button = nil;
    
    // On iPad and iOS 13+ the minimizedVC is getting null'ed somehow, so putting it in the temp var makes it OK
    UIViewController* toRestore = self.minimizedVC;
    
    //if ([[GlobalRouter sharedManager] getTopViewController] == self.minimizedVC) {
    //    return;
    //}
    
    if (![self.minimizedVC checkRestore:[Encryptor getSlowHashForString:[GlobalRouter sharedManager].pin]]) {
        return;
    }
    /*
    [UIView animateWithDuration:0.4 animations:^{
        [self.minimizedVC.view setFrame:self->savedRect];
    }];
    [[[GlobalRouter sharedManager]getDetailNavController] pushViewController:self.minimizedVC animated:NO];
    self.minimizedVC = nil;
     */
    
    // Begin animation block
    UIView *thisViewTemp = self.minimizedVC.view;
    
    // Add this view to the parent ViewControllers View
    [[[GlobalRouter sharedManager] getRootVC].view addSubview:thisViewTemp];
    
    thisViewTemp.layer.masksToBounds = NO;
    [thisViewTemp.layer setShadowColor:[UIColor grayColor].CGColor];
    [thisViewTemp.layer setShadowOpacity:0.5];
    [thisViewTemp.layer setShadowOffset:CGSizeMake(3, 3)];
    
    /*
    [UIView animateWithDuration:0.25 delay:0 options: UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         thisViewTemp.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.6, 0.6);
                     }
                     completion:^(BOOL fin){
                         if (fin) {
                         }
                     }];*/
    
    __weak __typeof__(self) weakSelf = self;
    [UIView animateWithDuration:0.15 delay:0.20 options: UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         __strong __typeof__(self) strongSelf = weakSelf;
                         thisViewTemp.frame = strongSelf->savedRect;
                         thisViewTemp.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.0, 1.0);
                     }
                     completion:^(BOOL fin){
                         //if (fin) {
                         // CHECK if it's already there
                         BOOL onStack = NO;
                         
                         for (UIViewController* item in [[GlobalRouter sharedManager]getDetailNavController].viewControllers) {
                             if ([/*self.minimizedVC*/toRestore isEqual:item]) {
                                 onStack = YES;
                                 break;
                             }
                         }
                         
                         if (onStack) {
                             [[[GlobalRouter sharedManager]getDetailNavController] popToViewController:/*self.minimizedVC*/toRestore animated:NO];
                             self.minimizedVC = nil;
                         }else{
                             
                             @try {
                                 [[[GlobalRouter sharedManager]getDetailNavController] pushViewController:/*self.minimizedVC*/toRestore animated:NO];
                                 self.minimizedVC = nil;
                             }
                             @catch (NSException *exception) {
                             }
                         }
                             // finally display the new viewcontroller for real
                             //[[[GlobalRouter sharedManager]getDetailNavController] pushViewController:self.minimizedVC animated:NO];
                             
                         //}
                     }];
    
}

-(BOOL)showIfExistsMinimized
{
    BOOL ret = NO;
    if (button != nil) {
        [self restoreVC:nil];
        ret = YES;
    }
    
    return ret;
}

-(void)removeMinimizer
{
    [button removeFromSuperview];
    button = nil;
    self.minimizedVC = nil;
}

@end
