//
//  FloatingToolbar.h
//  SenseMailShare
//
//  Created by Sergey on 07.05.2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FloatingToolbar : UIView
{
    int currentColorIndex;
    int foreColorIndex;
    NSArray* colors;
    NSArray* colorValues;
}

@property (nonatomic, strong) WKWebView* wView;

-(void)addToolbarToView:(UIView*)toView withWebView:(WKWebView*)wkView topOffset:(float)topOffset;

@end

NS_ASSUME_NONNULL_END
