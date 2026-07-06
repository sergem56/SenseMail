//
//  OTCsListViewController.h
//  SenseMailShare
//
//  Created by Sergey on 16/01/2019.
//  Copyright © 2019 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OTCsListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
    // UIBarButtons
    UIBarButtonItem *deleteAllButton;
    UIBarButtonItem *resendButton;
    UIBarButtonItem *editButton;
    UIBarButtonItem *flexibleItem;
    UIBarButtonItem *doneButton;
}
@property (nonatomic, assign) BOOL showingDetails;
@property (nonatomic, assign) int currentSection;

@property (nonatomic, strong) IBOutlet UITableView* tableView;
@property (nonatomic, strong) IBOutlet UILabel* noData;
@property (nonatomic, strong) NSDictionary* items;
@property (nonatomic, strong) NSArray* topItems;

-(void)loadOTCs;
-(void)setNoData;

@end

NS_ASSUME_NONNULL_END
