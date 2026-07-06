//
//  ComposeMessageViewController.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "ComposeMessageViewController.h"
#import "FullMessageEntity.h"
#import "GlobalRouter.h"
#import "CommonProcs.h"
#import "Encryptor.h"
#import "SettingsEntity.h"
#import "FloatingToolbar.h"

#import "Autocomplete.h"
#import "WindowMinimizer.h"

#import "usePINViewController.h"
#import "OneTimeCert.h"

@interface ComposeMessageViewController ()

@end

@implementation ComposeMessageViewController

@synthesize presenter, message, pinCode;

// 5 bytes signature + 6 bytes for cert ID + 44-byte HMAC + 24-byte salt + 44 just in case = 123 bytes
// The rest is 255-123 = 132, divide by 2 for unicode, round it down = 64
#define MAX_SUBJECT_LENGTH 64
#define MAX_DEMO_TEXT_LENGTH 80

//BOOL sending = NO;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (message.messageID == nil) {
        self.textTopConstraint.constant = 8;
        //[self setupMessage:YES forward:NO];
    }else{
        //[self setupMessage];
    }
    
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
    
    UIBarButtonItem* button0 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needSend)];
    //UIBarButtonItem* button0 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@""] style:UIBarButtonItemStylePlain target:self action:@selector(needSend)];
    UIBarButtonItem *fixedItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedItem.width = 12;
    attButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"📎",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needToAddAttachment:)];
/*
#if LITE
    pinButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
#else
    pinButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"PIN",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needPin)];
    pinButton.tintColor = [UIColor redColor];
#endif
 */
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeMessage)];
    
    UIImage *image = [[UIImage imageNamed:@"iconMinimize24"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem *buttonMin = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(minimize:)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:/*pinButton,flexibleItem, */attButton, flexibleItem, button0, flexibleItem, button2,buttonMin, nil]];
    
    
    // Add a WKWebView here - migrate from UITextView
    NSString *jScript = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width');meta.setAttribute('minimum-scale', '0.5'); meta.setAttribute('user-scalable', 'yes'); document.getElementsByTagName('head')[0].appendChild(meta);";

    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    WKUserContentController *wkUController = [[WKUserContentController alloc] init];
    [wkUController addUserScript:wkUScript];

    WKWebViewConfiguration *wkWebConfig = [[WKWebViewConfiguration alloc] init];
    wkWebConfig.userContentController = wkUController;
    wkWebConfig.ignoresViewportScaleLimits = YES;
    
    int pos = self.attScroll.frame.origin.y+self.attScroll.frame.size.height+16;
    self.messageText = [[WKWebView alloc] initWithFrame:CGRectMake(0, pos, self.view.frame.size.width-16, self.view.frame.size.height-pos-80) configuration:wkWebConfig];
    self.messageText.UIDelegate = self;
    self.messageText.navigationDelegate = self;
    
    if (@available(iOS 13.0, *)) {
        self.messageText.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        // Fallback on earlier versions
        self.messageText.backgroundColor = [UIColor whiteColor];
    }

    [self.viewInScroll addSubview:self.messageText];
    // Constraints
    
    self.messageText.scrollView.bounces = NO;
    self.messageText.scrollView.minimumZoomScale = 0.5;
    //self.textWK.scrollView.scrollEnabled = NO;
    self.messageText.exclusiveTouch = NO;
    self.messageText.contentMode = UIViewContentModeScaleToFill;
    
    //self.view.translatesAutoresizingMaskIntoConstraints = NO;
    self.messageText.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.messageText
                                    attribute:NSLayoutAttributeLeading
                                    relatedBy:0
                                    toItem:self.viewInScroll
                                    attribute:NSLayoutAttributeLeading
                                    multiplier:1.0
                                    constant:8];
    [self.view addConstraint:leftConstraint];
    
    
    self.textWidthConstraint = [NSLayoutConstraint constraintWithItem:self.messageText
                                            attribute:NSLayoutAttributeWidth
                                            relatedBy:NSLayoutRelationEqual
                                            toItem:nil
                                            attribute:NSLayoutAttributeNotAnAttribute
                                            multiplier:1.0
                                            constant:self.view.frame.size.width];
    [self.view addConstraint:self.textWidthConstraint];
    
    /*
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint   constraintWithItem:self.messageText
                                            attribute:NSLayoutAttributeTrailing
                                            relatedBy:1
                                            toItem:self.scroll
                                            attribute:NSLayoutAttributeTrailing
                                            multiplier:1.0
                                            constant:16];
    [self.view addConstraint:rightConstraint];
    */
    /*
    NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint constraintWithItem:self.messageText
                                            attribute:NSLayoutAttributeBottom
                                            relatedBy:1
                                            toItem:self.viewInScroll
                                            attribute:NSLayoutAttributeBottom
                                            multiplier:1.0
                                            constant:46];
    [self.view addConstraint:bottomConstraint];
    
    */
    self.textHeightConstraint = [NSLayoutConstraint constraintWithItem:self.messageText
                                            attribute:NSLayoutAttributeHeight
                                            relatedBy:NSLayoutRelationEqual
                                            toItem:nil
                                            attribute:NSLayoutAttributeNotAnAttribute
                                            multiplier:1.0
                                            constant:self.view.frame.size.height-pos-80];
    [self.view addConstraint:self.textHeightConstraint];
    
    self.textTopConstraint = [NSLayoutConstraint constraintWithItem:self.messageText
                                            attribute:NSLayoutAttributeTop
                                            relatedBy:0
                                            toItem:self.readReceiptButton
                                            attribute:NSLayoutAttributeBottom
                                            multiplier:1.0
                                            constant:8];
    [self.view addConstraint:self.textTopConstraint];
    
    // AccessoryView toolbar
    UIBarButtonItem* button20 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needSend)];
    UIBarButtonItem *fixedItem22 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedItem22.width = 10;
    attButton22 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"📎",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needToAddAttachment:)];
/*
#if LITE
    pinButton22 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
#else
    pinButton22 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"PIN",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needPin)];
    pinButton22.tintColor = [UIColor redColor];
#endif
 */
    UIBarButtonItem *flexibleItem22 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button22 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeMessage)];
    UIBarButtonItem* button23 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(hideKeyboard)];
    [button23 setTitleTextAttributes:@{NSFontAttributeName : [UIFont boldSystemFontOfSize:8.0]} forState:UIControlStateNormal];
    
    UIImage *image2 = [[UIImage imageNamed:@"iconMinimize24"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem *buttonMin2 = [[UIBarButtonItem alloc] initWithImage:image2 style:UIBarButtonItemStylePlain target:self action:@selector(minimize:)];
    
    self.inputAccessoryToolbar = [[UIToolbar alloc] init];//self.navigationController.toolbar;
    self.inputAccessoryToolbar.frame = CGRectMake(0,0,300,44);
    self.inputAccessoryToolbar.items = [NSArray arrayWithObjects:/*pinButton22,flexibleItem22,*/ attButton22, flexibleItem22, button20, flexibleItem22, button22, /*button23,*/buttonMin2, nil];
    self.subject.inputAccessoryView = self.inputAccessoryToolbar;
    //self.messageText.inputAssistantItem.leadingBarButtonGroups = @[[[UIBarButtonItemGroup alloc] initWithBarButtonItems:self.inputAccessoryToolbar.items representativeItem:nil]];
    //self.messageText.inputAccessoryView = self.inputAccessoryToolbar;
    self.addressTo.inputAccessoryView = self.inputAccessoryToolbar;
    self.addressFrom.inputAccessoryView = self.inputAccessoryToolbar;
    
    //[self registerForKeyboardNotifications];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    // prevents the scroll view from swallowing up the touch event of child buttons
    tapGesture.cancelsTouchesInView = NO;
    //[self.scroll addGestureRecognizer:tapGesture];
    
    /*
    UIPickerView *picker = [[UIPickerView alloc] init];
    picker.dataSource = self;
    picker.delegate = self;
    self.addressFrom.inputView = picker;
    self.accounts = [[GlobalRouter sharedManager].accountsNames allKeys];
    */
    
    self.message.readReceiptTo = nil;
    self.readReceiptButton.alpha = 0.4;
    
    self.addressTo.delegate = self;
    //self.toAutocomplete = [[Autocomplete alloc] init];
    //[self.toAutocomplete createAutocompleteFor:self.addressTo withAllElements:[GlobalRouter sharedManager].possibleAddresses];
    
    [self setupMessage:YES forward:NO];
    
    /*
    [[self.priorityButton layer] setCornerRadius:5.0f];
    [[self.priorityButton layer] setMasksToBounds:YES];
    [[self.priorityButton layer] setBorderWidth:1.0f];
    [[self.priorityButton layer] setBorderColor:[UIColor blueColor].CGColor];
     */
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self == self.minimizer.minimizedVC) {
        [self.minimizer removeMinimizer];
    }
    
    self.view.frame = CGRectMake(0, 0, 100, 150);
    self.view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
    
    // There is a difference in behaviour in iOS7 and iOS8 -
    // viewDidLayoutSubviews on iOS7 is not called on text
    // update (on iOS8 it is). So I need to enable scrolling.
    if (!SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        //self.messageText.scrollEnabled = YES;
    }
    
    [[self.messageText layer] setCornerRadius:6.0f];
    [[self.messageText layer] setMasksToBounds:YES];
    [[self.messageText layer] setBorderWidth:1.0f];
    [[self.messageText layer] setBorderColor:[UIColor lightGrayColor].CGColor];
    //[[self.messageText layer] setBackgroundColor:[UIColor whiteColor].CGColor];
    if (@available(iOS 13.0, *)) {
        //self.messageText.textColor = [UIColor labelColor];
    } else {
        // Fallback on earlier versions
        //self.messageText.textColor = [UIColor blackColor];
    }
    
    UIPickerView *picker = [[UIPickerView alloc] init];
    picker.dataSource = self;
    picker.delegate = self;
    self.addressFrom.inputView = picker;
    self.accounts = [[GlobalRouter sharedManager].accountsNames allKeys];
    
    self.toAutocomplete = [[Autocomplete alloc] init];
    [self.toAutocomplete createAutocompleteFor:self.addressTo withAllElements:[GlobalRouter sharedManager].possibleAddresses];
    
    [self registerForKeyboardNotifications];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Alert if the from and replyTo are different
    [self.presenter checkFromAndReplyTo:message.fromAddress replyTo:message.replyToAddress];
    wkToolBar = [[FloatingToolbar alloc] init];
    wkToolBar.hidden = YES;
    float topPadding = 20;
    if (@available(iOS 11.0, *)) {
        UIWindow *window = UIApplication.sharedApplication.keyWindow;
        topPadding = window.safeAreaInsets.top;
    }
    [wkToolBar addToolbarToView:self.view withWebView:self.messageText topOffset:topPadding];
}

/*
- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (UIView *)inputAccessoryView
{
    return self.navigationController.toolbar;
}
*/

-(void)setupAddress
{
    self.addressTo.text = message.fromAddress;
}

-(BOOL)checkRestore:(NSString*)toCheckAgainst
{
    BOOL ret = [check isEqualToString:toCheckAgainst];
    if (ret && !self.presenter) {
        self.presenter = [[[GlobalRouter sharedManager] getComposeRouter] getPresenter];
        [self.presenter restoreVC:self];
        // Check attachments validity since it might be cleared if went to bg and used different PIN
        [self.presenter checkAttachmentsValidity];
    }
    return ret;
}

-(void)setupMessage:(BOOL)includeAttachments forward:(BOOL)forward
{
    BOOL signatureAdded = NO;
    check = [Encryptor getSlowHashForString:[GlobalRouter sharedManager].pin];
    self.highPriority = NO;
    [self.priorityButton setImage:[UIImage imageNamed:@"BlueDot"] forState:UIControlStateNormal];
    self.priorityButton.alpha = 0.4;
    
    NSString* emptyBlackEnabled = @"<html><head><style> :root{color-scheme: light dark;} @media (prefers-color-scheme: dark){:root {background: black; font-color: #ccc; color: #ccc;}}</style></head> <body><div id='editor' contenteditable='true' style='font-family: Helvetica;'><p><br><br></p></div></body></html>";
    
    if(self.message == nil){
        // Unlikely to get here, since we pass an empty message, not nil
        self.message = [[FullMessageEntity alloc] init];
        //self.messageText.text = @"  ";
        self.addressTo.text = @"";
        self.subject.text = @"";
        self.textTopConstraint.constant = 8;
        NSArray *viewsToRemove = [self.attScroll subviews];
        for (UIView *v in viewsToRemove) [v removeFromSuperview];
        self.addressFrom.text = @"";
        self.answering = NO;
        
        //NSString* bbb = @"<html><head><style type='text/css'> @media (prefers-color-scheme: dark) { body { background-color: rgb(10,10,10); color: rgb(250,250,250);}}</style></head><body><div id='editor' contenteditable='true' style='font-family: Helvetica;'<br><br></div></body></html>";
        
        [self.messageText loadHTMLString:emptyBlackEnabled baseURL:nil];
    }else{
        /**/
        if(message.messageBody != nil && self.message.encType != enTypePasswordForCert){
            //self.messageText.text = [NSString stringWithFormat:@"-----\n%@, %@\n\n%@",message.fromAddress, message.date, message.messageBody];
            //body = [NSString stringWithFormat:@"<span style=\"font-family: %@; font-size: %i\">%@</span>",@"Helvetica", 14, body];
            self.answering = YES;
            
            NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateStyle:NSDateFormatterShortStyle];
            [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
            NSString *dateString = [dateFormatter stringFromDate:message.date];
            
            // Need to insert this into the <body>
            NSString* bbb = [NSString stringWithFormat:@"<div id='editor' contenteditable='true' style='font-family: Helvetica;'><br><br>%@ wrote on  %@</div>", message.fromAddress, dateString];
            
            NSString* body = [NSString stringWithFormat:@"%@<br>%@",bbb, message.messageBody];
            
            [self.messageText loadHTMLString:body baseURL:nil];
            
        }else{
            self.answering = NO;
            //NSString* bbb = @"<div id='input' contenteditable='true' style='font-family: Helvetica;'><br><br></div>";
            //NSString* bbb = @"<html><head><style type=\"text/css\">@media (prefers-color-scheme: dark) { body { background-color: rgb(10,10,10); color: rgb(250,250,250);}}</style></head><body><div id='editor' contenteditable='true' style='font-family: Helvetica;'<br><br></div></body></html>";

            [self.messageText loadHTMLString:emptyBlackEnabled baseURL:nil];
            //self.messageText.text = @"";
        }
        if(!forward){
            if(message.replyToAddress && ![message.replyToAddress isEqualToString:@""]){
                self.addressTo.text = message.replyToAddress;
            }else{
                self.addressTo.text = message.fromAddress;
            }
        }
        if(message.subject != nil){
            if(!forward){
                self.subject.text = [NSString stringWithFormat:@"Re:%@",message.subject];
            }else{
                self.subject.text = [NSString stringWithFormat:@"Fwd:%@",message.subject];
            }
        }else
            self.subject.text = @"";
        
        if (self.subject.text.length > MAX_SUBJECT_LENGTH) {
            // Warn
            self.subject.backgroundColor = [UIColor redColor];
            self.subject.text = [self.subject.text substringToIndex:MAX_SUBJECT_LENGTH];
            [self performSelector:@selector(setSubjColorWhite) withObject:nil afterDelay:0.2];
        }
        
        if (message.attachments.count == 0) {
            self.textTopConstraint.constant = 8;
        }
        
        if (!includeAttachments && message.attachments != nil) {
            [message.attachments removeAllObjects];
        }
        [self setupAttachmentIcons];
        
        fromAddress = message.toAddress;
        if(fromAddress != nil){
            NSString* nameAcc = [[GlobalRouter sharedManager].accountsNames objectForKey:fromAddress];
            self.addressFrom.text = [NSString stringWithFormat:@"%@ (%@)", nameAcc, fromAddress];
            SettingsEntity* sett = [[GlobalRouter sharedManager] getSettingForAddress:fromAddress];
            if (sett){
                NSString* sig = sett.signature;
                if (!(sig == nil || [sig isEqualToString:@""])) {
                    //self.messageText.text = [NSString stringWithFormat:@"%@\n%@",sig, self.messageText.text];
                }
                signatureAdded = YES;
            }
        }
        //[CommonProcs hideProgressAlways];
    }
    pinCode = [NSMutableString stringWithString: @""];
    //pinButton.tintColor = [UIColor redColor];
    //pinButton22.tintColor = [UIColor redColor];
    
    if (self.message.encType == enTypePasswordForCert) {
#if !LITE
        attButton.enabled = NO;
        self.addAttachmentButton.enabled = NO;
        if([self.message.messageBody  isEqual: @""] /* && [self.messageText.text isEqualToString:@""]*/){
            //self.messageText.text = [self generateCert];
        }else{
            //self.messageText.text = self.message.messageBody;
        }
#endif
    }else{
        attButton.enabled = YES;
        self.addAttachmentButton.enabled = YES;
    }
    
    if ([GlobalRouter sharedManager].accountsNames.count == 1) {
        fromAddress = [[[GlobalRouter sharedManager].accountsNames allKeys] firstObject];
        if (fromAddress == nil) {
            fromAddress = @"";
        }
        NSString* nameAcc = [[GlobalRouter sharedManager].accountsNames objectForKey:fromAddress];
        self.addressFrom.text = [NSString stringWithFormat:@"%@ (%@)", nameAcc, fromAddress];
        if(!signatureAdded){
            SettingsEntity* sett = [[GlobalRouter sharedManager] getSettingForAddress:fromAddress];
            if (sett){
                NSString* sig = sett.signature;
                if (!(sig == nil || [sig isEqualToString:@""])) {
                    //self.messageText.text = [NSString stringWithFormat:@"%@\n%@",sig, self.messageText.text];
                }
            }
        }
    }else if ([GlobalRouter sharedManager].accountsNames.count == 0) {
        fromAddress = nil;
        self.addressFrom.text = @"";
    }
    
    self.message.readReceiptTo = nil;
    self.readReceiptButton.alpha = 0.4;
    
    if(message.messageBody){
        // Set the cursor
        //self.messageText.selectedTextRange = [self.messageText textRangeFromPosition:self.messageText.beginningOfDocument toPosition:self.messageText.beginningOfDocument];
        //[self.messageText becomeFirstResponder];
    }else{
        //[self.addressFrom becomeFirstResponder]; // Annoying!
    }
}

#if !LITE
-(NSString*)generateCert
{
    return [Encryptor generateCert:self];
}
#endif

-(void)setCert:(NSString*)cert
{
    //self.messageText.text = cert;
}

-(void)setupAttachmentIcons
{
    if (message.attachments.count == 0) {
        self.textTopConstraint.constant = 8;
        self.attCount.hidden = YES;
    }else{
        self.textTopConstraint.constant = 93;
        self.attCount.hidden = NO;
        self.attCount.text = [NSString stringWithFormat:NSLocalizedString(@"Attachments\n%lu", nil), (unsigned long)message.attachments.count];
    }

    NSArray* attViews = [CommonProcs showAttachmentsIcons:message scroll:self.attScroll];
    for (UIImageView* att in attViews) {
        // Add action
        [att setUserInteractionEnabled:YES];
        UITapGestureRecognizer *singleTap =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAttachment:)];
        [singleTap setNumberOfTapsRequired:1];
        [att addGestureRecognizer:singleTap];
    }
}

// method to hide keyboard when user taps on a scrollview
-(void)hideKeyboard
{
    [self.view endEditing:YES];
    if (self.toAutocomplete != nil && ![self.toAutocomplete isHidden]) {
        [self.toAutocomplete hideTable];
    }
}

-(void)minimize:(id)sender
{
    //self.minimizer = [[WindowMinimizer alloc] init];
    //[self.minimizer minimizeWindow:self];
    wkToolBar.hidden = YES;
    [self.presenter minimizeComposerAnimated:YES];
}

-(IBAction)needToAddAttachment:(id)sender
{    
    [presenter needToAddAttachment];
}

-(IBAction)needToGetAddress:(id)sender
{
    [presenter needAddress];
}

-(void)needPINOnly0
{
#if LITE
    [self sendWithNoPIN];
#else
    controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter PIN",nil)
                                    message:NSLocalizedString(@"Set a PIN-code for the message\nMutable PIN will be randomly mutated to enhance security",nil)
                                    preferredStyle:UIAlertControllerStyleAlert];
    
    /*UIAlertAction *button1 = [UIAlertAction actionWithTitle:NSLocalizedString(@"Use simple PIN",nil) style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        [self useSimplePIN];
                                                    }];*/
    
    UIAlertAction *button2 = [UIAlertAction actionWithTitle:NSLocalizedString(@"Use mutable PIN",nil) style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        [self useMutablePIN];
                                                    }];
    UIAlertAction *button3 = [UIAlertAction actionWithTitle:NSLocalizedString(@"Send unprotected",nil) style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        [self useNoPIN];
                                                    }];
    
    //UIAlertActionStyleDestructive gives you a red colored button
    UIAlertAction *buttonCancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil) style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             
                                                         }];
    __weak __typeof__(self) weakSelf = self;
    [controller addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        __strong __typeof__(self) strongSelf = weakSelf;
        textField.placeholder = @"PIN-code for a message";
        textField.textColor = [UIColor blueColor];
        textField.keyboardType = UIKeyboardTypeDefault;
        if (![strongSelf->pinCode isEqualToString:@""]) {
            textField.text = strongSelf->pinCode;
        }
        //textField.secureTextEntry = YES;
    }];
    
    //[controller addAction:button1];
    [controller addAction:button2];
    [controller addAction:button3];
    [controller addAction:buttonCancel];
    
    [self presentViewController:controller animated:YES completion:nil];
#endif
}

-(void)needPINOnly
{
#if LITE
    [self sendWithNoPIN];
#else
    
    windowController = [[usePINViewController alloc] initWithNibName:@"usePINViewController" bundle:nil];
    //windowController.definesPresentationContext = YES;
    __weak typeof(self) weakSelf = self;
    windowController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:windowController animated:YES completion:^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->windowController.sendButton addTarget:self action:@selector(useMutablePIN) forControlEvents:UIControlEventTouchUpInside];
        [strongSelf->windowController.sendUnprotectedButton addTarget:self action:@selector(useNoPIN) forControlEvents:UIControlEventTouchUpInside];
    }];
#endif
}

-(void)useSimplePIN
{
    //pinCode = [NSMutableString stringWithString: [[controller textFields][0] text]];
    pinCode = [NSMutableString stringWithString:windowController.pinText.text];
    if(![pinCode isEqualToString:@""]){
        //pinButton.tintColor = [UIColor colorWithRed:0.2 green:0.5 blue:0 alpha:1];
        //pinButton22.tintColor = [UIColor colorWithRed:0.2 green:0.5 blue:0 alpha:1];
        if (self.presenter.sending) {
            self.presenter.sending = NO;
            [self needSend];
        }
    }else{
        //pinButton.tintColor = [UIColor redColor];
        //pinButton22.tintColor = [UIColor redColor];
    }
    
    [windowController dismissViewControllerAnimated:YES completion:nil];
}

-(NSDate*) getExpirationDate
{
    NSDate* ret;
    if (windowController.expireSegments.selectedSegmentIndex == 1) {
        // 1 day
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        dayComponent.day = 1;
        NSCalendar *theCalendar = [NSCalendar currentCalendar];
        ret = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
    }else if (windowController.expireSegments.selectedSegmentIndex == 2) {
        // 3 days
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        dayComponent.day = 3;
        NSCalendar *theCalendar = [NSCalendar currentCalendar];
        ret = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
    }else if (windowController.expireSegments.selectedSegmentIndex == 3) {
        // 7 days
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        dayComponent.day = 7;
        NSCalendar *theCalendar = [NSCalendar currentCalendar];
        ret = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
    }else{
        // Do not expire
    }
    
    return ret;
}

-(void)useMutablePIN
{
    //pinCode = [NSMutableString stringWithString: [[controller textFields][0] text]];
    pinCode = [NSMutableString stringWithString:windowController.pinText.text];
    
    uint8_t buf[4];
    int cpRet = SecRandomCopyBytes(kSecRandomDefault, 4, buf);
    if (cpRet != errSecSuccess) {
        arc4random_buf(buf, sizeof(buf));
    }
    uint32_t* i = (uint32_t*)(&buf);
    self.message.mutationNumber = *i%(mutationBase-1)+1;
    
    if(![pinCode isEqualToString:@""]){
        //pinButton.tintColor = [UIColor colorWithRed:0.2 green:0.5 blue:0 alpha:1];
        //pinButton22.tintColor = [UIColor colorWithRed:0.2 green:0.5 blue:0 alpha:1];
        
        self.message.expireOTCon = [OneTimeCert getStringForDate:[self getExpirationDate]];
        /*
        if (windowController.expireSegments.selectedSegmentIndex == 1) {
            // 1 day
            NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
            dayComponent.day = 1;
            NSCalendar *theCalendar = [NSCalendar currentCalendar];
            NSDate *nextDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];

            self.message.expireOTCon = [OneTimeCert getStringForDate:nextDate];
        }else if (windowController.expireSegments.selectedSegmentIndex == 2) {
            // 3 days
            NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
            dayComponent.day = 3;
            NSCalendar *theCalendar = [NSCalendar currentCalendar];
            NSDate *nextDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];

            self.message.expireOTCon = [OneTimeCert getStringForDate:nextDate];
        }else if (windowController.expireSegments.selectedSegmentIndex == 3) {
            // 7 days
            NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
            dayComponent.day = 7;
            NSCalendar *theCalendar = [NSCalendar currentCalendar];
            NSDate *nextDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];

            self.message.expireOTCon = [OneTimeCert getStringForDate:nextDate];
        }else{
            // Do not expire
        }*/
        if (self.presenter.sending) {
            self.presenter.sending = NO;
            [self needSend];
        }
    }else{
        //pinButton.tintColor = [UIColor redColor];
        //pinButton22.tintColor = [UIColor redColor];
    }
    
    [windowController dismissViewControllerAnimated:YES completion:nil];
}

-(void)sendWithNoPIN
{
    pinCode = [NSMutableString stringWithString: NSLocalizedString(@"no", nil)];
    //pinButton.tintColor = [UIColor colorWithRed:0.2 green:0.5 blue:0 alpha:1];
    //pinButton22.tintColor = [UIColor colorWithRed:0.2 green:0.5 blue:0 alpha:1];
    if (self.presenter.sending) {
        self.presenter.sending = NO;
        [self needSend];
    }
}

-(void)useNoPIN
{
    self.message.expireOTCon = [OneTimeCert getStringForDate:[self getExpirationDate]];
    
    // Confirm first
    UIAlertController* contr = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Are you sure?",nil)
                                    message:NSLocalizedString(@"Send it without any protection?",nil)
                                    preferredStyle:UIAlertControllerStyleAlert];
    __weak __typeof__(self) weakSelf = self;
    UIAlertAction *button1 = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes",nil) style:UIAlertActionStyleDefault
            handler:^(UIAlertAction * _Nonnull action) {
        __strong __typeof__(self) strongSelf = weakSelf;
        strongSelf->pinCode = [NSMutableString stringWithString: NSLocalizedString(@"no", nil)];
        //strongSelf->pinButton.tintColor = [UIColor colorWithRed:0.2 green:0.5 blue:0 alpha:1];
        //strongSelf->pinButton22.tintColor = [UIColor colorWithRed:0.2 green:0.5 blue:0 alpha:1];
        
        if (self.presenter.sending) {
            self.presenter.sending = NO;
            [self needSend];
        }
    }];
    
    //UIAlertActionStyleDestructive gives you a red colored button
    UIAlertAction *buttonCancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"No",nil) style:UIAlertActionStyleDestructive
                             handler:^(UIAlertAction * _Nonnull action) {
        [self needPINOnly];
                             }];
    
    [contr addAction:button1];
    [contr addAction:buttonCancel];
    
    // Dismiss before showing a new controller
    [windowController dismissViewControllerAnimated:YES completion:^{
        [self presentViewController:contr animated:YES completion:nil];
    }];
    //[self presentViewController:contr animated:YES completion:nil];
}

// Check for OTC, if no, ask for a pin
-(void)needPin
{
    // [self gatherMessage]; // Don't need that here
#if !LITE
    if([presenter checkForOTC:self.message]) return;
#endif
    [self needPINOnly];
    
    /*
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter PIN",nil) message:NSLocalizedString(@"Set PIN-code for the message",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Done",nil),nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    if (![pinCode isEqualToString:@""]) {
        [[alert textFieldAtIndex:0] setText:pinCode];
    }
    [alert setTag:100];
    
    //BUGFIX - iOS8 crashes if you call alert while the keyboard is on...
    UITextField *txt = [alert textFieldAtIndex:0];
    [txt becomeFirstResponder];
    
    [alert show];
     */
}

-(BOOL)isAddressValid:(NSString*)address
{
    BOOL ret = YES;
    // 1. Check address
    if(address == nil || [address isEqualToString:@""]){
        ret = NO;
    }else{
        // 2. Check format
        NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        BOOL val = [emailTest evaluateWithObject:address];
        ret &= val;
    }
    
    return ret;
}

-(BOOL)sanityCheck
{
    BOOL fromValid = [self isAddressValid:message.fromAddress];
    BOOL toValid = [self isAddressValid:message.toAddress];
    if(!fromValid || !toValid){
        NSMutableString* invalidAddrText = [[NSMutableString alloc] init];
        if (!fromValid) {
            [invalidAddrText appendString:NSLocalizedString(@"From address is invalid \n",nil)];
        }
        if (!toValid) {
            [invalidAddrText appendString:NSLocalizedString(@"To address is invalid",nil)];
        }
        [CommonProcs showMessage:invalidAddrText title:NSLocalizedString(@"Error",nil)];
    }
    
    return  fromValid & toValid;
}

-(BOOL)sanityCheckOld
{
    BOOL ret = YES;
    // 1. Check address
    if(message.fromAddress == nil || [message.fromAddress isEqualToString:@""]){
        ret = NO;
        [CommonProcs showMessage:NSLocalizedString(@"Address is empty",nil) title:NSLocalizedString(@"Error",nil)];
        //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil) message:NSLocalizedString(@"Address is empty",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
        //alert.tag = 10000;
        //[alert show];
    }else{
        // 2. Check format
        NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        BOOL val = [emailTest evaluateWithObject:message.fromAddress];
        if (!val) {
            [CommonProcs showMessage:NSLocalizedString(@"Address is invalid",nil) title:NSLocalizedString(@"Error",nil)];
            //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil) message:NSLocalizedString(@"Address is invalid",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
            //alert.tag = 10000;
            //[alert show];
        }
        ret &= val;
    }
    
    return ret;
}

-(void) gatherMessageWithBlock:(dispatch_block_t)blockSend
{
    if (!message.readyToSend) {
        message.fromAddress = fromAddress;
        if (fromAddress == nil && !(self.addressFrom.text == nil || [self.addressFrom.text isEqualToString:@""])) {
            NSString* fromTemp = self.addressFrom.text;
            // get rid of (...) part
            NSRange pos1 = [fromTemp rangeOfString:@" ("];
            NSRange pos2 = [fromTemp rangeOfString:@")"];
            if (pos1.location == NSNotFound) {
                pos1.location = -2;
            }
            if (pos2.location == NSNotFound) {
                pos2.location = fromTemp.length;
            }
            message.fromAddress = [fromTemp substringWithRange:NSMakeRange(pos1.location+2, pos2.location-pos1.location-2)];
            fromAddress = message.fromAddress;
        }
        
        if (message.readReceiptTo.length > 0) {
            message.readReceiptTo = message.fromAddress;
        }
        
        message.toAddress = self.addressTo.text;
        message.subject = self.subject.text;
        if (message.subject.length > MAX_SUBJECT_LENGTH) {
            // Truncate it
            message.subject = [message.subject substringToIndex:MAX_SUBJECT_LENGTH];
        }
        if (self.highPriority) {
            message.flags = mfImportant;
        }else{
            message.flags = mfNone;
        }
        
        __weak typeof(self)weakSelf = self;
        [self.messageText evaluateJavaScript:@"document.documentElement.outerHTML.toString()" completionHandler:^(id _Nullable html, NSError * _Nullable error) {
            __strong typeof(self)strongSelf = weakSelf;
            if([html isKindOfClass:[NSString class]])
                strongSelf->message.messageBody = html;
            blockSend();
        }];
    }else{
        blockSend();
    }
}

-(void) gatherMessage
{
    if (!message.readyToSend) {
        message.fromAddress = fromAddress;
        if (fromAddress == nil && !(self.addressFrom.text == nil || [self.addressFrom.text isEqualToString:@""])) {
            NSString* fromTemp = self.addressFrom.text;
            // get rid of (...) part
            NSRange pos1 = [fromTemp rangeOfString:@" ("];
            NSRange pos2 = [fromTemp rangeOfString:@")"];
            if (pos1.location == NSNotFound) {
                pos1.location = -2;
            }
            if (pos2.location == NSNotFound) {
                pos2.location = fromTemp.length;
            }
            message.fromAddress = [fromTemp substringWithRange:NSMakeRange(pos1.location+2, pos2.location-pos1.location-2)];
            fromAddress = message.fromAddress;
        }
        
        if (message.readReceiptTo.length > 0) {
            message.readReceiptTo = message.fromAddress;
        }
        
        message.toAddress = self.addressTo.text;
        message.subject = self.subject.text;
        if (message.subject.length > MAX_SUBJECT_LENGTH) {
            // Truncate it
            message.subject = [message.subject substringToIndex:MAX_SUBJECT_LENGTH];
        }
        if (self.highPriority) {
            message.flags = mfImportant;
        }else{
            message.flags = mfNone;
        }
        //dispatch_semaphore_t sem = dispatch_semaphore_create(0);
        __weak typeof(self)weakSelf = self;
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.messageText evaluateJavaScript:@"document.documentElement.outerHTML.toString()" completionHandler:^(id _Nullable html, NSError * _Nullable error) {
            __strong typeof(self)strongSelf = weakSelf;
            if([html isKindOfClass:[NSString class]])
                strongSelf->message.messageBody = html;
            //dispatch_semaphore_signal(sem);
            //strongSelf->canSend = YES;
        }];
        //});
        //dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        
        //message.messageBody = self.messageText.text;
    }
    //message.readyToSend = NO; // Re-send bug
    /*
    NSAttributedString *s = self.messageText.attributedText;
    NSDictionary *documentAttributes = @{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType};
    NSData *htmlData = [s dataFromRange:NSMakeRange(0, s.length) documentAttributes:documentAttributes error:NULL];
    NSString *htmlString = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
    
    message.messageBody = htmlString;
    */
}

-(void)needSend
{
    NSLog(@"Widths scroll = %fx%f, viewInScroll = %fx%f, web=%fx%f", self.scroll.frame.size.width, self.scroll.frame.size.height, self.viewInScroll.frame.size.width, self.viewInScroll.frame.size.height, self.messageText.frame.size.width, self.messageText.frame.size.height);
    
    __weak typeof(self)weakSelf = self;
    [self gatherMessageWithBlock:^{
        __strong typeof(self)strongSelf = weakSelf;
        // Filter out lethal errors first
        if (![self sanityCheck]) {
            return;
        }
        
        [self hideKeyboard];
        
        if ([strongSelf->pinCode isEqual:@""]) {
            self.presenter.sending = YES;
            [self needPin];
        }else{
            //[self hideKeyboard];
            self.presenter.sending = NO;
            [CommonProcs spawnProcWithProgress:@selector(needSendMessage:pin:) object:strongSelf->presenter withParam1:strongSelf->message withParam2:strongSelf->pinCode];
        }
    }];
    
    /*
    [self gatherMessage];
    
    // Filter out lethal errors first
    if (![self sanityCheck]) {
        return;
    }
    
    [self hideKeyboard];
    
    if ([pinCode isEqual:@""]) {
        self.presenter.sending = YES;
        [self needPin];
    }else{
        //[self hideKeyboard];
        self.presenter.sending = NO;
        [CommonProcs spawnProcWithProgress:@selector(needSendMessage:pin:) object:presenter withParam1:message withParam2:pinCode];
    }
     */
}

-(void)showAttachment:(UIGestureRecognizer *)recognizer
{
    [presenter attachmentTapped:(int)[recognizer view].tag];
}

-(void)closeMessage
{
    [self.toAutocomplete removeTable];
    wkToolBar.hidden = YES;
    // Remove attachments
    [[[GlobalRouter sharedManager] getComposeRouter] finished];
}

-(void)closeMessageWithSentAnimation
{
    UIView *thisViewTemp = self.view;
    [self.toAutocomplete removeTable];
    
    wkToolBar.hidden = YES;
    
    // Add this view to the parent ViewControllers View
    [[self parentViewController].view addSubview:thisViewTemp];
    
    // Pop the VC
    [self.navigationController popViewControllerAnimated:NO];
    
    thisViewTemp.layer.masksToBounds = NO;
    [thisViewTemp.layer setShadowColor:[UIColor grayColor].CGColor];
    [thisViewTemp.layer setShadowOpacity:0.5];
    [thisViewTemp.layer setShadowOffset:CGSizeMake(3, 3)];
    
    [UIView animateWithDuration:0.25 delay:0 options: UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         thisViewTemp.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.8, 0.8);
                     }
                     completion:^(BOOL fin){
                         if (fin) {
                         }
                     }];

    
    [UIView animateWithDuration:0.35 delay:0.2 options: UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         thisViewTemp.frame = CGRectMake(thisViewTemp.frame.size.width*0.1, -thisViewTemp.frame.size.height*0.4, thisViewTemp.frame.size.width, thisViewTemp.frame.size.height);
                         thisViewTemp.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.2, 0.2);
                     }
                     completion:^(BOOL fin){
                         if (fin) {
                             // finally display the new viewcontroller for real
                             [thisViewTemp removeFromSuperview];
                        }
                     }];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews
{
    //[super viewDidLayoutSubviews];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat fixedWidth = self.messageText.frame.size.width;
        CGSize newSize = [self.messageText sizeThatFits:CGSizeMake(fixedWidth, CGFLOAT_MAX)];
        if (newSize.height<300) {
            CGRect screenRect = [[UIScreen mainScreen] bounds];
            CGFloat newHeight = screenRect.size.height - self.messageText.frame.origin.y - self.navigationController.toolbar.frame.size.height-24;
            self.textHeightConstraint.constant = newHeight;
        }else{
            self.textHeightConstraint.constant = newSize.height;
        }
        //NSLog(@"--------");
        //[super viewWillLayoutSubviews];
    });
    
    [self.view layoutIfNeeded];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
}

- (void)keyboardWasShown:(NSNotification*)aNotification {
    
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scroll.contentInset.top, self.scroll.contentInset.left, kbSize.height+32, 0.0);
    self.scroll.contentInset = contentInsets;
    self.scroll.scrollIndicatorInsets = contentInsets;
    
    if (![self.addressTo isFirstResponder] && ![self.subject isFirstResponder] && ![self.addressFrom isFirstResponder]) {
        wkToolBar.hidden = NO;
    }else{
        wkToolBar.hidden = YES;
    }
    
    /*
    if([self.messageText isFirstResponder] && self.messageText.selectedTextRange != nil)
    {
        CGRect cursorPosition = [self.messageText caretRectForPosition:self.messageText.selectedTextRange.start];
        cursorPosition.origin.y += self.messageText.frame.origin.y;
        [self.scroll scrollRectToVisible:cursorPosition animated:YES];
    }*/
    
    /*
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.messageText.frame.origin) ) {
        [self.scroll scrollRectToVisible:self.messageText.frame animated:YES];
    }
     */
    
    /*
    UIView* contentView;
    for (UIView* subview in self.messageText.scrollView.subviews) {
        if ([[[subview classForCoder] description] isEqualToString:@"WKContentView"]) {
            contentView = subview;
        }
    }
    
    contentView.inputAssistantItem.leadingBarButtonGroups = @[[[UIBarButtonItemGroup alloc] initWithBarButtonItems:self.inputAccessoryToolbar.items representativeItem:nil]];
     */
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    //UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scroll.contentInset.top, 0.0, 32, 0.0);
    self.scroll.contentInset = contentInsets;
    self.scroll.scrollIndicatorInsets = contentInsets;
    
    wkToolBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

- (void)keyboardDidHide:(NSNotification*)aNotification
{
    //[self becomeFirstResponder];
}

-(void)setPinColor
{
    if(![pinCode isEqualToString:@""]){
        //pinButton.tintColor = [UIColor colorWithRed:0.2 green:0.5 blue:0 alpha:1];
        //pinButton22.tintColor = [UIColor colorWithRed:0.2 green:0.5 blue:0 alpha:1];
    }else{
        //pinButton.tintColor = [UIColor redColor];
        //pinButton22.tintColor = [UIColor redColor];
    }
}

-(void)showError:(NSString*)error
{
    [CommonProcs showMessage:@"" title:error];
    //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:error message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
    //alert.tag = 10000;
    //[alert show];
    
    if ([error isEqualToString:NSLocalizedString(@"Wrong pin", nil)]) {
        pinCode = [NSMutableString stringWithString: @""];
    }
}

-(IBAction)setFromAccount:(id)sender
{
    
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.accounts.count;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return  1;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.accounts[row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    //self.addressFrom.text = self.accounts[row];
    fromAddress = self.accounts[row];
    self.addressFrom.text = [NSString stringWithFormat:@"%@ (%@)", [[GlobalRouter sharedManager].accountsNames objectForKey:fromAddress], fromAddress];
    [self.addressFrom resignFirstResponder];
    
    // Add signature
    SettingsEntity* sett = [[GlobalRouter sharedManager] getSettingForAddress:fromAddress];
    if (sett){//} && [self.messageText.text isEqualToString:@""]) {
        NSString* sig = sett.signature;
        if(!(sig == nil || [sig isEqualToString:@""])){
            //self.messageText.text = [NSString stringWithFormat:@"%@\n%@",sig, self.messageText.text];
        }
    }
    
}

-(IBAction)subjChanged:(id)sender
{
    if (self.subject.text.length > MAX_SUBJECT_LENGTH) {
        // Warn
        self.subject.backgroundColor = [UIColor redColor];
        self.subject.text = [self.subject.text substringToIndex:MAX_SUBJECT_LENGTH];
        [self performSelector:@selector(setSubjColorWhite) withObject:nil afterDelay:0.2];
        
    }else{
        //self.subject.backgroundColor = [UIColor whiteColor];
    }
}

-(void)textViewDidChange:(UITextView *)textView
{
#ifdef DEMO
    if (self.messageText.text.length > MAX_DEMO_TEXT_LENGTH) {
        self.messageText.text = [self.messageText.text substringToIndex:MAX_DEMO_TEXT_LENGTH];
        [CommonProcs thisFeatureIsInFull:@"Text without limitation"];
    }
#endif
}

-(void)setSubjColorWhite
{
    if (@available(iOS 13.0, *)) {
        self.subject.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        // Fallback on earlier versions
        self.subject.backgroundColor = [UIColor whiteColor];
    }
}

/*
- (void)textViewDidChange:(UITextView *)textView
{
    CGFloat fixedWidth = textView.frame.size.width;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, CGFLOAT_MAX)];
    CGRect newFrame = textView.frame;
    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
    textView.frame = newFrame;
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

#pragma mark Autocomplete

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if([textField isEqual:self.addressTo]){
        NSString *substring = [NSString stringWithString:textField.text];
        substring = [substring stringByReplacingCharactersInRange:range withString:string];
        [self.toAutocomplete filterItems:substring];
    }else{
        //[self.toAutocomplete hideTable];
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // Remove autocomplete
    if([textField isEqual:self.addressTo]){
        [self.toAutocomplete hideTable];
    }
}

-(IBAction)priorityChanged:(id)sender
{
    /*
    [self.messageText evaluateJavaScript:@"document.getSelection().toString()" completionHandler:^(id _Nullable html, NSError * _Nullable error) {
        NSLog(@"Selected %@", html);
    }]; */
    /*
    [self.messageText evaluateJavaScript:@"document.execCommand('fontSize', false, '5')" completionHandler:^(id _Nullable html, NSError * _Nullable error) {
        NSLog(@"Selected %@", html);
    }];*/
    
    //FloatingToolbar* tb = [[FloatingToolbar alloc] init];
    //[tb addToolbarToView:self.view withWebView:self.messageText];
    
    self.highPriority = !self.highPriority;
    if (self.highPriority) {
        //[self.priorityButton setTitle:@"H" forState:UIControlStateNormal];
        [self.priorityButton setImage:[UIImage imageNamed:@"RedDot"] forState:UIControlStateNormal];
        self.priorityButton.alpha = 1;
        //self.priorityButton.backgroundColor = [UIColor colorWithRed:1 green:0.51 blue:0.51 alpha:1];
        [CommonProcs showVanishingMessage:@"High importance set" inView:self.view inRect:CGRectMake(self.priorityButton.frame.origin.x-190, self.priorityButton.frame.origin.y+10, 186, 24) timeToShow:1];
    }else{
        //[self.priorityButton setTitle:@"N" forState:UIControlStateNormal];
        //[self.priorityButton setImage:nil forState:UIControlStateNormal];
        [self.priorityButton setImage:[UIImage imageNamed:@"BlueDot"] forState:UIControlStateNormal];
        self.priorityButton.alpha = 0.4;
        //self.priorityButton.backgroundColor = [UIColor whiteColor];
        [CommonProcs showVanishingMessage:@"Normal importance set" inView:self.view inRect:CGRectMake(self.priorityButton.frame.origin.x-190, self.priorityButton.frame.origin.y+10, 186, 24) timeToShow:1];
    }
}

-(IBAction)needReadReceipt:(id)sender
{
    if (self.addressFrom.text.length < 3) {
        [CommonProcs showMessage:NSLocalizedString(@"Invalid e-mail address", nil) title:@"Read receipt request"];
        return;
    }
    if (self.message.readReceiptTo == nil || [self.message.readReceiptTo isEqualToString:@""]) {
        NSString* fromTemp = self.addressFrom.text;
        // get rid of (...) part
        NSRange pos1 = [fromTemp rangeOfString:@" ("];
        NSRange pos2 = [fromTemp rangeOfString:@")"];
        if (pos1.location == NSNotFound) {
            pos1.location = -2;
        }
        if (pos2.location == NSNotFound) {
            pos2.location = fromTemp.length;
        }
        self.message.readReceiptTo = [fromTemp substringWithRange:NSMakeRange(pos1.location+2, pos2.location-pos1.location-2)];
        self.readReceiptButton.alpha = 1;
        
        [CommonProcs showVanishingMessage:@"Read receipt: ON" inView:self.view inRect:CGRectMake(self.readReceiptButton.frame.origin.x-190, self.readReceiptButton.frame.origin.y+10, 186, 24) timeToShow:1];
    }else{
        self.message.readReceiptTo = nil;
        self.readReceiptButton.alpha = 0.4;
        
        [CommonProcs showVanishingMessage:@"Read receipt: OFF" inView:self.view inRect:CGRectMake(self.readReceiptButton.frame.origin.x-190, self.readReceiptButton.frame.origin.y+10, 186, 24) timeToShow:1];
    }
}

#pragma mark WKWebView

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (navigationAction.navigationType == UIWebViewNavigationTypeLinkClicked) {
        // Do not open links
        decisionHandler(WKNavigationActionPolicyCancel);
    }else{
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)aWebView didFinishNavigation:(WKNavigation *)navigation
{
    // Need to do that on orientation change as well
    //[self.messageText setFrame:CGRectMake(self.messageText.frame.origin.x, self.messageText.frame.origin.y, self.view.frame.size.width-16, self.view.frame.size.height - self.messageText.frame.origin.y-70)];
    //[self.scroll setContentSize:CGSizeMake(300, 480)];
    
    [self adjustWebViewSetWidthScale:YES];
    return;
}

-(void)adjustWebViewSetWidthScale:(BOOL)forceScale
{
    [self.messageText evaluateJavaScript:@"document.readyState" completionHandler:^(id _Nullable complete, NSError * _Nullable error) {
        if(complete){
            // Do this since some emails not shown the right width. For example, yahoo info mails are zoomed too much
            //__weak typeof(self) weakSelf = self;
            [self.messageText evaluateJavaScript:@"document.body.style.transform = 'scale(1)';document.body.scrollWidth" completionHandler:^(NSNumber* _Nullable width, NSError * _Nullable error) {
                //NSLog(@"Evaluated height = %ld", (long)height.integerValue);
                long wd = width.intValue;
                
                // on iPad the width is not the screen, but the view - there is a list on the left
                int wdFullScreen = [[UIScreen mainScreen] bounds].size.width - self.messageText.frame.origin.x*2;
                NSLog(@"Frame size %ld/%d or %f", wd,wdFullScreen, self.viewInScroll.frame.size.width);
                //
                wdFullScreen = self.viewInScroll.frame.size.width;
                float zoom = (float)wdFullScreen/(float)wd;
                if (!self.message.messageBody) {
                    zoom = 1;
                }
                if(forceScale || ( /*zoom != 1 &&*/ zoom != 0)){
                    NSString *jsZCommand;
                    if (zoom >= 10000 /*test*/) {
                        // setting % for width and height makes everything OK, but some mails are still wider that the screen. Setting just the float makes it look OK, but the other mails that look good with % are too narrow with float. So, I made two for zoom in and out.
                        jsZCommand = [NSString stringWithFormat: @"document.body.style.transform = 'scale(%f)'; document.body.style.webkitTransform = 'scale(%f)'; document.body.style.transformOrigin = 'top left'; document.body.style.width = %f%%;document.body.style.height = %f%%;", zoom, zoom, zoom*100, zoom*100];
                    }else{ // This one (no width and fake float height) makes the least harmful bug - empty space after the page when rotated...
                        jsZCommand = [NSString stringWithFormat: @"document.body.style.transform = 'scale(%f)'; document.body.style.webkitTransform = 'scale(%f)'; document.body.style.transformOrigin = 'top left';  document.body.style.height = %f;", zoom, zoom, zoom/*, zoom*/];//document.body.style.width = %f;
                    }
                    [self.messageText evaluateJavaScript:jsZCommand completionHandler:^(NSString *result, NSError *error) {
                        if(error != nil) {
                            //NSLog(@"Error: %@",error);
                            //return;
                        }else{
                            //NSLog(@" Success");
                        }
                    }];
                }
                //__strong typeof(self) strongSelf = weakSelf;
                
                [self.messageText evaluateJavaScript:@"document.body.scrollHeight" completionHandler:^(NSNumber* _Nullable height, NSError * _Nullable error) {
                    //NSLog(@"Evaluated height = %ld", (long)height.integerValue);
                    long ht = height.intValue;
                    int htFullScreen = [[UIScreen mainScreen] bounds].size.height - self.messageText.frame.origin.y;
                    if (ht < htFullScreen) {
                        ht = htFullScreen;
                    }
                    [self.scroll setContentSize: CGSizeMake(/*[[UIScreen mainScreen] bounds].size.width-16*/self.view.frame.size.width-16, ht+self.messageText.frame.origin.y)];
                    
                    self.textHeightConstraint.constant = ht+12;
                    [self.messageText setFrame:CGRectMake(self.messageText.frame.origin.x, self.messageText.frame.origin.y, self.view.frame.size.width-16,ht+12)];
                    //self.viewInScrollHeightConstraint.constant = ht+self.messageText.frame.origin.y+12+48;
                    self.textWidthConstraint.constant = (int)(self.view.frame.size.width-16);
                    //NSLog(@"Frame set to %f,%f,%f", self.textWK.frame.size.height, self.viewInScroll.frame.size.height, self.textWK.frame.size.width);
                }];
                
            }];
            
            [CommonProcs hideSmallWheel];
        }else{
            [self.messageText evaluateJavaScript:@"document.body.scrollHeight" completionHandler:^(NSNumber* _Nullable height, NSError * _Nullable error) {
                //NSLog(@"Evaluated height = %ld", (long)height.integerValue);
                long ht = height.intValue;
                int htFullScreen = [[UIScreen mainScreen] bounds].size.height - self.messageText.frame.origin.y;
                if (ht < htFullScreen) {
                    ht = htFullScreen;
                }
                [self.scroll setContentSize: CGSizeMake([[UIScreen mainScreen] bounds].size.width-16, ht+self.messageText.frame.origin.y)];
                
                self.textHeightConstraint.constant = ht+12;
                [self.messageText setFrame:CGRectMake(self.messageText.frame.origin.x, self.messageText.frame.origin.y, self.view.frame.size.width-16,ht+12)];
                //self.viewInScrollHeightConstraint.constant = ht+self.messageText.frame.origin.y+12+48;
            }];
        }
    }];
    return;
}

-(void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    if(previousTraitCollection != nil){
        [self adjustWebViewSetWidthScale:YES];
    }
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {

    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        // TODO: put your code here (runs AFTER transition complete)
        [self adjustWebViewSetWidthScale:YES];
    }];
}

@end
