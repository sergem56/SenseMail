//
//  ModalDialogViewController.h
//  SenseMail2
//
//  Created by Sergey on 12.05.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ModalDialogViewController : UIViewController

+(NSString*)runWithHeader:(NSString*)header text1:(NSString*)text1 text2:(NSString*)text2 block:(dispatch_block_t)dblock;
+(NSString*)getText1;
+(NSString*)getText2;

@property (nonatomic, weak) IBOutlet UIButton* okButton;
@property (nonatomic, weak) IBOutlet UIButton* cancelButton;

-(IBAction)ok:(id)sender;
-(IBAction)cancel:(id)sender;

@end
