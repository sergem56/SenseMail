//
//  MessageInfoInteractor.m
//  SenseMailShare
//
//  Created by Sergey on 02.02.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

#import "MessageInfoInteractor.h"
#import "MessageInfoViewController.h"

@implementation MessageInfoInteractor

-(int)presentViewInNavController:(UINavigationController*)nav messageInfo:(NSString *)info
{
    if(viewController == nil)
    {
        viewController = [[MessageInfoViewController alloc] initWithNibName:@"MessageInfoViewController" bundle:nil];
    }
    
    NSMutableAttributedString* res = [[NSMutableAttributedString alloc] initWithData:[info dataUsingEncoding:NSUTF8StringEncoding]
               options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
    documentAttributes:nil error:nil];
    
    UIColor* color;
    if (@available(iOS 13.0, *)) {
        color = [UIColor labelColor];
    } else {
        // Fallback on earlier versions
        color = [UIColor blackColor];
    }
    
    [res addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, res.length)];
    
    viewController.messageInfo = res;//info;
    
    BOOL onStack = NO;
    
    for (UIViewController* item in nav.viewControllers) {
        if ([viewController isEqual:item]) {
            onStack = YES;
            break;
        }
    }
    
    if (onStack) {
        [nav popToViewController:viewController animated:YES];
    }else{
        
        @try {
            [nav pushViewController:viewController animated:YES];
        }
        @catch (NSException *exception) {
        }
    }
    
    return 1;
}
@end
