//
//  PinViewController.m
//  SenseMailShare
//
//  Created by Sergey on 29/03/2019.
//  Copyright © 2019 Sergey. All rights reserved.
//

#import <LocalAuthentication/LocalAuthentication.h>
#import "PinViewController.h"
#import "GlobalRouter.h"
#import "Encryptor.h"

@interface PinViewController ()

@end

@implementation PinViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self setupBioID];
    
    self.titleLabel.text = self.titleText;
    self.subTitleLabel.text = self.subTitleText;
    
    [self registerForKeyboardNotifications];
    [self.pinField becomeFirstResponder];
    
    [[self.cancelButton layer] setCornerRadius:8.0f];
    [[self.cancelButton layer] setMasksToBounds:YES];
    [[self.cancelButton layer] setBorderWidth:1.0f];
    [[self.cancelButton layer] setBorderColor:[UIColor redColor].CGColor];
    
    [[self.okButton layer] setCornerRadius:8.0f];
    [[self.okButton layer] setMasksToBounds:YES];
    [[self.okButton layer] setBorderWidth:1.0f];
    [[self.okButton layer] setBorderColor:[UIColor grayColor].CGColor];
    
    [[self.contentView layer] setCornerRadius:12.0f];
    [[self.contentView layer] setMasksToBounds:YES];
    [[self.contentView layer] setBorderWidth:1.0f];
    [[self.contentView layer] setBorderColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1].CGColor];

    [self placeView:self.view.frame.size.height];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"pinScrollBg"]];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    tapGesture.delegate = self;
    [self.scroll addGestureRecognizer:tapGesture];
    
    self.pinField.delegate = self;
}

-(void)hideKeyboard
{
    [self.view endEditing:YES];
}

-(void)placeView:(int)height
{
    int pss = height-300;
    if (pss < 0) {
        pss = 100;
    }
    self.topConstraint.constant = pss/5;
}

-(void)setupBioID
{
    LAContext* context = [[LAContext alloc] init];
    NSError* error;
    [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    NSString* bioType = nil;
    if (error) {
        [self.bioIDImage setImage:nil forState:UIControlStateNormal];// .imageView.image = nil;//[UIImage imageNamed:@"touchid"];
        [self.bioIDImage setTitle:@"" forState:UIControlStateNormal];
        self.bioButtonHeight.constant = 0;
        bioType = @"";//NSLocalizedString(@"No bio auth available", nil);
        self.bioID.enabled = NO;
        self.bioButtonWidth.constant = 0;
        self.cvHeightConstraint.constant = 240;
    }else{
        self.bioButtonHeight.constant = 48;
        self.bioID.enabled = YES;
        self.bioIDImage.enabled = YES;
        self.cvHeightConstraint.constant = 320;
        
        if (@available(iOS 11.0, *)) {
            switch (context.biometryType) {
                case LABiometryTypeFaceID:
                    //self.bioIDImage.imageView.image = [UIImage imageNamed:@"faceid"];
                    [self.bioIDImage setImage:[UIImage imageNamed:@"faceid"] forState:UIControlStateNormal];
                    bioType = NSLocalizedString(@"Face ID", nil);
                    break;
                    
                case LABiometryTypeTouchID:
                    //self.bioIDImage.imageView.image = [UIImage imageNamed:@"touchid"];
                    [self.bioIDImage setImage:[UIImage imageNamed:@"touchid"] forState:UIControlStateNormal];
                    bioType = NSLocalizedString(@"Touch ID", nil);
                    break;
                    
                default:
                    break;
            }
        } else {
            // Fallback on earlier versions
            //self.bioIDImage.imageView.image = [UIImage imageNamed:@"touchid"];
            [self.bioIDImage setImage:[UIImage imageNamed:@"touchid"] forState:UIControlStateNormal];
            bioType = NSLocalizedString(@"Touch ID", nil);
        }
    }
    [self.bioID setTitle:bioType forState:UIControlStateNormal];// .titleLabel.text = bioType;
}

/*
-(void)viewDidAppear:(BOOL)animated
{
    NSLog(@"Size = %fx%f, x=%f,%f", self.view.frame.size.width, self.view.frame.size.height, self.view.frame.origin.x, self.view.frame.origin.y);
}
*/

-(IBAction)cancel:(id)sender
{
    [[GlobalRouter sharedManager] needExit];
    //[self dismissViewControllerAnimated:YES completion:nil];
    //exit(0);
}

-(IBAction)ok:(id)sender
{
    [GlobalRouter sharedManager].pin = [NSMutableString stringWithString:self.pinField.text];
    self.okBlock();
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)bioTap:(id)sender
{
    NSMutableDictionary *returnDictionary00 = [[NSMutableDictionary alloc] init];
    SecAccessControlRef access = SecAccessControlCreateWithFlags(NULL,  // Use the default allocator.
                                                                 //kSecAttrAccessibleWhenUnlocked,
                                    kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                    kSecAccessControlUserPresence,
                                    NULL);
    [returnDictionary00 setObject:(__bridge id _Nonnull)(access) forKey:(__bridge id)kSecAttrAccessControl];
    [returnDictionary00 setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [returnDictionary00 setObject:@"SMService" forKey:(__bridge id)kSecAttrService];
    [returnDictionary00 setObject:@"SMAccount" forKey:(__bridge id)kSecAttrAccount];
    [returnDictionary00 setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnData];
    [returnDictionary00 setObject:@"Touch ID" forKey:(__bridge id)kSecUseOperationPrompt];
    CFDataRef passwordData = NULL;
    OSStatus err00 = SecItemCopyMatching((__bridge CFDictionaryRef)returnDictionary00, (CFTypeRef *)&passwordData);
    if(err00 != errSecSuccess) {
        //Check the error
        [self.bioID setTitle:NSLocalizedString(@"Biometric ID is not enabled",nil) forState:UIControlStateNormal];
    }
    if (passwordData) {
        NSData* pd = (__bridge NSData*)passwordData;
        NSString* stored = [[NSString alloc] initWithData:pd encoding:NSUTF8StringEncoding];
        NSString* kkk = [[UIDevice currentDevice].identifierForVendor UUIDString];
        Encryptor* cryptor = [[Encryptor alloc] initWithSimpleKey:kkk];
        stored = [cryptor decryptFromBase64:stored];
        //NSLog(@"Stored value %@", stored);
        self.pinField.text = stored;
        [self ok:self.okButton];
    }
}

// Enable return key for ok button
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self ok:textField];
    return YES;
}

#pragma mark - Keyboard show/hide scroll change
-(void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    int toAdd = 32;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scroll.contentInset.top, self.scroll.contentInset.left, kbSize.height+toAdd, 0.0);
    
    self.scroll.contentInset = contentInsets;
    self.scroll.scrollIndicatorInsets = contentInsets;
    
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= (kbSize.height+toAdd);
    
    kbHeight = kbSize.height;
    //self.topConstraint.constant = (aRect.size.height-kbHeight)/4; // this cause the view jump up
    
    UIView* activeField;
    for (UIView *subView in self.contentView.subviews) {
        if ([subView isFirstResponder]) {
            activeField = subView;
        }
    }
    
    if (activeField != nil && !CGRectContainsPoint(aRect, activeField.frame.origin) ) {
        //CGPoint scrollPoint = CGPointMake(0.0, activeField.frame.origin.y-kbSize.height);
        CGPoint scrollPoint = CGPointMake(0.0, activeField.frame.origin.y - aRect.size.height + toAdd);
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [self placeView:size.height];
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
