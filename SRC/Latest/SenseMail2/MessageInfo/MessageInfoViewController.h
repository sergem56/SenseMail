//
//  MessageInfoViewController.h
//  SenseMailShare
//
//  Created by Sergey on 02.02.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MessageInfoViewController : UIViewController

@property (nonatomic, strong) /*NSString**/ NSMutableAttributedString* messageInfo;

@property (nonatomic, weak) IBOutlet UITextView* info;

@end
