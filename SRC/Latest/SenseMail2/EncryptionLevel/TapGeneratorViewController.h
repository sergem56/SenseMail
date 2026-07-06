//
//  TapGeneratorViewController.h
//  SenseMailShare
//
//  Created by Sergey on 01.04.16.
//  Copyright © 2016 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <mach/mach_time.h>

@interface TapGeneratorViewController : UIViewController <UIGestureRecognizerDelegate>
{
    
}

@property (nonatomic, weak) IBOutlet UIProgressView* progress;
@property (nonatomic, weak) IBOutlet UILabel* tapArea;
@property (nonatomic, weak) IBOutlet UILabel* bytesLabel;
@property (nonatomic, weak) IBOutlet UITextView* collectedData;

-(IBAction)ok:(id)sender;
-(IBAction)cancel:(id)sender;

+(void)showTapDialogInNavController:(UINavigationController*)nav bytesToCollect:(int)btc semaphore:(dispatch_semaphore_t)sem;
+(void)showTapDialog:(dispatch_semaphore_t)sem bytesToCollect:(int)btc;
+(NSMutableData*)getResult;

@end
