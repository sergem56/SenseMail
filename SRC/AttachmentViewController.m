//
//  AttachmentViewController.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "AttachmentViewController.h"
#import "GlobalRouter.h"
#import "AttachmentViewPresenter.h"

@interface AttachmentViewController ()

@end

@implementation AttachmentViewController

@synthesize image, scroll, presenter, attachment;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationController.toolbarHidden = NO;
    UIBarButtonItem* button0 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save secure",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(needSaveImageSecure)];
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(needSaveImage)];
    //UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(closeView)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeView)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:button0, button1, flexibleItem, button2, nil]];
    
}

-(void)initImage
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    [self.view setFrame:CGRectMake(0, 0, screenWidth-30, screenHeight-30)];
    [self.image setFrame:CGRectMake(0, 0, screenWidth-30, screenHeight-30)];
    [scroll setContentSize:self.image.frame.size];
    
    [self.image setImage:attachment];
    
    float zoomHor = screenWidth/self.image.image.size.width;
    float zoomVer = screenHeight/self.image.image.size.height;
    [scroll setZoomScale:zoomHor>zoomVer?zoomVer:zoomHor];
}

-(void)closeView
{
    [[[GlobalRouter sharedManager] getAttachmentRouter] finished];
}

-(void)needSaveImage
{
    BOOL res = [presenter needSaveImage:attachment];
    
    if(res)
    {
        //[self closeView];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Image saved",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
        alert.tag = 10000;
        [alert show];
    }else{
        // Shouldn't get here, but who knows
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error saving image",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
        alert.tag = 10000;
        [alert show];
    }
}

-(void)needSaveImageSecure
{
    [presenter needSaveImageSecure:attachment];
}


- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView{
    return image;
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
