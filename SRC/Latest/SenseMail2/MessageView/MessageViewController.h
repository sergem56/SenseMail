//
//  MessageViewController.h
//  SenseMail2
//
//  Created by Sergey on 30.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "FullMessageEntity.h"

@class MessageViewPresenter;
@class CommonProcs;

@interface MessageViewController : UIViewController <UIActionSheetDelegate, UIGestureRecognizerDelegate, WKUIDelegate, WKNavigationDelegate> {
    dispatch_block_t alertBlock;
    CommonProcs* cp;
    BOOL finishedLoading;
    CGFloat lastScale;
    //BOOL allowLoad;
    BOOL fromExpanded;
    float currentZoom;
}

@property (nonatomic) FullMessageEntity* currentMessage;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* viewInScrollWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* viewInScrollHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* textWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* textHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* attScrollWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* attScrollHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* subjWidthConstraint;
@property (nonatomic, weak) NSLayoutConstraint* heightConstraint;

@property (nonatomic, weak) MessageViewPresenter* presenter;
@property (nonatomic, weak) IBOutlet UIScrollView* scroll;
@property (nonatomic, weak) IBOutlet UITextView* Ttext;
//@property (nonatomic, weak) IBOutlet UIWebView* text;
@property (nonatomic, strong) WKWebView* textWK;

@property (nonatomic, weak) IBOutlet UILabel* subjLabel;
@property (nonatomic, weak) IBOutlet UIView* viewInScroll;
@property (nonatomic, weak) IBOutlet UIScrollView* attScroll;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* actionButton;
@property (nonatomic, assign) int fontSize;
@property (nonatomic, assign) BOOL plainView;

-(IBAction)done:(id)sender;
-(IBAction)toggleAttachmentStrip:(id)sender;
-(IBAction)saveAllAttachments:(id)sender;

-(void)updateMessageView;

-(IBAction)wantReplyToMessage:(id)sender;
-(IBAction)wantForwardMessage:(id)sender;
-(IBAction)wantMarkMessage:(id)sender;
-(IBAction)wantDeleteMessage:(id)sender;
-(IBAction)addContact:(id)sender;

-(IBAction)nextMessage:(id)sender;
-(IBAction)prevMessage:(id)sender;

-(IBAction)increaseFontSize:(id)sender;
-(IBAction)decreaseFontSize:(id)sender;

-(IBAction)textHtmlView:(id)sender;
//-(void)wantShowAttachment:(UIImage*)attachment;

-(void)showError:(NSString*)error;
//-(void)askAndDoWithTitle:(NSString*)title text:(NSString*)alertText block:(dispatch_block_t)block;

@end
