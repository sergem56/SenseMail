//
//  ComposeMessageViewController.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "ComposeMessageViewController.h"
#import "FullMessageEntity.h"
#import "GlobalRouter.h"
#import "CommonProcs.h"
#import "Encryptor.h"

@interface ComposeMessageViewController ()

@end

@implementation ComposeMessageViewController

@synthesize presenter, message;

BOOL sending = NO;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (message.messageID == nil) {
        self.textTopConstraint.constant = 8;
        //[self setupMessage:YES forward:NO];
    }else{
        //[self setupMessage];
    }
    
    self.navigationController.toolbarHidden = NO;
    UIBarButtonItem* button0 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(needSend)];
    UIBarButtonItem *fixedItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedItem.width = 7;
    attButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"📎",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(needToAddAttachment:)];
    pinButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"PIN",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(needPin)];
    pinButton.tintColor = [UIColor redColor];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeMessage)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:pinButton,fixedItem, attButton, fixedItem, button0, flexibleItem, button2, nil]];
    
    [self registerForKeyboardNotifications];
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    // prevents the scroll view from swallowing up the touch event of child buttons
    tapGesture.cancelsTouchesInView = NO;
    [self.scroll addGestureRecognizer:tapGesture];
    
    UIPickerView *picker = [[UIPickerView alloc] init];
    picker.dataSource = self;
    picker.delegate = self;
    self.addressFrom.inputView = picker;
    self.accounts = [[GlobalRouter sharedManager].accountsNames allKeys];
    
    [self setupMessage:YES forward:NO];
}

-(void)setupAddress
{
    self.addressTo.text = message.fromAddress;
}

-(void)setupMessage:(BOOL)includeAttachments forward:(BOOL)forward
{
    if(self.message == nil){
        self.message = [[FullMessageEntity alloc] init];
        self.messageText.text = @"  ";
        self.addressTo.text = @"";
        self.subject.text = @"";
        self.textTopConstraint.constant = 8;
        NSArray *viewsToRemove = [self.attScroll subviews];
        for (UIView *v in viewsToRemove) [v removeFromSuperview];
        self.addressFrom.text = @"";
        
    }else{
        if(message.messageBody != nil && self.message.encType != enTypePasswordForCert){
            //self.messageText.text = [NSString stringWithFormat:@"-----\n%@, %@\n\n%@",message.fromAddress, message.date, message.messageBody];
            //body = [NSString stringWithFormat:@"<span style=\"font-family: %@; font-size: %i\">%@</span>",@"Helvetica", 14, body];
            self.messageText.attributedText = [[NSAttributedString alloc] initWithData:[[NSString stringWithFormat:@"<span style=\"font-family: Helvetica; font-size: 14\"><br>-----<br>%@, %@<br><br>%@</span>",message.fromAddress, message.date, message.messageBody] dataUsingEncoding:NSUTF8StringEncoding]
                                             options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                       NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                  documentAttributes:nil error:nil];
        }else
            self.messageText.text = @"";
        if(!forward){
            self.addressTo.text = message.fromAddress;
        }
        if(message.subject != nil){
            if(forward){
                self.subject.text = [NSString stringWithFormat:@"Re:%@",message.subject];
            }else{
                self.subject.text = [NSString stringWithFormat:@"Fwd:%@",message.subject];
            }
        }else
            self.subject.text = @"";
        if (message.attachments.count == 0) {
            self.textTopConstraint.constant = 8;
        }
        
        if (!includeAttachments) {
            [message.attachments removeAllObjects];
        }
        [self setupAttachmentIcons];
        
        fromAddress = message.toAddress;
        if(fromAddress != nil){
            NSString* nameAcc = [[GlobalRouter sharedManager].accountsNames objectForKey:fromAddress];
            self.addressFrom.text = [NSString stringWithFormat:@"%@ (%@)", nameAcc, fromAddress];
        }
    }
    pinCode = @"";
    pinButton.tintColor = [UIColor redColor];
    
    if (self.message.encType == enTypePasswordForCert) {
        attButton.enabled = NO;
        self.addAttachmentButton.enabled = NO;
        if([self.message.messageBody  isEqual: @""])
            self.messageText.text = [self generateCert];
        else
            self.messageText.text = self.message.messageBody;
    }else{
        attButton.enabled = YES;
        self.addAttachmentButton.enabled = YES;
    }
    
    if ([GlobalRouter sharedManager].accountsNames.count == 1) {
        fromAddress = [[[GlobalRouter sharedManager].accountsNames allKeys] firstObject];
        NSString* nameAcc = [[GlobalRouter sharedManager].accountsNames objectForKey:fromAddress];
        self.addressFrom.text = [NSString stringWithFormat:@"%@ (%@)", nameAcc, fromAddress];
    }else if ([GlobalRouter sharedManager].accountsNames.count == 0) {
        fromAddress = nil;
        self.addressFrom.text = @"";
    }
}

-(NSString*)generateCert
{
    return [Encryptor generateCert];
}

-(void)setupAttachmentIcons
{
    if (message.attachments.count == 0) {
        self.textTopConstraint.constant = 8;
    }else{
        self.textTopConstraint.constant = 93;
    }

    NSArray* attViews = [CommonProcs showAttachmentsIcons:message scroll:self.attScroll];
    for (UIImageView* att in attViews) {
        // Add action
        [att setUserInteractionEnabled:YES];
        UITapGestureRecognizer *singleTap =  [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showAttachment:)];
        [singleTap setNumberOfTapsRequired:1];
        [att addGestureRecognizer:singleTap];
    }
}

// method to hide keyboard when user taps on a scrollview
-(void)hideKeyboard
{
    [self.view endEditing:YES];
}

-(IBAction)needToAddAttachment:(id)sender
{
    [presenter needToAddAttachment];
}

-(IBAction)needToGetAddress:(id)sender
{
    [presenter needAddress];
}

-(void)needPin
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter PIN",nil) message:NSLocalizedString(@"Set PIN-code for the message",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Done",nil),nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    if (![pinCode isEqualToString:@""]) {
        [[alert textFieldAtIndex:0] setText:pinCode];
    }
    [alert setTag:100];
    [alert show];
}

-(BOOL)sanityCheck
{
    BOOL ret = YES;
    // 1. Check address
    if(message.fromAddress == nil || [message.fromAddress isEqualToString:@""]){
        ret = NO;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil) message:NSLocalizedString(@"Address is empty",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
        alert.tag = 10000;
        [alert show];
    }else{
        // 2. Check format
        NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}";
        NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
        BOOL val = [emailTest evaluateWithObject:message.fromAddress];
        if (!val) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil) message:NSLocalizedString(@"Address is invalid",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
            alert.tag = 10000;
            [alert show];
        }
        ret &= val;
    }
    
    return ret;
}

-(void) gatherMessage
{
    message.fromAddress = fromAddress;
    if (fromAddress == nil && !(self.addressFrom.text == nil || [self.addressFrom.text isEqualToString:@""])) {
        NSString* fromTemp = self.addressFrom.text;
        // get rid of (...) part
        NSRange pos1 = [fromTemp rangeOfString:@" ("];
        NSRange pos2 = [fromTemp rangeOfString:@")"];
        message.fromAddress = [fromTemp substringWithRange:NSMakeRange(pos1.location+2, pos2.location-pos1.location-2)];
        fromAddress = message.fromAddress;
    }
    message.toAddress = self.addressTo.text;
    message.subject = self.subject.text;
    message.flags = mfNone;
    message.messageBody = self.messageText.text;
    message.readyToSend = NO;
    /*
    NSAttributedString *s = self.messageText.attributedText;
    NSDictionary *documentAttributes = @{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType};
    NSData *htmlData = [s dataFromRange:NSMakeRange(0, s.length) documentAttributes:documentAttributes error:NULL];
    NSString *htmlString = [[NSString alloc] initWithData:htmlData encoding:NSUTF8StringEncoding];
    
    message.messageBody = htmlString;
    */
}

-(void)needSend
{
    [self gatherMessage];
    
    // Filter out lethal errors first
    if (![self sanityCheck]) {
        return;
    }
    
    if ([pinCode  isEqual: @""]) {
        sending = YES;
        [self needPin];
    }else{
        [CommonProcs spawnProcWithProgress:@selector(needSendMessage:pin:) object:presenter withParam1:message withParam2:pinCode];
        
        /*
        if([presenter needSendMessage:message pin:pinCode])
        {
            //[self closeMessage];
        }else{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error sending message",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
            alert.tag = 10000;
            [alert show];
        }
         */
    }
}

-(void)showAttachment:(UIGestureRecognizer *)recognizer
{
    [presenter attachmentTapped:(int)[recognizer view].tag];
}

-(void)closeMessage
{
    [[[GlobalRouter sharedManager] getAttachmentRouter] finished];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews {
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat fixedWidth = self.messageText.frame.size.width;
        CGSize newSize = [self.messageText sizeThatFits:CGSizeMake(fixedWidth, CGFLOAT_MAX)];
        self.textHeightConstraint.constant = newSize.height<200?200:newSize.height;
        //NSLog(@"--------");
    });
}

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
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scroll.contentInset.top, self.scroll.contentInset.left, kbSize.height, 0.0);
    self.scroll.contentInset = contentInsets;
    self.scroll.scrollIndicatorInsets = contentInsets;
    
    if([self.messageText isFirstResponder] && self.messageText.selectedTextRange != nil)
    {
        CGRect cursorPosition = [self.messageText caretRectForPosition:self.messageText.selectedTextRange.start];
        cursorPosition.origin.y += self.messageText.frame.origin.y;
        [self.scroll scrollRectToVisible:cursorPosition animated:YES];
    }
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

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100)
    {
        if (buttonIndex == 0)
        {
            //[self finished];
        }else{
            pinCode = [[alertView textFieldAtIndex:0] text];
            if(![pinCode isEqualToString:@""]){
                pinButton.tintColor = [UIColor greenColor];
                if (sending) {
                    sending = NO;
                    [self needSend];
                }
            }else
                pinButton.tintColor = [UIColor redColor];
        }
    }
}

-(void)showError:(NSString*)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:error message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
    alert.tag = 10000;
    [alert show];
    
    if ([error isEqualToString:NSLocalizedString(@"Wrong pin", nil)]) {
        pinCode = @"";
    }
}

-(IBAction)setFromAccount:(id)sender
{
    
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.accounts.count;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return  1;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.accounts[row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    //self.addressFrom.text = self.accounts[row];
    fromAddress = self.accounts[row];
    self.addressFrom.text = [NSString stringWithFormat:@"%@ (%@)", [[GlobalRouter sharedManager].accountsNames objectForKey:fromAddress], fromAddress];
    [self.addressFrom resignFirstResponder];
}

/*
- (void)textViewDidChange:(UITextView *)textView
{
    CGFloat fixedWidth = textView.frame.size.width;
    CGSize newSize = [textView sizeThatFits:CGSizeMake(fixedWidth, CGFLOAT_MAX)];
    CGRect newFrame = textView.frame;
    newFrame.size = CGSizeMake(fmaxf(newSize.width, fixedWidth), newSize.height);
    textView.frame = newFrame;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
