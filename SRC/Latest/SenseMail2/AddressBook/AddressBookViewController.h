//
//  AddressBookViewController.h
//  SenseMail2
//
//  Created by Sergey on 09.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonStuff.h"

@class  AddressBookPresenter;

@interface AddressBookViewController : UITableViewController <UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate>

@property (strong, nonatomic) UISearchController *searchController;

@property (nonatomic, strong) NSMutableArray* book;
//@property (nonatomic, strong) NSMutableDictionary* bookDict;
//@property (nonatomic, strong) NSArray* bookTitles;

@property (nonatomic, strong) NSMutableArray* nameSets;
@property (nonatomic, strong) NSMutableArray* sectionTitles;
@property (nonatomic, strong) NSMutableDictionary* indicesDict;
@property (nonatomic, strong) NSMutableArray* filteredNames;

@property (nonatomic, assign) BOOL showingGroup;
@property (nonatomic, strong) NSString* currentGroup;
@property (nonatomic, weak) AddressBookPresenter* presenter;
@property (nonatomic, assign) BOOL addingToGroup;
//@property (nonatomic) IBOutlet UIView* addNew;

@property (nonatomic, strong) UIBarButtonItem* addContact;
@property (nonatomic, strong) UIBarButtonItem* addContactGroup;
@property (nonatomic, strong) UIBarButtonItem* addContactToGroup;
@property (nonatomic, strong) UIBarButtonItem* removeContactFromGroup;

@property (nonatomic, weak) id<CanGetAddressFromBook> caller;

-(void)setCurrentBook;
-(void)enableAdding:(BOOL)enable;
-(void)enableButtons;

@end
