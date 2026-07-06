//
//  MessageViewController.m
//  SenseMail2
//
//  Created by Sergey on 30.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "MessageViewController.h"
#import "GlobalRouter.h"
#import "MessageViewPresenter.h"
#import "CommonProcs.h"
#import "AppDelegate.h"

@interface MessageViewController ()

@end

@implementation MessageViewController

@synthesize currentMessage, viewInScrollWidthConstraint, presenter, scroll, subjLabel,textWidthConstraint, textHeightConstraint;
@synthesize viewInScroll, attScrollWidthConstraint;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //[self updateMessageView];
    
    //scroll.translatesAutoresizingMaskIntoConstraints  = NO;
    //viewInScroll.translatesAutoresizingMaskIntoConstraints = NO;
    
    /*
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    UIView *contentView;
    contentView = [[UIView alloc] initWithFrame:CGRectMake(0,0,screenWidth,screenHeight)];
    [scroll addSubview:contentView];
    
    // DON'T change contentView's translatesAutoresizingMaskIntoConstraints,
    // which defaults to YES;
    
    // Set the content size of the scroll view to match the size of the content view:
    [scroll setContentSize:CGSizeMake(screenWidth,screenHeight)];
    
    */
    /*
    [viewInScroll setFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    
    scroll.contentSize = CGSizeMake(self.view.frame.size.width, screenHeight>screenWidth?screenHeight:screenWidth);
    
    CGSize sz = [viewInScroll systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    [viewInScroll setFrame:CGRectMake(0, 0, sz.width, sz.height)];
    [scroll setContentSize:sz];
     
     */
    
    //UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(scale:)];
    //[pinchRecognizer setDelegate:self];
    //[self.view addGestureRecognizer:pinchRecognizer];
    
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
    
    /*topTextConstraint = [NSLayoutConstraint constraintWithItem:text
                                            attribute:NSLayoutAttributeTop
                                            relatedBy:NSLayoutRelationEqual
                                            toItem:subjLabel
                                            attribute:NSLayoutAttributeBottom
                                            multiplier:1.0
                                            constant:80];
     */
    
    //self.automaticallyAdjustsScrollViewInsets = NO;
    
    // Expand from and to addresses since sometimes I want to see to which account the message
    // was sent
    UITapGestureRecognizer* fromTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fromTapped:)];
    UILabel *fromAddrLbl = (UILabel *)[self.view viewWithTag:2];
    [fromAddrLbl addGestureRecognizer:fromTap];
    fromExpanded = NO;
    
    // Migrate to WKWebView
    //self.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSString *jScript = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width');meta.setAttribute('minimum-scale', '0.5'); meta.setAttribute('user-scalable', 'yes'); document.getElementsByTagName('head')[0].appendChild(meta);";

    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    WKUserContentController *wkUController = [[WKUserContentController alloc] init];
    [wkUController addUserScript:wkUScript];

    WKWebViewConfiguration *wkWebConfig = [[WKWebViewConfiguration alloc] init];
    wkWebConfig.userContentController = wkUController;
    wkWebConfig.ignoresViewportScaleLimits = YES;
    
    int pos = self.attScroll.frame.origin.y+self.attScroll.frame.size.height+16;
    self.textWK = [[WKWebView alloc] initWithFrame:CGRectMake(0, pos, self.view.frame.size.width, self.view.frame.size.height-pos-40) configuration:wkWebConfig];
    self.textWK.UIDelegate = self;
    self.textWK.navigationDelegate = self;
    
    if (@available(iOS 13.0, *)) {
        self.textWK.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        // Fallback on earlier versions
        self.textWK.backgroundColor = [UIColor whiteColor];
    }
    
    //[self.text removeFromSuperview];
    /*
    [self.textWK loadHTMLString:@"<head><style type=\"text/css\">\
    @media (prefers-color-scheme: dark) {\
        body {\
            background-color: rgb(20,20,20);\
            color: white;\
        }\
        a:link {\
            color: #0096e2;\
        }\
        a:visited {\
            color: #9d57df;\
        }\
     }</head>" baseURL:nil];*/
    
    [self.viewInScroll addSubview:self.textWK];
    // Constraints
    //[self.textWK setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
     NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.textWK
                                            attribute:NSLayoutAttributeTop
                                            relatedBy:0
                                            toItem:self.attScroll
                                            attribute:NSLayoutAttributeBottom
                                            multiplier:1.0
                                            constant:3];
    [self.view addConstraint:topConstraint];
    self.textWK.scrollView.bounces = NO;
    self.textWK.scrollView.minimumZoomScale = 0.5;
    //self.textWK.scrollView.scrollEnabled = NO;
    self.textWK.exclusiveTouch = NO;
    self.textWK.contentMode = UIViewContentModeScaleToFill;
    
    //self.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.textWK.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.textWK
                                    attribute:NSLayoutAttributeLeading
                                    relatedBy:0
                                    toItem:self.view
                                    attribute:NSLayoutAttributeLeading
                                    multiplier:1.0
                                    constant:0];
    [self.view addConstraint:leftConstraint];
    
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.textWK
                                            attribute:NSLayoutAttributeTrailing
                                            relatedBy:0
                                            toItem:self.view
                                            attribute:NSLayoutAttributeTrailing
                                            multiplier:1.0
                                            constant:0];
    [self.view addConstraint:rightConstraint];
    
    self.heightConstraint = [NSLayoutConstraint constraintWithItem:self.textWK
                                            attribute:NSLayoutAttributeHeight
                                            relatedBy:NSLayoutRelationEqual
                                            toItem:nil
                                            attribute:NSLayoutAttributeNotAnAttribute
                                            multiplier:1.0
                                            constant:300];
    [self.textWK addConstraint:self.heightConstraint];
    
    viewInScrollWidthConstraint.constant = self.view.frame.size.width;
    
    //[self.textWK setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    /*UILayoutGuide *margin = self.view.layoutMarginsGuide;
    [self.textWK.topAnchor constraintEqualToAnchor:margin.topAnchor constant:0].active = YES;
    [self.textWK.bottomAnchor constraintEqualToAnchor:margin.bottomAnchor constant:0].active = YES;
    [self.textWK.leadingAnchor constraintEqualToAnchor:margin.leadingAnchor constant:0].active = YES;
    [self.textWK.trailingAnchor constraintEqualToAnchor:margin.trailingAnchor constant:0].active = YES;*/
    //[self.view layoutSubviews];
}

-(void)fromTapped:(id)sender
{
    UILabel *fromAddrLbl = (UILabel *)[self.view viewWithTag:2];
    if (!(currentMessage.fromName && currentMessage.fromAddress)) {
        [fromAddrLbl setText:@""];
    }else{
        fromExpanded = !fromExpanded;
        if(fromExpanded){
            [fromAddrLbl setText:[NSString stringWithFormat:@"from: %@ (%@)\nto: %@\nreply-to: %@\nsize: %@", currentMessage.fromName, currentMessage.fromAddress, currentMessage.toAddress, currentMessage.replyToAddress, [CommonProcs getSizeRep:currentMessage.size]]];
        }else{
            [fromAddrLbl setText:[NSString stringWithFormat:@"%@ (%@)", currentMessage.fromName, currentMessage.fromAddress]];
        }
    }
}

/*
- (void)viewDidLayoutSubviews {
    
    [super viewDidLayoutSubviews];
    
    if (finishedLoading) {
        //return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        //[self adjustWebView];
    });
    
}
*/

//- (void)webViewDidFinishLoad:(UIWebView *)aWebView
- (void)webView:(WKWebView *)aWebView didFinishNavigation:(WKNavigation *)navigation
{
    [self adjustWebView];
    return;
}

//-(BOOL)webView:(UIWebView*)webView shouldStartLoadWithRequest:(nonnull NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (navigationAction.navigationType == UIWebViewNavigationTypeLinkClicked) {
        // Open with Safary?
        [self.presenter wantOpenURL:navigationAction.request];
        decisionHandler(WKNavigationActionPolicyCancel);
        //return NO;
    }else{
        //return YES;
        decisionHandler(WKNavigationActionPolicyAllow);
    }
    //decisionHandler(WKNavigationActionPolicyCancel);
}

-(void)adjustWebView
{
    [self adjustWebViewSetWidthScale:NO];
}

-(void)adjustWebViewSetWidthScale:(BOOL)forceScale
{
    //return;
    //[self.scroll setContentSize:CGSizeZero];
    // I use mainscreen since self.view had somehow zero width... I've change the view hierarchy after that as self.view was a scroll view and I put it inside a UIView
    viewInScrollWidthConstraint.constant = self.view.frame.size.width;// [[UIScreen mainScreen] bounds].size.width;//self.view.frame.size.width;
    
    [self.textWK evaluateJavaScript:@"document.readyState" completionHandler:^(id _Nullable complete, NSError * _Nullable error) {
        if(complete){
            
            /*
            NSString *jsCommand = [NSString stringWithFormat:@"document.body.style.zoom = 0.9;"];
            [self.textWK evaluateJavaScript:jsCommand completionHandler:^(NSString *result, NSError *error) {
                if(error != nil) {
                    NSLog(@"Error: %@",error);
                    //return;
                }else
                    NSLog(@" Success");
            }];*/
            
            //[self.textWK setFrame:CGRectMake(self.textWK.frame.origin.x, self.textWK.frame.origin.y, [[UIScreen mainScreen] bounds].size.width,1)];
            
            // Do this since some emails not shown the right width. For example, yahoo info mails are zoomed too much
            __weak typeof(self) weakSelf = self;
            [self.textWK evaluateJavaScript:@"document.body.scrollWidth" completionHandler:^(NSNumber* _Nullable width, NSError * _Nullable error) {
                //NSLog(@"Evaluated height = %ld", (long)height.integerValue);
                long wd = width.intValue;
                int wdFullScreen = [[UIScreen mainScreen] bounds].size.width - self.textWK.frame.origin.x*2;
                //NSLog(@"Frame size %ld/%d", wd,wdFullScreen);
                float zoom = (float)wdFullScreen/(float)wd;
                if(forceScale || ( /*zoom != 1 &&*/ zoom != 0)){
                    NSString *jsZCommand;
                    if (zoom >= 10000 /*test*/) {
                        // setting % for width and height makes everything OK, but some mails are still wider that the screen. Setting just the float makes it look OK, but the other mails that look good with % are too narrow with float. So, I made two for zoom in and out.
                        jsZCommand = [NSString stringWithFormat: @"document.body.style.transform = 'scale(%f)'; document.body.style.webkitTransform = 'scale(%f)'; document.body.style.transformOrigin = 'top left'; document.body.style.width = %f%%;document.body.style.height = %f%%;", zoom, zoom, zoom*100, zoom*100];
                    }else{ // This one (no width and fake float height) makes the least harmful bug - empty space after the page when rotated...
                        jsZCommand = [NSString stringWithFormat: @"document.body.style.transform = 'scale(%f)'; document.body.style.webkitTransform = 'scale(%f)'; document.body.style.transformOrigin = 'top left';  document.body.style.height = %f;", zoom, zoom, zoom/*, zoom*/];//document.body.style.width = %f;
                    }
                    [self.textWK evaluateJavaScript:jsZCommand completionHandler:^(NSString *result, NSError *error) {
                        /*
                        if(error != nil) {
                            NSLog(@"Error: %@",error);
                            //return;
                        }else{
                            NSLog(@" Success");
                        }*/
                    }];
                }
                __strong typeof(self) strongSelf = weakSelf;
                strongSelf->currentZoom = zoom;
                
                [self.textWK evaluateJavaScript:@"document.body.scrollHeight" completionHandler:^(NSNumber* _Nullable height, NSError * _Nullable error) {
                    //NSLog(@"Evaluated height = %ld", (long)height.integerValue);
                    long ht = height.intValue;
                    int htFullScreen = [[UIScreen mainScreen] bounds].size.height - self.textWK.frame.origin.y;
                    if (ht < htFullScreen) {
                        ht = htFullScreen;
                    }
                    [self.scroll setContentSize: CGSizeMake([[UIScreen mainScreen] bounds].size.width, ht+self.textWK.frame.origin.y)];
                    
                    self.heightConstraint.constant = ht+12;
                    [self.textWK setFrame:CGRectMake(self.textWK.frame.origin.x, self.textWK.frame.origin.y, [[UIScreen mainScreen] bounds].size.width,ht+12)];
                    self.viewInScrollHeightConstraint.constant = ht+self.textWK.frame.origin.y+12+48;
                    
                    //NSLog(@"Frame set to %f,%f,%f", self.textWK.frame.size.height, self.viewInScroll.frame.size.height, self.textWK.frame.size.width);
                    
                    
                }];
                
            }];
            
            [CommonProcs hideSmallWheel];
            
            /*
             // This one does not reduce the height once it was set. It can only increase it.
            [self.scroll setContentSize:CGSizeMake(self.textWK.scrollView.contentSize.width, self.textWK.scrollView.contentSize.height+self.textWK.frame.origin.y)];// self.textWK.scrollView.contentSize];
            
            [self.textWK setFrame:CGRectMake(self.textWK.frame.origin.x, self.textWK.frame.origin.y, self.textWK.frame.size.width, self.textWK.scrollView.contentSize.height)];*/
        }else{
            [self.textWK evaluateJavaScript:@"document.body.scrollHeight" completionHandler:^(NSNumber* _Nullable height, NSError * _Nullable error) {
                //NSLog(@"Evaluated height = %ld", (long)height.integerValue);
                long ht = height.intValue;
                int htFullScreen = [[UIScreen mainScreen] bounds].size.height - self.textWK.frame.origin.y;
                if (ht < htFullScreen) {
                    ht = htFullScreen;
                }
                [self.scroll setContentSize: CGSizeMake([[UIScreen mainScreen] bounds].size.width, ht+self.textWK.frame.origin.y)];
                
                self.heightConstraint.constant = ht+12;
                [self.textWK setFrame:CGRectMake(self.textWK.frame.origin.x, self.textWK.frame.origin.y, [[UIScreen mainScreen] bounds].size.width,ht+12)];
                self.viewInScrollHeightConstraint.constant = ht+self.textWK.frame.origin.y+12+48;
            }];
        }
    }];
    return;
}

-(void)updateMessageView
{
    if (currentMessage == nil) {
        currentMessage = [[FullMessageEntity alloc] init];
        //return;
    }
    
    if (currentMessage.flags & mfNew) {
        self.presenter.needToSendRR = YES;
    }else{
        self.presenter.needToSendRR = NO;
    }
    // remove new flag
    currentMessage.flags &= ~mfNew;
    
    finishedLoading = NO;
    
    UILabel *fromLbl = (UILabel *)[self.view viewWithTag:1];
    [fromLbl setText:currentMessage.subject];
    //[fromLbl setText:currentMessage.fromName];
    
    UILabel *fromAddrLbl = (UILabel *)[self.view viewWithTag:2];
    if (!currentMessage.fromName && !currentMessage.fromAddress) {
        [fromAddrLbl setText:@""];
    }else{
        if(currentMessage.fromName){
            [fromAddrLbl setText:[NSString stringWithFormat:@"%@ (%@)", currentMessage.fromName, currentMessage.fromAddress]];
        }else{
            [fromAddrLbl setText:[NSString stringWithFormat:@"%@", currentMessage.fromAddress]];
        }
    }
    //[fromAddrLbl setText:currentMessage.fromAddress];
    
    UIButton* addButton = (UIButton *)[self.view viewWithTag:101];
    addButton.hidden = [fromAddrLbl.text isEqualToString:@""];

    UILabel *dateLbl = (UILabel *)[self.view viewWithTag:3];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    //[dateFormatter setDateFormat:@"dd.MM.YY HH:mm"];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    NSString *dateString = [dateFormatter stringFromDate:currentMessage.date];
    [dateLbl setText:dateString];
    
    /*
    UILabel *subjLbl = (UILabel *)[self.view viewWithTag:4];
    [subjLbl setText:currentMessage.subject];
     */
    //[subjLbl sizeToFit];
    
    //UILabel* subj = (UILabel*)[self.view viewWithTag:4];
    //CGFloat hgt = subj.frame.size.height;
    
    UIButton *star = (UIButton*)[self.view viewWithTag:5];
    if (currentMessage.flags & mfFavourite) {
        [star setImage:[UIImage imageNamed:@"starYellow"] forState:UIControlStateNormal];
    }else{
        UIImage* strL = [UIImage imageNamed:@"starLight"];
        [star setImage:strL forState:UIControlStateNormal];
    }
    
    self.fontSize = 14;
    
    //[text setText:currentMessage.messageBody];
    NSString* body = currentMessage.messageBody;
    BOOL isPlain = !([body containsString:@"text/html"] || [body containsString:@"/>"]);
    
    if(body != nil){
        // Show encrypted messages as html as well
        if (/*currentMessage.encType != enTypeNone ||*/ isPlain) {
            // Set font since it's a plaintext and the font is shit
            body = [NSString stringWithFormat:@"<head><style type=\"text/css\">\
            @media (prefers-color-scheme: dark) {\
                body {\
                    background-color: rgb(20,20,20);\
                    color: white;\
                }\
                a:link {\
                    color: #0096e2;\
                }\
                a:visited {\
                    color: #9d57df;\
                }\
            }</head>\
            </style><span style=\"font-family: %@; font-size: %i; -webkit-hyphens:auto;\">%@</span>",
                          @"Helvetica",
                          14,
                          body];
            
            //body = [body stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
            //text.scalesPageToFit = NO;
        }else{
            // Use this font setting, since sometimes there is no font and it is really small
            // if the font is set, this setting gets ignored anyway
            // Add a viewport meta to fix zoom level of the message
            //body = [NSString stringWithFormat:@"<meta name='viewport' content='width=device-width,minimum-scale=0.25,maximum-scale=3.0,user-scalable=yes' /> <font face='Helvetica'>%@", body];
            //text.scalesPageToFit = YES;
        }
        
        // Added NSAllowsArbitraryLoadsInWebContent instead as we need to load content and we don't go anywhere else from the page
        /*
        // Try loading everything via secure connection, anyway plain http won't be loaded as it's prohibited by the security policy
        body = [body stringByReplacingOccurrencesOfString:@"http:" withString:@"https:"];*/
    }
    
    //NSAttributedString* body2 = [[NSAttributedString alloc] initWithData:[body dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute: [NSNumber numberWithInt:NSUTF8StringEncoding]} documentAttributes:nil error:nil];
    if (body == nil) {
        //body = @"";
        body = @"<head><style type=\"text/css\">\
        @media (prefers-color-scheme: dark) {\
            body {\
                background-color: rgb(20,20,20);\
                color: white;\
            }\
            a:link {\
                color: #0096e2;\
            }\
            a:visited {\
                color: #9d57df;\
            }\
        }</head>";
    }
    
    if (self.plainView) {
        // Load as plain text, do not render html
        //body = [body stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"];
        NSData* data=[currentMessage.messageBody dataUsingEncoding:NSUTF8StringEncoding];
        if (data){
            //[self.textWK loadData:data MIMEType:<#(nonnull NSString *)#> characterEncodingName:<#(nonnull NSString *)#> baseURL:<#(nonnull NSURL *)#>]
            [self.textWK loadData:data MIMEType:@"text/plain" characterEncodingName:@"UTF-8" baseURL:[NSURL URLWithString:@""]];
        }
    }else{
        //body = [NSString stringWithFormat:@"%@<br>%@",@"<div id='input' contenteditable='true'>Type here</div>", body];
        
        [self.textWK loadHTMLString:isPlain?[body stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"]:body baseURL:nil];
        [CommonProcs showSmallWheelinView:self.view];
        [CommonProcs setSWLabelText:NSLocalizedString(@"Loading resources...", nil)];
        
        /*
         // Block external images
        id blockRules = @" [{ \"trigger\": { \"url-filter\": \".*\", \"resource-type\": [\"image\"] }, \"action\": { \"type\": \"block\" } }] ";

        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://www.supremenewyork.com/"]];

        [[WKContentRuleListStore defaultStore] compileContentRuleListForIdentifier: @"ContentBlockingRules" encodedContentRuleList:blockRules completionHandler:^(WKContentRuleList *contentRuleList, NSError *error) {

            if (error != nil) {
                NSLog(@"Error = %@", error.localizedDescription);
            }
            else {
                WKWebViewConfiguration *configuration = self.webView.configuration;
                [[configuration userContentController] addContentRuleList:contentRuleList];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.webView loadRequest:request];
                });
            }
        }];
         */
    }
    
    //UIScrollView* attScroll = (UIScrollView*)[self.view viewWithTag:10];
    
    //attScroll.subviews
    NSArray *viewsToRemove = [self.attScroll subviews];
    for (UIView *v in viewsToRemove) [v removeFromSuperview];
    
    if(currentMessage.attachments.count == 0){
        [self setAttachmentStripVisible:NO :NO];
        [self toggleAttachmentButtonHidden:YES];
    }else{
        //int index = 0;
        [self setAttachmentStripVisible:YES :NO];
        [self toggleAttachmentButtonHidden:NO];
        UILabel *attLabel = (UILabel *)[self.view viewWithTag:12];
        attLabel.text = [NSString stringWithFormat:@"(%lu)", (unsigned long)currentMessage.attachments.count];
        
        NSArray* attViews = [CommonProcs showAttachmentsIcons:currentMessage scroll:self.attScroll];
        for (UIImageView* att in attViews) {
            // Add action
            [att setUserInteractionEnabled:YES];
            UITapGestureRecognizer *singleTap =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAttachment:)];
            [singleTap setNumberOfTapsRequired:1];
            [att addGestureRecognizer:singleTap];
        }
    }
    
    //self.subjWidthConstraint.constant = 320 - 39 - 50 - 6;
    [self.viewInScroll layoutIfNeeded];
}

-(IBAction)textHtmlView:(id)sender
{
    self.plainView = !self.plainView;
    
    /*
    if (self.plainView) {
        [(UIBarButtonItem*)sender setTitle:@"Html"];
    }else{
        [(UIBarButtonItem*)sender setTitle:@"Text"];
    }*/
    
    [self updateMessageView];
    [self adjustWebView];
}

-(IBAction)increaseFontSize:(id)sender
{
    self.fontSize++;
    [self updateFontSize];
}

-(IBAction)decreaseFontSize:(id)sender
{
    self.fontSize--;
    if (self.fontSize < 5) {
        self.fontSize = 5;
    }
    
    [self updateFontSize];
}


-(void)updateFontSize
{
    NSString* body = currentMessage.messageBody;
    
    if(body != nil){
        if (currentMessage.encType != enTypeNone) {
            // Set font since it's a plaintext and the font is shit
            body = [NSString stringWithFormat:@"<span style=\"font-family: %@; font-size: %i; -webkit-hyphens:auto;\">%@</span>",
                    @"Helvetica",
                    self.fontSize,
                    body];
            //body = [body stringByReplacingOccurrencesOfString:@"\n" withString:@"<br/>"];
            //text.scalesPageToFit = NO;
        }else{
            //text.scalesPageToFit = YES;
        }
    }
    //allowLoad = YES;
    if (body == nil) {
        body = @"";
    }
    [self.textWK loadHTMLString:body baseURL:nil];
    
    CGSize sz = [viewInScroll systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    sz.width = screenRect.size.width-20;
    [scroll setContentSize:sz];
}

-(void)scale:(id)sender {
    
    if (currentMessage.encType != enTypeNone) {
        if([(UIPinchGestureRecognizer*)sender state] == UIGestureRecognizerStateEnded) {
            lastScale = 1.0;
            return;
        }
    
        //allowLoad = YES;
        CGFloat scale = 1.0 - (lastScale - [(UIPinchGestureRecognizer*)sender scale]);
        lastScale = [(UIPinchGestureRecognizer*)sender scale];
        
        if (lastScale < scale) {
            if (scale/lastScale>1.1f)
                [self decreaseFontSize:nil];
        }else{
            if (lastScale/scale>1.1f)
                [self increaseFontSize:nil];
        }
    }

}

-(void)showAttachment:(UIGestureRecognizer *)recognizer
{
    //[presenter wantShowAttachment:currentMessage.attachments[[recognizer view].tag-1000] atIndex:(int)[recognizer view].tag-1000];
    [presenter wantShowAttachment:currentMessage.attachments atIndex:(int)[recognizer view].tag-1000];
}

-(IBAction)saveAllAttachments:(id)sender
{
    [presenter wantSaveAll:currentMessage];
    /*
    if([presenter wantSaveAll:currentMessage])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Attachments saved",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
        alert.tag = 10000;
        [alert show];
    }
     */
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)done:(id)sender
{
    [CommonProcs hideSmallWheel];
    
    [self.textWK stopLoading];
    //allowLoad = YES;
    //NSString* emptyHTML = @"<!DOCTYPE html><head><style type=""text/css"">@media (prefers-color-scheme: dark) { \
            body { \
                background-color: rgb(8,8,8); \
                color: white; \
            } \
        } \
        </style> \
        <title>Stopped</title></head> \
    <body style=""font-family:verdana;""> \
        <p><h3>Stopped</h3></p>";
    //[self.textWK loadHTMLString:emptyHTML baseURL:nil];
    self.textWK = nil;
    [[[GlobalRouter sharedManager] getMessageRouter] finished];
}

-(void)toggleAttachmentButtonHidden:(BOOL)hidden
{
    UIButton* attButton = (UIButton*)[self.view viewWithTag:11];
    UILabel *attLabel = (UILabel *)[self.view viewWithTag:12];
    UIButton* saveButton = (UIButton*)[self.view viewWithTag:13];
    
    attButton.hidden = hidden;
    attLabel.hidden = hidden;
    saveButton.hidden = YES;//hidden;
}

-(IBAction)toggleAttachmentStrip:(id)sender
{
    [self setAttachmentStripVisible:NO :YES];
}

-(void)setAttachmentStripVisible:(BOOL)visible :(BOOL)invert
{
    //CGRect attRect = self.attScroll.frame;
    //CGRect textRect = text.frame;
    //float hiddenOrigin = attRect.origin.y;
    //float shownOrigin = attRect.origin.y + attRect.size.height;
    
    UILabel *attLabel = (UILabel *)[self.view viewWithTag:12];
    
    if (invert) {
        //textRect.origin.y = textRect.origin.y==shownOrigin?hiddenOrigin:shownOrigin;//attRect.origin.y + 72;
        _attScrollHeightConstraint.constant = _attScrollHeightConstraint.constant == 1?72:1;
    }else{
        //textRect.origin.y = visible?shownOrigin:hiddenOrigin; //visible?attRect.origin.y + 72:attRect.origin.y;
        _attScrollHeightConstraint.constant = visible?72:1;
    }
    
    attLabel.hidden = _attScrollHeightConstraint.constant == 1;
    
    //textRect.size.width = 310;
    //[text setFrame:textRect];
    
    
}

-(IBAction)wantReplyToMessage:(id)sender
{
    [presenter wantReplyToMessage:currentMessage];
}

-(IBAction)wantForwardMessage:(id)sender
{
    if(!cp)
        cp = [[CommonProcs alloc] init];
    UIView* source = self.navigationController.toolbar.subviews[0];
    [cp wantMoveMessage:currentMessage fromRect:[source convertRect:[[sender view] frame] toView:self.view] canForward:YES fromView:self.view fromVC:self];
}

-(IBAction)wantMarkMessage:(id)sender
{
    [presenter wantMarkMessage:currentMessage];
    
    UIButton *star = (UIButton*)[self.view viewWithTag:5];
    if (currentMessage.flags & mfFavourite) {
        [star setImage:[UIImage imageNamed:@"starYellow"] forState:UIControlStateNormal];
    }else{
        [star setImage:[UIImage imageNamed:@"starLight"] forState:UIControlStateNormal];
    }
}

-(IBAction)wantDeleteMessage:(id)sender
{
    [presenter wantDeleteMessage:currentMessage];
}


-(void)showError:(NSString*)error
{
    [CommonProcs showMessage:@"" title:error];
    
    //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:error message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
    //alert.tag = 10000;
    //[alert show];
}

/*
-(void)askAndDoWithTitle:(NSString*)title text:(NSString*)alertText block:(dispatch_block_t)block
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:alertText delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"OK",nil), nil];
    alert.tag = 101;
    alertBlock = block;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 101)
    {
        if (buttonIndex == 0)
        {
        
        }else{
            alertBlock();
        }
    }
}
*/

-(IBAction)addContact:(id)sender
{
    [self.presenter wantToAddContactFor:currentMessage.fromName address:currentMessage.fromAddress];
}

-(void)prevMessage:(id)sender
{
    [presenter wantShowPrevMessageFor:currentMessage];
}

-(void)nextMessage:(id)sender
{
    [presenter wantShowNextMessageFor:currentMessage];
}

/*
- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Who knows cancel button index?
    if (buttonIndex == -1) {
        return;
    }
    NSString* buttonPressed = [popup buttonTitleAtIndex:buttonIndex];
    if ([buttonPressed isEqualToString:NSLocalizedString(@"Cancel",nil)]) {
        return;
    }
*/
    /*
    if(popup.tag == 202){
        if ([buttonPressed isEqualToString:NSLocalizedString(@"Forward",nil)]) {
            [presenter wantForwardMessage:currentMessage];
            
        }else if([buttonPressed isEqualToString:NSLocalizedString(@"Move to folder",nil)]){
            [presenter wantMoveMessage:currentMessage];
            
        }else if([buttonPressed isEqualToString:NSLocalizedString(@"Copy to folder",nil)]){
            [presenter wantCopyMessage:currentMessage];
            
        }else if([buttonPressed isEqualToString:NSLocalizedString(@"Reset all",nil)]){
            //[self search:nil];
        }else if([buttonPressed isEqualToString:NSLocalizedString(@"Info",nil)]){
            //[self showHelp:nil];
        }
        
    }
    */
//}


/*
-(void)wantShowAttachment:(UIImage*)attachment
{
    [presenter wantShowAttachment:attachment];
}
 
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    if(previousTraitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        NSLog(@"User has rotated to landscape");
    }else if(previousTraitCollection.verticalSizeClass == UIUserInterfaceSizeClassCompact) {
        NSLog(@"User has rotated to portrait");
    }
    
    if(previousTraitCollection != nil){
        //[text.scrollView setZoomScale:1];
        [self adjustWebViewSetWidthScale:YES];
    }
}

/*
- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [text.scrollView setZoomScale:1];
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
//- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self adjustWebView];
}
*/

@end
