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
#import "CommonProcs.h"

@interface HelpViewController ()

@end

@implementation HelpViewController

@synthesize webView;

// webView is nil until view is shown, so update content in viewDidLoad at first run
- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *jScript = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);";

    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    WKUserContentController *wkUController = [[WKUserContentController alloc] init];
    [wkUController addUserScript:wkUScript];

    WKWebViewConfiguration *wkWebConfig = [[WKWebViewConfiguration alloc] init];
    wkWebConfig.userContentController = wkUController;
    
    //WKWebViewConfiguration* conf = [[WKWebViewConfiguration alloc] init];
    webView = [[WKWebView alloc] initWithFrame:self.view.frame configuration:wkWebConfig];
    webView.UIDelegate = self;
    webView.navigationDelegate = self;
    webView.backgroundColor = [UIColor darkGrayColor];
    [self.view addSubview:webView];
    // Constraints
    [webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    /*UILayoutGuide *margin = self.view.layoutMarginsGuide;
    [webView.topAnchor constraintEqualToAnchor:margin.topAnchor constant:0].active = YES;
    [webView.bottomAnchor constraintEqualToAnchor:margin.bottomAnchor constant:0].active = YES;
    [webView.leadingAnchor constraintEqualToAnchor:margin.leadingAnchor constant:0].active = YES;
    [webView.trailingAnchor constraintEqualToAnchor:margin.trailingAnchor constant:0].active = YES;*/
    
    // Load content
    //NSString* helpFileName = NSLocalizedString(@"helpFile",nil);
    //if (helpFileName == nil) {
    //    helpFileName = @"helpEn";
    //}
    //[webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:self.helpFile ofType:@"html"]isDirectory:NO]]];
    NSString* pathExt = [self.helpFile pathExtension];
    if ([pathExt isEqualToString:@"html"] || [pathExt isEqualToString:@""]) {
        [self updateFile];
    }else{
        [self updateOtherFile];
    }
    
    UIBarButtonItem* button0 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveFile)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeView)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:button0, flexibleItem, button2, nil]];
}

-(void)updateFile
{
    NSString *htmlFile = [[NSBundle mainBundle] pathForResource:self.helpFile ofType:@"html"];
    NSString* htmlString = [NSString stringWithContentsOfFile:htmlFile encoding:NSUTF8StringEncoding error:nil];
    //webView.scalesPageToFit = NO;
    [webView loadHTMLString:htmlString baseURL:[[NSBundle mainBundle] bundleURL]];
    
    //[webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:self.helpFile ofType:@"html"]isDirectory:NO]]];
}

-(void)updateOtherFile
{
    //[webView loadHTMLString:@"" baseURL:nil];
    
    NSURL *url = [NSURL fileURLWithPath:self.helpFile];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [webView loadRequest:request];
    //webView.scalesPageToFit = YES;
    webView.navigationDelegate = self;
}

-(void)closeView
{
    //[webView loadHTMLString:@"" baseURL:nil]; // Clear webView for next attachment
    [[[GlobalRouter sharedManager] getHelpRouter] finished];
}

-(void)saveFile
{
    NSString* res = [CommonProcs copyFileToDocs:self.helpFile];
    NSString* msg;
    if (res == nil) {
        msg = NSLocalizedString(@"Error saving file", nil);
        res = self.helpFile;
    }else{
        msg = NSLocalizedString(@"File saved to Documents", nil);
    }
    [CommonProcs showMessage:msg title:[res lastPathComponent]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


//- (void)webView:(UIWebView * _Nonnull)webView didFailLoadWithError:(NSError*)error
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    //NSLog(error.localizedDescription);
    NSString* res = [NSString stringWithFormat:@"<h1>%@<h1>/\n<h2>%@</h2>",NSLocalizedString(@"Cannot preview file",nil), [self.helpFile lastPathComponent]];
    [webView loadHTMLString:res baseURL:nil];
    //[webView loadHTMLString:NSLocalizedString(@"<h1>Cannot preview file</h1>",nil) baseURL:nil];
}


-(void)dealloc
{
    webView.navigationDelegate = nil;
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
