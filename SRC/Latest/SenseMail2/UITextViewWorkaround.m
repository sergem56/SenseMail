//
//  UITextViewWorkaround.m
//  SenseMailShare
//
//  Created by Sergey on 05.11.2019.
//  Copyright © 2019 Sergey. All rights reserved.
//

#import "UITextViewWorkaround.h"
#import  <objc/runtime.h>
#import <UIKit/UIKit.h>


// This is a xcode 11.2 bug workaround

@implementation UITextViewWorkaround

+(void)executeWorkaround {
    if (@available(iOS 13.2, *)){
    }else{
        const char *className = "_UITextLayoutView";
        Class cls = objc_getClass(className);
        if (cls == nil) {
            cls = objc_allocateClassPair([UIView class], className, 0);
            objc_registerClassPair(cls);
#if DEBUG
            printf("added %s dynamically\n", className);
#endif
        }
    }
}

@end
