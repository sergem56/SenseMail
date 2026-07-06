//
//  AppDelegate.h
//  SenseMail2
//
//  Created by Sergey on 05.02.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GlobalRouter.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, weak) IBOutlet GlobalRouter* router;

@end

