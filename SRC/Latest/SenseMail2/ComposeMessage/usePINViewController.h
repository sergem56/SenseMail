//
//  usePINViewController.h
//  SenseMailShare
//
//  Created by Sergey on 04/03/2019.
//  Copyright © 2019 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface usePINViewController : UIViewController

@property (nonatomic, weak) id parent;

@property (nonatomic, strong) IBOutlet UILabel* titleLabel;
@property (nonatomic, strong) IBOutlet UILabel* subTitleLabel;
@property (nonatomic, strong) IBOutlet UITextField* pinText;
@property (nonatomic, strong) IBOutlet UIButton* generatePassword;
@property (nonatomic, strong) IBOutlet UISegmentedControl* expireSegments;
@property (nonatomic, strong) IBOutlet UIButton* sendButton;
@property (nonatomic, strong) IBOutlet UIButton* sendUnprotectedButton;
@property (nonatomic, strong) IBOutlet UIButton* cancelButton;
@property (nonatomic, strong) IBOutlet UIView* contentView;
@property (nonatomic, strong) IBOutlet UIScrollView* scroll;

-(IBAction)generatePassword:(id)sender;
-(IBAction)cancel:(id)sender;
@end

NS_ASSUME_NONNULL_END
