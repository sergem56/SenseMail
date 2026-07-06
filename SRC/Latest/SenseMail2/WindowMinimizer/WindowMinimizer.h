//
//  WindowMinimizer.h
//  SenseMailShare
//
//  Created by Sergey on 10.09.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol Minimized <NSObject>
-(BOOL)checkRestore:(NSString*)toCheckAgainst;
@end

@interface WindowMinimizer : NSObject
{
    UIButton* button;
    CGRect savedRect;
}

@property (nonatomic, strong) UIViewController<Minimized>* minimizedVC;

-(void)minimizeWindow:(UIViewController<Minimized>*) toMinimize;
-(void)minimizeWindow:(UIViewController<Minimized>*)toMinimize animated:(BOOL)animated;
-(BOOL)showIfExistsMinimized;
-(void)removeMinimizer;

@end
