//
//  HelpViewController.m
//  SenseMail2
//
//  Created by Sergey on 04.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "HelpViewController.h"
#import "GlobalRouter.h"
#import "HelpRouter.h"

@interface HelpViewController ()

@end

@implementation HelpViewController

@synthesize webView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Load content
    //NSString* helpFileName = NSLocalizedString(@"helpFile",nil);
    //if (helpFileName == nil) {
    //    helpFileName = @"helpEn";
    //}
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:self.helpFile ofType:@"html"]isDirectory:NO]]];
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeView)];
    
    [self setToolbarItems:[NSArray arrayWithObjects: flexibleItem, button2, nil]];
}

-(void)updateFile
{
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:self.helpFile ofType:@"html"]isDirectory:NO]]];
}

-(void)closeView
{
    [[[GlobalRouter sharedManager] getHelpRouter] finished];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
