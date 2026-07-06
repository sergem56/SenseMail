//
//  PinInteractor.m
//  SenseMailShare
//
//  Created by Sergey on 29/03/2019.
//  Copyright © 2019 Sergey. All rights reserved.
//

#import "PinInteractor.h"
#import "PinViewController.h"
#import "GlobalRouter.h"

@implementation PinInteractor

-(void)showDialogWithTitle:(NSString*)title message:(NSString*)message okBlock:(void(^)(void))okBlock
{
    vc = [[PinViewController alloc] initWithNibName:@"PinViewController" bundle:nil];
    
    vc.okBlock = [okBlock copy];
    vc.titleText = title;
    vc.subTitleText = message;
    //[vc setupBioID];
    UINavigationController* navc = [[GlobalRouter sharedManager] getDetailNavController];
    // Check if a view in a view hierarchy. What if we are in a BG mode?
    if (navc.view.window) {
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        //vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [navc presentViewController:vc animated:YES completion:^{
            NSLog(@"PIN presented");
        }];
    }else{
        okBlock();
    }
}

-(void)cancelPinDialog
{
    __weak __typeof__(self) weakSelf = self;
    if(vc){
        __strong __typeof__(self) strongSelf = weakSelf;
        [vc dismissViewControllerAnimated:NO completion:^{
            strongSelf->vc = nil;
        }];
        //[[GlobalRouter sharedManager] cancelPinDialog];
    }
}

@end
