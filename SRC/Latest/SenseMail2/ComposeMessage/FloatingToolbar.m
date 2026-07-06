//
//  FloatingToolbar.m
//  SenseMailShare
//
//  Created by Sergey on 07.05.2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

#import "FloatingToolbar.h"

@implementation FloatingToolbar

-(id)init
{
    if (self = [super init]) {
        
        /*
        tbH = [[GlobalRouter sharedManager] getDetailNavController].toolbar.frame.size.height + 60;
        if (@available(iOS 11.0, *)) {
            UIWindow *window = UIApplication.sharedApplication.keyWindow;
            tbH += window.safeAreaInsets.bottom;
        }
        if (tbH == 0) {
            tbH = 100;
        }
        button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button addTarget:self action:@selector(restoreVC:) forControlEvents:UIControlEventTouchUpInside];
        [button setImage:[UIImage imageNamed:@"writeMail"] forState:UIControlStateNormal];
        UIViewController* rootVC = [[GlobalRouter sharedManager] getRootVC];
        button.frame = CGRectMake(rootVC.view.frame.size.width-75, rootVC.view.frame.size.height-tbH, 60.0, 60.0);
        [rootVC.view addSubview:button];
        button.tag = 888888;
        button.hidden = YES;
        
        button.translatesAutoresizingMaskIntoConstraints = false;
        
        // Ancors are available since iOS 9, but anyway we are aiming at iOS 9 at least
        if(@available(iOS 9,*)){
            [button.widthAnchor constraintEqualToConstant:60].active = YES;
            [button.heightAnchor constraintEqualToConstant:60].active = YES;
            [button.rightAnchor constraintEqualToAnchor:rootVC.view.rightAnchor constant:-15].active = YES;
            [button.topAnchor constraintEqualToAnchor:rootVC.view.bottomAnchor constant:-tbH].active = YES;
        }
         */
    }
    
    colors = @[@"red", @"green", @"blue", @"yellow"];
    colorValues = @[[UIColor redColor], [UIColor greenColor], [UIColor blueColor], [UIColor yellowColor]];
    currentColorIndex = 0;
    
    return self;
}

-(void)addToolbarToView:(UIView*)toView withWebView:(WKWebView*)wkView topOffset:(float)topOffset
{
#define bSp 6
    
    float buttonW = 28;
    if ([UIScreen mainScreen].bounds.size.width == 320) {
        buttonW = 24;
    }
    /*
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        int scrht = (int)[[UIScreen mainScreen] nativeBounds].size.height;
        if (scrht > 1500) {
            // Make the toolbar larger
            buttonW = 32;
        }
    }*/
    
    self.wView = wkView;
    [self setFrame:CGRectMake(10, topOffset, (buttonW+bSp)*10, buttonW+2)];
    self.clipsToBounds = YES;
    if (@available(iOS 13.0, *)) {
        [self setBackgroundColor:[UIColor systemBackgroundColor]];
    } else {
        // No black theme, OK to go
    }
    
    [[self layer] setCornerRadius:3.0f];
    [[self layer] setMasksToBounds:YES];
    [[self layer] setBorderWidth:1.0f];
    [[self layer] setBorderColor:[UIColor lightGrayColor].CGColor];
    
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self action:@selector(closeBar:) forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[UIImage imageNamed:@"NO2"] forState:UIControlStateNormal];
    button.frame = CGRectMake(2, 4, buttonW-8, buttonW-8);
    //[button setBackgroundImage:[UIImage imageNamed:@"textButtonBg"] forState:UIControlStateNormal];
    [self addSubview:button];
    button.tag = 10001;
    //button.translatesAutoresizingMaskIntoConstraints = false;
    if(@available(iOS 9,*)){
        [button.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:4].active = YES;
    }
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    UIButton* buttonLeft = [UIButton buttonWithType: UIButtonTypeCustom];
    [buttonLeft addTarget:self action:@selector(setLeftAlign:) forControlEvents:UIControlEventTouchUpInside];
    [buttonLeft setImage:[UIImage imageNamed:@"leftAlign"] forState:UIControlStateNormal];
    buttonLeft.frame = CGRectMake(4+(buttonW+bSp)*1, 4, buttonW, buttonW);
    //[buttonLeft setBackgroundImage:[UIImage imageNamed:@"textButtonBg"] forState:UIControlStateNormal];
    [self addSubview:buttonLeft];
    buttonLeft.tag = 10002;
    buttonLeft.translatesAutoresizingMaskIntoConstraints = false;
    if(@available(iOS 9,*)){
        [buttonLeft.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:4+(buttonW+bSp)*1].active = YES;
        [buttonLeft.topAnchor constraintEqualToAnchor:self.topAnchor constant:4].active = YES;
    }
    buttonLeft.imageView.contentMode = UIViewContentModeCenter;
    
    UIButton* buttonCenter = [UIButton buttonWithType: UIButtonTypeCustom];
    [buttonCenter addTarget:self action:@selector(setCenterAlign:) forControlEvents:UIControlEventTouchUpInside];
    [buttonCenter setImage:[UIImage imageNamed:@"centerAlign"] forState:UIControlStateNormal];
    buttonCenter.frame = CGRectMake(4+(buttonW+bSp)*2, 4, buttonW, buttonW);
    //[buttonCenter setBackgroundImage:[UIImage imageNamed:@"textButtonBg"] forState:UIControlStateNormal];
    [self addSubview:buttonCenter];
    buttonCenter.tag = 10003;
    buttonCenter.translatesAutoresizingMaskIntoConstraints = false;
    if(@available(iOS 9,*)){
        [buttonCenter.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:4+(buttonW+bSp)*2].active = YES;
        [buttonCenter.topAnchor constraintEqualToAnchor:self.topAnchor constant:4].active = YES;
    }
    
    UIButton* buttonRight = [UIButton buttonWithType: UIButtonTypeCustom];
    [buttonRight addTarget:self action:@selector(setRightAlign:) forControlEvents:UIControlEventTouchUpInside];
    [buttonRight setImage:[UIImage imageNamed:@"rightAlign"] forState:UIControlStateNormal];
    buttonRight.frame = CGRectMake(4+(buttonW+bSp)*3, 4, buttonW, buttonW);
    //[buttonRight setBackgroundImage:[UIImage imageNamed:@"textButtonBg"] forState:UIControlStateNormal];
    [self addSubview:buttonRight];
    buttonRight.tag = 10004;
    buttonRight.translatesAutoresizingMaskIntoConstraints = false;
    if(@available(iOS 9,*)){
        [buttonRight.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:4+(buttonW+bSp)*3].active = YES;
        [buttonRight.topAnchor constraintEqualToAnchor:self.topAnchor constant:4].active = YES;
    }
    
    UIButton* buttonH1 = [UIButton buttonWithType: UIButtonTypeCustom];
    [buttonH1 addTarget:self action:@selector(setH1Style:) forControlEvents:UIControlEventTouchUpInside];
    [buttonH1 setImage:[UIImage imageNamed:@"textLarge"] forState:UIControlStateNormal];
    buttonH1.frame = CGRectMake(4+(buttonW+bSp)*4, 4, buttonW, buttonW);
    //[buttonH1 setBackgroundImage:[UIImage imageNamed:@"textButtonBg"] forState:UIControlStateNormal];
    [self addSubview:buttonH1];
    buttonH1.tag = 10005;
    buttonH1.translatesAutoresizingMaskIntoConstraints = false;
    if(@available(iOS 9,*)){
        [buttonH1.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:4+(buttonW+bSp)*4].active = YES;
        [buttonH1.topAnchor constraintEqualToAnchor:self.topAnchor constant:4].active = YES;
    }
    
    UIButton* buttonClear = [UIButton buttonWithType: UIButtonTypeCustom];
    [buttonClear addTarget:self action:@selector(removeFormat:) forControlEvents:UIControlEventTouchUpInside];
    [buttonClear setImage:[UIImage imageNamed:@"textClearFormat"] forState:UIControlStateNormal];
    buttonClear.frame = CGRectMake(4+(buttonW+bSp)*5, 2, buttonW-6, buttonW-6);
    //[buttonClear setBackgroundImage:[UIImage imageNamed:@"textButtonBg"] forState:UIControlStateNormal];
    [self addSubview:buttonClear];
    buttonClear.tag = 10006;
    buttonClear.translatesAutoresizingMaskIntoConstraints = false;
    if(@available(iOS 9,*)){
        [buttonClear.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:4+(buttonW+bSp)*5].active = YES;
        [buttonClear.topAnchor constraintEqualToAnchor:self.topAnchor constant:4].active = YES;
    }
    buttonClear.imageView.contentMode = UIViewContentModeCenter;
    
    UIButton* buttonSmall = [UIButton buttonWithType: UIButtonTypeCustom];
    [buttonSmall addTarget:self action:@selector(setSmallStyle:) forControlEvents:UIControlEventTouchUpInside];
    [buttonSmall setImage:[UIImage imageNamed:@"textSmall"] forState:UIControlStateNormal];
    buttonSmall.frame = CGRectMake(4+(buttonW+bSp)*6, 4, buttonW, buttonW);
    //[buttonSmall setBackgroundImage:[UIImage imageNamed:@"textButtonBg"] forState:UIControlStateNormal];
    [self addSubview:buttonSmall];
    buttonSmall.tag = 10007;
    buttonSmall.translatesAutoresizingMaskIntoConstraints = false;
    if(@available(iOS 9,*)){
        [buttonSmall.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:4+(buttonW+bSp)*6].active = YES;
        [buttonSmall.topAnchor constraintEqualToAnchor:self.topAnchor constant:4].active = YES;
    }
    
    UIButton* buttonRedFont = [UIButton buttonWithType: UIButtonTypeCustom];
    [buttonRedFont addTarget:self action:@selector(setRedFont:) forControlEvents:UIControlEventTouchUpInside];
    //UIImage *image = [[UIImage imageNamed:@"image_name"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [buttonRedFont setImage:[[UIImage imageNamed:@"textRed"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [buttonRedFont setTintColor:colorValues[currentColorIndex]];
    buttonRedFont.frame = CGRectMake(4+(buttonW+bSp)*7, 4, buttonW, buttonW);
    //[buttonRedFont setBackgroundImage:[UIImage imageNamed:@"textButtonBg"] forState:UIControlStateNormal];
    [self addSubview:buttonRedFont];
    buttonRedFont.tag = 10008;
    buttonRedFont.translatesAutoresizingMaskIntoConstraints = false;
    if(@available(iOS 9,*)){
        [buttonRedFont.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:4+(buttonW+bSp)*7].active = YES;
        [buttonRedFont.topAnchor constraintEqualToAnchor:self.topAnchor constant:4].active = YES;
    }
    
    UIButton* buttonRedBg = [UIButton buttonWithType: UIButtonTypeCustom];
    [buttonRedBg addTarget:self action:@selector(setRedBg:) forControlEvents:UIControlEventTouchUpInside];
    [buttonRedBg setImage:[[UIImage imageNamed:@"textRedBg"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [buttonRedBg setTintColor:colorValues[currentColorIndex]];
    buttonRedBg.frame = CGRectMake(4+(buttonW+bSp)*8, 4, buttonW, buttonW);
    //[buttonRedBg setBackgroundImage:[UIImage imageNamed:@"textButtonBg"] forState:UIControlStateNormal];
    [self addSubview:buttonRedBg];
    buttonRedBg.tag = 10009;
    buttonRedBg.translatesAutoresizingMaskIntoConstraints = false;
    if(@available(iOS 9,*)){
        [buttonRedBg.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:4+(buttonW+bSp)*8].active = YES;
        [buttonRedBg.topAnchor constraintEqualToAnchor:self.topAnchor constant:4].active = YES;
    }
    
    UIButton* buttonBgColor = [UIButton buttonWithType: UIButtonTypeCustom];
    [buttonBgColor addTarget:self action:@selector(setBgColor:) forControlEvents:UIControlEventTouchUpInside];
    [buttonBgColor setImage:[[UIImage imageNamed:@"textRotateColors"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [buttonBgColor setTintColor:colorValues[0]];
    buttonBgColor.frame = CGRectMake(4+(buttonW+bSp)*9, 4, buttonW, buttonW);
    //[buttonBgColor setBackgroundImage:[UIImage imageNamed:@"textButtonBg"] forState:UIControlStateNormal];
    [self addSubview:buttonBgColor];
    buttonBgColor.tag = 10010;
    buttonBgColor.translatesAutoresizingMaskIntoConstraints = false;
    if(@available(iOS 9,*)){
        [buttonBgColor.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:4+(buttonW+bSp)*9].active = YES;
        [buttonBgColor.topAnchor constraintEqualToAnchor:self.topAnchor constant:4].active = YES;
    }
    
    [toView addSubview:self];
}

-(void)closeBar:(id)sender
{
    //[self removeFromSuperview];
    self.hidden = YES;
}

-(void)setLeftAlign:(id)sender
{
    [self.wView evaluateJavaScript:@"document.execCommand('justifyLeft', false, 0)" completionHandler:^(id _Nullable html, NSError * _Nullable error) {
        //NSLog(@"Selected %@", html);
    }];
}

-(void)setCenterAlign:(id)sender
{
    [self.wView evaluateJavaScript:@"document.execCommand('justifyCenter', false, 0)" completionHandler:^(id _Nullable html, NSError * _Nullable error) {
        //NSLog(@"Selected %@", html);
    }];
}

-(void)setRightAlign:(id)sender
{
    [self.wView evaluateJavaScript:@"document.execCommand('justifyRight', false, 0)" completionHandler:^(id _Nullable html, NSError * _Nullable error) {
        //NSLog(@"Selected %@", html);
    }];
}

-(void)setH1Style:(id)sender
{
    [self.wView evaluateJavaScript:@"document.execCommand('fontSize', false, '5')" completionHandler:^(id _Nullable html, NSError * _Nullable error) {
        //NSLog(@"Selected %@", html);
    }];
}

-(void)setSmallStyle:(id)sender
{
    [self.wView evaluateJavaScript:@"document.execCommand('fontSize', false, '2')" completionHandler:^(id _Nullable html, NSError * _Nullable error) {
        //NSLog(@"Selected %@", html);
    }];
}

-(void)removeFormat:(id)sender
{
    [self.wView evaluateJavaScript:@"document.execCommand('removeFormat', false, 0)" completionHandler:^(id _Nullable html, NSError * _Nullable error) {
        //NSLog(@"Selected %@", html);
    }];
}

-(void)setRedFont:(id)sender
{
    NSString* command = [NSString stringWithFormat:@"document.execCommand('foreColor', false, '%@')",colors[currentColorIndex]];
    [self.wView evaluateJavaScript:command completionHandler:^(id _Nullable html, NSError * _Nullable error) {
        
    }];
    
    /*
    [self.wView evaluateJavaScript:@"document.execCommand('foreColor', false, 'red')" completionHandler:^(id _Nullable html, NSError * _Nullable error) {
        //NSLog(@"Selected %@", html);
    }];*/
}

-(void)setRedBg:(id)sender
{
    NSString* command = [NSString stringWithFormat:@"document.execCommand('backColor', false, '%@')",colors[currentColorIndex]];
    //[self.wView evaluateJavaScript:@"document.execCommand('backColor', false, 'red')"
    [self.wView evaluateJavaScript:command completionHandler:^(id _Nullable html, NSError * _Nullable error) {
        //NSLog(@"Selected %@", html);
    }];
}

-(void)setBgColor:(id)sender
{
    currentColorIndex++;
    currentColorIndex = currentColorIndex%(colorValues.count);
    
    [(UIButton*)sender setTintColor:colorValues[currentColorIndex]];
    
    UIButton* b1 = [self viewWithTag:10008];
    [b1 setTintColor:colorValues[currentColorIndex]];
    
    UIButton* b2 = [self viewWithTag:10009];
    [b2 setTintColor:colorValues[currentColorIndex]];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/


@end
