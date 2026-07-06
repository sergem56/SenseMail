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
    self.navigationItem.hidesBackButton = YES;
    //UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save and close",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needSaveSettings)];
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(needSaveSettings)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeSettings)];
    
    //UIBarButtonItem* buttonAdd = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add account",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needAddItem)];
    UIBarButtonItem* buttonAdd = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"addEmailAcc"] style:UIBarButtonItemStylePlain target:self action:@selector(needAddItem)];
    self.buttonDel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(needDeleteItem)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:button1, flexibleItem, buttonAdd, flexibleItem, self.buttonDel, flexibleItem, button2, nil]];
    
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.needAddAccount) {
        [self needAddItem];
    }
}


-(void)closeSettings
{
    BOOL isChanged = NO;
    for (SettingsViewController* set in self.viewControllersT) {
        /*
        if ([set.settings.userName isEqualToString:GENERAL_SETTINGS]) {
            continue;
        }*/
        isChanged |= [set checkIfChanged];
    }
    if (isChanged) {
        [CommonProcs askYesNoAndDoWithTitle:NSLocalizedString(@"Warning",nil) text:NSLocalizedString(@"There are unsaved changes. Save before closing.",nil) blockYes:^{
            [self needSaveSettings];
        } blockNo:^{
            [[[GlobalRouter sharedManager] getSettingsRouter] finished];
        }];
        /*
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",nil) message:NSLocalizedString(@"There are unsaved changes. Save before closing.",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Close",nil) otherButtonTitles:NSLocalizedString(@"Save",nil),nil];
        [alert setTag:104];
        [alert show];*/
    }else{
        /*
        SettingsViewController* set = (SettingsViewController*) [self.pageController.viewControllers lastObject];
        if ([set.settings.userName  isEqual: GENERAL_SETTINGS]) {
            [[[GlobalRouter sharedManager] getSettingsRouter] finished];
        }else{
            [[GlobalRouter sharedManager] checkConnection:set.settings completion:^{
                [[[GlobalRouter sharedManager] getSettingsRouter] finished];
            }];
        }
        
        */
        [[[GlobalRouter sharedManager] getSettingsRouter] finished];
    }
}

/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 105){
        if (buttonIndex == 0)
        {
            // Cancelled
        }else if(buttonIndex == 1){
            // Don't save - restore the page or delete it if it is new
            SettingsViewController* set = (SettingsViewController*) [self.pageController.viewControllers lastObject];
            // Restore settings not to ask it is changed any more
            [set setCurrentSettings];
            
            if(pageLeaved != NULL)pageLeaved();
        }else{
            //Save settings, authorize and execute block
            SettingsViewController* set = (SettingsViewController*) [self.pageController.viewControllers lastObject];
            [set needSaveSettings];
            
            // TODO: need check connection
            if ([set.settings.userName  isEqual: GENERAL_SETTINGS]) {
                if(pageLeaved != NULL)pageLeaved();
            }else{
                __weak __typeof__(self) weakSelf = self;
                if([[GlobalRouter sharedManager] checkConnection:set.settings completion:^(BOOL res){
                    __strong __typeof__(self) strongSelf = weakSelf;
                    if(strongSelf->pageLeaved != NULL)strongSelf->pageLeaved();
                }]){
                    //if(pageLeaved != NULL)pageLeaved();
                }else{
                    
                }
            }
        }
    }
}*/

-(void)needSaveSettings
{
    BOOL canClose = YES;
    for (SettingsViewController* set in self.viewControllersT) {
        canClose &= [set needSaveSettings];
    }
    
    if (canClose) {
        [[[GlobalRouter sharedManager] getSettingsRouter] finished];
    }
    
    // Need to wait until writing is done
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [[GlobalRouter sharedManager] checkSessions];
    });
    //[[GlobalRouter sharedManager] performSelectorInBackground:@selector(checkSessions) withObject:nil];// afterDelay:1.5];
}

-(void)needAddItem
{
#ifdef DEMO
    if (self.viewControllersT.count >= 2) {
        [CommonProcs thisFeatureIsInFull:@"Unlimited accounts feature"];
        return;
    }
#endif
    
    [self willLeaveThatPageWithHandler:^{
        [[[GlobalRouter sharedManager] getSettingsRouter] addNewSetting];
    }];
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
        //[((SettingsViewController*)(self.pageController.viewControllers[0])) adjustForSettings];
    }
}


-(void)pageViewController:(UIPageViewController *)pvc willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    int ind0 = (int)([self.viewControllersT indexOfObject:[self.pageController.viewControllers lastObject]]);
    int ind1 = (int)([self.viewControllersT indexOfObject:[pendingViewControllers firstObject]]);
    
    [self willLeaveThatPageWithHandler:^{
        [pvc setViewControllers:pendingViewControllers direction:ind0<ind1?UIPageViewControllerNavigationDirectionForward:UIPageViewControllerNavigationDirectionReverse animated:YES completion:^(BOOL finished) {
        
        }];
    }];
    
}

-(void)willLeaveThatPageWithHandler:(dispatch_block_t)handler
{
    pageLeaved = [handler copy];
    
    SettingsViewController* set = ((SettingsViewController*)(self.pageController.viewControllers[0]));
    if([set checkIfChanged]){
        // Save and connect session
        /*
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning",nil) message:NSLocalizedString(@"There are unsaved changes. Save before closing.",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Don't save",nil),NSLocalizedString(@"Save",nil),nil];
        [alert setTag:105];
        [alert show];
        */
        __weak typeof(self) weakSelf = self;
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:NSLocalizedString(@"Warning",nil)
                                     message:NSLocalizedString(@"There are unsaved changes. Save before closing.",nil)
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                 style:UIAlertActionStyleDestructive
                                 handler:^(UIAlertAction * action)
                                 {
                                     
                                 }];
        [alert addAction:cancel];
        
        UIAlertAction* dont = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"Don't save",nil)
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction * action)
        {
            __strong typeof(self) strongSelf = weakSelf;
            SettingsViewController* set = (SettingsViewController*) [self.pageController.viewControllers lastObject];
            // Restore settings not to ask it is changed any more
            [set setCurrentSettings];
            
            if(strongSelf->pageLeaved != NULL)strongSelf->pageLeaved();
        }];
        [alert addAction:dont];
        
        UIAlertAction* save = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"Save",nil)
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
        {
            __strong typeof(self) strongSelf = weakSelf;
            //Save settings, authorize and execute block
            SettingsViewController* set = (SettingsViewController*) [self.pageController.viewControllers lastObject];
            [set needSaveSettings];
            
            // TODO: need check connection
            if ([set.settings.userName  isEqual: GENERAL_SETTINGS]) {
                if(strongSelf->pageLeaved != NULL)strongSelf->pageLeaved();
            }else{
                if([[GlobalRouter sharedManager] checkConnection:set.settings completion:^(BOOL res){
                    if(strongSelf->pageLeaved != NULL)strongSelf->pageLeaved();
                }]){
                    //if(pageLeaved != NULL)pageLeaved();
                }else{
                    
                }
            }
        }];
        [alert addAction:save];
        
        UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
        alert.popoverPresentationController.sourceView = pView;
        alert.popoverPresentationController.sourceRect = pView.frame;
        [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
        
    }else{
        if(pageLeaved != NULL)pageLeaved();
    }
}

@end
