//
//  CertExchangeViewController.m
//  SenseMailShare
//
//  Created by Sergey on 06.04.16.
//  Copyright © 2016 Sergey. All rights reserved.
//

#import "CertExchangeViewController.h"
#import "GlobalRouter.h"
#import "Encryptor.h"
#import "CertExchangePresenter.h"
#import "AddressBookEntity.h"

@interface CertExchangeViewController ()

@end

#define placeHolderText [NSString stringWithFormat:NSLocalizedString(@"No certificate. Please, enter one here, generate new or read QR-code from %@",nil), self.address]

@implementation CertExchangeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.numericView.delegate = self;
    [[self.numericView layer] setBorderWidth:1.0f];
    [[self.numericView layer] setBorderColor:[UIColor lightGrayColor].CGColor];
    [self.numericView setText:@""];
    
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
    
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needSaveCert)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeView)];
    
    [self setToolbarItems:[NSArray arrayWithObjects: button1, flexibleItem, button2, nil]];
    
    //if(self.certificate != nil)
        [self addCert:self.certificate forAddress:self.address];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    // prevents the scroll view from swallowing up the touch event of child buttons
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
    
    //static NSDateFormatter *dateFormatter = nil;
    if(dateFormatter == nil){
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        //[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    
    [self registerForKeyboardNotifications];
    
    UIBarButtonItem* button12 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needSaveCert)];
    UIBarButtonItem *flexibleItem2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button22 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeView)];
    UIToolbar* inputAccessoryToolbar = [[UIToolbar alloc] init];
    inputAccessoryToolbar.frame = CGRectMake(0,0,250,44);
    inputAccessoryToolbar.items = [NSArray arrayWithObjects: button12, flexibleItem2, button22, nil];
    self.password.inputAccessoryView = inputAccessoryToolbar;
    self.numericView.inputAccessoryView = inputAccessoryToolbar;
    
    [self setLeftConstraintValue];
    
    [self.warningLabel setText:NSLocalizedString(@"For security reasons we do not show the QR-code and its password at the same time", nil)];
    //[self.QRView setFrame:CGRectMake(self.QRView.frame.origin.x, self.QRView.frame.origin.y, 300, 300)];
}

-(void)hideKeyboard
{
    [self.view endEditing:YES];
}

-(void)setLeftConstraintValue
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenHeight = screenRect.size.height;
    CGFloat screenWidth = screenRect.size.width;
    
    float lft = screenWidth/2-(screenHeight/2-60);
    if (lft <= 40) {
        lft = 40;
    }
    NSInteger horizontalClass = self.traitCollection.horizontalSizeClass;
    NSInteger verticalCass = self.traitCollection.verticalSizeClass;
    if (horizontalClass == UIUserInterfaceSizeClassRegular && verticalCass == UIUserInterfaceSizeClassRegular) {
        lft = 200;
    }
    self.leftConstraint.constant = lft;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    
    //CGRect screenRect = [[UIScreen mainScreen] bounds];
    
    CGFloat screenHeight = size.height;
    CGFloat screenWidth = size.width;
    
    float lft = screenWidth/2-(screenHeight/2-60);
    if (lft <= 40) {
        lft = 40;
    }
    
    NSInteger horizontalClass = self.traitCollection.horizontalSizeClass;
    NSInteger verticalCass = self.traitCollection.verticalSizeClass;
    if (horizontalClass == UIUserInterfaceSizeClassRegular && verticalCass == UIUserInterfaceSizeClassRegular) {
        lft = 200;
    }
    self.leftConstraint.constant = lft;
    /*
    if(screenWidth > screenHeight){
        self.leftConstraint.constant = screenWidth/2-120; //70 + (screenWidth - screenHeight)/2;
    }else{
        self.leftConstraint.constant = screenWidth/2-120; //20;
    }
    */
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}


-(void)needSaveCert
{
    [self.presenter needSaveCert:self.numericView.text pwd:self.password.text];
}

-(void)closeView
{
    //[self setCert:nil];
    //[[GlobalRouter sharedManager] finishedWithCurrentView:YES];
    
    if (_isReading) {
        [self stopReading];
    }else{
        [self.presenter wantCloseCert:[self getCertString]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)generateNew:(id)sender
{
    [Encryptor generateCert:self];
}

-(void)setCert:(NSString *)cert keepOld:(BOOL)keep // cert is in BASE64!!!
{
    if(!keep){
        [self addCert:cert forAddress:self.address];
        //[self.presenter setSavedCertString:self.numericView.text];
        
        //self.addressBE.key = (cert != nil) || self.addressBE.key;
    }
}

-(void)setCert:(NSString *)cert
{
    [self setCert:cert keepOld:NO];
}

// Read QR-Code
-(IBAction)enterNew:(id)sender
{
    if (!_isReading) {
        // This is the case where the app should read a QR code when the start button is tapped.
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:NSLocalizedString(@"Quick tip",nil)
                                     message:NSLocalizedString(@"ReadQRTip", @"")
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* start = [UIAlertAction
                                  actionWithTitle:NSLocalizedString(@"Start", nil)
                                  style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * action)
                                  {
                                      self.QRView.alpha = 1.0;
                                      if ([self startReading]) {
                                          [self.readQR setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
                                      }
                                  }];
        [alert addAction:start];
        
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction * action)
                                 {
                                     
                                 }];
        [alert addAction:cancel];
        
        UIView* pView = self.view; //[[GlobalRouter sharedManager] getCurrentView];
        alert.popoverPresentationController.sourceView = pView;
        alert.popoverPresentationController.sourceRect = pView.frame;
        [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
    }
    else{
        // In this case the app is currently reading a QR code and it should stop doing so.
        [self stopReading];
        [self.readQR setTitle:NSLocalizedString(@"Scan QR", nil) forState:UIControlStateNormal];
    }
}

// This is disabled since it is totally insecure
-(IBAction)sendByEmail:(id)sender
{
    
}

-(NSString*)getCertString
{
    if ([self.numericView.text isEqualToString:placeHolderText]) {
        return nil;
    }
    return self.numericView.text;
}

-(NSString*)getCheckSum
{
    NSString* ret;
    
    return ret;
}

-(IBAction)showPwd:(id)sender
{
    self.password.secureTextEntry = !self.password.secureTextEntry;
    self.QRView.hidden = !self.password.secureTextEntry;
    
    NSString* imageName = self.password.secureTextEntry?@"eye":@"eye-close";
    [self.togglePwdButton setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];

}

// Cert is in Base64
-(void)addCert:(NSString *)cert forAddress:(NSString*)address
{
    //if(![NSThread isMainThread]){
    //dispatch_async(dispatch_get_main_queue(), ^{
    NSMutableString* res = [[NSMutableString alloc] init];
    if(!(cert == nil || [cert  isEqual: INVALID_CERT])){
        
        //NSLog(@"Setting cert %@", cert);
        
        NSData* certData = [[NSData alloc] initWithBase64EncodedString:cert options:NSDataBase64DecodingIgnoreUnknownCharacters];
        
        //TODO: Encrypt cert with a password to show?
        // If cert is scanned and is already encrypted???
        if(!readNew){
            NSArray* enc = [self.presenter encryptCertForPresentation:certData];
            [self.password setText:[enc firstObject]];
            certData = [enc lastObject];
        }else{
            self.password.userInteractionEnabled = YES;
            readNew = NO;
        }
        
        [certData enumerateByteRangesUsingBlock:^(const void *bytes, NSRange byteRange, BOOL *stop)
        {
            [res appendFormat:@"%d", ((uint8_t*)bytes)[0]];
            for (NSUInteger i = 1; i < byteRange.length; ++i) {
                [res appendFormat:@" %d", ((uint8_t*)bytes)[i]];
            }
            
        }];
        
        self.numericView.text = res;
        if (@available(iOS 13.0, *)) {
            self.numericView.textColor = [UIColor labelColor];
        } else {
            // Fallback on earlier versions
            self.numericView.textColor = [UIColor blackColor];
        }
        
        CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
        
        [filter setDefaults];
        
        NSData *data = [res dataUsingEncoding:NSUTF8StringEncoding];
        [filter setValue:data forKey:@"inputMessage"];
        
        CIImage *outputImage = [filter outputImage];
        
        CIContext *context = [CIContext contextWithOptions:nil];
        CGImageRef cgImage = [context createCGImage:outputImage
                                           fromRect:[outputImage extent]];
        
        UIImage *image = [UIImage imageWithCGImage:cgImage scale:1. orientation:UIImageOrientationUp];
        
        // Resize without interpolating
        UIImage *resized = [self resizeImage:image withQuality:kCGInterpolationNone rate:5.0];
        
        self.QRView.image = resized;
        self.QRView.alpha = 1.0;
        CGImageRelease(cgImage);
        self.certificate = cert;
        
        //self.forDate.text = [dateFormatter stringFromDate:<#(nonnull NSDate *)#>];
    }else{
        //self.numericView.text = [NSString stringWithFormat:NSLocalizedString(@"No certificate. Please, enter one here, generate new or read QR-code from %@",nil), address];
        self.numericView.text = @"";
        [self textViewDidEndEditing:self.numericView];
        self.QRView.image = nil;
        self.certificate = nil;
        
        CIFilter *filter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
        [filter setDefaults];
        NSData *data = [@"NO CERTIFICATE IS SET" dataUsingEncoding:NSUTF8StringEncoding];
        [filter setValue:data forKey:@"inputMessage"];
        
        CIImage *outputImage = [filter outputImage];
        
        CIContext *context = [CIContext contextWithOptions:nil];
        CGImageRef cgImage = [context createCGImage:outputImage fromRect:[outputImage extent]];
        UIImage *image = [UIImage imageWithCGImage:cgImage scale:1. orientation:UIImageOrientationUp];
        // Resize without interpolating
        UIImage *resized = [self resizeImage:image withQuality:kCGInterpolationNone rate:5.0];
        self.QRView.alpha = 0.2;
        self.QRView.image = resized;
        CGImageRelease(cgImage);
    }
    self.header.text = [NSString stringWithFormat:NSLocalizedString(@"Certificate for %@",nil), address];
    self.address = address;
    //});
}

- (UIImage *)resizeImage:(UIImage *)image withQuality:(CGInterpolationQuality)quality rate:(CGFloat)rate
{
    UIImage *resized = nil;
    CGFloat width = image.size.width * rate;
    CGFloat height = image.size.height * rate;
    
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, quality);
    [image drawInRect:CGRectMake(0, 0, width, height)];
    resized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resized;
}

#pragma mark - QR-Reader stuff

- (BOOL)startReading {
    NSError *error;
    
    // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
    // as the media type parameter.
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // Get an instance of the AVCaptureDeviceInput class using the previous device object.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    
    if (!input) {
        // If any error occurs, simply log the description of it and don't continue any more.
        NSLog(@"%@", [error localizedDescription]);
        return NO;
    }
    
    // Initialize the captureSession object.
    _captureSession = [[AVCaptureSession alloc] init];
    // Set the input device on the capture session.
    [_captureSession addInput:input];
    
    
    // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [_captureSession addOutput:captureMetadataOutput];
    
    // Create a new serial dispatch queue.
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [_videoPreviewLayer setFrame:self.QRView.layer.bounds];
    [self.QRView.layer addSublayer:_videoPreviewLayer];
    
    
    // Start video capture.
    
    [_captureSession startRunning];
    
    _isReading = YES;
    
    return YES;
}


-(void)stopReading{
    // Stop video capture and make the capture session object nil.
    [_captureSession stopRunning];
    _captureSession = nil;
    
    // Remove the video preview layer from the viewPreview view's layer.
    [_videoPreviewLayer removeFromSuperlayer];
    _isReading = NO;
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate method implementation

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    // Check if the metadataObjects array is not nil and it contains at least one object.
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        // Get the metadata object.
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            // If the found metadata is equal to the QR code metadata then update the status label's text,
            // stop reading and change the bar button item's title and the flag's value.
            // Everything is done on the main thread.
            
            //[ performSelectorOnMainThread:@selector(setText:) withObject:[metadataObj stringValue] waitUntilDone:NO];
            
            [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
            //[_bbitemStart performSelectorOnMainThread:@selector(setTitle:) withObject:@"Start!" waitUntilDone:NO];
            
            NSMutableData* ret = [[NSMutableData alloc] initWithCapacity:32];
            NSArray* bytes = [[metadataObj stringValue] componentsSeparatedByString:@" "];
            for (NSString* byte in bytes) {
                int8_t i = (uint8_t)[byte intValue];
                [ret appendBytes:&i length:1];
            }
            
            // TODO: Need to decrypt the data, if it has a password
            // Ask for a password...
            
            NSString* retBase = [ret base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
            readNew = YES;
            [self performSelectorOnMainThread:@selector(setCert:) withObject:retBase waitUntilDone:YES];
            _isReading = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.readQR setTitle:NSLocalizedString(@"Scan QR", nil) forState:UIControlStateNormal];
            });
        }
    }
}


-(void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:placeHolderText]) {
        textView.text = @"";
        if (@available(iOS 13.0, *)) {
            textView.textColor = [UIColor labelColor];
        } else {
            // Fallback on earlier versions
            textView.textColor = [UIColor blackColor];
        } //optional
    }
    [textView becomeFirstResponder];
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        textView.text = placeHolderText;
        textView.textColor = [UIColor lightGrayColor]; //optional
    }
    [textView resignFirstResponder];
}

-(IBAction)forDateTouchDown:(id)sender
{
    if(self.forDate.inputView == nil)
    {
        UIDatePicker *datePicker = [[UIDatePicker alloc] init];
        datePicker.datePickerMode = UIDatePickerModeDate;
        [datePicker addTarget:self action:@selector(updateForDateText:) forControlEvents:UIControlEventValueChanged];
        [self.forDate setInputView:datePicker];
    }
}

-(void)updateForDateText:(UIDatePicker*)sender
{
    //static NSDateFormatter *dateFormatter = nil;
    if(dateFormatter == nil){
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    self.forDate.text = [dateFormatter stringFromDate:sender.date];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification {
    
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scroll.contentInset.top, self.scroll.contentInset.left, kbSize.height+44, 0.0);
    self.scroll.contentInset = contentInsets;
    self.scroll.scrollIndicatorInsets = contentInsets;
    
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= (kbSize.height+44);
    UIView* activeField;
    if ([self.password isFirstResponder]) {
        activeField = self.password;
    }
    
    if (activeField != nil && !CGRectContainsPoint(aRect, activeField.frame.origin) ) {
        //CGPoint scrollPoint = CGPointMake(0.0, activeField.frame.origin.y-kbSize.height);
        CGPoint scrollPoint = CGPointMake(0.0, activeField.frame.origin.y - aRect.size.height + 44);
        [self.scroll setContentOffset:scrollPoint animated:YES];
    }
    
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    //UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scroll.contentInset.top, 0.0, 32, 0.0);
    self.scroll.contentInset = contentInsets;
    self.scroll.scrollIndicatorInsets = contentInsets;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}


@end
