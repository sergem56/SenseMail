//
//  SettingsPager.m
//  SenseMailShare
//
//  Created by Sergey on 08.07.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "SettingsPager.h"
#import "GlobalRouter.h"
#import "SettingsViewController.h"
#import "SettingsEntity.h"

@implementation SettingsPager

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.navigationController.toolbarHidden = NO;
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save and close",nil) style:UIBarButtonItemStyleBordered target:self action:@selector(needSaveSettings)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeSettings)];
    
    UIBarButtonItem* buttonAdd = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(needAddItem)];
    self.buttonDel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(needDeleteItem)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:button1, flexibleItem, buttonAdd, flexibleItem, self.buttonDel, flexibleItem, button2, nil]];
}

-(void)closeSettings
{
    [[[GlobalRouter sharedManager] getSettingsRouter] finished];
}

-(void)needSaveSettings
{
    for (SettingsViewController* set in self.viewControllersT) {
        [set needSaveSettings];
    }
}

-(void)needAddItem
{
    [[[GlobalRouter sharedManager] getSettingsRouter] addNewSetting];
}

-(void)needDeleteItem
{
    SettingsViewController* entVC = (SettingsViewController*) [self.pageController.viewControllers lastObject];
    SettingsEntity* sent = entVC.settings;
    [[[GlobalRouter sharedManager] getSettingsRouter] deleteSetting:sent];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed) {
        if ([((SettingsViewController*)(self.pageController.viewControllers[0])).settings.userName isEqualToString:GENERAL_SETTINGS]) {
            self.buttonDel.enabled = NO;
        }else{
            self.buttonDel.enabled = YES;
        }
    }
}

@end
