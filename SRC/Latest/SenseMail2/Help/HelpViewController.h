//
//  HelpViewController.h
//  SenseMail2
//
//  Created by Sergey on 04.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h> //WKWebView starts from iOS 11. before need to create it in code

@interface HelpViewController : UIViewController <WKNavigationDelegate, WKUIDelegate>

@property (nonatomic, strong) IBOutlet WKWebView* webView;
@property (nonatomic, strong) NSString* helpFile;

-(void)updateFile;
-(void)updateOtherFile;

@end
