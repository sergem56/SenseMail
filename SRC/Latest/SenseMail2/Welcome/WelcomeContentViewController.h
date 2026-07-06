//
//  WelcomeContentViewController.h
//  SenseMailShare
//
//  Created by Sergey on 28.09.16.
//  Copyright © 2016 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WelcomeContentViewController : UIViewController
{

}
@property (nonatomic, weak) IBOutlet UITextField* pinText;

-(IBAction)nextStep:(id)sender;
-(IBAction)exit:(id)sender;
-(IBAction)gotoSettings:(id)sender;
-(IBAction)later:(id)sender;

-(NSString*)getPin;

@end
