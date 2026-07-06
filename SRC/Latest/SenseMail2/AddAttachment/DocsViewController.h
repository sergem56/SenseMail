//
//  DocsViewController.h
//  SenseMailShare
//
//  Created by Sergey on 27.12.16.
//  Copyright © 2016 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuickLook/QuickLook.h>
#import "CommonStuff.h"

@interface DocsViewController : QLPreviewController <QLPreviewControllerDataSource,QLPreviewControllerDelegate, userInfoNotificationReceiver>

@property (nonatomic, strong) NSArray* items; // item path
@property (nonatomic, assign) BOOL showSaveButton;
@property (nonatomic, assign) BOOL deleteOnExit;

-(void)thumbReady:(UIImage*)thumb;

@end
