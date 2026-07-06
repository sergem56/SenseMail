//
//  CertExchangeRouter.h
//  SenseMailShare
//
//  Created by Sergey on 06.04.16.
//  Copyright © 2016 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CommonStuff.h"

@class CertExchangePresenter;
@class AddressBookEntity;

@interface CertExchangeRouter : NSObject{
    UINavigationController* nav;
}

@property (nonatomic, strong) CertExchangePresenter* presenter;

-(void)showViewInNavController:(UINavigationController*)navController forAddress:(AddressBookEntity*)addr;

@end
