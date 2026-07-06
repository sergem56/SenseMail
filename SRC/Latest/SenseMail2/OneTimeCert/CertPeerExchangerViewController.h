//
//  CertPeerExchangerViewController.h
//  SenseMailShare
//
//  Created by Sergey on 15.06.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Autocomplete;

@interface CertPeerExchangerViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>

@property (nonatomic, retain) NSArray* accounts;
@property (nonatomic, strong) Autocomplete* toAutocomplete;

@property (nonatomic, strong) IBOutlet UITextField* yourEmail;
@property (nonatomic, strong) IBOutlet UITextField* otherEmail;
@property (nonatomic, strong) NSString* otherEmailString;
@property (nonatomic, strong) IBOutlet UIButton* generateButton;
@property (nonatomic, strong) IBOutlet UIButton* receiveButton;

-(IBAction)generate:(id)sender;
-(IBAction)receive:(id)sender;
-(IBAction)cancel:(id)sender;
-(IBAction)iWillBeAGenerator:(id)sender;

// Debug
-(IBAction)getNextCert:(id)sender;
-(IBAction)deleteAll:(id)sender;

@end
