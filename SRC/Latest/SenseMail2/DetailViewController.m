//
//  DetailViewController.m
//  SenseMailShare
//
//  Created by Sergey on 27.04.16.
//  Copyright © 2016 Sergey. All rights reserved.
//

#import "DetailViewController.h"
#import "GlobalRouter.h"

@interface DetailViewController ()

@end

@implementation DetailViewController

@synthesize masterButton;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self showMaster:nil];
    [GlobalRouter sharedManager].detailVC = self;
    
    //self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"settingsBg"]];
    
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation))
    {
        [self hideButtons];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    if(self.splitViewController.displayMode == UISplitViewControllerDisplayModeAllVisible){ //UISplitViewControllerDisplayModeAllVisible){
        // Show buttons
        [self addButtons];
    }else{
        // Hide buttons
        [self hideButtons];
    }
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}

-(void)addButtons
{
    NSMutableArray *items = [self.toolbar.items mutableCopy];
    
    if ([items containsObject:self.bookButton]) {
        
    }else{
        UIBarButtonItem* fixed = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        fixed.width = 24;
        [items insertObject:self.bookButton atIndex:0];
        [items insertObject:fixed atIndex:0];
        [items insertObject:self.composeButton atIndex:0];
        UIBarButtonItem* fixed2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        fixed2.width = 44;
        [items insertObject:fixed2 atIndex:0];
        [items insertObject:self.masterButton atIndex:0];
        
        [self.toolbar setItems:items animated:YES];
    }
}

-(void)hideButtons
{
    NSMutableArray *items = [self.toolbar.items mutableCopy];
    if(items.count > 6){
        [items removeObjectAtIndex:0];
        [items removeObjectAtIndex:0];
        [items removeObjectAtIndex:0];
        [items removeObjectAtIndex:0];
        [items removeObjectAtIndex:0];
        [self.toolbar setItems:items animated:YES];
    }
}

-(IBAction)showMaster:(id)sender
{
    //if (self.splitViewController.displayMode == UISplitViewControllerDisplayModeAllVisible){// ePrimaryHidden){
        self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModePrimaryOverlay;
        [self.splitViewController.displayModeButtonItem action];
   // }else{
        //self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModePrimaryHidden;
        //[self.splitViewController.displayModeButtonItem action];
   // }
    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAutomatic;
}

-(void)hideMaster
{
    if (self.splitViewController.displayMode == UISplitViewControllerDisplayModePrimaryOverlay){
        self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModePrimaryHidden;
        [self.splitViewController.displayModeButtonItem action];
    }else{
        
    }
    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAutomatic;
}

-(void)hideMasterAndRestore
{
    if (self.splitViewController.displayMode == UISplitViewControllerDisplayModePrimaryOverlay){
        self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModePrimaryHidden;
        [self.splitViewController.displayModeButtonItem action];
        //[self performSelector:@selector(setOverlayMode) withObject:nil afterDelay:1];
        self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAutomatic;
    }else{
        
    }
}

-(void)setOverlayMode
{
    self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeAutomatic;
}

-(void)setMasterHidden:(BOOL)hidden
{
    masterButton.enabled = hidden;
}

-(IBAction)exitApp:(id)sender
{
    [[GlobalRouter sharedManager] needExit];
}

-(IBAction)newMessage:(id)sender
{
    [[GlobalRouter sharedManager] newMessage];
}

-(IBAction)showBook:(id)sender
{
    [[GlobalRouter sharedManager] needShowAddressBook];
}

-(IBAction)showGallery:(id)sender
{
    [CommonProcs spawnProcWithProgress:@selector(needShowGallery) object:[GlobalRouter sharedManager] withParam:nil];
}

-(IBAction)showNotes:(id)sender
{
    [CommonProcs spawnProcWithProgress:@selector(needShowNotes) object:[GlobalRouter sharedManager] withParam:nil];
}

-(IBAction)gotoInbox:(id)sender
{
    [self showMaster:nil];
    [[GlobalRouter sharedManager] needShowInbox];
}

-(IBAction)composeNew:(id)sender
{
    [[GlobalRouter sharedManager] newMessage];
}

-(IBAction)showSettings:(id)sender
{
    [self showMaster:nil];
    [[GlobalRouter sharedManager] needSettings];
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
