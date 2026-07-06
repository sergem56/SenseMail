//
//  HelpRouter.h
//  SenseMail2
//
//  Created by Sergey on 04.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class HelpViewController;

@interface HelpRouter : NSObject{
    UINavigationController* nav;
}

@property (nonatomic, strong) HelpViewController* viewController;

-(void)showHelpInNavController:(UINavigationController*)navigationController;
-(void)showHelpInNavController:(UINavigationController*)navigationController file:(NSString*)file;
-(void)finished;


@end
