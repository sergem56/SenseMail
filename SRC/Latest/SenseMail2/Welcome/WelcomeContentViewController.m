//
//  WelcomeContentViewController.m
//  SenseMailShare
//
//  Created by Sergey on 28.09.16.
//  Copyright © 2016 Sergey. All rights reserved.
//

#import "WelcomeContentViewController.h"
#import "GlobalRouter.h"

@interface WelcomeContentViewController (){
    BOOL keyboardIsShown;
}

@end

@implementation WelcomeContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    // prevents the scroll view from swallowing up the touch event of child buttons
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
}

-(void)hideKeyboard
{
    [self.view endEditing:YES];
    keyboardIsShown = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma keyBoard
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

-(void)keyboardWillShow:(NSNotification *)notification
{
    if (keyboardIsShown) {
        return;
    }
    CGRect kbFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGSize keyboardSize = kbFrame.size;
    
    float pinOrigin = self.pinText.frame.origin.y;
    float adj = 0;
    if (pinOrigin + 106 > kbFrame.origin.y-keyboardSize.height) {
        adj = pinOrigin+106 - (kbFrame.origin.y-keyboardSize.height);
    }
    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = self.view.frame;
        f.origin.y = -adj;// -keyboardSize.height;
        self.view.frame = f;
    }];
    
    keyboardIsShown = YES;
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    [UIView animateWithDuration:0.3 animations:^{
        CGRect f = self.view.frame;
        f.origin.y = 0.0f;
        self.view.frame = f;
    }];
    
    keyboardIsShown = NO;
}

#pragma --------------

-(IBAction)nextStep:(id)sender
{
    if ([self.pinText.text isEqualToString:@""]) {
        return;
    }
    [GlobalRouter sharedManager].pin = [NSMutableString stringWithString:self.pinText.text];
    //[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hasRunAppOnceKey"];
    [CommonProcs saveToKeychainAlways:@"1" account:@"hasRunAppOnceKey" service:@"SM"];
    [GlobalRouter sharedManager].thisIsTheFirstRun = NO;
    
    UIViewController* presenting = self.presentingViewController;
    [self dismissViewControllerAnimated:YES completion:^{
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"welcome" bundle:nil];
        WelcomeContentViewController *wcvc = [sb instantiateViewControllerWithIdentifier:@"Welcome02"];
        [presenting presentViewController:wcvc animated:YES completion:nil];
    }];
}

-(IBAction)exit:(id)sender
{
    // Exit the app, no chances
    exit(0);
}

-(IBAction)gotoSettings:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        //[[GlobalRouter sharedManager] needSettingsWithNew];
        [[GlobalRouter sharedManager] showAddMaster];
    }];
}

-(IBAction)later:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(NSString*)getPin
{
    return self.pinText.text;
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
