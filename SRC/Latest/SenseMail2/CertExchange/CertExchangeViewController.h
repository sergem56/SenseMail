//
//  CertExchangeViewController.h
//  SenseMailShare
//
//  Created by Sergey on 06.04.16.
//  Copyright © 2016 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class CertExchangePresenter;
@class AddressBookEntity;

@interface CertExchangeViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate, UITextViewDelegate>
{
    //NSString* addr;
    //NSString* certificate;
    BOOL readNew;
    NSDateFormatter *dateFormatter;
}

@property (nonatomic, weak) IBOutlet UIScrollView* scroll;
@property (nonatomic, weak) IBOutlet UILabel* header;
@property (nonatomic, weak) IBOutlet UITextField* forDate;
@property (nonatomic, weak) IBOutlet UITextView* numericView;
@property (nonatomic, weak) IBOutlet UILabel* numericHeader;
@property (nonatomic, weak) IBOutlet UIImageView* QRView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint* leftConstraint;
@property (nonatomic, weak) IBOutlet UITextField* password;
@property (nonatomic, weak) IBOutlet UIButton* readQR;
@property (nonatomic, weak) IBOutlet UIButton* togglePwdButton;
@property (nonatomic, weak) IBOutlet UILabel* warningLabel;

@property (nonatomic, weak) CertExchangePresenter* presenter;
@property (nonatomic, strong) NSString* certificate;
@property (nonatomic, strong) NSString* address;
@property (nonatomic, weak) AddressBookEntity* addressBE;

// QR-reader
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic) BOOL isReading;

-(IBAction)generateNew:(id)sender;
-(IBAction)enterNew:(id)sender;
-(IBAction)sendByEmail:(id)sender;
-(IBAction)showPwd:(id)sender;
-(IBAction)forDateTouchDown:(id)sender;

-(void)addCert:(NSString *)cert forAddress:(NSString*)address; // Base64 encoded
-(void)setCert:(NSString *)cert keepOld:(BOOL)keep;
-(void)setCert:(NSString *)cert;
-(NSString*)getCertString;

@end
