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
    self.navigationItem.hidesBackButton = YES;
    
    //UIBarButtonItem* button0 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save secure",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needSaveImageSecure)];
    
    UIBarButtonItem* button0 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"saveSec"] style:UIBarButtonItemStylePlain target:self action:@selector(needSaveImageSecure)];
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"save2"] style:UIBarButtonItemStylePlain target:self action:@selector(needSaveImage)];
    //UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needSaveImage)];
    //UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close",nil) style:UIBarButtonItemStylePlain target:self action:@selector(closeView)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeView)];
    
    if(self.isSecure){
        [self setToolbarItems:[NSArray arrayWithObjects:button1, flexibleItem, button2, nil]];
    }else{
        [self setToolbarItems:[NSArray arrayWithObjects:button0, button1, flexibleItem, button2, nil]];
    }
 
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomImage:)];
    // prevents the scroll view from swallowing up the touch event of child buttons
    tapGesture.cancelsTouchesInView = NO;
    tapGesture.numberOfTapsRequired = 2;
    [self.scroll addGestureRecognizer:tapGesture];
    
    // Comment that out for the time being... it's a bit tricky since I need to scroll as
    // a photo app does, sliding one attachment out and bringing the other one in. But,
    // one attachment is an image, the other is a document, the next one is something else...
    // Moreover, it might be encrypted or not loaded yet, going to have a delay that ruins everything...
    /*
    UISwipeGestureRecognizer* swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeNext:)];
    swipeGesture.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.scroll addGestureRecognizer:swipeGesture];
    
    UISwipeGestureRecognizer* swipeGestureP = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipePrev:)];
    swipeGestureP.direction = UISwipeGestureRecognizerDirectionRight;
    [self.scroll addGestureRecognizer:swipeGestureP];
    */
}

-(void)zoomImage:(UITapGestureRecognizer *)sender
{
    __weak typeof(self) weakSelf = self;
    if (self.scroll.zoomScale == nonZoomed) {
        
        [UIView animateWithDuration:0.25 delay:0 options: UIViewAnimationOptionCurveEaseIn
        animations:^{
            __strong typeof(self)strongSelf = weakSelf;
            [self.scroll setZoomScale:strongSelf->nonZoomed*4];
            // Set zoom point at center screen
            CGPoint location = [sender locationInView:self.view];
            float viewWidth = self.view.layer.frame.size.width;
            float viewHeight = self.view.layer.frame.size.height;
            [self.scroll scrollRectToVisible:CGRectMake(location.x*4-viewWidth/2, location.y*4-viewHeight/2, viewWidth, viewHeight) animated:NO];
                    }
        completion:^(BOOL fin){
            
        }];
    }else{
        [UIView animateWithDuration:0.25 delay:0 options: UIViewAnimationOptionCurveEaseIn
        animations:^{
            __strong typeof(self)strongSelf = weakSelf;
            [self.scroll setZoomScale:strongSelf->nonZoomed];
                    }
        completion:^(BOOL fin){
            
        }];
        
    }
}

/*
-(void)swipeNext:(UISwipeGestureRecognizer*)sender
{
    [presenter showNextAttachment];
}

-(void)swipePrev:(UISwipeGestureRecognizer*)sender
{
    [presenter showPrevAttachment];
}
*/

-(void)initImage
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    [self.view setFrame:CGRectMake(0, 0, screenWidth-30, screenHeight-30)];
    [self.image setFrame:CGRectMake(0, 0, screenWidth-30, screenHeight-30)];
    [scroll setContentSize:self.image.frame.size];
    
    [self.image setImage:attachment];
    
    //float zoomHor = screenWidth/self.image.image.size.width;
    //float zoomVer = screenHeight/self.image.image.size.height;
    //[scroll setZoomScale:zoomHor>zoomVer?zoomVer:zoomHor];
    nonZoomed = 1;//scroll.zoomScale;
    self.scroll.minimumZoomScale = 1;
}

-(void)closeView
{
    attachment = nil;
    [[[GlobalRouter sharedManager] getAttachmentRouter] finished];
}

-(void)needSaveImage
{
    BOOL res = [presenter needSaveImage:attachment];
    
    if(res)
    {
        //[self closeView];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:NSLocalizedString(@"Image saved",nil)
                                     message:@""
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"OK",nil)
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction * action)
                                 {
                                 }];
        [alert addAction:cancel];
        
        UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
        alert.popoverPresentationController.sourceView = pView;
        alert.popoverPresentationController.sourceRect = pView.frame;
        [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
        
        /*
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Image saved",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
        alert.tag = 10000;
        [alert show];*/
    }else{
        // Shouldn't get here, but who knows
        
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:NSLocalizedString(@"Error saving image",nil)
                                     message:@""
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"OK",nil)
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction * action)
                                 {
                                 }];
        [alert addAction:cancel];
        
        UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
        alert.popoverPresentationController.sourceView = pView;
        alert.popoverPresentationController.sourceRect = pView.frame;
        [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
        
        /*
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error saving image",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
        alert.tag = 10000;
        [alert show];*/
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
