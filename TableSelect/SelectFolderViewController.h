//
//  SelectFolderViewController.h
//  SenseMailShare
//
//  Created by Sergey on 14.07.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TableSelectViewController;

@interface SelectFolderViewController : UITableViewController

@property (nonatomic, weak) NSString* accountName;
@property (nonatomic) NSArray* items;

@property (nonatomic) NSString* selectedValue;
@property (nonatomic, weak) TableSelectViewController* parent;

//@property (nonatomic, weak) IBOutlet UIImageView* cellImage;
//@property (nonatomic, weak) IBOutlet UILabel* cellText;

-(IBAction)cancel:(id)sender;

@end
