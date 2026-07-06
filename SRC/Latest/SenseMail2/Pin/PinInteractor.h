//
//  PinInteractor.h
//  SenseMailShare
//
//  Created by Sergey on 29/03/2019.
//  Copyright © 2019 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PinViewController;

@interface PinInteractor : NSObject
{
    PinViewController* vc;
}

-(void)showDialogWithTitle:(NSString*)title message:(NSString*)message okBlock:(void(^)(void))okBlock;

-(void)cancelPinDialog;

@end

NS_ASSUME_NONNULL_END
