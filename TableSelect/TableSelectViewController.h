//
//  TableSelectViewController.h
//  SenseMailShare
//
//  Created by Sergey on 14.07.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableSelectViewController : UITableViewController

@property (nonatomic, weak) NSArray* items;
@property (nonatomic, strong) NSString* selectedItem;
@property (nonatomic, strong) NSString* selectedAccount;

@property (nonatomic, weak) id caller;

-(void)itemSelected:(NSString*)item title:(NSString*)title;

@end
