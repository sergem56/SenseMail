//
//  AddressBookRouter.h
//  SenseMail2
//
//  Created by Sergey on 09.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CommonStuff.h"

@class AddressBookPresenter;
@class AddressBookEntity;
@class AddressBookViewController;

@interface AddressBookRouter : NSObject{
    AddressBookPresenter* presenter;
    UINavigationController* nav;
}

@property (nonatomic, weak) id<CanGetAddressFromBook> caller;

-(void)showBookInNavController:(UINavigationController*)navigationController;
-(void)showGroupBook:(AddressBookViewController*)vc toGroup:(id<CanGetAddressFromBook>) callerGroup;
-(void)finished;
-(void)showAddItem:(AddressBookEntity*)item;

@end
