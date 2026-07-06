//
//  HelpViewController.h
//  SenseMail2
//
//  Created by Sergey on 04.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HelpViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIWebView* webView;
@property (nonatomic, strong) NSString* helpFile;

-(void)updateFile;

@end
