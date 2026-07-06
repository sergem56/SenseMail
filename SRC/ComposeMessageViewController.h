//
//  ComposeMessageViewController.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ComposeMessagePresenter.h"

@class FullMessageEntity;

@interface ComposeMessageViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate> {
    NSString* pinCode;
    UIBarButtonItem* pinButton;
    UIBarButtonItem* attButton;
    NSString* fromAddress;
}

@property (nonatomic) FullMessageEntity* message;
@property (nonatomic, weak) ComposeMessagePresenter* presenter;

@property (nonatomic) IBOutlet UITextField* addressTo;
@property (nonatomic) IBOutlet UITextField* subject;
@property (nonatomic) IBOutlet UITextView* messageText;
@property (nonatomic) IBOutlet NSLayoutConstraint* textHeightConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint* textTopConstraint;
@property (nonatomic) IBOutlet UIScrollView* attScroll;
@property (nonatomic) IBOutlet UIScrollView* scroll;
@property (nonatomic) IBOutlet UIButton* addAttachmentButton;

@property (nonatomic) IBOutlet UITextField* addressFrom;
@property (nonatomic, retain) NSArray* accounts;
-(IBAction)setFromAccount:(id)sender;


-(void)setupMessage:(BOOL)includeAttachments forward:(BOOL)forward;
-(void)setupAddress;
-(void)setupAttachmentIcons;
-(IBAction)needToAddAttachment:(id)sender;
-(IBAction)needToGetAddress:(id)sender;

-(void)closeMessage;
-(void)showError:(NSString*)error;

@end
