//
//  AddViewController.h
//  SenseMail2
//
//  Created by Sergey on 15.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AddressBookPresenter;
@class AddressBookEntity;

@interface AddViewController : UIViewController

@property (nonatomic, weak) AddressBookPresenter* presenter;
@property (nonatomic, strong) AddressBookEntity* item;

@property (nonatomic) IBOutlet UITextField* name;
@property (nonatomic) IBOutlet UITextField* email;
@property (nonatomic) IBOutlet UITextField* note;
@property (nonatomic) IBOutlet UITextField* groupName;
@property (nonatomic, strong) IBOutlet UILabel* certLabel;
@property (nonatomic, strong) IBOutlet UIButton* resendButton;
@property (nonatomic, strong) IBOutlet UIButton* deleteButton;

-(void)updateItem;

-(IBAction)writeMail:(id)sender;
-(IBAction)sendCertificate:(id)sender;
-(IBAction)reSendCertificate:(id)sender;
-(IBAction)deleteCertificate:(id)sender;

@end
