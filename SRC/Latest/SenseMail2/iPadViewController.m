//
//  iPadViewController.m
//  SenseMailShare
//
//  Created by Sergey on 27.04.16.
//  Copyright © 2016 Sergey. All rights reserved.
//

#import "iPadViewController.h"
#import "GlobalRouter.h"
#import "DetailViewController.h"

@interface iPadViewController ()

@end

@implementation iPadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UINavigationController* temp = self.viewControllers[1];
    if (temp != nil) {
        temp.toolbarHidden = NO;
        temp.navigationItem.hidesBackButton = YES;
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
    DetailViewController* initial = [storyboard instantiateViewControllerWithIdentifier:@"DetailVC"];
    
    [temp pushViewController:initial animated:NO];
    
    //temp.navigationItem.hidesBackButton = YES;
    
    if (self.displayMode == UISplitViewControllerDisplayModePrimaryHidden)
    {
        [initial setMasterHidden:NO];
    }else{
        [initial setMasterHidden:YES];
    }
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
