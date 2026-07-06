//
//  SearchViewController.h
//  SenseMailShare
//
//  Created by Sergey on 21.09.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonStuff.h"

@class SearchInteractor;


NS_ASSUME_NONNULL_BEGIN

@interface SearchViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
    //NSMutableDictionary* imagesForSearch;
    BOOL showingSuggested;
}

@property (nonatomic, strong) NSMutableArray* elements;
@property (nonatomic, strong) NSMutableArray* dateElements;
@property( nonatomic, strong) NSMutableDictionary* imagesForSearch;
@property (nonatomic, strong) NSMutableDictionary* elementCommands;
@property (nonatomic, weak) SearchInteractor* interactor;
@property (nonatomic, assign) searchTypes searchType;
@property (nonatomic, strong) NSString* userInputSearch;

@property (nonatomic, strong) IBOutlet UITableView* searchTableView;
@property (nonatomic, strong) IBOutlet UITextField* searchTextView;
@property (nonatomic, strong) IBOutlet UIButton* searchButton;

-(IBAction)searchPressed:(id)sender;
-(IBAction)filterStringChanged:(id)sender;

@end

NS_ASSUME_NONNULL_END
