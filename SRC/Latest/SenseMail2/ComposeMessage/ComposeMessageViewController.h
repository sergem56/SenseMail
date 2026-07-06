//
//  ComposeMessageViewController.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "ComposeMessagePresenter.h"
#import "WindowMinimizer.h"

@class FullMessageEntity;
@class Autocomplete;
@class usePINViewController;
@class FloatingToolbar;
//@class WindowMinimizer;

@interface ComposeMessageViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UITextViewDelegate, UITextFieldDelegate, Minimized, WKUIDelegate, WKNavigationDelegate> {
    //NSString* pinCode;
    UIBarButtonItem* pinButton;
    UIBarButtonItem* attButton;
    
    UIBarButtonItem* pinButton22;
    UIBarButtonItem* attButton22;
    NSString* fromAddress;
    NSString* check;
    UIAlertController *controller;
    usePINViewController* windowController;
    BOOL canSend;
    FloatingToolbar* wkToolBar;
}

@property (nonatomic) FullMessageEntity* message;
@property (nonatomic, assign) BOOL answering;
@property (nonatomic, weak) ComposeMessagePresenter* presenter;

@property (nonatomic, strong) WindowMinimizer* minimizer;

@property (nonatomic) IBOutlet UITextField* addressTo;
@property (nonatomic, strong) Autocomplete* toAutocomplete;
@property (nonatomic) IBOutlet UITextField* subject;
@property (nonatomic) IBOutlet UITextView* messageText0;
@property (nonatomic, strong) IBOutlet WKWebView* messageText;
@property (nonatomic) IBOutlet NSLayoutConstraint* textHeightConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint* viewInScrollHeightConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint* textTopConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint* textWidthConstraint;
@property (nonatomic) IBOutlet UIScrollView* attScroll;
@property (nonatomic) IBOutlet UIScrollView* scroll;
@property (nonatomic) IBOutlet UIButton* addAttachmentButton;
@property (nonatomic) IBOutlet UILabel* attCount;
@property (nonatomic) IBOutlet UIButton* priorityButton;
@property (nonatomic) IBOutlet UIButton* readReceiptButton;
@property (nonatomic, strong) NSMutableString* pinCode;
@property (strong, nonatomic) UIToolbar *inputAccessoryToolbar;
@property (nonatomic, weak) IBOutlet UIView* viewInScroll;

@property (nonatomic) IBOutlet UITextField* addressFrom;
@property (nonatomic, retain) NSArray* accounts;

@property (nonatomic, assign) BOOL highPriority;

-(IBAction)setFromAccount:(id)sender;
-(IBAction)subjChanged:(id)sender;
-(IBAction)priorityChanged:(id)sender;
-(IBAction)needReadReceipt:(id)sender;

-(void)setupMessage:(BOOL)includeAttachments forward:(BOOL)forward;
-(void)setupAddress;
-(void)setupAttachmentIcons;
-(IBAction)needToAddAttachment:(id)sender;
-(IBAction)needToGetAddress:(id)sender;
-(void)needSend;

-(void)closeMessage;
-(void)closeMessageWithSentAnimation;
-(void)showError:(NSString*)error;

-(void)setCert:(NSString*)cert;

-(void)hideKeyboard;

-(BOOL)checkRestore:(NSString*)toCheckAgainst;

-(void)setPinColor;
-(void)needPINOnly;

@end
