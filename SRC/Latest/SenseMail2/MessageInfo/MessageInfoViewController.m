//
//  MessageInfoViewController.m
//  SenseMailShare
//
//  Created by Sergey on 02.02.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

#import "MessageInfoViewController.h"
#import "GlobalRouter.h"

@interface MessageInfoViewController ()

@end

@implementation MessageInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
    
    //[self.info setText:self.messageInfo];
    [self.info setAttributedText:self.messageInfo];
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeInfo)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:flexibleItem, button2, nil]];
}

-(void)closeInfo
{
    [[GlobalRouter sharedManager] finishedWithDetailView:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
