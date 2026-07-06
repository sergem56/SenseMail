//
//  useOTCViewController.m
//  SenseMailShare
//
//  Created by Sergey on 18/12/2018.
//  Copyright © 2018 Sergey. All rights reserved.
//
//#import <Foundation/NSCalendar.h>

#import "useOTCViewController.h"
#import "GlobalRouter.h"
#import "OneTimeCert.h"


@interface useOTCViewController ()

@end

@implementation useOTCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem* button0 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Use PIN...",nil) style:UIBarButtonItemStylePlain target:self action:@selector(usePIN)];
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send",nil) style:UIBarButtonItemStylePlain target:self action:@selector(useOTC:)];//[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(useOTC:)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    [self setToolbarItems:[NSArray arrayWithObjects: button0, flexibleItem, button1, button2, nil]];
    
    self.expirationDatePicker.enabled = NO;
    self.expirationDate.selectedSegmentIndex = 0;
    //expDate = [NSDate dateWithTimeIntervalSinceNow:24*60*60];
    NSDateComponents* dayComponent = [[NSDateComponents alloc] init];
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDate* std = [theCalendar startOfDayForDate:[NSDate date]];
    dayComponent.second = -1;
    dayComponent.day = -1;
    expDate = [theCalendar dateByAddingComponents:dayComponent toDate:std options:0];
}

-(IBAction)setExpirationValueChanged:(id)sender
{
    if (self.useExpiration.isOn) {
        self.expirationDate.enabled = YES;
        self.expirationDate.selectedSegmentIndex = 0;
        expDate = [NSDate dateWithTimeIntervalSinceNow:24*60*60];
    }else{
        self.expirationDate.enabled = NO;
        self.expirationDatePicker.enabled = NO;
        expDate = nil;//[NSDate dateWithTimeIntervalSinceNow:50*365*24*60*60]; // set it 50 years ahead
    }
}

-(void)usePIN
{
    self.cert.yourEmail = nil;
    self.completionBlock();
}

-(void)useOTC:(id)sender
{
    self.cert.expirationDate = [OneTimeCert getStringForDate:expDate];
    self.completionBlock();
}

-(IBAction)cancel:(id)sender
{
    [[GlobalRouter sharedManager] finishedWithDetailView:YES];// finishedWithCurrentView];
}

-(IBAction)expirationDateValueChanged:(id)sender
{
    NSDateComponents* dayComponent = [[NSDateComponents alloc] init];
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDate* std = [theCalendar startOfDayForDate:[NSDate date]];
    dayComponent.second = -1; // Set the expiration date to the end of the day adding an extra day without a second
    switch (self.expirationDate.selectedSegmentIndex) {
        case 0:
            dayComponent.day = -1;
            expDate = [theCalendar dateByAddingComponents:dayComponent toDate:std options:0];
            break;
        case 1:
            dayComponent.day = 2;
            expDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
            break;
            
        case 2:
            dayComponent.day = 4;
            expDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
            break;
            
        case 3:
            dayComponent.day = 8; // assume a 30-day month
            expDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];
            break;
            
        case 4:
            useCalendarWheel = YES;
            [_expirationDatePicker setMinimumDate: [NSDate date]];
            break;
        default:
            break;
    }
    
    if (self.expirationDate.selectedSegmentIndex == 4) {
        self.expirationDatePicker.enabled = YES;
    }else{
        self.expirationDatePicker.enabled = NO;
        useCalendarWheel = NO;
    }
}

-(IBAction)datePickerValueChanged:(id)sender
{
    NSDateComponents* dayComponent = [[NSDateComponents alloc] init];
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDate* std = [theCalendar startOfDayForDate:self.expirationDatePicker.date];
    dayComponent.second = -1;
    dayComponent.day = 1;
    expDate = [theCalendar dateByAddingComponents:dayComponent toDate:std options:0];
    //expDate = self.expirationDatePicker.date;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
