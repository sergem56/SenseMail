//
//  TapGeneratorViewController.m
//  SenseMailShare
//
//  Created by Sergey on 01.04.16.
//  Copyright © 2016 Sergey. All rights reserved.
//

#import "TapGeneratorViewController.h"
#import "GlobalRouter.h"

#define acceptedMinimum 100

@interface TapGeneratorViewController ()
{
    mach_timebase_info_data_t _clock_timebase;
    //uint64_t prevTime;
    int counter;
    //dispatch_semaphore_t sema;
}
@end

@implementation TapGeneratorViewController

static dispatch_semaphore_t sema;
static NSMutableData* retData;
static BOOL res;
static int bytesToCollect;

+(void)showTapDialog:(dispatch_semaphore_t)sem bytesToCollect:(int)btc
{
    /*
    sema = sem;
    retData = [[NSMutableData alloc] init];
    TapGeneratorViewController* viewController = [[TapGeneratorViewController alloc] initWithNibName:@"TapGeneratorViewController" bundle:nil];
    [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:viewController animated:YES completion:nil];
    bytesToCollect = btc;
    if (bytesToCollect == 0) {
        bytesToCollect = 32;
    }*/
    
    [self showTapDialogInNavController:[[GlobalRouter sharedManager] getDetailNavController] bytesToCollect:btc semaphore:sem];
}

static UINavigationController* navCtl;
+(void)showTapDialogInNavController:(UINavigationController*)nav bytesToCollect:(int)btc semaphore:(dispatch_semaphore_t)sem
{
    navCtl = nav;
    
    sema = sem;
    retData = [[NSMutableData alloc] init];
    TapGeneratorViewController* viewController = [[TapGeneratorViewController alloc] initWithNibName:@"TapGeneratorViewController" bundle:nil];
    //viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    //[nav presentViewController:viewController animated:YES completion:nil];
    [nav pushViewController:viewController animated:YES];
    bytesToCollect = btc;
    if (bytesToCollect == 0) {
        bytesToCollect = 32;
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    mach_timebase_info(&_clock_timebase);
    //prevTime = 0;
    counter = 0;
    
    //[self.progress ]
    [self.progress setProgress:0];
    
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.cancelsTouchesInView = YES;
    tap.numberOfTapsRequired = 1;
    tap.delegate = self;
    [self.tapArea addGestureRecognizer:tap];
    
    [[self.tapArea layer] setCornerRadius:8.0f];
    [[self.tapArea layer] setMasksToBounds:YES];
    [[self.tapArea layer] setBorderWidth:0.5f];
    [[self.tapArea layer] setBorderColor:[UIColor grayColor].CGColor];
    
    self.collectedData.text = @"";
    // Turn on Selectable in xib for the next line to work!!!
    self.collectedData.font = [UIFont fontWithName:@"Courier" size:9.0f];
    
    if (bytesToCollect == 3200){
        self.tapArea.text = NSLocalizedString(@"We are about to generate 100 certificates. We need lots of data - no less than 200 taps. The sane minimum number of taps is 700. The best is 3200.\nWe'll get the rest of data from the device's built-in secure RNG.",nil);
    }else{
        self.tapArea.text = NSLocalizedString(@"We are about to generate a certificate. We need to collect 256 bits of random data. Please, tap the screen at least 32 times.",nil);
    }
    
    self.navigationController.toolbarHidden = YES;
}

-(NSString*)getCrackTimeString:(int)byteCount
{
    NSString* ret = @"";
    
    //if (byteCount > 32) {
    //    byteCount = 32;
    //}
    
    int collected = byteCount/(bytesToCollect/32);
    
    if (collected <= 2) {
        ret = NSLocalizedString(@"instantly", nil);
    }else if (collected == 3){
        ret = NSLocalizedString(@"less than a minute", nil);
    }else if (collected == 4){
        ret = NSLocalizedString(@"about an hour", nil);
    }else if (collected == 5){
        ret = NSLocalizedString(@"10 days", nil);
    }else if (collected == 6){
        ret = NSLocalizedString(@"8 years", nil);
    }else if (collected == 7){
        ret = NSLocalizedString(@"2000 years", nil);
    }else if (collected == 8){
        ret = NSLocalizedString(@"500.000 years", nil);
    }else if (collected == 9){
        ret = NSLocalizedString(@"150 million years", nil);
    }else if (collected == 10 || collected == 11 || collected == 12){
        ret = NSLocalizedString(@"eons", nil);
    }else if (collected == 13 || collected == 14 || collected == 15 || collected == 16){
        ret = NSLocalizedString(@"eternity", nil);
    }else if (collected >= 17 && collected <= 27){
        ret = NSLocalizedString(@"never", nil);
    }else{
        ret = NSLocalizedString(@"never ever", nil);
    }
    
    /*
    switch (byteCount) {
        case 1:
        case 2:
            ret = NSLocalizedString(@"instantly", nil);
            break;
        case 3:
            ret = NSLocalizedString(@"less than a minute", nil);
            break;
        case 4:
            ret = NSLocalizedString(@"about an hour", nil);
            break;
        case 5:
            ret = NSLocalizedString(@"10 days", nil);
            break;
        case 6:
            ret = NSLocalizedString(@"8 years", nil);
            break;
        case 7:
            ret = NSLocalizedString(@"2000 years", nil);
            break;
        case 8:
            ret = NSLocalizedString(@"500.000 years", nil);
            break;
        case 9:
            ret = NSLocalizedString(@"150 million years", nil);
            break;
        case 10:
        case 11:
        case 12:
            ret = NSLocalizedString(@"eons", nil);
            break;
        case 13:
        case 14:
        case 15:
        case 16:
            ret = NSLocalizedString(@"eternity", nil);
            break;
        case 17:
        case 18:
        case 19:
        case 20:
        case 21:
        case 22:
        case 23:
        case 24:
            ret = NSLocalizedString(@"never", nil);
            break;
        default:
            ret = NSLocalizedString(@"never ever", nil);
            break;
    }
    */
    /*
    //double vars = pow(256,byteCount);
    const int guessesPerSecond = 100000000;
    long double days = (pow(256,byteCount)/guessesPerSecond)/86400.0;
    
    if (days < 365) {
        ret = [NSString stringWithFormat:@"Days to crack: %.2Lf",days];
    }else if(days < 365*1000){
        ret = [NSString stringWithFormat:@"Years to crack: %.0Lf",days/365];
    }else if(days < (double)365*1000*99000){
        ret = [NSString stringWithFormat:@"Millenia to crack: %.0Lf",days/365000];
    }else{
        ret = @"Time to crack: never";
    }
    */
    return [NSString stringWithFormat:NSLocalizedString(@"Time to crack: %@", nil), ret];
}

-(void) handleTap:(UIGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        CGPoint pt = [sender locationInView:nil];
        uint8_t dx = (((uint8_t)pt.x)%2)<<7;
        uint8_t dy = (((uint8_t)pt.y)%2)<<6;
        //dx = dx << dy;
        //NSLog(@"XY:%02X (%04X, %04X)", dx^dy, dx,dy);
        uint64_t machtime = mach_absolute_time(); // Got ticks?
        //NSLog(@"Tap time: %llx", machtime);
        //uint64_t nanos = (machtime * _clock_timebase.numer) / _clock_timebase.denom;
        //uint64_t diff = machtime - prevTime;
        //prevTime = machtime;
        uint8_t toUse = (uint8_t)(machtime&0xFF);//diff;
        //toUse ^= ((int)pt.x&0x7)+((int)pt.y&0x7);
        toUse ^= (dx^dy);
        if (counter == 0) {
            self.tapArea.text = @"";
        }
        if(counter < 10000){
            [retData appendBytes:&toUse length:1]; // Use just 1 byte to get it more random
            self.collectedData.text = [NSString stringWithFormat:@"%@%@%02X", self.collectedData.text,(counter>0)?@" ":@"", toUse];
            counter++;
            
            if(self.collectedData.text.length > 0 ) {
                NSRange bottom = NSMakeRange(self.collectedData.text.length -1, 1);
                [self.collectedData scrollRangeToVisible:bottom];
            }
        }
        if (counter == bytesToCollect){ //32) {
            [self.tapArea setBackgroundColor:[UIColor colorWithRed:152.0/255 green:251.0/255 blue:152.0/255 alpha:1.0]];
            [self.tapArea setText:NSLocalizedString(@"We have enough data to make your key now! You may continue tapping if you wish.", nil)];
        }
        [self.bytesLabel setText:[NSString stringWithFormat:NSLocalizedString(@"Bytes collected: %d\n%@", nil), counter, [self getCrackTimeString:counter]]];
        //NSLog(@"%hhu, tap:%d:%d - %llX",toUse,0x7,0x7, machtime);
        
        self.progress.progress+= 1.0/bytesToCollect;//0.03125;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)ok:(id)sender
{
    if (bytesToCollect == 3200 && counter < acceptedMinimum) {
        [CommonProcs showMessage:[NSString stringWithFormat:NSLocalizedString(@"Not enough data, tap at least %lu times",nil), acceptedMinimum] title:NSLocalizedString(@"Error",nil)];
        return;
    }
    res = YES;
    //[self dismissViewControllerAnimated:YES completion:nil];
    [navCtl popViewControllerAnimated:YES];
    self.navigationController.toolbarHidden = NO;
    dispatch_semaphore_signal(sema);
}

-(IBAction)cancel:(id)sender
{
    res = NO;
    //[self dismissViewControllerAnimated:YES completion:nil];
    [navCtl popViewControllerAnimated:YES];
    self.navigationController.toolbarHidden = NO;
    dispatch_semaphore_signal(sema);
}

+(NSMutableData*)getResult
{
    if (res) {
        return retData;
    }else{
        return nil;
    }
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
