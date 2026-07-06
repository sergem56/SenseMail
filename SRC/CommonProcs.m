//
//  CommonProcs.m
//  SenseMail2
//
//  Created by Sergey on 17.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "CommonProcs.h"
#import "FullMessageEntity.h"
#import "AttCollectionViewCell.h"
#import "SettingsEntity.h"
#import "GlobalRouter.h"
//#import <AssetsLibrary/AssetsLibrary.h>

@implementation CommonProcs

static BOOL showingWheel;
static UIView* dimView;
static UIActivityIndicatorView* indicator;
static UILabel* loading;
static UIButton* stop;
static NSString* currentMessage;

// Simple indicator
static UIView* busyView;
static UIActivityIndicatorView* busyIndicator;

static dispatch_queue_t my_q;

+(NSArray*)showAttachmentsIcons:(FullMessageEntity *)currentMessage scroll:(UIScrollView *)attScroll
{
    NSMutableArray* ret = [[NSMutableArray alloc] init];
    
    //attScroll.subviews
    NSArray *viewsToRemove = [attScroll subviews];
    for (UIView *v in viewsToRemove) [v removeFromSuperview];
    
    int index = 0;

    //for (ALAsset* asset in currentMessage.attachments) {
    for (NSObject* asset in currentMessage.attachments) {

        UIImageView* att;
        // Create thumbnail image
        if([asset isKindOfClass:[ALAsset class]]){
            att = [self thumbnailViewFromAsset:(ALAsset*)asset];
        }else if ([asset isKindOfClass:[NSString class]]){
            att = [self thumbnailViewFromPath:(NSString*)asset];
        }
        if(att != nil){
            att.tag = index+1000;
            CGRect frameRect = att.frame;
            // Add a 72x72 image view for attachment
            frameRect.origin = CGPointMake(index*78, 0);
            frameRect.size = CGSizeMake(72, 72);
            att.frame = frameRect;
            att.contentMode = UIViewContentModeScaleToFill;
            
            [attScroll addSubview:att];
            [ret addObject:att];
            index++;
        }
    }
    [attScroll setContentSize:CGSizeMake(80*index,72)]; // set scroll inner size to enable scrolling

    return ret;
}

+(UIImageView*)thumbnailViewFromAsset:(ALAsset*)asset
{
    return [[UIImageView alloc] initWithImage: [[UIImage alloc] initWithCGImage: [asset thumbnail]]];
}

+(UIImageView*)thumbnailViewFromPath:(NSString*)path
{
    //UIImageView* ret;
    UIImage* im = [[UIImage alloc] initWithContentsOfFile:path];
    
    CGSize destinationSize = CGSizeMake(70, 70);
    
    UIGraphicsBeginImageContext(destinationSize);
    [im drawInRect:CGRectMake(0,0,destinationSize.width,destinationSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    im = nil;
    
    return [[UIImageView alloc] initWithImage:newImage];
}

+(UIImage*)thumbnailImageFromImage:(UIImage*)image
{
    CGSize destinationSize = CGSizeMake(80, 80);
    CGSize originalSize = image.size;
    
    float x = 1;
    float y = 1;
    if (originalSize.height > originalSize.width) {
        x = originalSize.height/originalSize.width;
        y = 1;
    }else{
        y = originalSize.width/originalSize.height;
        x = 1;
    }
    
    UIGraphicsBeginImageContext(destinationSize);
    [image drawInRect:CGRectMake(40-0.5*(destinationSize.width/x),40-0.5*(destinationSize.height/y),destinationSize.width/x,destinationSize.height/y)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+(UIImage*)getFullImage:(NSObject*)item
{
    UIImage* att;
    
    if([item isKindOfClass:[ALAsset class]]){
        att = [self fullImageFromAsset:(ALAsset*)item];
    }else if ([item isKindOfClass:[NSString class]]){
        att = [self fullImageFromPath:(NSString*)item];
    }
    
    return att;
}

+(UIImage*)fullImageFromAsset:(ALAsset*)asset
{
    ALAssetRepresentation* rep = [asset defaultRepresentation];
    return [[UIImage alloc] initWithCGImage: [rep fullResolutionImage]];
}

+(UIImage*)fullImageFromPath:(NSString*)path
{
    return [[UIImage alloc] initWithContentsOfFile:path];
}

+(NSString*)getTempPathForImage
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tmpDirectory = NSTemporaryDirectory();
    NSString *path = [tmpDirectory stringByAppendingPathComponent:@"image.jpg"];
    int ind = 1;
    while ([fileManager fileExistsAtPath:path]) {
        NSString* theFileName = [[@"image.jpg" lastPathComponent] stringByDeletingPathExtension];
        NSString* ext = [@"image.jpg" pathExtension];
        NSString* version = [NSString stringWithFormat:@"%@-%d.%@",theFileName, ind, ext];
        path = [tmpDirectory stringByAppendingPathComponent:version];
        ind++;
    }
    
    return path;
}

+(NSString*)getTempPathForImageInDocuments
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* imageName = [NSString stringWithFormat:@"%@.jpg",[[NSUUID UUID] UUIDString]];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:imageName];
    int ind = 1;
    while ([fileManager fileExistsAtPath:path]) {
        NSString* theFileName = [[imageName lastPathComponent] stringByDeletingPathExtension];
        NSString* ext = [imageName pathExtension];
        NSString* version = [NSString stringWithFormat:@"%@%d.%@",theFileName, ind, ext];
        path = [documentsDirectory stringByAppendingPathComponent:version];
        ind++;
    }
    
    return path;
}



+(void)showWheelinView:(UIView*)view
{
    [CommonProcs showWheelinView:view message:NSLocalizedString(@"Connecting...", nil) stopButtonVisible:YES];
}

+(void)showWheelinView:(UIView*)view message:(NSString*)messageText stopButtonVisible:(BOOL)stopButtonVisible
{
    if (showingWheel) {
        return;
    }
    
    showingWheel = YES;
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    dimView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)];
    dimView.backgroundColor = [UIColor blackColor];
    dimView.alpha = 0.5f;
    dimView.userInteractionEnabled = YES; // YES! it should be YES to eat input
    [view addSubview:dimView];
    
    indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
    indicator.center = CGPointMake(view.bounds.size.width / 2, view.bounds.size.height/2 - 45);
    [view addSubview:indicator];
    [indicator startAnimating];
    
    loading = [[UILabel alloc] initWithFrame:CGRectMake(0, view.bounds.size.height/2 - 15, screenWidth, 22)];
    //loading.text = NSLocalizedString(@"Loading...", nil);
    loading.text = messageText;
    loading.textAlignment = NSTextAlignmentCenter;
    loading.textColor = [UIColor whiteColor];
    [view addSubview:loading];
    
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    
    if(stopButtonVisible){
        stop = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth/2-80, view.bounds.size.height/2+14, 160, 30)];
        [stop setTitle: NSLocalizedString(@"Stop", nil) forState:UIControlStateNormal];
        [stop addTarget:self action:@selector(stopPressed:) forControlEvents:UIControlEventTouchUpInside];
        [[stop layer] setCornerRadius:8.0f];
        [[stop layer] setMasksToBounds:YES];
        [[stop layer] setBorderWidth:1.0f];
        [[stop layer] setBorderColor:[UIColor whiteColor].CGColor];
        [[stop layer] setBackgroundColor:[UIColor redColor].CGColor];
        stop.tag = 1001;
        [view addSubview:stop];
    }
}

+(void)addStopButtonInView:(UIView*)view
{
    if (stop == nil) {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        stop = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth/2-80, view.bounds.size.height/2+14, 160, 30)];
        [stop setTitle: NSLocalizedString(@"Stop", nil) forState:UIControlStateNormal];
        [stop addTarget:self action:@selector(stopPressed:) forControlEvents:UIControlEventTouchUpInside];
        [[stop layer] setCornerRadius:8.0f];
        [[stop layer] setMasksToBounds:YES];
        [[stop layer] setBorderWidth:1.0f];
        [[stop layer] setBorderColor:[UIColor whiteColor].CGColor];
        [[stop layer] setBackgroundColor:[UIColor redColor].CGColor];
        stop.tag = 1001;
        [view addSubview:stop];
    }else if([view viewWithTag:1001] == nil) {
        [view addSubview:stop];
    }else{
        stop.hidden = NO;
    }
}

+(void)stopPressed:(id)sender
{
    [[GlobalRouter sharedManager]cancelQ];
    progressCount = 1;
    [self hideProgress]; // showProgress:10 max:10 inView:nil];
}

+(void)showProgress:(int)progress max:(int)maxValue inView:(UIView *)view
{
    [self showProgressWithTitle:progress max:maxValue inView:view title:NSLocalizedString(@"Connecting...", nil) stopButton:YES];
}

+(void)setProgress:(int)progress max:(int)maxValue title:(NSString *)title
{
    dispatch_async(dispatch_get_main_queue(), ^{
        int progressToShow = progress, maxToShow = maxValue;
        
        if(showingWheel){ // should be YES
            if (progress > 0) {
                NSString* pSfx = @"";
                if (progress > 1024) {
                    progressToShow = (int)(progress/1024);
                    pSfx = @"K";
                }
                NSString* mSfx = @"";
                if (maxValue > 1024) {
                    maxToShow = (int)(maxValue/1024);
                    mSfx = @"K";
                }
                loading.text = [NSString stringWithFormat:@"%@ (%d%@/%d%@)", NSLocalizedString(@"Loading...", nil),progressToShow,pSfx, maxToShow, mSfx];
            }else{
                loading.text = title;
            }
        }
    });
}

static int progressCount = 0;

+(void)showProgressWithTitle:(int)progress max:(int)maxValue inView:(UIView*)view title:(NSString *)title stopButton:(BOOL)stopButton
{
    progressCount++;
    
    currentMessage = title;
    dispatch_async(dispatch_get_main_queue(), ^{
        //NSLog(@"Wanna show progress %d of %d", progress,maxValue);
        int progressToShow = progress, maxToShow = maxValue;
        if (progress == maxValue) {
            [self hideProgress];
            
        }else if(!showingWheel && view != nil && progress != maxValue){
            //[self showWheelinView :view];
            [self showWheelinView:view message:title stopButtonVisible:stopButton];
            //progressCount++;
        }else if(showingWheel){
            if ([view.subviews indexOfObject:dimView] == NSNotFound) {
                //NSLog(@"Not found");
                [self showWheelinView:view message:title stopButtonVisible:stopButton];
            }
            if (stopButton) {
                [self addStopButtonInView:view];
            }
            if (progress > 0) {
                NSString* pSfx = @"";
                if (progress > 1024) {
                    progressToShow = (int)(progress/1024);
                    pSfx = @"K";
                }
                NSString* mSfx = @"";
                if (maxValue > 1024) {
                    maxToShow = (int)(maxValue/1024);
                    mSfx = @"K";
                }
                loading.text = [NSString stringWithFormat:@"%@ (%d%@/%d%@)", NSLocalizedString(@"Loading...", nil),progressToShow,pSfx, maxToShow, mSfx];
            }else{
                loading.text = title;
                [view setNeedsDisplay];
            }
            //[view bringSubviewToFront:dimView];
        }
    });
}

+(void)hideProgress
{
    if(progressCount > 0)
        progressCount--;
    else
        progressCount = 0;
    
    if(progressCount == 0){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (indicator == nil) {
                return;
            }
            [indicator stopAnimating];
            [indicator removeFromSuperview];
            [dimView removeFromSuperview];
            [loading removeFromSuperview];
            [stop removeFromSuperview];
            dimView = nil;
            indicator = nil;
            loading = nil;
            stop = nil;
            showingWheel = NO;
        });
    }
}

+(void)setMessageInProgress:(NSString *)message
{
    currentMessage = message;
    dispatch_async(dispatch_get_main_queue(), ^{
        loading.text = message;
        //[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
    });
}

+(NSString*)getMessageInProgress
{
    return currentMessage; //loading.text;
}

+(BOOL)areSettingsEmpty:(SettingsEntity*)settings
{
    BOOL ret = NO;
    if(settings.userName == nil || [settings.userName isEqualToString:@""]) ret = YES;
    if(settings.password == nil || [settings.password isEqualToString:@""]) ret = YES;
    
    return ret;
}

+(void)showBusyInView:(UIView*)view
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    //CGFloat screenHeight = screenRect.size.height;
    busyView = [[UIView alloc] initWithFrame:CGRectMake(screenWidth/2-30, 10, 60, 60)];
    //busyView.backgroundColor = [UIColor whiteColor];
    [view addSubview:busyView];
    
    busyIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
    busyIndicator.center = CGPointMake(busyView.bounds.size.width / 2, busyView.bounds.size.height/2);
    busyIndicator.tintColor = [UIColor whiteColor];
    [busyView addSubview:busyIndicator];
    busyIndicator.color = [UIColor blackColor];
    [busyIndicator startAnimating];
}

+(void)hideBusy
{
    [busyIndicator stopAnimating];
    [busyView removeFromSuperview];
}

+(void)showMessage:(NSString *)message title:(NSString *)title
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
    alert.tag = 10000;
    [alert show];
}

+(void)spawnProc:(SEL)selector object:(id)object withParam:(id)withObject
{
    //[self showProgress:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    //[self showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Loading...", nil) stopButton:NO];
    if (my_q == nil) {
        my_q = dispatch_queue_create("my.q", NULL);
    }
    dispatch_async(my_q, ^{
        IMP imp = [object methodForSelector:selector];
        void (*func)(id, SEL,id) = (void *)imp;
        func(object, selector, withObject);
        //[object performSelector:selector withObject:withObject]; // Warning - since ARC doesn't know what to do with ret of the func, so we need to tell all the parameters of the called proc...
    });
    //[object performSelectorInBackground:selector withObject:withObject];
}

+(void)spawnProcWithProgress:(SEL)selector object:(id)object withParam:(id)withObject
{
    //[self showProgress:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    [self showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Loading...", nil) stopButton:NO];
    if (my_q == nil) {
        my_q = dispatch_queue_create("my.q", NULL);
    }
    dispatch_async(my_q, ^{
        IMP imp = [object methodForSelector:selector];
        void (*func)(id, SEL,id) = (void *)imp;
        func(object, selector, withObject);
        //[object performSelector:selector withObject:withObject]; // Warning - since ARC doesn't know what to do with ret of the func, so we need to tell all the parameters of the called proc...
    });
    //[object performSelectorInBackground:selector withObject:withObject];
}

+(void)spawnProcWithProgress:(SEL)selector object:(id)object withParam1:(id)withObject1 withParam2:(id)withObject2
{
    //[self showProgress:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    [self showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Loading...", nil) stopButton:NO];
    if (my_q == nil) {
        my_q = dispatch_queue_create("my.q", NULL);
    }
    dispatch_async(my_q, ^{
        IMP imp = [object methodForSelector:selector];
        void (*func)(id, SEL,id, id) = (void *)imp;
        func(object, selector, withObject1, withObject2);
        //[object performSelector:selector withObject:withObject]; // Warning - since ARC doesn't know what to do with ret of the func, so we need to tell all the parameters of the called proc...
    });
    //[object performSelectorInBackground:selector withObject:withObject];
}

static int32_t requestsCount = 0;

+ (void)increment
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (requestsCount == 0){
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        }
        requestsCount++;
    });
}

+ (void)decrement
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (requestsCount == 0){
            return;
        }
        requestsCount--;
        
        if (requestsCount == 0){
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        }
    });
}

/*
+(NSArray*)showAttachmentsIconsFromImagesArray:(FullMessageEntity *)currentMessage scroll:(UIScrollView *)attScroll
{
    NSMutableArray* ret = [[NSMutableArray alloc] init];
    
    //attScroll.subviews
    NSArray *viewsToRemove = [attScroll subviews];
    for (UIView *v in viewsToRemove) [v removeFromSuperview];
    
    int index = 0;
    
    for (UIImage* im in currentMessage.attachments) {
        
        // Create thumbnail image
        CGSize destinationSize = CGSizeMake(70, 70);
        
        UIGraphicsBeginImageContext(destinationSize);
        [im drawInRect:CGRectMake(0,0,destinationSize.width,destinationSize.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        UIImageView* att = [[UIImageView alloc] initWithImage:newImage];
        att.tag = index;
        CGRect frameRect = att.frame;
        // Add a 72x72 image view for attachment
        frameRect.origin = CGPointMake(index*78, 0);
        frameRect.size = CGSizeMake(72, 72);
        att.frame = frameRect;
        att.contentMode = UIViewContentModeScaleToFill;
        
        [attScroll addSubview:att];
        [ret addObject:att];
        index++;
    }
    [attScroll setContentSize:CGSizeMake(80*index,72)]; // set scroll inner size to enable scrolling
    
    return ret;
}
*/


@end
