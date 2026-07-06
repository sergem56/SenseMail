//
//  usePINViewController.m
//  SenseMailShare
//
//  Created by Sergey on 04/03/2019.
//  Copyright © 2019 Sergey. All rights reserved.
//

#import "usePINViewController.h"
#import "Encryptor.h"

@interface usePINViewController ()

@end

@implementation usePINViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [[self.contentView layer] setCornerRadius:6.0f];
    [[self.contentView layer] setMasksToBounds:YES];
    [[self.contentView layer] setBorderWidth:0.35f];
    [[self.contentView layer] setBorderColor:[UIColor lightGrayColor].CGColor];
    
    [[self.generatePassword layer] setCornerRadius:2.0f];
    [[self.generatePassword layer] setMasksToBounds:YES];
    [[self.generatePassword layer] setBorderWidth:0.35f];
    [[self.generatePassword layer] setBorderColor:[UIColor lightGrayColor].CGColor];
    /*
    [[self.sendButton layer] setCornerRadius:1.0f];
    [[self.sendButton layer] setMasksToBounds:YES];
    [[self.sendButton layer] setBorderWidth:0.35f];
    [[self.sendButton layer] setBorderColor:[UIColor lightGrayColor].CGColor];
    
    [[self.sendUnprotectedButton layer] setCornerRadius:1.0f];
    [[self.sendUnprotectedButton layer] setMasksToBounds:YES];
    [[self.sendUnprotectedButton layer] setBorderWidth:0.35f];
    [[self.sendUnprotectedButton layer] setBorderColor:[UIColor lightGrayColor].CGColor];
    
    [[self.cancelButton layer] setCornerRadius:1.0f];
    [[self.cancelButton layer] setMasksToBounds:YES];
    [[self.cancelButton layer] setBorderWidth:0.35f];
    [[self.cancelButton layer] setBorderColor:[UIColor lightGrayColor].CGColor];
     */
    
    [self.subTitleLabel setText:NSLocalizedString(@"Set a PIN-code for the message\nMutable PIN will be randomly mutated to enhance security", nil)];
    [self.titleLabel setText:NSLocalizedString(@"Enter PIN", nil)];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    // prevents the scroll view from swallowing up the touch event of child buttons
    tapGesture.cancelsTouchesInView = NO;
    [self.scroll addGestureRecognizer:tapGesture];
    
    [self registerForKeyboardNotifications];
}

-(void)hideKeyboard
{
    [self.view endEditing:YES];
}

-(IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)generatePassword:(id)sender
{
    self.pinText.text = @"";
    if (arc4random_uniform(2) == 1) {
        self.pinText.text = [Encryptor generatePhrase:3+arc4random()%2];
    }else{
        self.pinText.text = [Encryptor generateWord:2+arc4random_uniform(2)];
    }
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.pinText becomeFirstResponder];
    [self.scroll setContentSize:self.contentView.frame.size]; //CGSizeMake(self.view.frame.size.width, self.view.frame.size.height)];
}

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
}

- (void)keyboardWasShown:(NSNotification*)aNotification {
    
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scroll.contentInset.top, self.scroll.contentInset.left, kbSize.height+32, 0.0);
    self.scroll.contentInset = contentInsets;
    self.scroll.scrollIndicatorInsets = contentInsets;
    
    /*
    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.messageText.frame.origin) ) {
        [self.scroll scrollRectToVisible:self.messageText.frame animated:YES];
    }
     */
    
    
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
