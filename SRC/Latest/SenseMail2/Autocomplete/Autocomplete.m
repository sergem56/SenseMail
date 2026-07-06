//
//  Autocomplete.m
//  SenseMailShare
//
//  Created by Sergey on 15.01.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

#import "Autocomplete.h"
#import "GlobalRouter.h"

@implementation Autocomplete

@synthesize autocompleteTableView;

-(void)createAutocompleteFor:(UITextField *)textField withAllElements:(NSArray *)allElements
{
    self.parentTextField = textField;
    self.allElements = [allElements copy];
    self.elements = [[NSMutableArray alloc] init];
    
    autocompleteTableView = [[UITableView alloc] initWithFrame: CGRectMake(5, self.parentTextField.frame.origin.y+self.parentTextField.frame.size.height, 310, 140) style:UITableViewStylePlain];
    autocompleteTableView.delegate = self;
    autocompleteTableView.dataSource = self;
    autocompleteTableView.scrollEnabled = YES;
    autocompleteTableView.hidden = YES;
    //autocompleteTableView.backgroundColor = [UIColor lightGrayColor];
    autocompleteTableView.rowHeight = 42;
    [self.parentTextField.superview addSubview:autocompleteTableView];
    
    autocompleteTableView.layer.masksToBounds = YES;
    autocompleteTableView.layer.borderColor = UIColor.grayColor.CGColor;//(red: 153/255, green: 153/255, blue:0/255, alpha: 1.0 ).CGColor;
    autocompleteTableView.layer.borderWidth = 1.0;
    autocompleteTableView.layer.cornerRadius = 10;
}

-(void)filterItems:(NSString *)substring
{
    [self.elements removeAllObjects];
    for(AutocompleteItem *curString in self.allElements) {
        NSRange substringRange = [curString.email rangeOfString:substring options:NSCaseInsensitiveSearch];
        if (substringRange.location != NSNotFound) {
            [self.elements addObject:curString];
        }else{
            NSRange substringRange = [curString.name rangeOfString:substring options:NSCaseInsensitiveSearch];
            if (substringRange.location != NSNotFound) {
                [self.elements addObject:curString];
            }
        }
    }
    if(self.elements.count > 0){
        autocompleteTableView.hidden = NO;
    }else{
        autocompleteTableView.hidden = YES;
    }
    [autocompleteTableView reloadData];
}

-(void)removeTable
{
    [self.elements removeAllObjects];
    //self.allElements = nil;
    autocompleteTableView.hidden = YES;
}

-(void)hideTable
{
    // Make a short delay since TextField ends editing before calling didSelect in table
    __weak __typeof__(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if(weakSelf){ // Because of the delay and clearance procedures it might be nulled
            __strong __typeof__(self) strongSelf = weakSelf;
            strongSelf->autocompleteTableView.hidden = YES;
        }
    });
    //autocompleteTableView.hidden = YES;
}

-(BOOL)isHidden
{
    return self.autocompleteTableView.hidden;
}

-(nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    AutocompleteItem* au = [self.elements objectAtIndex:indexPath.row];
    cell.textLabel.text = au.name;
    if(![au.name isEqualToString:au.email]){
        cell.detailTextLabel.text = au.email;
    }else{
        cell.detailTextLabel.text = @"";
    }
    [cell.textLabel setFont:[UIFont systemFontOfSize:13 weight:UIFontWeightBold]];
    
    return cell;
}

-(NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.elements.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AutocompleteItem* au = [self.elements objectAtIndex:indexPath.row];
    self.parentTextField.text = au.email; //[self.elements objectAtIndex:indexPath.row];
    self.autocompleteTableView.hidden = YES;
}

@end
