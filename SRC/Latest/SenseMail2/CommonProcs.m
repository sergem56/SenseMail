//
//  CommonProcs.m
//  SenseMail2
//
//  Created by Sergey on 17.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <StoreKit/StoreKit.h>

#import "CommonProcs.h"
#import "FullMessageEntity.h"
#import "AttCollectionViewCell.h"
#import "SettingsEntity.h"
#import "GlobalRouter.h"
#import "ModalDialogViewController.h"
#import "Encryptor.h"
#import "SelectFolderViewController.h"
#import "MessageListRouter.h"
#import "DataManager.h"
#import "MessageDataLevel/DataStorage.h"
//#import <AssetsLibrary/AssetsLibrary.h>
#import <WebKit/WebKit.h>
#import "MessageView/MessageViewPresenter.h"
#import "MessageViewInteractor.h"

#import "KeychainWrapper.h"

#import "AddAttachment/DocsViewController.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "FolderInfo.h"

///*
@interface ThumbnailGenerator: WKWebView <WKNavigationDelegate>
{
    id delegate;
}
@property (nonatomic, strong) NSURL* url;
@property (nonatomic, strong) UIImage* thumb;

@end

@implementation ThumbnailGenerator

-(id)initWithURL:(NSURL*)url delegate:(id)deleg
{
    self = [super init];
    self.thumb = nil;
    delegate = deleg;
    self.navigationDelegate = self;
    self.url = url;
    //[self setFrame:CGRectMake(1000, 1000, 240, 320)];
    
    CGRect bnds = ((DocsViewController*)delegate).view.bounds;
    [self setFrame:CGRectMake(1000, 1000, bnds.size.width, bnds.size.height)];
    [CommonProcs showWheelinView: ((DocsViewController*)delegate).view message:@"Saving..." stopButtonVisible:NO];
    
    //[self loadRequest:[NSURLRequest requestWithURL:url]];
    
    return self;
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    __weak __typeof__(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.9 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        self.thumb = [CommonProcs screenshot:self];
        if (self.thumb == nil) {
            self.thumb = [CommonProcs thumbnailViewFromPath:self.url.path].image;//self.thumb = [UIImage imageNamed:@"docIcon"];
        }
        self.thumb = [CommonProcs sizeAndTypeOnThumbForPath:self.url.path thumbnail:self.thumb];
        [(DocsViewController*)strongSelf->delegate thumbReady:self.thumb];
        [CommonProcs hideBusy];
    });
    
}

@end
 //*/

/*
@interface ThumbnailGenerator: QLPreviewController <QLPreviewControllerDataSource,QLPreviewControllerDelegate>
{
    id delegate;
}
@property (nonatomic, strong) NSURL* url;
@property (nonatomic, strong) UIImage* thumb;

@end

@implementation ThumbnailGenerator

-(id)initWithURL:(NSURL*)url delegate:(id)deleg
{
    self = [super init];
    self.thumb = nil;
    delegate = deleg;
    self.url = url;
    self.delegate = self;
    self.dataSource = self;
    CGRect bnds = ((DocsViewController*)delegate).view.bounds;
    [self.view setFrame:CGRectMake(1000, 1000, bnds.size.width, bnds.size.height)];
    [CommonProcs showWheelinView: ((DocsViewController*)delegate).view message:@"Saving..." stopButtonVisible:NO];
    // Docx files take more time to render, so make a delay longer
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.thumb = [CommonProcs screenshot:self.view];
        if (self.thumb == nil) {
            self.thumb = [CommonProcs thumbnailViewFromPath:url.path].image;// [UIImage imageNamed:@"docIcon"];
        }
        [(DocsViewController*)self->delegate thumbReady:self.thumb];
        [CommonProcs hideBusy];
    });
    
    return self;
}

-(NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller
{
    return 1;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    return self.url;
}

@end
*/

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

static BOOL saveResult = NO;

static UIActivityIndicatorView* smallIndicator;
static int smallWheelsNo = 0;
static UILabel* smallWheelLabel;

static KeychainWrapper* keychain = nil;

+(NSArray*)getColorValues
{
    static NSArray* _colorValues;
    static dispatch_once_t onceTokenV;
    UIColor* systemLabel;
    if (@available(iOS 13.0, *)) {
        systemLabel = [UIColor systemBackgroundColor];
    } else {
        // Fallback on earlier versions
        systemLabel = [UIColor whiteColor];
    }
        
    dispatch_once(&onceTokenV, ^{
        _colorValues = @[systemLabel, // System for label
                 [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:0.65], // White
                 [UIColor colorWithRed:1.00 green:1.00 blue:0.94 alpha:0.65], // Ivory
                 [UIColor colorWithRed:1.00 green:1.00 blue:0.67 alpha:0.65],
                 [UIColor colorWithRed:1.00 green:0.96 blue:0.93 alpha:0.65],
                 [UIColor colorWithRed:1.00 green:0.94 blue:0.84 alpha:0.65], // Papaya whip
                 [UIColor colorWithRed:1.00 green:0.89 blue:0.77 alpha:0.65],
                 [UIColor colorWithRed:1.00 green:0.84 blue:0.00 alpha:0.65],
                 [UIColor colorWithRed:1.00 green:0.76 blue:0.76 alpha:0.65], // Rosy brown
                 [UIColor colorWithRed:1.00 green:0.80 blue:0.07 alpha:0.65], // Mustard
                 [UIColor colorWithRed:0.90 green:0.91 blue:0.98 alpha:0.65],
                 [UIColor colorWithRed:0.91 green:0.95 blue:0.83 alpha:0.65],
                 [UIColor colorWithRed:0.69 green:0.69 blue:0.69 alpha:0.65], // Gray
                 [UIColor colorWithRed:0.75 green:0.75 blue:0.75 alpha:0.65],
                 [UIColor colorWithRed:0.89 green:0.89 blue:0.89 alpha:0.65],
                 [UIColor colorWithRed:0.94 green:0.94 blue:0.94 alpha:0.65], // Very light gray
                 [UIColor colorWithRed:0.90 green:0.90 blue:0.98 alpha:0.65],
                 [UIColor colorWithRed:0.90 green:0.74 blue:0.23 alpha:0.65],
                 [UIColor colorWithRed:0.89 green:0.66 blue:0.41 alpha:0.65], // Melon
                 [UIColor colorWithRed:0.88 green:0.93 blue:0.93 alpha:0.65], // Azure
                 [UIColor colorWithRed:0.88 green:0.87 blue:0.86 alpha:0.65],
                 [UIColor colorWithRed:0.87 green:0.63 blue:0.87 alpha:0.65],
                 [UIColor colorWithRed:0.86 green:1.00 blue:0.97 alpha:0.65], // Mint blue
                 [UIColor colorWithRed:0.86 green:0.58 blue:0.44 alpha:0.65],
                 [UIColor colorWithRed:0.85 green:0.85 blue:0.95 alpha:0.65],
                 [UIColor colorWithRed:0.85 green:0.85 blue:0.79 alpha:0.65], // Wheat
                 [UIColor colorWithRed:0.78 green:0.96 blue:0.15 alpha:0.65],
                 [UIColor colorWithRed:0.80 green:0.40 blue:0.00 alpha:0.65],
                 [UIColor colorWithRed:0.80 green:0.22 blue:0.00 alpha:0.65], // Orange red
                 [UIColor colorWithRed:0.75 green:0.15 blue:0.15 alpha:0.65], // Strawberry
                 [UIColor colorWithRed:0.62 green:0.02 blue:0.03 alpha:0.65],
                 [UIColor colorWithRed:0.50 green:0.00 blue:0.00 alpha:0.65],
                 [UIColor colorWithRed:0.65 green:0.16 blue:0.16 alpha:0.65], // Brown
                 [UIColor colorWithRed:0.80 green:0.89 blue:0.45 alpha:0.65],
                 [UIColor colorWithRed:0.81 green:0.80 blue:0.08 alpha:0.65],
                 [UIColor colorWithRed:0.82 green:0.89 blue:0.19 alpha:0.65], // Pear
                 [UIColor colorWithRed:0.83 green:0.93 blue:0.57 alpha:0.65],
                 [UIColor colorWithRed:0.76 green:1.00 blue:0.76 alpha:0.65],
                 [UIColor colorWithRed:0.75 green:0.90 blue:0.33 alpha:0.65], // Cat eye
                 [UIColor colorWithRed:0.75 green:0.94 blue:1.00 alpha:0.65],
                 [UIColor colorWithRed:0.76 green:0.94 blue:0.96 alpha:0.65],
                 [UIColor colorWithRed:0.79 green:0.88 blue:1.00 alpha:0.65], // Light steelblue
                 [UIColor colorWithRed:0.82 green:0.93 blue:0.93 alpha:0.65],
                 [UIColor colorWithRed:0.73 green:1.00 blue:1.00 alpha:0.65],
                 [UIColor colorWithRed:0.00 green:0.00 blue:0.20 alpha:0.99], // Midnight blue
                 [UIColor colorWithRed:0.00 green:0.00 blue:0.55 alpha:0.65],
                 [UIColor colorWithRed:0.00 green:0.38 blue:0.11 alpha:0.65], // Celtic
                 [UIColor colorWithRed:0.15 green:0.25 blue:0.55 alpha:0.65], // Royal blue
                 [UIColor colorWithRed:0.00 green:0.20 blue:0.00 alpha:0.99],
                 [UIColor colorWithRed:0.12 green:0.24 blue:0.19 alpha:0.99],
                 [UIColor colorWithRed:0.18 green:0.03 blue:0.33 alpha:0.99], // Indigo
                 [UIColor colorWithRed:0.20 green:0.00 blue:0.00 alpha:0.99],
                 [UIColor colorWithRed:0.21 green:0.16 blue:0.10 alpha:0.99],
                 [UIColor colorWithRed:0.10 green:0.10 blue:0.10 alpha:0.99], // Gray 10
                 [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:0.99],
                 [UIColor colorWithRed:0.30 green:0.30 blue:0.30 alpha:0.99],
                 [UIColor colorWithRed:0.09 green:0.13 blue:0.32 alpha:0.99]
            ];
        });
    
    return _colorValues;
}

+(NSArray*)getColorNames
{
    static NSArray* _colorNames;
    static dispatch_once_t onceTokenN;
    dispatch_once(&onceTokenN, ^{
        _colorNames = @[@"System",          @"White",           @"Ivory",
                        @"Popcorn",         @"Sea shell",       @"Papaya whip",
                        @"Bisque",          @"Gold",            @"Rosy brown",
                        @"Mustard",         @"Silver",          @"Chrome",
                        @"Gray",            @"Light gray",      @"Lighter gray",
                        @"Very light gray", @"Lavender",        @"Beer",
                        @"Melon",           @"Azure",           @"Stainless steel",
                        @"Plum",            @"Mint blue",       @"Tan",
                        @"Quartz",          @"Wheat",           @"Safety vest",
                        @"Dark orange",     @"Orange red",      @"Strawberry",
                        @"Burgundy",        @"Maroon",          @"Brown",
                        @"Iceberg lettuce", @"Green grape",     @"Pear",
                        @"Limepulp",        @"Dark seagreen",   @"Cat eye",
                        @"Light blue",      @"Pastel blue",     @"Light steelblue",
                        @"Light cyan",      @"Pale turquoise",  @"Midnight blue",
                        @"Dark blue",       @"Celtics",         @"Royal blue",
                        @"Pine green",      @"Packer green",    @"Indigo",
                        @"Dark Cherry",     @"Cafe Americano",  @"Gray 10",
                        @"Gray 20",         @"Gray 30",         @"Blue velvet"
                       ];
    });
    
    return _colorNames;
}


+(NSString*)getStringFromKeychainForAccount:(NSString*)account
{
    if (keychain == nil) {
        keychain = [[KeychainWrapper alloc] init];
    }
    
    return [keychain getKeychainDataForAccount:account];
}

+(void)writeValueToKeychain:(id)value forAccount:(NSString*)account
{
    if (keychain == nil) {
        keychain = [[KeychainWrapper alloc] init];
    }
    
    [keychain mySetObject:value forKey:(__bridge id)kSecValueData forAccount:account];
    //[keychain writeToKeychain];
}



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
static int indexAtt;
static int totalAtts;
static UIScrollView* attScroll;

-(void)thumbReady:(UIImage*)thumb
{
    UIImageView* att;
    if (thumb) {
        att = [[UIImageView alloc] initWithImage:thumb];
    }else{
        att = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"docIcon"]];
    }
    att.tag = indexAtt+1000;
    CGRect frameRect = att.frame;
    // Add a 72x72 image view for attachment
    frameRect.origin = CGPointMake(indexAtt*78, 0);
    frameRect.size = CGSizeMake(72, 72);
    att.frame = frameRect;
    att.contentMode = UIViewContentModeScaleToFill;
    [attScroll addSubview:att];
    indexAtt++;
    if (indexAtt == totalAtts) {
        // Notify the receiver
        
        [attScroll setContentSize:CGSizeMake(80*indexAtt,72)]; // set scroll inner size to enable scrolling
    }
}

+(void)showAttachmentsIconsNew:(FullMessageEntity *)currentMessage scroll:(UIScrollView *)attScroll receiver:(id)receiver
{
    //attScroll.subviews
    NSArray *viewsToRemove = [attScroll subviews];
    for (UIView *v in viewsToRemove) [v removeFromSuperview];

    for (NSObject* asset in currentMessage.attachments) {
        // Create thumbnail image
        if ([asset isKindOfClass:[NSString class]]){
            [self getThumbnailFromURL:[NSURL fileURLWithPath:(NSString*)asset] delegate:self];
        }
    }
}

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
        /*if([asset isKindOfClass:[ALAsset class]]){
            att = [self thumbnailViewFromAsset:(ALAsset*)asset];
        }else */if ([asset isKindOfClass:[NSString class]]){
            //att = [self thumbnailViewFromPath:(NSString*)asset];
            UIImage* thim = [self getThumbnailFromURL:[NSURL fileURLWithPath:(NSString*)asset] delegate:nil];
            att = [[UIImageView alloc] initWithImage:thim];
            if (!att) {
                att = [self thumbnailViewFromPath:(NSString*)asset];
            }
        }else if([asset isKindOfClass:[PHAsset class]]){
            att = [self thumbnailViewFromPHAsset:(PHAsset*)asset];
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
    
    //UIDocumentInteractionController
    /*
     -(void)loadDocument:(NSString*)documentName inView:(UIWebView*)webView
     {
     NSString *path = [[NSBundle mainBundle] pathForResource:documentName ofType:nil];
     NSURL *url = [NSURL fileURLWithPath:path];
     NSURLRequest *request = [NSURLRequest requestWithURL:url];
     [webView loadRequest:request];
     }
     
     // Calling -loadDocument:inView:
     [self loadDocument:@"mydocument.rtfd.zip" inView:self.myWebview];
    */
}

+(NSString*)getSizeRep:(unsigned long long)size
{
    NSString* sizeStr;
    if(size > 1024*1024*1024){
        sizeStr = [NSString stringWithFormat:@"%.01fG", (float)(size/(1024*1048576.0))];
    }else if (size > 1024*1024) {
        sizeStr = [NSString stringWithFormat:@"%.01fM", (float)(size/1048576.0)];
    }else{
        if (size < 512) {
            sizeStr = [NSString stringWithFormat:@"%.01fK", (float)(round(size/100.0)/10.0)];
        }else{
            sizeStr = [NSString stringWithFormat:@"%.00fK", (float)ceil(size/1024.0)];
        }
    }
    
    return sizeStr;
}

+(NSString*)getByteSizeRep:(unsigned long long)size
{
    NSString* sizeStr;
    if(size > 1024*1024*1024){
        sizeStr = [NSString stringWithFormat:@"%.01fG", (float)(size/(1024*1048576.0))];
    }else if (size > 1024*1024) {
        sizeStr = [NSString stringWithFormat:@"%.01fM", (float)(size/1048576.0)];
    }else{
        if (size < 512) {
            sizeStr = [NSString stringWithFormat:@"%llub", size];
        }else{
            sizeStr = [NSString stringWithFormat:@"%.02fK", (float)(round(size/10.0)/100.0)];
        }
    }
    
    return sizeStr;
}

/*
+(UIImageView*)thumbnailViewFromAsset:(ALAsset*)asset
{
    return [[UIImageView alloc] initWithImage: [[UIImage alloc] initWithCGImage: [asset thumbnail]]];
}*/

+(UIImageView*)thumbnailViewFromPHAsset:(PHAsset*)asset
{
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    options.networkAccessAllowed = YES;
    
    NSInteger retinaMultiplier = [UIScreen mainScreen].scale;
    CGSize retinaSquare = CGSizeMake(100 * retinaMultiplier, 100 * retinaMultiplier);
    
    dispatch_semaphore_t semap = dispatch_semaphore_create(0);
    __block UIImage* im;
    
    [[PHImageManager defaultManager]
     requestImageForAsset:(PHAsset *)asset
     targetSize:retinaSquare
     contentMode:PHImageContentModeAspectFill
     options:options
     resultHandler:^(UIImage *result, NSDictionary *info) {
         im = [UIImage imageWithCGImage:result.CGImage scale:retinaMultiplier orientation:result.imageOrientation];
         dispatch_semaphore_signal(semap);
     }];
    dispatch_semaphore_wait(semap, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20.0 * NSEC_PER_SEC)));//DISPATCH_TIME_FOREVER);
    return [[UIImageView alloc] initWithImage:im];
}

+(UIImage*)sizeAndTypeOnThumbForPath:(NSString*)path thumbnail:(UIImage*)thumb
{
    UIImage* im = [thumb copy];
    
    unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
    
    //NSString* pathExt = nil;
    //NSMutableAttributedString *textStyle = nil;
    NSMutableAttributedString *sizeText = nil;
    
    // File size
    sizeText = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    sizeText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@ ",[CommonProcs getSizeRep:fileSize]]];
    [sizeText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0 green:0 blue:0.4 alpha:1] range:NSMakeRange(0, sizeText.length)];
    [sizeText addAttribute:NSFontAttributeName  value:[UIFont systemFontOfSize:8.5] range:NSMakeRange(0, sizeText.length)];
    
    NSMutableAttributedString* nameText = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    nameText = [[NSMutableAttributedString alloc] initWithString:[path pathExtension]];//[path lastPathComponent]];
    [nameText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0 green:0 blue:0.4 alpha:1] range:NSMakeRange(0, nameText.length)];
    [nameText addAttribute:NSFontAttributeName  value:[UIFont systemFontOfSize:7] range:NSMakeRange(0, nameText.length)];
    
    CGSize destinationSize = CGSizeMake(70, 70);
    CGSize originalSize = im.size;
    
    float x = 1;
    float y = 1;
    if (originalSize.height > originalSize.width) {
        x = originalSize.height/originalSize.width;
        y = 1;
    }else{
        y = originalSize.width/originalSize.height;
        x = 1;
    }
    
    UIGraphicsBeginImageContextWithOptions(destinationSize, NO, 0.0f);
    [im drawInRect:CGRectMake(35-0.5*(destinationSize.width/x),35-0.5*(destinationSize.height/y),destinationSize.width/x,destinationSize.height/y)];
    
    UIImage* infoLine = [UIImage imageNamed:@"infoLine"];
    [infoLine drawInRect:CGRectMake(1,43,60,21)];
    
    [sizeText drawAtPoint:CGPointMake(8, 52)];
    [nameText drawAtPoint:CGPointMake(10, 45)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    im = nil;
    
    return newImage;
}

+(UIImageView*)thumbnailViewFromPath:(NSString*)path
{
    //UIImageView* ret;
    UIImage* im = [[UIImage alloc] initWithContentsOfFile:path];
    unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
    
    NSString* pathExt = nil;
    NSMutableAttributedString *textStyle = nil;
    NSMutableAttributedString *sizeText = nil;
    
    // File size
    sizeText = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    sizeText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@ ",[CommonProcs getSizeRep:fileSize]]];
    [sizeText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0 green:0 blue:0.4 alpha:1] range:NSMakeRange(0, sizeText.length)];
    [sizeText addAttribute:NSFontAttributeName  value:[UIFont systemFontOfSize:8.5] range:NSMakeRange(0, sizeText.length)];
    
    NSMutableAttributedString* nameText = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    nameText = [[NSMutableAttributedString alloc] initWithString:[path lastPathComponent]];
    [nameText addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0 green:0 blue:0.4 alpha:1] range:NSMakeRange(0, nameText.length)];
    [nameText addAttribute:NSFontAttributeName  value:[UIFont systemFontOfSize:6] range:NSMakeRange(0, nameText.length)];
    
    UIColor* tintColor = nil;
    if (im == nil) {
        pathExt = [path pathExtension];
        if (pathExt.length > 4) {
            pathExt = [pathExt substringToIndex:4];
        }
        im = [UIImage imageNamed:@"docIcon"];
        textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        textStyle = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@",pathExt]];
        // text color
        [textStyle addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0 green:0 blue:0.4 alpha:1] range:NSMakeRange(0, textStyle.length)];
        // text font
        [textStyle addAttribute:NSFontAttributeName  value:[UIFont systemFontOfSize:17.0] range:NSMakeRange(0, textStyle.length)];
        
        
        if ([pathExt isEqualToString:@"pdf"]) {
            tintColor = [UIColor redColor];
        }else if ([pathExt isEqualToString:@"xls"] || [pathExt isEqualToString:@"xlsx"]){
            tintColor = [UIColor colorWithRed:0 green:0.4 blue:0 alpha:1];
        }else if ([pathExt isEqualToString:@"doc"] || [pathExt isEqualToString:@"docx"]){
            tintColor = [UIColor blueColor];
        }else{
            if (@available(iOS 13.0, *)) {
                tintColor = [UIColor labelColor];
            } else {
                // Fallback on earlier versions
                tintColor = [UIColor blackColor];
            }
        }
    }else{
        //[sizeText addAttribute:NSBackgroundColorAttributeName value:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.6] range:NSMakeRange(0,sizeText.length)];
        //[nameText addAttribute:NSBackgroundColorAttributeName value:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.6] range:NSMakeRange(0,nameText.length)];
    }
    
    CGSize destinationSize = CGSizeMake(70, 70);
    CGSize originalSize = im.size;
    
    float x = 1;
    float y = 1;
    if (originalSize.height > originalSize.width) {
        x = originalSize.height/originalSize.width;
        y = 1;
    }else{
        y = originalSize.width/originalSize.height;
        x = 1;
    }
    
    //UIGraphicsBeginImageContext(destinationSize); // This one gives a blurred image... use UIGraphicsBeginImageContextWithOptions
    UIGraphicsBeginImageContextWithOptions(destinationSize, NO, 0.0f);
    if (@available(iOS 13.0, *)) {
        [[UIColor systemBackgroundColor] setFill];
    } else {
        // Fallback on earlier versions
        [[UIColor whiteColor] setFill];
    }
    CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, 70, 70));
    //[im drawInRect:CGRectMake(0,0,destinationSize.width,destinationSize.height)];
    
    [im drawInRect:CGRectMake(35-0.5*(destinationSize.width/x),35-0.5*(destinationSize.height/y),destinationSize.width/x,destinationSize.height/y)];
    if (pathExt != nil) {
        [textStyle drawAtPoint:CGPointMake(10, 6)];
    }else{
        UIImage* infoLine = [UIImage imageNamed:@"infoLine"];
        //[infoLine drawInRect:CGRectMake(35-0.5*(destinationSize.width/x),68-0.5*(destinationSize.height/y),destinationSize.width/x,30/y)];
        [infoLine drawInRect:CGRectMake(1,43,60,21)];
    }
    [sizeText drawAtPoint:CGPointMake(8, 52)];
    [nameText drawAtPoint:CGPointMake(10, 45)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    im = nil;
    
    UIImageView* ret = [[UIImageView alloc] initWithImage:newImage];
    if(tintColor != nil){
        ret.image = [ret.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [ret setTintColor:tintColor];
    }
    return ret;
    //return [[UIImageView alloc] initWithImage:newImage];
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
    
    //newImage = [CommonProcs sizeAndTypeOnThumbForPath:url.path thumbnail:newImage];
    
    return newImage;
}

+(UIImage*)getFullImage:(NSObject*)item
{
    __block UIImage* att;
    
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        /*if([item isKindOfClass:[ALAsset class]]){
            att = [self fullImageFromAsset:(ALAsset*)item];
        }else */if ([item isKindOfClass:[NSString class]]){
            att = [self fullImageFromPath:(NSString*)item];
        }else if([item isKindOfClass:[PHAsset class]]){
            if ([NSThread isMainThread]) {
                NSLog(@"ERROR!!!! getFullImage was called from the main thread!");
                //dispatch_semaphore_t semap = dispatch_semaphore_create(0);
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    att = [self fullImageFromPHAsset:(PHAsset*)item];
                    //dispatch_semaphore_signal(semap);
                });
                //dispatch_semaphore_wait(semap, DISPATCH_TIME_FOREVER);
            }else{
                att = [self fullImageFromPHAsset:(PHAsset*)item];
            }
        }
    //});
    
    return att;
}

+(UIImage*)fullImageFromPHAsset:(PHAsset*)asset
{
    __block PHImageRequestID reqID;
    __block BOOL cancelled = NO;
    [CommonProcs showProgressWithTitle:0 max:100 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Loading image",nil) stopButton:YES withBlock:^{
        [[PHImageManager defaultManager] cancelImageRequest:reqID]; // Looks like it's for async
        [CommonProcs hideProgress];
        cancelled = YES;
    }];
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    options.synchronous = YES;
    options.networkAccessAllowed = YES;
    options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        //NSLog(@"%f", progress);
        [CommonProcs setProgress:(int)(progress*100) max:100 title:NSLocalizedString(@"Loading image",nil)];
        if (cancelled) {
            //NSLog(@"CANCELLED");
            *stop = YES;
        }
         if(progress == 1){
             //[CommonProcs hideProgress];
         }
    };
    
    //dispatch_semaphore_t semap = dispatch_semaphore_create(0);
    __block UIImage* im;
    
    reqID = [[PHImageManager defaultManager]
        requestImageForAsset:(PHAsset*)asset
        targetSize:PHImageManagerMaximumSize
        contentMode:PHImageContentModeDefault
        options:options
        resultHandler:^(UIImage *result, NSDictionary *info) {
            NSError* err = [info valueForKey:PHImageErrorKey];
            if (err) {
                [CommonProcs hideProgress];
                [CommonProcs showMessage:err.localizedDescription title:@"Error"];
            }
            im = result;
            //dispatch_semaphore_signal(semap);
     }];
    //dispatch_semaphore_wait(semap, DISPATCH_TIME_FOREVER);
    
    [CommonProcs hideProgress];
    return im;
}

/*
+(UIImage*)fullImageFromAsset:(ALAsset*)asset
{
    ALAssetRepresentation* rep = [asset defaultRepresentation];
    return [[UIImage alloc] initWithCGImage: [rep fullResolutionImage]];
}*/

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

+(NSString*)getTempPathForDoc:(NSString*)ext
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tmpDirectory = NSTemporaryDirectory();
    NSString *path = [tmpDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"doc.%@", ext]];
    int ind = 1;
    while ([fileManager fileExistsAtPath:path]) {
        NSString* theFileName = @"doc";//[[@"doc.doc" lastPathComponent] stringByDeletingPathExtension];
        //NSString* ext = [@"image.jpg" pathExtension];
        NSString* version = [NSString stringWithFormat:@"%@-%d.%@",theFileName, ind, ext];
        path = [tmpDirectory stringByAppendingPathComponent:version];
        ind++;
    }
    
    return path;
}

+(NSString*)getTempPathForImageInDocuments
{
    return [CommonProcs getTempPathForImageInDocumentsWithExtension:@"jpg"];
}

+(NSString*)getTempPathForImageInDocumentsWithExtension:(NSString*)extention
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsGalleryDirectory = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Gallery"];
    NSString* imageName = [NSString stringWithFormat:@"%@.%@",[[NSUUID UUID] UUIDString],extention];
    NSString *path = [documentsGalleryDirectory stringByAppendingPathComponent:imageName];
    int ind = 1;
    while ([fileManager fileExistsAtPath:path]) {
        NSString* theFileName = [[imageName lastPathComponent] stringByDeletingPathExtension];
        NSString* ext = [imageName pathExtension];
        NSString* version = [NSString stringWithFormat:@"%@%d.%@",theFileName, ind, ext];
        path = [documentsGalleryDirectory stringByAppendingPathComponent:version];
        ind++;
    }
    
    return path;
}

+(NSString*)getGalleryPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Gallery"];
}

+(NSString*)copyFileToTemp:(NSString *)filename
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *tmpDirectory = NSTemporaryDirectory();
    NSString* nameAndExt = [filename lastPathComponent];
    NSString* theFileName = [nameAndExt stringByDeletingPathExtension];
    NSString *path = [tmpDirectory stringByAppendingPathComponent:nameAndExt];
    int ind = 1;
    while ([fileManager fileExistsAtPath:path]) {
        NSString* ext = [filename pathExtension];
        NSString* version = [NSString stringWithFormat:@"%@-%d.%@",theFileName, ind, ext];
        path = [tmpDirectory stringByAppendingPathComponent:version];
        ind++;
    }
    NSError* error;
    
    [fileManager copyItemAtPath:filename toPath:path error:&error];
    if (error) {
        return nil;
    }
    
    return path;
}

+(NSString*)copyFileToDocs:(NSString *)filename
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString *resourcePath;
    NSString* ext = [filename pathExtension];
    if ([ext isEqualToString:@""]) {
        ext = @"html";
    }
    if (![fileManager fileExistsAtPath:filename]) {
        resourcePath = [[NSBundle mainBundle] pathForResource:[[filename lastPathComponent] stringByDeletingPathExtension] ofType:ext];
    }else{
        resourcePath = filename;
    }
    
    NSString* nameAndExt = [resourcePath lastPathComponent];
    NSString* theFileName = [nameAndExt stringByDeletingPathExtension];
    NSString *path = [documentsPath stringByAppendingPathComponent:nameAndExt];
    int ind = 1;
    while ([fileManager fileExistsAtPath:path]) {
        NSString* ext = [filename pathExtension];
        NSString* version = [NSString stringWithFormat:@"%@-%d.%@",theFileName, ind, ext];
        path = [documentsPath stringByAppendingPathComponent:version];
        ind++;
    }
    NSError* error;
    
    [fileManager copyItemAtPath:resourcePath toPath:path error:&error];
    if (error) {
        return nil;
    }
    
    return path;
}

+(NSString*)saveImageForPHAssetToTempFile:(PHAsset*)asset
{
    __block NSString* path;
    __block BOOL wait = asset.mediaType == PHAssetMediaTypeVideo;
    if (asset.mediaType == PHAssetMediaTypeVideo) {
        if (asset.mediaSubtypes&PHAssetMediaSubtypeVideoHighFrameRate) {
            
            [CommonProcs showProgressWithTitle:0 max:100 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Loading video",nil) stopButton:YES];
            
            PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
            options.networkAccessAllowed = YES;
            [options setProgressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [CommonProcs setProgress:progress*100 max:100 title:@"Loading..."];
                    });
            }];
            
            [[PHImageManager defaultManager] requestExportSessionForVideo:asset options:options exportPreset:AVAssetExportPresetPassthrough resultHandler:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {
                if (!exportSession) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [CommonProcs hideProgress];
                    });
                    return;
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [CommonProcs addStopButtonInView:[[GlobalRouter sharedManager] getCurrentView] withBlock:^{
                        [exportSession cancelExport];
                        [CommonProcs hideProgress];
                    }];
                });
                NSString* pathTmp = [CommonProcs getTempPathForDoc:@"mov"];
                
                exportSession.outputURL = [NSURL fileURLWithPath:pathTmp];
                exportSession.outputFileType = AVFileTypeQuickTimeMovie;
                //exportSession.shouldOptimizeForNetworkUse = YES;
                                    
                [exportSession exportAsynchronouslyWithCompletionHandler:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [CommonProcs hideProgress];
                        if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                            path = pathTmp;
                            [CommonProcs hideProgress];
                        }
                    });
                }];
            }];
        }else{
            [CommonProcs showProgressWithTitle:0 max:100 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Loading video",nil) stopButton:YES withBlock:^{
                wait = NO;
                path = @"";
                [CommonProcs hideProgress];
            }];
            // Allow downloading from iCloud
            PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
            options.networkAccessAllowed = YES;
            options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info)
            {
                [CommonProcs setProgress:ceil(progress*100) max:100 title:NSLocalizedString(@"Loading video",nil)];
            };
            [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset *avAsset, AVAudioMix *audioMix, NSDictionary *info) {
                NSURL *url = (NSURL *)[[(AVURLAsset *)avAsset URL] fileReferenceURL];
                //NSLog(@"url = %@", [url absoluteString]);
                //NSLog(@"url = %@", [url relativePath]);
                path = [CommonProcs getTempPathForDoc:[url.path pathExtension]];
                NSError *error;
                AVURLAsset *avurlasset = (AVURLAsset*) avAsset;
                
                // Write to documents folder
                NSURL *fileURL = [NSURL fileURLWithPath:path];
                if ([[NSFileManager defaultManager] copyItemAtURL:avurlasset.URL
                                                            toURL:fileURL
                                                            error:&error]) {
                    //NSLog(@"Copied correctly");
                }
                path = fileURL.path;
                [CommonProcs hideProgress];
            }];
        }
    }else{
        UIImage* img = [CommonProcs fullImageFromPHAsset:asset];
        if (!img) {
            path = nil;
        }else{
            float cRatio = [[[GlobalRouter sharedManager] getListRouter].dataStore getJPEGCompression];
            NSData* jpeg = UIImageJPEGRepresentation(img, cRatio);
            //NSData* encoded = [enc encryptAESData:jpeg];
            path = [CommonProcs getTempPathForImage];
            [jpeg writeToFile:path atomically:YES];
            //[atts addObject:path];
            img = nil;
            jpeg = nil;
        }
        //encoded = nil;
    }
    if(wait){
        while (!path) {
            sleep(1);
        }
        wait = NO;
        return path;
    }else
        return path;
}

+(void)showSmallWheelinView:(UIView*)view
{
    if (showingWheel || smallIndicator) {
        smallWheelsNo++;
        return;
    }
    
    showingWheel = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (@available(iOS 13.0, *)) {
            smallIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleMedium /*UIActivityIndicatorViewStyleGray*/];
        } else {
            // Fallback on earlier versions
            smallIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
        }
        smallIndicator.center = CGPointMake(view.bounds.size.width / 2, 37);
        [view addSubview:smallIndicator];
        [smallIndicator startAnimating];
        
        smallWheelLabel = [[UILabel alloc] initWithFrame:CGRectMake(view.bounds.size.width / 2-80, 43, 160, 20)];
        [smallWheelLabel setFont:[UIFont systemFontOfSize:10]];
        [smallWheelLabel setTextAlignment:NSTextAlignmentCenter];
        [smallWheelLabel setTextColor:[UIColor grayColor]];
        [view addSubview:smallWheelLabel];
    });
    
    //[[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
}

+(BOOL)isSWPresent
{
    return smallWheelLabel != nil;
}

+(void)setSWLabelText:(NSString*)text
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [smallWheelLabel setText:text];
    });
}

+(void)hideSmallWheel
{
    if(smallWheelsNo > 0)
        smallWheelsNo--;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (smallIndicator == nil) {
            return;
        }
        [smallIndicator stopAnimating];
        [smallIndicator removeFromSuperview];
        smallIndicator = nil;
        showingWheel = NO;
        smallWheelsNo = 0;
        
        [smallWheelLabel removeFromSuperview];
        smallWheelLabel = nil;
    });
}

+(void)showWheelinView:(UIView*)view
{
    [CommonProcs showWheelinView:view message:NSLocalizedString(@"Connecting...", nil) stopButtonVisible:YES];
}

+(UIView*)getDimView
{
    return dimView;
}

+(void)showWheelinView:(UIView*)view message:(NSString*)messageText stopButtonVisible:(BOOL)stopButtonVisible
{
    [CommonProcs showWheelinView:view message:messageText stopButtonVisible:stopButtonVisible withBlock:nil];
}

+(void)showWheelinView:(UIView*)view message:(NSString*)messageText stopButtonVisible:(BOOL)stopButtonVisible withBlock:(void(^)(void))stopBl
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
        stopBlock = [stopBl copy];
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
    [CommonProcs addStopButtonInView:view withBlock:nil];
}

static void (^stopBlock)(void);
+(void)addStopButtonInView:(UIView*)view withBlock:(void(^)(void))stopBl
{
    if (dimView == nil) {
        // Sometimes the process is faster than we get here and there's no need to stop
        return;
    }
    if (stop == nil) {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        stop = [[UIButton alloc] initWithFrame:CGRectMake(screenWidth/2-80, view.bounds.size.height/2+14, 160, 30)];
        [stop setTitle: NSLocalizedString(@"Stop", nil) forState:UIControlStateNormal];
        stopBlock = [stopBl copy];
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
        stopBlock = [stopBl copy];
    }else{
        stop.hidden = NO;
        stopBlock = [stopBl copy];
    }
}

+(void)stopPressed:(id)sender
{
    
    if(stopBlock){
        stopBlock();
    }else{
        [[GlobalRouter sharedManager] cancelQ];
    }
    
    progressCount = 1;
    [self hideProgress]; // showProgress:10 max:10 inView:nil];
    // hide refresh control if any
    MessageListRouter* rt = [[GlobalRouter sharedManager] getListRouter];
    if(rt)
        [rt needHideRefreshControl];
}

+(void)showProgress:(int)progress max:(int)maxValue inView:(UIView *)view
{
    [self showProgressWithTitle:progress max:maxValue inView:view title:NSLocalizedString(@"Connecting...", nil) stopButton:YES];
}

+(void)setProgress:(int)progress max:(int)maxValue title:(NSString *)title
{
    dispatch_async(dispatch_get_main_queue(), ^{
        int progressToShow = progress, maxToShow = maxValue;
        
        if(showingWheel || loading){ // should be YES
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
                loading.text = [NSString stringWithFormat:@"%@ (%d%@/%d%@)", title /*NSLocalizedString(@"Loading...", nil)*/,progressToShow,pSfx, maxToShow, mSfx];
            }else{
                loading.text = title;
            }
        }
    });
}

static int progressCount = 0;

+(void)showProgressWithTitle:(int)progress max:(int)maxValue inView:(UIView*)view title:(NSString *)title stopButton:(BOOL)stopButton
{
    [CommonProcs showProgressWithTitle:progress max:maxValue inView:view title:title stopButton:stopButton withBlock:nil];
}

+(void)showProgressWithTitle:(int)progress max:(int)maxValue inView:(UIView*)view title:(NSString *)title stopButton:(BOOL)stopButton withBlock:(void(^)(void))stopBl
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
            [self showWheelinView:view message:title stopButtonVisible:stopButton withBlock:stopBl];
            //progressCount++;
        }else if(showingWheel){
            if ([view.subviews indexOfObject:dimView] == NSNotFound) {
                //NSLog(@"Not found");
                showingWheel = NO;
                [self showWheelinView:view message:title stopButtonVisible:stopButton withBlock:stopBl];
            }
            if (stopButton) {
                //[self addStopButtonInView:view];
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

+(void)hideProgressAlways
{
    dispatch_async(dispatch_get_main_queue(), ^{
        progressCount = 0;
        if (indicator) {
            [indicator stopAnimating];
            [indicator removeFromSuperview];
        }
        if(dimView)[dimView removeFromSuperview];
        if(loading)[loading removeFromSuperview];
        if(stop)[stop removeFromSuperview];
        dimView = nil;
        indicator = nil;
        loading = nil;
        stop = nil;
        showingWheel = NO;
    });
}

+(void)hideProgress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if(progressCount > 0)
            progressCount--;
        else
            progressCount = 0;
        
        if(progressCount == 0){
        
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
        }
    });
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
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([GlobalRouter sharedManager].goingToBG || [UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
            return;
        }
        
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:title
                                     message:message
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
        alert.modalPresentationStyle = UIModalPresentationOverFullScreen;
        [[[GlobalRouter sharedManager] /*getDetailNavController*/ getTopViewController] presentViewController:alert animated:YES completion:nil];
        
        //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
        //alert.tag = 10000;
        //[alert show];
    });
}

+(void)askAndDoWithTitle:(NSString*)title text:(NSString*)alertText block:(dispatch_block_t)block
{
    //alertBlock = block;
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:alertText
                                 preferredStyle:UIAlertControllerStyleAlert];
    //__weak __typeof__(self) weakSelf = self;
    UIAlertAction* ok = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"OK", nil)
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
                                   //__strong __typeof__(self) strongSelf = weakSelf;
                                   block();
                               }];
    [alert addAction:ok];
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"Cancel",nil)
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 
                             }];
    [alert addAction:cancel];
    
    UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
    alert.popoverPresentationController.sourceView = pView;
    alert.popoverPresentationController.sourceRect = pView.frame;
    [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
}

+(void)askYesNoAndDoWithTitle:(NSString*)title text:(NSString*)alertText blockYes:(dispatch_block_t)blockYes blockNo:(dispatch_block_t)blockNo
{
    [CommonProcs askYesNoAndDoWithTitles:title text:alertText button1Title:NSLocalizedString(@"Yes", nil) button2Title:NSLocalizedString(@"No", nil) blockYes:blockYes blockNo:blockNo];
    
    /*
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:alertText
                                 preferredStyle:UIAlertControllerStyleAlert];
    //__weak __typeof__(self) weakSelf = self;
    UIAlertAction* ok = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"Yes", nil)
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
                                   //__strong __typeof__(self) strongSelf = weakSelf;
                                   blockYes();
                               }];
    [alert addAction:ok];
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"No",nil)
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 blockNo();
                             }];
    [alert addAction:cancel];
    
    UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
    alert.popoverPresentationController.sourceView = pView;
    alert.popoverPresentationController.sourceRect = pView.frame;
    [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
     */
}

+(void)askYesNoAndDoWithTitles:(NSString*)title text:(NSString*)alertText button1Title:(NSString*)button1Title button2Title:(NSString*)button2Title blockYes:(dispatch_block_t)blockYes blockNo:(dispatch_block_t)blockNo
{
    //alertBlock = block;
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:alertText
                                 preferredStyle:UIAlertControllerStyleAlert];
    //__weak __typeof__(self) weakSelf = self;
    UIAlertAction* ok = [UIAlertAction
                               actionWithTitle:button1Title
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
                                   //__strong __typeof__(self) strongSelf = weakSelf;
                                   blockYes();
                               }];
    [alert addAction:ok];
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:button2Title
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 blockNo();
                             }];
    [alert addAction:cancel];
    
    UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
    alert.popoverPresentationController.sourceView = pView;
    alert.popoverPresentationController.sourceRect = pView.frame;
    [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
}


+(void)thisFeatureIsInFull:(NSString*)feature
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* title = [NSString stringWithFormat:NSLocalizedString(@"Feature %@ is unavailable", nil), feature];
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:title
                                     message:NSLocalizedString(@"Get the full version?", nil)
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* getIt = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Get full version!",nil)
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action)
                                   {
                                       // Go to the app store https://itunes.apple.com/app/id1105423160
                                       static NSInteger const kAppITunesItemIdentifier = 1105423160;
                                       [[GlobalRouter sharedManager] openStoreProductViewControllerWithITunesItemIdentifier:kAppITunesItemIdentifier];
                                   }];
        [alert addAction:getIt];
        
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction * action)
                                 {
                                     
                                 }];
        [alert addAction:cancel];
        
        UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
        alert.popoverPresentationController.sourceView = pView;
        alert.popoverPresentationController.sourceRect = pView.frame;
        [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
        
        //NSString* title = [NSString stringWithFormat:NSLocalizedString(@"Feature %@ is unavailable", nil), feature];
        //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:NSLocalizedString(@"Get the full version?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles: NSLocalizedString(@"Get full version!",nil), nil];
        //alert.tag = 500;
        //[alert show];
    });
}

/*
+(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 500)
    {
        if (buttonIndex == 0)
        {
        }else{
            // Go to the app store https://itunes.apple.com/app/id1105423160
            static NSInteger const kAppITunesItemIdentifier = 1105423160;
            [[GlobalRouter sharedManager] openStoreProductViewControllerWithITunesItemIdentifier:kAppITunesItemIdentifier];
            
            //NSString *iTunesLink = @"itms://itunes.apple.com/us/app/apple-store/id1105423160?mt=8";
            //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
        }
    }
}
*/
    
+(void)spawnProc:(SEL)selector object:(id)object withParam:(id)withObject
{
    if (!object) {
        NSLog(@"Spawn func with no object");
        return;
    }
    
    //[self showProgress:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    //[self showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Loading...", nil) stopButton:NO];
    /*if (my_q == nil) {
        my_q = dispatch_queue_create("my.q", NULL);
    }
    dispatch_async(my_q, ^{*/
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        IMP imp = [object methodForSelector:selector];
        void (*func)(id, SEL,id) = (void *)imp;
        func(object, selector, withObject);
        //[object performSelector:selector withObject:withObject]; // Warning - since ARC doesn't know what to do with ret of the func, so we need to tell all the parameters of the called proc...
    });
    //[object performSelectorInBackground:selector withObject:withObject];
}
+(void)spawnProcWithProgress:(SEL)selector object:(id)object withParam:(id)withObject
{
    [CommonProcs spawnProcWithProgress:selector object:object withParam:withObject onMain:NO];
}

+(void)spawnProcWithProgress:(SEL)selector object:(id)object withParam:(id)withObject onMain:(BOOL)onMain
{
    if (!object) {
        NSLog(@"Spawn func with no object");
        return;
    }
    //[self showProgress:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
//#warning here!
    ///////////////[self showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Loading...", nil) stopButton:NO];
    /*if (my_q == nil) {
        my_q = dispatch_queue_create("my.q", NULL);
    }
    dispatch_async(my_q, ^{
     */
    dispatch_queue_t queue = onMain?dispatch_get_main_queue():dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        IMP imp = [object methodForSelector:selector];
        void (*func)(id, SEL,id) = (void *)imp;
        func(object, selector, withObject);
        //[object performSelector:selector withObject:withObject]; // Warning - since ARC doesn't know what to do with ret of the func, so we need to tell all the parameters of the called proc...
    });
    //[object performSelectorInBackground:selector withObject:withObject];
}

+(void)spawnProcWithProgress:(SEL)selector object:(id)object withParam1:(id)withObject1 withParam2:(id)withObject2
{
    if (!object) {
        NSLog(@"Spawn func with no object");
        return;
    }
    //[self showProgress:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    [self showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Loading...", nil) stopButton:NO];
    /*if (my_q == nil) {
        my_q = dispatch_queue_create("my.q", NULL);
    }
    dispatch_async(my_q, ^{*/
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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

+(NSString*)getPathIntoDocs:(NSString*)fileName
{
    //get the documents directory:
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    //make a file name to write the data to using the documents directory:
    NSString *retName = [NSString stringWithFormat:@"%@/%@",documentsDirectory, fileName];
    
    return retName;
}

#ifdef STRONG
+(void)askToMakeKeyFile
{
    [ModalDialogViewController runWithHeader:NSLocalizedString(@"Enter password to create the key file", nil)
                                       text1:NSLocalizedString(@"Password:", nil)
                                       text2:NSLocalizedString(@"Repeat password:", nil)
                                       block:^{
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               [CommonProcs showWheelinView:[[GlobalRouter sharedManager] getCurrentView] message:NSLocalizedString(@"Copying...",nil) stopButtonVisible:NO];
                                           });
                                           dispatch_semaphore_t makeSem = dispatch_semaphore_create(0);
                                           dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                               Encryptor* enc = [[Encryptor alloc]initWithKey:[ModalDialogViewController getText1]];
                                               [enc shuffleKeyFiles:@"dataFile"];
                                               [[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"callMe"];
                                               [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:@"pos"];
                                               /*
                                               int keyID = (int)[[[NSUserDefaults standardUserDefaults] valueForKey:@"callID"] integerValue];
                                               [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:keyID++] forKey:@"callID"];
                                               [GlobalRouter sharedManager].keyID = keyID;
                                                */
                                               [[NSUserDefaults standardUserDefaults] synchronize];
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   [CommonProcs hideProgress];
                                               });
                                               dispatch_semaphore_signal(makeSem);
                                           });
                                           dispatch_semaphore_wait(makeSem, DISPATCH_TIME_FOREVER);
                                           
                                       } isPassword:YES];
}
#endif

#if !LITE
+(void)saveCert:(NSString *)cert forAddress:(NSString *)address
{
    saveResult = NO;
    [ModalDialogViewController runWithHeader:NSLocalizedString(@"Certificate protection",nil)
       text1:NSLocalizedString(@"Password to save this certificate",nil)
       text2:NSLocalizedString(@"Repeat the password",nil)
       block:^{
           // Save cert
           if (!(cert == nil || [cert isEqualToString:@""])) {
               [CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Saving certificate...", nil) stopButton:NO];
               
               UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
               if([dataMan saveKeyForAddress:address yourPin:[ModalDialogViewController getText1] key:[cert dataUsingEncoding:NSUTF8StringEncoding] forDate:[NSDate date]]){
                }else{
                   //Error
                    [self showMessage:NSLocalizedString(@"Error saving certificate", nil) title:NSLocalizedString(@"Error", nil)];
               }
               [CommonProcs hideProgress];
               saveResult = YES;
           }else{
               //[messageViewController showError:NSLocalizedString(@"Error decoding certificate", nil)];
               saveResult = NO;
           }
       } isPassword:YES];

}
#endif

+(BOOL)getSaveResult
{
    return saveResult;
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

#pragma mark Move-copy message
-(void)wantMoveMessage:(FullMessageEntity*)item fromRect:(CGRect)rect canForward:(BOOL)canForward fromView:(UIView*)viewS fromVC:(UIViewController*)vcS
{
    currentMessage = item;
    /*
    UIActionSheet *popup;
    if(canForward){
        popup = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select action",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Forward", nil), NSLocalizedString(@"Move to folder", nil), NSLocalizedString(@"Copy to folder", nil), nil];
    }else{
        popup = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select action",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Mark as read", nil), NSLocalizedString(@"Move to folder", nil), NSLocalizedString(@"Copy to folder", nil), nil];
    }
    
    popup.tag = 202;
    //[popup showFromRect:rect inView:[[GlobalRouter sharedManager] getCurrentView] animated:YES];
    
    */
    //==============
    __weak __typeof__(self) weakSelf = self;
    UIAlertController * view=   [UIAlertController
                                 alertControllerWithTitle:NSLocalizedString(@"Select action",nil)
                                 message:@""
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction* cancel = [UIAlertAction
                         actionWithTitle:NSLocalizedString(@"Cancel",nil)
                         style:UIAlertActionStyleCancel
                         handler:^(UIAlertAction * action)
                         {
                             //Do some thing here
                             [view dismissViewControllerAnimated:YES completion:nil];
                             
                         }];
    [view addAction:cancel];
    
    if(canForward){
        UIAlertAction* forward = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"Forward", nil)
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
                                 {
                                     __strong __typeof__(self) strongSelf = weakSelf;
                                     [strongSelf wantForwardMessage:strongSelf->currentMessage];
                                     
                                 }];
        [view addAction:forward];
    }
    
    UIAlertAction* moveToSpam = [UIAlertAction
                              actionWithTitle:NSLocalizedString(@"Move to spam", nil)
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
                                  __strong __typeof__(self) strongSelf = weakSelf;
                                  [strongSelf moveToSpam];
                                  
                              }];
    [view addAction:moveToSpam];
    
    UIAlertAction* move = [UIAlertAction
                              actionWithTitle:NSLocalizedString(@"Move to folder", nil)
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
                                  __strong __typeof__(self) strongSelf = weakSelf;
                                  [strongSelf wantMoveMessage:strongSelf->currentMessage];
                                  
                              }];
    [view addAction:move];
    
    UIAlertAction* copy = [UIAlertAction
                              actionWithTitle:NSLocalizedString(@"Copy to folder", nil)
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
                                  __strong __typeof__(self) strongSelf = weakSelf;
                                  [strongSelf wantCopyMessage:strongSelf->currentMessage];
                                  
                              }];
    [view addAction:copy];
    
    if(!canForward){
        UIAlertAction* mark = [UIAlertAction
                                  actionWithTitle:NSLocalizedString(@"Mark as read", nil)
                                  style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * action)
                                  {
                                      /*
                                      if (!(currentMessage.flags & mfNew)) {
                                          [UIApplication sharedApplication].applicationIconBadgeNumber++;
                                      }else{
                                          [UIApplication sharedApplication].applicationIconBadgeNumber--;
                                      }
                                       */
                                      __strong __typeof__(self) strongSelf = weakSelf;
                                      [[[GlobalRouter sharedManager] getListRouter].manager markAsRead:strongSelf->currentMessage];
                                      strongSelf->currentMessage.flags ^= mfNew;
                                      if (strongSelf->currentMessage.flags & mfNew) {
                                          // we set the flag
                                          [GlobalRouter sharedManager].newMessages++;
                                          [GlobalRouter sharedManager].newMessagesTotal++;
                                      }else{
                                          [GlobalRouter sharedManager].newMessages--;
                                          [GlobalRouter sharedManager].newMessagesTotal--;
                                      }
                                      [[GlobalRouter sharedManager] updateCurrentList];
                                      
                                  }];
        [view addAction:mark];
    }
    
#pragma warn "SAVE SECURE TO DO"
    if([currentMessage isKindOfClass:[FullMessageEntity class]]){
        UIAlertAction* saveToSecure = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Save text to secure notes", nil)
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action)
                                       {
                                           __strong __typeof__(self) strongSelf = weakSelf;
                                           [strongSelf wantSaveToNotes:strongSelf->currentMessage];
                                           
                                       }];
        [view addAction:saveToSecure];
    }
    
    UIAlertAction* info = [UIAlertAction
                           actionWithTitle:NSLocalizedString(@"Message info...", nil)
                           style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action)
                           {
                               __strong __typeof__(self) strongSelf = weakSelf;
                               [strongSelf wantMessageInfo:strongSelf->currentMessage];
                               
                           }];
    [view addAction:info];
    
    if (currentMessage.encType == enTypeOTC) {
        UIAlertAction* expire = [UIAlertAction
                               actionWithTitle:NSLocalizedString(@"Expire OTC now", nil)
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action)
                               {
                                   __strong __typeof__(self) strongSelf = weakSelf;
                                   [strongSelf wantExpireCert:strongSelf->currentMessage];
                                   
                               }];
        [view addAction:expire];
    }
    
    if([currentMessage isKindOfClass:[FullMessageEntity class]]){
        UIAlertAction* reEncrypt = [UIAlertAction
                                       actionWithTitle:NSLocalizedString(@"Encrypt message on a server...", nil)
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action)
                                       {
                                           __strong __typeof__(self) strongSelf = weakSelf;
                                           [strongSelf wantReEncrypt:strongSelf->currentMessage];
                                           
                                       }];
        [view addAction:reEncrypt];
    }
    
    if([currentMessage isKindOfClass:[FullMessageEntity class]]){
        UIAlertAction* switchView = [UIAlertAction
                                    actionWithTitle:NSLocalizedString(@"HTML-Text view", nil)
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action)
                                    {
                                        __strong __typeof__(self) strongSelf = weakSelf;
                                        [strongSelf wantSwitchView:strongSelf->currentMessage];
                                        
                                    }];
        [view addAction:switchView];
    }
    
    if([UIPrintInteractionController isPrintingAvailable] && [currentMessage isKindOfClass:[FullMessageEntity class]]){
        UIAlertAction* printIt = [UIAlertAction
                                    actionWithTitle:NSLocalizedString(@"Print...", nil)
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action)
                                    {
                                        __strong __typeof__(self) strongSelf = weakSelf;
                                        [strongSelf wantToPrint:strongSelf->currentMessage fromRect:rect inView:viewS];
                                        
                                    }];
        [view addAction:printIt];
    }
    
    //UIViewController* temp = [[[UIApplication sharedApplication] delegate] window].rootViewController;
    view.popoverPresentationController.sourceView = viewS;
    view.popoverPresentationController.sourceRect = rect;// viewS.bounds;
    [vcS presentViewController:view animated:YES completion:nil];
    
    //==============
}

/*
- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Who knows cancel button index?
    if (buttonIndex == -1) {
        return;
    }
    NSString* buttonPressed = [popup buttonTitleAtIndex:buttonIndex];
    if ([buttonPressed isEqualToString:NSLocalizedString(@"Cancel",nil)]) {
        return;
    }
    
    if(popup.tag == 202){
        if ([buttonPressed isEqualToString:NSLocalizedString(@"Forward",nil)]) {
            [self wantForwardMessage:currentMessage];
            
        }else if([buttonPressed isEqualToString:NSLocalizedString(@"Move to folder",nil)]){
            [self wantMoveMessage:currentMessage];
            
        }else if([buttonPressed isEqualToString:NSLocalizedString(@"Copy to folder",nil)]){
            [self wantCopyMessage:currentMessage];
            
        }else if([buttonPressed isEqualToString:NSLocalizedString(@"Reset all",nil)]){
            //[self search:nil];
        }else if([buttonPressed isEqualToString:NSLocalizedString(@"Mark as read",nil)]){
            [[[GlobalRouter sharedManager] getListRouter].manager markAsRead:currentMessage];
            currentMessage.flags ^= mfNew;
            [[GlobalRouter sharedManager] updateCurrentList];
        }
    }
}
*/

-(void)itemSelected:(NSString*)itemPath title:(NSString*)title
{
    //NSLog(@"Moving to %@ (%@)", title, itemPath);
    if(isMoving){
        [[[GlobalRouter sharedManager] getMessageRouter] wantMoveMessage:currentMessage to:itemPath];
    }else{
        [[[GlobalRouter sharedManager] getMessageRouter] wantCopyMessage:currentMessage to:itemPath];
    }
}

// TODO:
-(void)wantToPrint:(FullMessageEntity*)message fromRect:(CGRect)rect inView:(UIView*)inView
{
    [[[GlobalRouter sharedManager] getMessageRouter].interactor printHTMLContent:message fromRect:rect inView:inView];
    
    /*
    UIPrintInteractionController *pc = [UIPrintInteractionController
                                        sharedPrintController];
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.orientation = UIPrintInfoOrientationPortrait;
    printInfo.jobName =@"Message";

    pc.printInfo = printInfo;
    pc.showsPageRange = YES;
    
    // Use MCOMessageRenderer and html presentation to print?
    
    pc.printingItem = [NSData dataWithContentsOfURL:[NSURL URLWithString:@"https://test.com/Print_for_Client_Name.pdf"]];

    UIPrintInteractionCompletionHandler completionHandler =
    ^(UIPrintInteractionController *printController, BOOL completed,
      NSError *error) {
        if(!completed && error){
            NSLog(@"Print failed - domain: %@ error code %ld", error.domain,
                  (long)error.code);
        }
    };


    [pc presentFromRect:CGRectMake(0, 0, 300, 300) inView:[[GlobalRouter sharedManager] getDetailNavController].view animated:YES completionHandler:completionHandler];
     */
}

-(void)moveToSpam
{
    NSString* accountName = [[GlobalRouter sharedManager].accountsNames valueForKey:currentMessage.toAddress];
    NSArray* alll = [[[GlobalRouter sharedManager].otherFolders objectForKey:accountName] allKeys];
    NSString* spamPath = nil;
    for (NSString* key in alll) {
        FolderInfo* fi = (FolderInfo*)([[[GlobalRouter sharedManager].otherFolders objectForKey:accountName] valueForKey:key]);
        if (fi.folderType == btSpam) {
            spamPath = fi.folderPath;
            break;
        }
    }
    if(spamPath)
        [[[GlobalRouter sharedManager] getMessageRouter] wantMoveMessage:currentMessage to:spamPath];
}

-(void)askWhereToPutItem:(FullMessageEntity*)item
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SelectStoryboard" bundle: nil];
    SelectFolderViewController* sFolder = [storyboard instantiateViewControllerWithIdentifier:@"FolderSelect"];
    if(item.toAddress != nil){
        sFolder.accountName = [[GlobalRouter sharedManager].accountsNames valueForKey:item.toAddress];
        sFolder.parent = self;
        //sFolder.items = [[[GlobalRouter sharedManager].otherFolders valueForKey:sFolder.accountName] allKeys];
        sFolder.items = [[[GlobalRouter sharedManager].otherFolders objectForKey:sFolder.accountName] allKeys];
        [[[GlobalRouter sharedManager] getDetailNavController] pushViewController:sFolder animated:YES];
    }
}

-(void)wantForwardMessage:(FullMessageEntity*)item
{
    [[[GlobalRouter sharedManager] getMessageRouter] wantForwardMessage:item];
}

-(void)wantMoveMessage:(FullMessageEntity *)item
{
    // Ask where
    isMoving = YES;
    [self askWhereToPutItem:item];
}

-(void)wantCopyMessage:(FullMessageEntity *)item
{
    isMoving = NO;
    [self askWhereToPutItem:item];
    
}

-(void)wantMessageInfo:(FullMessageEntity *)item
{
    // currentMessage (item) = ShortMessageEntity, request the header from
    // the DataManager and display it
    [CommonProcs showSmallWheelinView:[[GlobalRouter sharedManager] getCurrentView]];
    [CommonProcs setSWLabelText:NSLocalizedString(@"Loading...", nil)];
    
    [[[GlobalRouter sharedManager] getListRouter].manager readFullHeaderForMessage:item];
}

-(void)wantSaveToNotes:(FullMessageEntity*)item
{
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    BOOL ret = [dataMan saveMessageToNotes:item pin:[GlobalRouter sharedManager].pin];
    if (ret) {
        [CommonProcs showMessage:@"Message saved" title:@"Success"];
    }else{
        [CommonProcs showMessage:@"Message not saved" title:@"Error"];
    }
}

-(void)wantExpireCert:(FullMessageEntity*)item
{
#if !LITE
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:NSLocalizedString(@"Are you sure?",nil)
                                 message:NSLocalizedString(@"The certificate will be wiped out and the message will be inaccessible any more",nil)
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* expireIt = [UIAlertAction
                              actionWithTitle:NSLocalizedString(@"Yes", nil)
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
                                  UserInfoDataManager* manager = [[UserInfoDataManager alloc] init];
                                  [manager deleteCertWithID:item.keyID from:item.fromAddress];
                              }];
    [alert addAction:expireIt];
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"Cancel",nil)
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 
                             }];
    [alert addAction:cancel];
    
    UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
    alert.popoverPresentationController.sourceView = pView;
    alert.popoverPresentationController.sourceRect = pView.frame;
    [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
#endif
}

-(void)wantReEncrypt:(FullMessageEntity*)item
{
    [[[GlobalRouter sharedManager] getMessageRouter] wantReEncryptMessage:item];
}

-(void)wantSwitchView:(FullMessageEntity*)item
{
    [[[[GlobalRouter sharedManager] getMessageRouter] getPresenter] switchView];
}

//////////////////////
// Code to detect main thread lags

+(void)startPing
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    while (!NSThread.currentThread.isCancelled) {
        static bool pingTaskIsRunning;
        pingTaskIsRunning = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            pingTaskIsRunning = NO;
            dispatch_semaphore_signal(semaphore);
        });
        [NSThread sleepForTimeInterval:0.4]; 
        if (pingTaskIsRunning) {
            // Notification about lock
            NSLog(@"Main thread is blocked");
        }
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        [NSThread sleepForTimeInterval:0.1];
    }
}

+(NSTextCheckingResult*)isEmailValid:(NSString *)email
{
    NSError* error;
    NSRegularExpression* regex = [[NSRegularExpression alloc] initWithPattern:@"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,16}$" options:NSRegularExpressionCaseInsensitive error:&error];
    return [regex firstMatchInString:email options:0 range:NSMakeRange(0, [email length])];
}

+(NSDate*)dateFromString:(NSString*)string
{
    NSDate* ret = nil;
    NSError *error = NULL;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeDate error:&error];
    
    NSArray *matches = [detector matchesInString:string
                                         options:0
                                           range:NSMakeRange(0, [string length])];
#if DEBUG
    NSLocale* currentLoc = [NSLocale currentLocale];
#endif
    for (NSTextCheckingResult *match in matches) {
        if ([match resultType] == NSTextCheckingTypeDate) {
#if DEBUG
            NSLog(@"Date: %@, dates-%lu", [[match date] descriptionWithLocale:currentLoc], (unsigned long)matches.count);
#endif
            ret = [match date];
            if(match.duration > 0){
                // Second date
#if DEBUG
                NSDateInterval* tin = [[NSDateInterval alloc] initWithStartDate:ret duration:match.duration];
                NSLog(@"Date 2: %@", [[tin endDate] descriptionWithLocale:currentLoc]);
#endif
            }
            break; // Only one date...
        }
    }
    
    return ret;
}

+(NSArray*)datesFromString:(NSString*)string
{
    NSMutableArray* ret = [[NSMutableArray alloc] init];
    NSError *error = NULL;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:(NSTextCheckingTypes)NSTextCheckingTypeDate error:&error];
    
    NSArray *matches = [detector matchesInString:string
                                         options:0
                                           range:NSMakeRange(0, [string length])];
    
    //NSLocale* currentLoc = [NSLocale currentLocale];
    if (matches.count >= 2) {
        [ret addObject:[(NSTextCheckingResult *)matches[0] date]];
        [ret addObject:[(NSTextCheckingResult *)matches[1] date]];
    }else if(matches.count == 1){
        [ret addObject:[(NSTextCheckingResult *)matches[0] date]];
        if(((NSTextCheckingResult *)matches[0]).duration > 0){
            // Second date
            NSDateInterval* tin = [[NSDateInterval alloc] initWithStartDate:((NSTextCheckingResult *)matches[0]).date duration:((NSTextCheckingResult *)matches[0]).duration];
            [ret addObject:tin.endDate];
        }
    }else{
        return nil;
    }
    
    return [NSArray arrayWithArray:ret];
}

+(long)longFromString:(NSString*)string
{
    // Input format:
    // - xxxxx
    // - xxxK or xxxKb
    // - xxxM or xxxMb
    // - xxxG or xxxGb
    long ret = 0;
    
    if (string.intValue) {
        ret = string.intValue;
    }
    NSRange found = [string rangeOfString:@"K" options:NSCaseInsensitiveSearch];
    if (found.location != NSNotFound) {
        NSString* val = [string substringToIndex:found.location];
        ret = val.intValue * 1024;
    }else{
        found = [string rangeOfString:@"M" options:NSCaseInsensitiveSearch];
        if (found.location != NSNotFound) {
            NSString* val = [string substringToIndex:found.location];
            ret = val.intValue * 1024 * 1024;
        }else{
            found = [string rangeOfString:@"G" options:NSCaseInsensitiveSearch];
            if (found.location != NSNotFound) {
                NSString* val = [string substringToIndex:found.location];
                ret = (long)(val.longLongValue * 1024 * 1024 * 1024);
            }
        }
    }
    
    return ret;
}

static ThumbnailGenerator* pv; // didfinishnavigation not called
+(UIImage*)getThumbnailFromURL:(NSURL*)url delegate:(id)delegate
{
    dispatch_semaphore_t thSem = dispatch_semaphore_create(0);
    __block UIImage* thumb;
    //BOOL noWaitWithoutDelegate = NO;
    
    NSString* ext = [[url pathExtension] lowercaseString];
    if ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"png"] || [ext isEqualToString:@"jpeg"] || [ext isEqualToString:@"gif"] || [ext isEqualToString:@"tiff"] || [ext isEqualToString:@"tif"] || [ext isEqualToString:@"bmp"] || [ext isEqualToString:@"bmpf"] || [ext isEqualToString:@"ico"] || [ext isEqualToString:@"cur"] || [ext isEqualToString:@"xbm"]) {
        // image
        
        thumb = [CommonProcs thumbnailViewFromPath:url.path].image;
        if (!thumb) {
            thumb = [CommonProcs thumbnailViewFromPath:url.path].image;
        }else{
            thumb = [CommonProcs sizeAndTypeOnThumbForPath:url.path thumbnail:thumb];
        }
        if(delegate){
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [(DocsViewController*)delegate thumbReady:thumb];
                //[CommonProcs hideBusy];
            });
        }else{
            dispatch_semaphore_signal(thSem);
        }
    }else if([ext isEqualToString:@"pdf"]){
        thumb = [CommonProcs screenshotPDF:url];
        if (!thumb) {
            thumb = [UIImage imageNamed:@"docIcon"];
        }
        thumb = [CommonProcs sizeAndTypeOnThumbForPath:url.path thumbnail:thumb];
        if(delegate){
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [(DocsViewController*)delegate thumbReady:thumb];
            });
        }else{
            dispatch_semaphore_signal(thSem);
        }
    }else if([ext isEqualToString:@"mov"] || [ext isEqualToString:@"mp4"] || [ext isEqualToString:@"avi"] || [ext isEqualToString:@"mpeg"]){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            thumb = [CommonProcs screenshotFromVideo:url]; //[UIImage imageNamed:@"docIcon"];
            if (!thumb) {
                thumb = [UIImage imageNamed:@"docIcon"];
            }
            thumb = [CommonProcs sizeAndTypeOnThumbForPath:url.path thumbnail:thumb];
            if(delegate){
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                        [(DocsViewController*)delegate thumbReady:thumb];
                });
            }else{
                dispatch_semaphore_signal(thSem);
            }
        });
    }else{
        // There might be a bug - loaded notification is not called. Need to
        // set some timer to cancel it.
        if (!delegate) {// There're some threading ussues, need to go for a delegete scheme
            //noWaitWithoutDelegate = YES;
            thumb = [UIImage imageNamed:@"docIcon"];
            thumb = [CommonProcs sizeAndTypeOnThumbForPath:url.path thumbnail:thumb];
            dispatch_semaphore_signal(thSem);
        }else{
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            pv = [[ThumbnailGenerator alloc] initWithURL:url delegate:delegate];
            [((DocsViewController*)delegate).view addSubview:pv];
            [pv loadRequest:[NSURLRequest requestWithURL:url]];
            
            // Potential error here... FIXED?
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if(!pv.thumb && pv.url == url){
                    [pv stopLoading];
                    thumb = [UIImage imageNamed:@"docIcon"];
                    thumb = [CommonProcs sizeAndTypeOnThumbForPath:url.path thumbnail:thumb];
                    if(delegate){
                        [(DocsViewController*)delegate thumbReady:thumb];
                    }else{
                        dispatch_semaphore_signal(thSem);
                    }
                }
            });
        //});
        }
    }
    
    if(!delegate){
        long iii = dispatch_semaphore_wait(thSem, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(36 * NSEC_PER_SEC)));
        if (iii != 0) {
            NSLog(@"Timeout!");
        }
        return thumb;
    }else{
        return nil;
    }
}

+(UIImage*)screenshotPDF:(NSURL*)url
{
    CGPDFDocumentRef pdf = CGPDFDocumentCreateWithURL((CFURLRef)url);
    CGPDFPageRef page;
    
    CGRect aRect = CGRectMake(0, 0, 80, 80); // thumbnail size
    UIGraphicsBeginImageContext(aRect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIImage* thumbnailImage;
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0.0, aRect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextSetGrayFillColor(context, 1.0, 1.0);
    CGContextFillRect(context, aRect);
    
    
    // Grab the first PDF page
    page = CGPDFDocumentGetPage(pdf,1);
    CGAffineTransform pdfTransform = CGPDFPageGetDrawingTransform(page, kCGPDFMediaBox, aRect, 0, true);
    // And apply the transform.
    CGContextConcatCTM(context, pdfTransform);
    
    CGContextDrawPDFPage(context, page);
    
    // Create the new UIImage from the context
    thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();

    CGContextRestoreGState(context);
    
    UIGraphicsEndImageContext();
    CGPDFDocumentRelease(pdf);
    
    return thumbnailImage;
}

+(UIImage*)screenshot:(UIView*)theView
{
    //UIView* snap = [theView snapshotViewAfterScreenUpdates:YES];
    //[pv removeFromSuperview];
    //pv = nil;
    
    //[snap setFrame:CGRectMake(0,40, 240, 320)];
    //[[[GlobalRouter sharedManager] getRootVC].view addSubview:snap];
    UIGraphicsBeginImageContextWithOptions(theView.bounds.size,NO,0.0);
    [theView.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    //[theView drawViewHierarchyInRect:theView.bounds afterScreenUpdates:YES];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [pv removeFromSuperview];
    pv = nil;
    //UIImage *scaledImage = [UIImage imageWithCGImage:[img CGImage] scale:(img.scale * 0.25) orientation:(img.imageOrientation)];
    return img;//scaledImage; //img;
}

+(UIImage*)screenshotFromVideo:(NSURL*)url
{
    AVAsset *asset = [AVAsset assetWithURL:url];
    AVAssetImageGenerator *imageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    CMTime time = [asset duration];
    time.value = 0;
    CGImageRef imageRef = [imageGenerator copyCGImageAtTime:time actualTime:NULL error:NULL];
    UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return thumbnail;
}

/*
 +(UIImage*)screenshot:(UIView*)theView
 {
 UIGraphicsBeginImageContextWithOptions(theView.bounds.size,NO,0.0);
 //[theView.layer renderInContext:UIGraphicsGetCurrentContext()];
 UIView* snap = [theView snapshotViewAfterScreenUpdates:NO];
 
 [snap drawViewHierarchyInRect:CGRectMake(0, 0, theView.bounds.size.width+0, theView.bounds.size.height+0) afterScreenUpdates:YES];
 UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
 UIGraphicsEndImageContext();
 
 [pv.view removeFromSuperview];
 pv = nil;
 UIImage *scaledImage = [UIImage imageWithCGImage:[img CGImage] scale:(img.scale * 0.25) orientation:(img.imageOrientation)];
 return scaledImage; //img;
 }
 */

+(void)showVanishingMessage:(NSString*)message inView:(UIView*)inView inRect:(CGRect)inRect timeToShow:(int)timeToShow
{
    UILabel *label = [[UILabel alloc] initWithFrame:inRect];
    label.text = message;
    label.textAlignment = NSTextAlignmentCenter;
    [[label layer] setCornerRadius:5.0f];
    [[label layer] setMasksToBounds:YES];
    [[label layer] setBorderWidth:1.0f];
    if (@available(iOS 13.0, *)) {
        [[label layer] setBorderColor:[UIColor labelColor].CGColor];
        label.backgroundColor = [UIColor secondarySystemBackgroundColor];
        label.textColor = [UIColor labelColor];
    } else {
        // Fallback on earlier versions
        [[label layer] setBorderColor:[UIColor blackColor].CGColor];
        label.backgroundColor = [UIColor groupTableViewBackgroundColor];
        label.textColor = [UIColor blackColor];
    }
    [label setFont:[UIFont systemFontOfSize:12]];
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.5;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(labelTapped:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    [label addGestureRecognizer:tapGestureRecognizer];
    label.userInteractionEnabled = YES;
    
    if ([message isEqualToString:NSLocalizedString(@"Error", nil)]) {
        label.textColor = [UIColor redColor];
    }
    CGSize neededSize = [label sizeThatFits:CGSizeMake(inRect.size.width, CGFLOAT_MAX)];
    //[label setFrame:CGRectMake(inRect.origin.x, inRect.origin.y+lastY, inRect.size.width, neededSize.height+4)];
    [label setFrame:CGRectMake(inRect.origin.x+inRect.size.width/2, inRect.origin.y+lastY, inRect.size.width, 0)];
    
    [inView addSubview:label];
    [UIView animateWithDuration:0.2f delay:0 options:0
                    animations:^{
                        [label setFrame:CGRectMake(inRect.origin.x, inRect.origin.y+lastY, inRect.size.width, neededSize.height+4)];
                    }
                     completion:nil];
     
    numberOfVanishingMessages++;
    lastY += neededSize.height+4-1; // -1 is for the frame
    
    // This is better since the gesture recognized is working
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeToShow * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @synchronized (label) {
            [UIView animateWithDuration:0.4f delay:0 options:0
            animations:^{
                label.alpha = 0.0;
            }
            completion:^(BOOL finished){
                if([label isDescendantOfView:inView]){
                    [label removeFromSuperview];
                    numberOfVanishingMessages--;
                    if (numberOfVanishingMessages <= 0) {
                        lastY = 0;
                    }
                }
            }];
        }
    });
    
    /*
    [UIView animateWithDuration:0.4f delay:timeToShow options:0
                     animations:^{
                         label.alpha = 0.0;
                     }
                     completion:^(BOOL finished){
                         [label removeFromSuperview];
                         numberOfVanishingMessages--;
                         //lastY -= label.frame.size.height+1;
                        if (numberOfVanishingMessages == 0) {
                            lastY = 0;
                        }
                     }];*/
}

+(void)labelTapped:(UITapGestureRecognizer*)sender
{
    //NSLog(@"Label tapped");
    @synchronized (sender.view) {
        [sender.view removeFromSuperview];
        numberOfVanishingMessages--;
        if (numberOfVanishingMessages <= 0) {
            lastY = 0;
        }
    }
}

static int numberOfVanishingMessages = 0;
static int lastY = 0;
+(void)showVanishingMessage:(NSString*)message
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    
    [CommonProcs showVanishingMessage:message inView:[[GlobalRouter sharedManager] getCurrentView] inRect:CGRectMake(40, 100, screenWidth-80, 30) timeToShow:3];
}

+(void)showVanishingErrorMessage:(NSString*)message
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    if (numberOfVanishingMessages == 0) {
        [CommonProcs showVanishingMessage:NSLocalizedString(@"Error", nil) inView:[[GlobalRouter sharedManager] getCurrentView] inRect:CGRectMake(40, 100, screenWidth-80, 30) timeToShow:3];
    }
    
    [CommonProcs showVanishingMessage:message inView:[[GlobalRouter sharedManager] getCurrentView] inRect:CGRectMake(40, 100, screenWidth-80, 30) timeToShow:3];
}

+(BOOL)checkBioIDAvailable
{
    LAContext* context = [[LAContext alloc] init];
    NSError* error;
    [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error];
    
    return error == nil;
}

// Secure wipe a string
+(void)SafeMemset:(void*)v  :(int)c :(size_t)n
{
    //volatile in this case announces that the value might changed behind our back so prevents the compiler from caching it in a CPU register.
    @try {
        volatile char *p = (volatile char *)v;
        while (n--)
        {
            *p++ = (char)c;
        }
#if DEBUG
        NSLog(@"Wiped!");
#endif
    } @catch (NSException *exception) {
#if DEBUG
        NSLog(@"SafeMemset Error %@", exception.description);
#endif
    }
    //return v;
}

// That works with NSMutableStrings only, with a simple NSString it gets a bad_access error
+(void)wipeString:(NSString*)string
{
    if(!string)return;
    //NSLog(@"Trying to wipe %@", string);
    
    unsigned char *keyStringChars = (unsigned char*)CFStringGetCStringPtr((CFStringRef)string, CFStringGetSystemEncoding());// CFStringGetFastestEncoding((__bridge CFStringRef)string));
    if(keyStringChars){
        [CommonProcs SafeMemset:keyStringChars :0 :[string length]];
        //[CommonProcs SafeMemset:/*keyStringChars*/(__bridge void *)(&(*string))+17 :0 :[string length]];
    }else{
#if DEBUG
        NSLog(@"Wiping string conversion error");
#endif
    }
}

+(void)wipeData:(NSData*)data
{
    [CommonProcs SafeMemset:(void *)[data bytes] :0 :[data length]];
}


+(void)saveToKeychainAlways:(NSString*)toSave account:(NSString*)account service:(NSString*)service
{
    //NSLog(@"Write to keychain %@", account);
    // First delete the key
    NSMutableDictionary *returnDictionary0 = [[NSMutableDictionary alloc] init];
    
    [returnDictionary0 setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [returnDictionary0 setObject:service forKey:(__bridge id)kSecAttrService];
    [returnDictionary0 setObject:account forKey:(__bridge id)kSecAttrAccount];
    //[returnDictionary0 setObject:(__bridge id)kSecAttrAccessibleAfterFirstUnlock forKey:(__bridge id)kSecAttrAccessible];
    OSStatus err0 = SecItemDelete((__bridge CFDictionaryRef)returnDictionary0);
    if(err0 != errSecSuccess) {
        //We check the error code
        NSLog(@"Delete error %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:err0 userInfo:nil].localizedDescription);
    }
    
    NSMutableDictionary *returnDictionary = [[NSMutableDictionary alloc] init];
    [returnDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [returnDictionary setObject:[toSave dataUsingEncoding:NSUTF8StringEncoding]
                         forKey:(__bridge id)kSecValueData];
    [returnDictionary setObject:service forKey:(__bridge id)kSecAttrService];
    [returnDictionary setObject:account forKey:(__bridge id)kSecAttrAccount];
    [returnDictionary setObject:(__bridge id)kSecAttrAccessibleAfterFirstUnlock forKey:(__bridge id)kSecAttrAccessible];
    OSStatus err = SecItemAdd((__bridge CFDictionaryRef)returnDictionary, nil);
    //let status = SecItemAdd(query, nil)
    if(err != errSecSuccess) {
        //We check the error code
        NSLog(@"%@", [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil].localizedDescription);
    }
}

+(NSString*)getStringFromKeychain:(NSString*)account service:(NSString*)service
{
    //NSLog(@"Read from keychain %@", account);
    //NSLog(@"Protected data available = %@", [UIApplication sharedApplication].isProtectedDataAvailable?@"YES":@"NO");
    __block NSString* ret;
    NSMutableDictionary *returnDictionary00 = [[NSMutableDictionary alloc] init];
    [returnDictionary00 setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [returnDictionary00 setObject:service forKey:(__bridge id)kSecAttrService];
    [returnDictionary00 setObject:account forKey:(__bridge id)kSecAttrAccount];
    [returnDictionary00 setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnData];
    [returnDictionary00 setObject:(__bridge id)kSecAttrAccessibleAfterFirstUnlock forKey:(__bridge id)kSecAttrAccessible];
    
    CFDataRef passwordData = NULL;
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus err00 = SecItemCopyMatching((__bridge CFDictionaryRef)returnDictionary00, (CFTypeRef *)&passwordData);
        if(err00 == errSecSuccess) {
            NSData* pd = (__bridge NSData*)passwordData;
            ret = [[NSString alloc] initWithData:pd encoding:NSUTF8StringEncoding];
        }else if(err00 == errSecItemNotFound){
            //ret = @"0";
        }else{
            NSLog(@"Keychain Error %i", (int)err00);
        }
    //});
    return ret;
    
}

// for the vpn password
+(CFDataRef)getPersistentDataFromKeychain:(NSString*)account service:(NSString*)service
{
    //NSLog(@"Read from keychain %@", account);
    //NSLog(@"Protected data available = %@", [UIApplication sharedApplication].isProtectedDataAvailable?@"YES":@"NO");
    __block CFDataRef ret = nil;
    NSMutableDictionary *returnDictionary00 = [[NSMutableDictionary alloc] init];
    [returnDictionary00 setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [returnDictionary00 setObject:service forKey:(__bridge id)kSecAttrService];
    [returnDictionary00 setObject:account forKey:(__bridge id)kSecAttrAccount];
    //[returnDictionary00 setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnData];
    [returnDictionary00 setObject:(__bridge id)kSecAttrAccessibleAfterFirstUnlock forKey:(__bridge id)kSecAttrAccessible];
    [returnDictionary00 setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnPersistentRef];
    
    CFDataRef passwordData = NULL;
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSStatus err00 = SecItemCopyMatching((__bridge CFDictionaryRef)returnDictionary00, (CFTypeRef *)&passwordData);
        if(err00 == errSecSuccess) {
            ret = passwordData;
        }else if(err00 == errSecItemNotFound){
            //ret = @"0";
            NSLog(@"Item not found");
        }else{
            NSLog(@"Keychain Error %i", (int)err00);
        }
    //});
    return ret;
}

/*
+(void)initPrefs
{
    static NSMutableDictionary* prefs;
    prefs = [[NSMutableDictionary alloc] initWithContentsOfFile: @"prefs.plist"];
}
*/

@end
