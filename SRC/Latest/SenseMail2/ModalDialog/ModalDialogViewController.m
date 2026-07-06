//
//  ModalDialogViewController.m
//  SenseMail2
//
//  Created by Sergey on 12.05.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "ModalDialogViewController.h"
#import "GlobalRouter.h"
#import "CommonProcs.h"

@interface ModalDialogViewController ()
@property (weak) IBOutlet UITextField *text1;
@property (weak) IBOutlet UITextField *text2;
@end

@implementation ModalDialogViewController

static NSMutableString* retText1;
static NSMutableString* retText2;
static dispatch_block_t block;

+(NSString*)runWithHeader:(NSString*)header text1:(NSString*)text1 text2:(NSString*)text2 block:(dispatch_block_t)dblock{
    return [ModalDialogViewController runWithHeader:header text1:text1 text2:text2 block:dblock isPassword:NO];
}

+(NSString*)runWithHeader:(NSString*)header text1:(NSString*)text1 text2:(NSString*)text2 block:(dispatch_block_t)dblock isPassword:(BOOL)isPassword
{
    __block NSString* ret;
    __block ModalDialogViewController* windowController;
    
    dispatch_semaphore_t semap = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_main_queue(), ^{
        windowController = [[ModalDialogViewController alloc] initWithNibName:@"ModalDialogViewController" bundle:nil];
        windowController.textsShouldMatch = isPassword;
        dispatch_semaphore_signal(semap);
    });
    
    dispatch_semaphore_wait(semap, DISPATCH_TIME_FOREVER);
    
    __block UILabel* headerLabel;// = (UILabel*)[windowController.view viewWithTag:1];
    dispatch_async(dispatch_get_main_queue(), ^{
        headerLabel = (UILabel*)[windowController.view viewWithTag:1];
        headerLabel.text = header;
    });
    
    __block UILabel* text1Label;// = (UILabel*)[windowController.view viewWithTag:2];
    dispatch_async(dispatch_get_main_queue(), ^{
        text1Label = (UILabel*)[windowController.view viewWithTag:2];
        text1Label.text = text1;
    });
    
    __block UILabel* text2Label;// = (UILabel*)[windowController.view viewWithTag:4];
    dispatch_async(dispatch_get_main_queue(), ^{
        text2Label = (UILabel*)[windowController.view viewWithTag:4];
        text2Label.text = text2;
    });
    
    retText1 = [NSMutableString stringWithString: @""];
    retText2 = [NSMutableString stringWithString:@""];
    block = dblock;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        windowController.okButton.titleLabel.text = NSLocalizedString(@"OK", nil);
        windowController.cancelButton.titleLabel.text = NSLocalizedString(@"Cancel", nil);
        [windowController.view setNeedsDisplay];
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        windowController.modalPresentationStyle = UIModalPresentationFullScreen;
        [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:windowController animated:YES completion:nil];
        [windowController.text1 becomeFirstResponder];
    });
    
    return ret;
}

+(NSMutableString*)getText1
{
    return retText1;
}

+(NSMutableString*)getText2
{
    return retText2;
}

-(IBAction)ok:(id)sender
{
    if (self.textsShouldMatch && !([self.text1.text isEqualToString:self.text2.text])) {
        [CommonProcs showMessage:NSLocalizedString(@"Passwords do not match", nil) title:nil];
        return;
    }
    [self dismissViewControllerAnimated:YES completion:^{
        retText1 = [NSMutableString stringWithString:self.text1.text];
        retText2 = [NSMutableString stringWithString:self.text2.text];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^{
            block();
        });
        //NSLog(@"OK-%@, %@", retText1, retText2);
    }];
}

-(IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    // prevents the view from swallowing up the touch event of child buttons
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
    
    [[self.text1 layer] setCornerRadius:8.0f];
    [[self.text1 layer] setMasksToBounds:YES];
    [[self.text1 layer] setBorderWidth:0.5f];
    [[self.text1 layer] setBorderColor:[UIColor grayColor].CGColor];

    [[self.text2 layer] setCornerRadius:8.0f];
    [[self.text2 layer] setMasksToBounds:YES];
    [[self.text2 layer] setBorderWidth:0.5f];
    [[self.text2 layer] setBorderColor:[UIColor grayColor].CGColor];
}

-(void)hideKeyboard
{
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
