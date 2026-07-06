//
//  EasySetupViewController.m
//  SenseMailShare
//
//  Created by Sergey on 18.05.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

#import "EasySetupViewController.h"
#import "EasySetupInteractor.h"
#import "CommonProcs.h"
#import "GlobalRouter.h"

@interface EasySetupViewController ()

@end

@implementation EasySetupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.address addTarget:self
                action:@selector(textFieldDidChange:)
                forControlEvents:UIControlEventEditingChanged];
    
    UIBarButtonItem *flexibleItem22 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button22 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    
    UIToolbar* inputAccessoryToolbar = [[UIToolbar alloc] init];
    inputAccessoryToolbar.frame = CGRectMake(0,0,300,44);
    inputAccessoryToolbar.items = [NSArray arrayWithObjects:flexibleItem22, button22, nil];
    self.address.inputAccessoryView = inputAccessoryToolbar;
    self.password.inputAccessoryView = inputAccessoryToolbar;
    
    self.password.hidden = YES;
    self.labelPassword.hidden = YES;
    
    [self.address becomeFirstResponder];
    
    self.definesPresentationContext = YES;
    
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    [self setToolbarItems:[NSArray arrayWithObjects:flexibleItem, button2, nil]];
    
}

-(void)showPasswordFieldAnimated
{
    [UIView transitionWithView:self.password
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.password.hidden = NO;
                    }
                    completion:NULL];
    [UIView transitionWithView:self.labelPassword
                      duration:0.4
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        self.labelPassword.hidden = NO;
                    }
                    completion:NULL];
}

-(void)textFieldDidChange:(id)sender
{
    if ([self.address.text containsString:@"gmail.com"]) {
        self.password.enabled = NO;
        self.password.placeholder = NSLocalizedString(@"Web-authorization", nil);
        [UIView transitionWithView:self.password
                          duration:0.4
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            self.password.hidden = YES;
                        }
                        completion:NULL];
        
        [UIView transitionWithView:self.labelPassword
                          duration:0.4
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{
                            self.labelPassword.textColor = [UIColor grayColor];
                            [self.labelPassword setFont:[UIFont fontWithName:self.labelPassword.font.fontName size:12]];
                            self.labelPassword.text = NSLocalizedString(@"Will open web-authorization page", nil);
                        }
                        completion:NULL];
    }else if([CommonProcs isEmailValid:self.address.text]){
        self.labelPassword.textColor = [UIColor blackColor];
        [self.labelPassword setFont:[UIFont fontWithName:self.labelPassword.font.fontName size:17]];
        self.password.placeholder = NSLocalizedString(@"password", nil);
        self.labelPassword.text = NSLocalizedString(@"Password:", nil);
        self.password.enabled = YES;
        [self showPasswordFieldAnimated];
    }else{
        self.password.hidden = YES;//NO;
        self.labelPassword.hidden = YES;
        self.password.enabled = YES;
        self.labelPassword.textColor = [UIColor blackColor];
        [self.labelPassword setFont:[UIFont fontWithName:self.labelPassword.font.fontName size:17]];
        self.password.placeholder = NSLocalizedString(@"password", nil);
        self.labelPassword.text = NSLocalizedString(@"Password:", nil);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)checkConnection:(id)sender
{
    [self.interactor emailEntered:self.address.text];
    //[self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)cancel:(id)sender
{
    self.checkButton.enabled = YES;
    //[self dismissViewControllerAnimated:YES completion:nil];
    [[GlobalRouter sharedManager] finishedWithCurrentView:YES]; // finishedWithDetailView:YES];
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
