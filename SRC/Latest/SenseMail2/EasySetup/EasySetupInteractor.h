//
//  EasySetupInteractor.h
//  SenseMailShare
//
//  Created by Sergey on 18.05.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class EasySetupViewController;

@interface EasySetupInteractor : NSObject
{
    UINavigationController* navi;
}

@property (nonatomic, strong) EasySetupViewController* vc;

-(void)showMasterInNC:(UINavigationController*)nav;

-(void)emailEntered:(NSString*)email;

@end
