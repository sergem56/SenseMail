//
//  FoldersTableViewController.h
//  SenseMailShare
//
//  Created by Sergey on 28.09.15.
//  Copyright © 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FoldersTableViewController : UITableViewController <UIGestureRecognizerDelegate>
{
    NSMutableIndexSet *expandedSections;
    NSMutableArray* serviceItems;
    NSMutableDictionary* items; // [dict(account name-dict(folder name-folder path))]
    NSMutableArray* sortedFolders; // array of arrays in order of sortedItems
    NSMutableArray* sortedItems;
    UILabel* noRecords;
    NSArray* oldToolbar;
}

@property (nonatomic, weak) id caller;
@property (nonatomic, strong) UITextField* searchText;
@property (strong, nonatomic) UIToolbar *inputAccessoryToolbar;

-(IBAction)close:(id)sender;
-(void)updateFolderList;
-(void)closeView;

@end
