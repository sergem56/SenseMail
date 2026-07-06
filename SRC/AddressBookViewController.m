//
//  AddressBookViewController.m
//  SenseMail2
//
//  Created by Sergey on 09.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "AddressBookViewController.h"
#import "AddressBookEntity.h"
#import "GlobalRouter.h"
#import "AddressBookPresenter.h"
#import "CommonProcs.h"

@interface AddressBookViewController ()

@end

@implementation AddressBookViewController

@synthesize book, caller, showingGroup, currentGroup, addingToGroup;//, bookTitles, bookDict;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    UINib *nib = [UINib nibWithNibName:@"TableCell" bundle:nil];
    [[self tableView] registerNib:nib forCellReuseIdentifier:@"AddressCell"];
    [[self searchDisplayController].searchResultsTableView registerNib:nib forCellReuseIdentifier:@"AddressCell"];
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationController.toolbarHidden = NO;
    //UIBarButtonItem* button0 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addItem)];
    self.addContact = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"addContact"] style:UIBarButtonItemStylePlain target:self action:@selector(addItem)];
    self.removeContactFromGroup = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"delContact"] style:UIBarButtonItemStylePlain target:self action:@selector(delItemFromGroup)];
    self.addContactToGroup = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"addContact"] style:UIBarButtonItemStylePlain target:self action:@selector(addItemToGroup)];
    UIBarButtonItem *fixedItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedItem.width = 5.0f;
    self.addContactGroup = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"addContactGroup"] style:UIBarButtonItemStylePlain target:self action:@selector(addGroupItem)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeBook)];
    
    
    if (showingGroup) {
        [self setToolbarItems:[NSArray arrayWithObjects: self.addContactToGroup, flexibleItem, button2, nil]];
    }else{
        [self setToolbarItems:[NSArray arrayWithObjects:self.addContact, fixedItem, self.addContactGroup, flexibleItem, button2, nil]];
    }
    
    [self buildIndexes];
}

-(void)addItem
{
    [self.presenter needShowAddItem];
}

-(void)addItemToGroup
{
    [self.presenter filterGroupAndShow:@""];
}

-(void)delItemFromGroup
{
    //[self.presenter :];
}

-(void)addGroupItem
{
    //[self.presenter needShowAddItem];
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter group name",nil) message:NSLocalizedString(@"",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Done",nil),nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert setTag:100];
    [alert show];
}

-(void)closeBook
{
    self.nameSets = nil;
    self.sectionTitles = nil;
    self.indicesDict = nil;
    self.filteredNames = nil;
    self.book = nil;
    [[[GlobalRouter sharedManager] getBookRouter] finished];
}

-(void)needSaveBook
{
    // check if empty
    if (book.count == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Address book is empty",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
        alert.tag = 10000;
        [alert show];
        return;
    }
    
    [CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Saving...", nil) stopButton:NO];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL res = [self.presenter needSaveBook:book pin:[GlobalRouter sharedManager].pin];
        dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs hideProgress];
            if(res){
                [self closeBook];
            }else{
            // Shouldn't get here, but who knows
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error saving settings",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
                alert.tag = 10000;
                [alert show];
            }
        });
    });
}

-(void) setCurrentBook
{
    [self buildIndexes];
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs hideProgress];
        [self.tableView reloadData];
    });
    //[self enableButtons];
}

/*
-(void)buildIndexes0
{
    NSMutableArray* indexes = [[NSMutableArray alloc] init];
    self.bookDict = [[NSMutableDictionary alloc] init];
    for (AddressBookEntity* item in book) {
        NSString* letter = [item.name substringToIndex:1];
        if ([indexes indexOfObject:letter] == NSNotFound) {
            [indexes addObject:letter];
            [bookDict setObject:[[NSMutableArray alloc] init] forKey:letter];
        }
        [[bookDict valueForKey:letter] addObject:item];
    }
    self.bookTitles = indexes;
}
 
*/

-(void)buildIndexes
{
    // Create sections for each letter
    NSInteger sectionTitlesCount = [[[UILocalizedIndexedCollation currentCollation] sectionTitles] count];
    NSMutableArray *allSections = [[NSMutableArray alloc] initWithCapacity:sectionTitlesCount];
    for (NSInteger i = 0; i < sectionTitlesCount; i++) {
        [allSections addObject:[NSMutableArray array]];
    }
    
    // Loop through the icons and add to appropriate section
    for (AddressBookEntity *item in book) {
        // Get section index for icon
        NSInteger sectionNumber = [[UILocalizedIndexedCollation currentCollation] sectionForObject:item collationStringSelector:@selector(name)];
        [allSections[sectionNumber] addObject:item];
    }
    
    self.nameSets = [NSMutableArray array];
    self.sectionTitles = [NSMutableArray array];
    self.indicesDict = [NSMutableDictionary dictionary];
    self.filteredNames = [NSMutableArray array];
    
    for (NSInteger i = 0; i < sectionTitlesCount; i++) {
        NSArray *curNames = allSections[i];
        
        NSString *sectionTitle = [[UILocalizedIndexedCollation currentCollation] sectionTitles][i];
        
        if (curNames.count > 0) {
            [self.sectionTitles addObject:sectionTitle];
            [self.nameSets addObject:[NSMutableArray arrayWithArray:[curNames sortedArrayUsingSelector:@selector(compare:)]]];
        }
        self.indicesDict[sectionTitle] = [NSNumber numberWithInt:MAX((int) self.nameSets.count-1, 0)];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)enableButtons
{
    BOOL enabled = self.caller == nil;
    self.addContact.enabled = enabled;
    self.addContactGroup.enabled = enabled;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return 1;
    }else{
        return self.nameSets.count; //bookTitles.count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //NSString* letter = [bookTitles objectAtIndex:section];
    //NSMutableArray* tmp = (NSMutableArray*)[bookDict valueForKey:letter];
    //return tmp.count;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.filteredNames.count;
    }else{
        NSMutableArray *set = self.nameSets[section];
        return set.count;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddressCell" forIndexPath:indexPath];
    AddressBookEntity *info;
    
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        info = self.filteredNames[indexPath.row];
    }else{
        // Configure the cell...
        NSMutableArray *set = self.nameSets[indexPath.section];
        info = set[indexPath.row];
    }
    
    cell.textLabel.text = info.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@",
                                 info.address];
    if(!(info.note == nil || [info.note isEqualToString:@""])) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@",cell.detailTextLabel.text, info.note];
    }
    
    if(info.key) {
        cell.textLabel.text = [NSString stringWithFormat:@"◇ %@", cell.textLabel.text];//🔑 ⚔
        cell.textLabel.textColor = [UIColor colorWithRed:7/255.0 green:100.0/255.0 blue:7/255.0 alpha:1];
    }else{
        cell.textLabel.textColor = [UIColor blackColor];
    }
    
    if (info.isGroup) {
        cell.detailTextLabel.text = NSLocalizedString(@"Group", nil);
    }
    
    return cell;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        NSMutableArray *set = self.nameSets[indexPath.section];
        AddressBookEntity* toDel = set[indexPath.row];
        
        if (showingGroup) {
            // Del from group only
            [self.presenter removeContactFromGroup:toDel fromGroup:currentGroup];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Contact has been deleted from this group only",nil) message:NSLocalizedString(@"It remains in the address book",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
            alert.tag = 10000;
            [alert show];
        }else{
            // Delete the row from the data source
            [self.presenter deleteItem:toDel];
        }
        
        [self deleteRowAt:indexPath]; // do not build indexes since it changes section number - fails if you delete last address in section
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self buildIndexes];
        if (set.count == 0) {
            [tableView deleteSections:[NSIndexSet indexSetWithIndex: indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
        }
        // Save!
        if(!showingGroup)
            [self.presenter needSaveBook];// needSaveBook:book pin:[GlobalRouter sharedManager].pin];
        
        [tableView reloadData];
        
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

-(void)deleteRowAt:(NSIndexPath*)indexPath
{
    NSMutableArray *set = self.nameSets[indexPath.section];
    AddressBookEntity* toDel = set[indexPath.row];
    [set removeObject:toDel];
}

-(void)enableAdding:(BOOL)enable
{
    NSMutableArray *toolBarButtons = [self.toolbarItems mutableCopy];
    if (enable) {
        [toolBarButtons insertObject:self.addContact atIndex:0];
        [toolBarButtons insertObject:self.addContactGroup atIndex:2];
    }else{
        [toolBarButtons removeObject:self.addContact];
        [toolBarButtons removeObject:self.addContactGroup];
        [toolBarButtons removeObject:self.addContactToGroup];
        
        [toolBarButtons insertObject:self.addContactToGroup atIndex:0];
    }
    [self setToolbarItems:toolBarButtons];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *set = self.nameSets[indexPath.section];
    AddressBookEntity* item = set[indexPath.row];
    //AddressBookEntity* item = [book objectAtIndex:indexPath.row];
    if (item.isGroup) {
        // This is a group, expand it
        [self.presenter filterGroupAndShow:item.name];
    }else{
        if (self.caller == nil) {
            // Show for editing
            [self.presenter needEditItem:item];
        }else{
            if ([caller respondsToSelector:@selector(setToAddress:)]) {
                [caller setToAddress:item];
                [self closeBook];
                if (self.showingGroup && !self.addingToGroup) {
                    [[GlobalRouter sharedManager] finishedWithCurrentView];
                }
            }
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return nil;
    }else{
        if (showingGroup) {
            return [NSString stringWithFormat:@"%@ (%@)", self.sectionTitles[section], currentGroup];
        }else
            return self.sectionTitles[section];
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return nil;
    } else {
        NSMutableArray *retval = [NSMutableArray arrayWithObject:UITableViewIndexSearch];
        [retval addObjectsFromArray:[[UILocalizedIndexedCollation currentCollation] sectionIndexTitles]];
        return retval;
    }
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if (index == 0) {
        CGRect searchBarFrame = self.searchDisplayController.searchBar.frame;
        [tableView scrollRectToVisible:searchBarFrame animated:YES];
        return NSNotFound;
    } else {
        return [self.indicesDict[title] integerValue];
    }
}

#pragma mark - Filtering

- (void)filterNames:(NSArray *)names forSearchText:(NSString *)searchText {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.name contains[c] %@ OR SELF.address contains[c] %@ OR SELF.note contains[c] %@", searchText, searchText, searchText];
    [self.filteredNames addObjectsFromArray:[names filteredArrayUsingPredicate:predicate]];
}

- (void)filterContentForSearchText:(NSString *)searchText scopeIndex:(NSInteger)scopeIndex {
    
    [self.filteredNames removeAllObjects];
    for (NSMutableArray *nameSet in self.nameSets) {
        [self filterNames:nameSet forSearchText:searchText];
    }
}

#pragma mark - UISearchDisplayController Delegate methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    [self filterContentForSearchText:searchString scopeIndex:self.searchDisplayController.searchBar.selectedScopeButtonIndex];
    return YES;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption
{
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scopeIndex:searchOption];
    return YES;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100)
    {
        if (buttonIndex == 0)
        {
            //[self finished];
        }else{
            NSString* text = [[alertView textFieldAtIndex:0] text];
            AddressBookEntity* item = [[AddressBookEntity alloc] init];
            item.name = text;
            item.isGroup = YES;
            item.uid = [[NSUUID UUID] UUIDString];
            
            [CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Saving...", nil) stopButton:NO];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self.presenter needAddItemToBook:item];
            });
        }
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
