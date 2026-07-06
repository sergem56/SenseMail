//
//  PinViewController.h
//  SenseMailShare
//
//  Created by Sergey on 29/03/2019.
//  Copyright © 2019 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PinViewController : UIViewController <UIGestureRecognizerDelegate, UITextFieldDelegate>
{
    int kbHeight;
}

@property (nonatomic, strong) NSString* titleText;
@property (nonatomic, strong) NSString* subTitleText;

@property (nonatomic, strong) IBOutlet UILabel* titleLabel;
@property (nonatomic, strong) IBOutlet UILabel* subTitleLabel;
@property (nonatomic, strong) IBOutlet UITextField* pinField;
@property (nonatomic, strong) IBOutlet UIButton* bioID;
@property (nonatomic, strong) IBOutlet UIButton* bioIDImage;
@property (nonatomic, strong) IBOutlet UIButton* cancelButton;
@property (nonatomic, strong) IBOutlet UIButton* okButton;
@property (nonatomic, strong) IBOutlet UIScrollView* scroll;
@property (nonatomic, strong) IBOutlet UIStackView* buttonsStack;
@property (nonatomic, strong) IBOutlet UIView* contentView;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint* bioButtonHeight;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* bioButtonWidth;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* topConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* cvHeightConstraint;

@property (nonatomic, copy, nullable) void (^okBlock)(void);

-(void)setupBioID;
-(IBAction)cancel:(id)sender;
-(IBAction)ok:(id)sender;
-(IBAction)bioTap:(id)sender;


@end

NS_ASSUME_NONNULL_END
