//
//  Autocomplete.h
//  SenseMailShare
//
//  Created by Sergey on 15.01.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Autocomplete : NSObject <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray* allElements;
@property (nonatomic, strong) NSMutableArray* elements;

@property (nonatomic, strong) UITableView* autocompleteTableView;
@property (nonatomic, weak) UITextField* parentTextField;

-(void)createAutocompleteFor:(UITextField*)textField withAllElements:(NSArray*)allElements;
-(void)filterItems:(NSString*)substring;
-(void)removeTable;
-(void)hideTable;
-(BOOL)isHidden;

@end
