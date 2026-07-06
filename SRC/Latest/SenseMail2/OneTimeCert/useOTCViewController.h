//
//  useOTCViewController.h
//  SenseMailShare
//
//  Created by Sergey on 18/12/2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class OneTimeCert;

NS_ASSUME_NONNULL_BEGIN

@interface useOTCViewController : UIViewController
{
    NSDate* expDate;
    BOOL useCalendarWheel;
}
@property (nonatomic, strong, nullable) OneTimeCert* cert;
@property (nonatomic, strong) IBOutlet UISwitch* useExpiration;
@property (nonatomic, strong) IBOutlet UISegmentedControl* expirationDate;
@property (nonatomic, strong) IBOutlet UIDatePicker* expirationDatePicker;
@property (nonatomic, copy) void(^completionBlock)(void);

-(IBAction)setExpirationValueChanged:(id)sender;
-(IBAction)expirationDateValueChanged:(id)sender;
-(IBAction)datePickerValueChanged:(id)sender;

@end

NS_ASSUME_NONNULL_END

