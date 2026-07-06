//
//  SearchViewController.m
//  SenseMailShare
//
//  Created by Sergey on 21.09.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

#import "SearchViewController.h"
#import "SearchInteractor.h"

@interface SearchViewController ()

@end

@implementation SearchViewController

@synthesize imagesForSearch;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeSearch)];
    [self setToolbarItems:[NSArray arrayWithObjects:flexibleItem, button2, nil]];
    
    self.dateElements = [[NSMutableArray alloc] init];
    
    self.elements = [[NSMutableArray alloc] initWithCapacity:8];
    imagesForSearch = [[NSMutableDictionary alloc] initWithCapacity:8];
    self.elementCommands = [[NSMutableDictionary alloc] initWithCapacity:8];
    
    [self.elements addObject:NSLocalizedString(@"Find unread", nil)];
    [imagesForSearch setObject:@"BlueDot" forKey:self.elements[0]];
    [self.elementCommands setObject:[NSNumber numberWithInt:stUnread] forKey:self.elements[0]];
    
    [self.elements addObject:NSLocalizedString(@"Find answered", nil)];
    [imagesForSearch setObject:@"repliedArrow" forKey:self.elements[1]];
    [self.elementCommands setObject:[NSNumber numberWithInt:stAnswered] forKey:self.elements[1]];
    
    [self.elements addObject:NSLocalizedString(@"Find large messages", nil)];
    [imagesForSearch setObject:@"iCloud" forKey:self.elements[2]];
    [self.elementCommands setObject:[NSNumber numberWithInt:stLarge] forKey:self.elements[2]];
    
    //[self.elements addObject:NSLocalizedString(@"Find messages with attachment", nil)];
    //[imagesForSearch setObject:@"Paperclip" forKey:self.elements[3]];
    
    [self.elements addObject:NSLocalizedString(@"Find flagged", nil)];
    [imagesForSearch setObject:@"starYellow" forKey:self.elements[3]];
    [self.elementCommands setObject:[NSNumber numberWithInt:stFlagged] forKey:self.elements[3]];
    
    [self.elements addObject:NSLocalizedString(@"Find protected", nil)];
    [imagesForSearch setObject:@"lockCentered" forKey:self.elements[4]];
    [self.elementCommands setObject:[NSNumber numberWithInt:stProtected] forKey:self.elements[4]];
    
    [self.elements addObject:NSLocalizedString(@"Find important", nil)];
    [imagesForSearch setObject:@"RedDot" forKey:self.elements[5]];
    [self.elementCommands setObject:[NSNumber numberWithInt:stImportant] forKey:self.elements[5]];
    
    [self.elements addObject:NSLocalizedString(@"Last week", nil)];
    [imagesForSearch setObject:@"calendar" forKey:self.elements[6]];
    [self.elementCommands setObject:[NSNumber numberWithInt:stLastWeek] forKey:self.elements[6]];
    
    [self.elements addObject:NSLocalizedString(@"Last month", nil)];
    [imagesForSearch setObject:@"calendar" forKey:self.elements[7]];
    [self.elementCommands setObject:[NSNumber numberWithInt:stLastMonth] forKey:self.elements[7]];
    
    showingSuggested = YES;
    self.searchTextView.delegate = self;
    
    UIBarButtonItem* button11 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"search"] style:UIBarButtonItemStylePlain target:self action:@selector(searchPressed:)];
    
    UIBarButtonItem *flexibleItem22 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button22 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeSearch)];
    
    UIToolbar* inputAccessoryToolbar = [[UIToolbar alloc] init];
    inputAccessoryToolbar.frame = CGRectMake(0,0,300,44);
    inputAccessoryToolbar.items = [NSArray arrayWithObjects:button22, flexibleItem22, button11, nil];
    self.searchTextView.inputAccessoryView = inputAccessoryToolbar;
}

-(IBAction)searchPressed:(id)sender
{
    SearchInteractor* inter = [[SearchInteractor alloc] init];
    inter.vc = self;
    self.searchType = stUserInput;
    self.userInputSearch = self.searchTextView.text;
    [inter doSearch];
}

-(void)closeSearch
{
    SearchInteractor* inter = [[SearchInteractor alloc] init];
    inter.vc = self; // No need, since we are cancelling
    [inter cancelSearch];
}

#pragma mark - UITableView stuff

-(nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    NSString* cellString;
    if (self.dateElements.count > 0 && indexPath.row < self.dateElements.count) {
        cellString = [self.dateElements objectAtIndex:indexPath.row];
    }else{
        if(self.dateElements.count == 0){
            cellString = [self.elements objectAtIndex:indexPath.row];
        }else{
            cellString = [self.elements objectAtIndex:(indexPath.row-self.dateElements.count)];
        }
    }
    cell.textLabel.text = cellString;
    NSString* imageName = [imagesForSearch objectForKey:cellString];
    if (imageName != nil) {
        [cell.imageView setImage:[UIImage imageNamed:imageName]];
        
        CGSize itemSize = CGSizeMake(18, 18);
        UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
        UIImage *image = cell.imageView.image;
        
        CGRect imageRect;
        if(image.size.height > image.size.width) {
            CGFloat width = itemSize.height * image.size.width / image.size.height;
            imageRect = CGRectMake((itemSize.width - width) / 2, 0, width, itemSize.height);
        } else {
            CGFloat height = itemSize.width * image.size.height / image.size.width;
            imageRect = CGRectMake(0, (itemSize.height - height) / 2, itemSize.width, height);
        }
        [cell.imageView.image drawInRect:imageRect];
        cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }else{
        [cell.imageView setImage:nil];
    }
    
    return cell;
}

-(NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.elements.count+self.dateElements.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (showingSuggested) {
        /*switch (indexPath.row) {
            case 0:
                self.searchType = stUnread;
                break;
            case 1:
                self.searchType = stAnswered;
                break;
            case 2:
                self.searchType = stLarge;
                break;
            //case 3:
            //    self.searchType = stWithAttachments;
            //    break;
            case 3:
                self.searchType = stFlagged;
                break;
            case 4:
                self.searchType = stProtected;
                break;
            default:
                break;
        }
        */
        
        NSString* cellString;
        if (self.dateElements.count > 0 && indexPath.row < self.dateElements.count) {
            cellString = [self.dateElements objectAtIndex:indexPath.row];
        }else{
            if(self.dateElements.count == 0){
                cellString = [self.elements objectAtIndex:indexPath.row];
            }else{
                cellString = [self.elements objectAtIndex:(indexPath.row-self.dateElements.count)];
            }
        }
        
        NSNumber* typeS = [self.elementCommands valueForKey:cellString];//self.elements[indexPath.row]];
        self.searchType = (searchTypes)[typeS integerValue];
        SearchInteractor* inter = [[SearchInteractor alloc] init];
        self.userInputSearch = self.searchTextView.text;
        inter.vc = self;
        [inter doSearch];
    }else{
        
    }
    //self.parentTextField.text = [self.elements objectAtIndex:indexPath.row];
    //self.autocompleteTableView.hidden = YES;
}

// Suggest search querries
// 1. if date's been detected:
//      - date, before date, after date
// 2. text detected:
//      - look for a sender and show if found
//      - look for a loaded subject
// 3. number detected:
//      - is it a beginning of a date? suggest current or last month - date, before, after. Adjust
//        on typing.
//      - not a date - ?

-(IBAction)filterStringChanged:(id)sender
{
    [self.interactor searchStringChanged:self.searchTextView.text];
}

// Perhaps use those?
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if([textField isEqual:self.searchTextView]){
        [self.interactor searchStringChanged:[self.searchTextView.text stringByReplacingCharactersInRange:range withString:string]];
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if([textField isEqual:self.searchTextView]){
        
    }
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
