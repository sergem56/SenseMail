//
//  MessageViewController.h
//  SenseMail2
//
//  Created by Sergey on 30.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FullMessageEntity.h"

@class MessageViewPresenter;

@interface MessageViewController : UIViewController{
    dispatch_block_t alertBlock;
}

@property (nonatomic) FullMessageEntity* currentMessage;
@property (nonatomic) IBOutlet NSLayoutConstraint* topTextConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint* textWidthConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint* textHeightConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint* attScrollWidthConstraint;

@property (nonatomic, weak) MessageViewPresenter* presenter;
@property (nonatomic) IBOutlet UIScrollView* scroll;
@property (nonatomic) IBOutlet UITextView* Ttext;
@property (nonatomic) IBOutlet UIWebView* text;

@property (nonatomic) IBOutlet UILabel* subjLabel;
@property (nonatomic) IBOutlet UIView* viewInScroll;
//@property (nonatomic) IBOutlet UIScrollView* attScroll;

-(IBAction)done:(id)sender;
-(IBAction)toggleAttachmentStrip:(id)sender;
-(IBAction)saveAllAttachments:(id)sender;

-(void)updateMessageView;

-(IBAction)wantReplyToMessage:(id)sender;
-(IBAction)wantForwardMessage:(id)sender;
-(IBAction)wantMarkMessage:(id)sender;
-(IBAction)wantDeleteMessage:(id)sender;
-(IBAction)addContact:(id)sender;
//-(void)wantShowAttachment:(UIImage*)attachment;

-(void)showError:(NSString*)error;
-(void)askAndDoWithTitle:(NSString*)title text:(NSString*)alertText block:(dispatch_block_t)block;

@end
