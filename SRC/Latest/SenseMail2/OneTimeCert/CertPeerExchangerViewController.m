//
//  CertPeerExchangerViewController.m
//  SenseMailShare
//
//  Created by Sergey on 15.06.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

#import "CertPeerExchangerViewController.h"

#import "GlobalRouter.h"
#import "OneTimeCertInteractor.h"
#import "OneTimeCert.h"
#import "Autocomplete.h"

@interface CertPeerExchangerViewController ()

@end

@implementation CertPeerExchangerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    
    [self setToolbarItems:[NSArray arrayWithObjects: flexibleItem, button2, nil]];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
    
    self.otherEmail.delegate = self;
    self.toAutocomplete = [[Autocomplete alloc] init];
    [self.toAutocomplete createAutocompleteFor:self.otherEmail withAllElements:[GlobalRouter sharedManager].possibleAddresses];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UIPickerView *picker = [[UIPickerView alloc] init];
    picker.dataSource = self;
    picker.delegate = self;
    self.yourEmail.inputView = picker;
    self.accounts = [[GlobalRouter sharedManager].accountsNames allKeys];
    
    self.otherEmail.text = self.otherEmailString;
    if ([GlobalRouter sharedManager].accountsNames.count == 1) {
        NSString* fromAddress = [[[GlobalRouter sharedManager].accountsNames allKeys] firstObject];
        if (fromAddress == nil) {
            fromAddress = @"";
        }
        self.yourEmail.text = fromAddress;
    }
}

-(void)hideKeyboard
{
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)generate:(id)sender
{
    /*
    if (![CommonProcs isEmailValid:self.yourEmail.text]) {
        [CommonProcs showMessage:NSLocalizedString(@"Your email is not valid",nil) title:NSLocalizedString(@"Error",nil)];
        return;
    }
    if (![CommonProcs isEmailValid:self.otherEmail.text]) {
        [CommonProcs showMessage:NSLocalizedString(@"Other's email is not valid",nil) title:NSLocalizedString(@"Error",nil)];
        return;
    }
     */
    [GlobalRouter sharedManager].oneTimeCertInteractor.yourEmail = self.yourEmail.text;
    [GlobalRouter sharedManager].oneTimeCertInteractor.otherEmail = self.otherEmail.text;
    [[GlobalRouter sharedManager] finishedWithDetailView:YES];// finishedWithCurrentView];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[GlobalRouter sharedManager].oneTimeCertInteractor presentTapViewInNavController:[[GlobalRouter sharedManager] getNavController]];
    });
}

-(IBAction)receive:(id)sender
{
    /*
    if (![CommonProcs isEmailValid:self.yourEmail.text]) {
        [CommonProcs showMessage:NSLocalizedString(@"Your email is not valid",nil) title:NSLocalizedString(@"Error",nil)];
        return;
    }
    if (![CommonProcs isEmailValid:self.otherEmail.text]) {
        [CommonProcs showMessage:NSLocalizedString(@"Other's email is not valid",nil) title:NSLocalizedString(@"Error",nil)];
        return;
    }
     */
    [GlobalRouter sharedManager].oneTimeCertInteractor.yourEmail = self.yourEmail.text;
    [GlobalRouter sharedManager].oneTimeCertInteractor.otherEmail = self.otherEmail.text;
    
    [[GlobalRouter sharedManager] finishedWithDetailView:YES];// finishedWithCurrentView];
    [[GlobalRouter sharedManager].oneTimeCertInteractor startReceiving];
}

-(IBAction)cancel:(id)sender
{
    [[GlobalRouter sharedManager] finishedWithDetailView:YES];// finishedWithCurrentView];
    [GlobalRouter sharedManager].oneTimeCertInteractor.otherEmail = nil;
}

-(IBAction)iWillBeAGenerator:(id)sender
{
    [[GlobalRouter sharedManager] finishedWithDetailView:YES];
    CertPeerExchangerViewController* ret = [[CertPeerExchangerViewController alloc] initWithNibName:@"CertPeerExchangerViewController" bundle:nil];
    ret.otherEmailString = self.otherEmailString;
    [[[GlobalRouter sharedManager] getDetailNavController] pushViewController:ret animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(IBAction)getNextCert:(id)sender
{
    OneTimeCert* cert = [[GlobalRouter sharedManager].oneTimeCertInteractor getNextCertForAddress:self.otherEmail.text fromAddress:self.yourEmail.text];
    if (cert) {
#if DEBUG
        NSLog(@"Got cert with used date = '%@' and ID=%@",cert.dateUsed, cert.certID);
        
        if([[GlobalRouter sharedManager].oneTimeCertInteractor setExpirationTimeForCert:cert.certID expiration:[NSDate date] dateUsed:[NSDate date] from:cert.otherEmail]){
            
        }else{
            NSLog(@"Error setting expiration");
        }
        if([[GlobalRouter sharedManager].oneTimeCertInteractor deleteExpired]){//[[GlobalRouter sharedManager].oneTimeCertInteractor deleteCertWithID:cert.certID from:cert.otherEmail]){
            
        }else{
            NSLog(@"Error deleting cert");
        }
        
#endif
    }else{
#if DEBUG
        NSLog(@"Got no certs");
#endif
    }
}

-(IBAction)deleteAll:(id)sender
{
    [[GlobalRouter sharedManager].oneTimeCertInteractor deleteAll];
}

#pragma mark PickerView
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
    self.yourEmail.text = self.accounts[row];
    [self.yourEmail resignFirstResponder];
}

#pragma mark Autocomplete

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if([textField isEqual:self.otherEmail]){
        NSString *substring = [NSString stringWithString:textField.text];
        substring = [substring stringByReplacingCharactersInRange:range withString:string];
        [self.toAutocomplete filterItems:substring];
    }else{
        //[self.toAutocomplete hideTable];
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    // Remove autocomplete
    if([textField isEqual:self.otherEmail]){
        [self.toAutocomplete hideTable];
    }
}

@end
