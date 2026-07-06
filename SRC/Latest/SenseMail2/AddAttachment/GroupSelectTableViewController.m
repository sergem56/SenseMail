//
//  GroupSelectTableViewController.m
//  SenseMailShare
//
//  Created by Sergey on 18.11.15.
//  Copyright © 2015 Sergey. All rights reserved.
//

#import "GroupSelectTableViewController.h"
#import "AddAttachmentPresenter.h"
#import "GlobalRouter.h"
#import "DocsViewController.h"


@interface GroupSelectTableViewController ()

@end

@implementation GroupSelectTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    UIBarButtonItem* button0 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didSelectedDocs)];
    
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(closeView)];
    
    if (self.items != nil && self.items.count >0 && [[[self.items objectAtIndex:0] class] isSubclassOfClass:[NSString class]]) {
        [self setToolbarItems:[NSArray arrayWithObjects:button0, flexibleItem, button2, nil]];
    }else{
        [self setToolbarItems:[NSArray arrayWithObjects: flexibleItem, button2, nil]];
    }
}

-(void)closeView
{
    if ([self.caller respondsToSelector:@selector(setGroupsShown:)]) {
        [self.caller setGroupsShown:NO];
    }
    [[GlobalRouter sharedManager] finishedWithCurrentView:YES];
}

-(void)didSelectedDocs
{
    // Add docs to the letter kept in caller
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    //NSLog(documentsPath);
    
    NSMutableArray* selCells = [[NSMutableArray alloc] init];
    for (NSIndexPath* ind in self.tableView.indexPathsForSelectedRows) {
        NSLog(@"Selected = %@", self.items[ind.row]);
        // Copy to temp!
        NSString* res = [CommonProcs copyFileToTemp:[NSString stringWithFormat:@"%@/%@", documentsPath, self.items[ind.row]]];
        if(res != nil) [selCells addObject:res];
    }
    [self.attReceiver setAttachments:selCells];
    
    //[[GlobalRouter sharedManager] finishedWithCurrentView:YES];
    [self closeView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    // Return the number of sections.
    if (self.items.count > 0){
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        self.tableView.backgroundView = nil;
        return 1;
    }else{
        // Display a message when the table is empty
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        if (self.gsType == gsiTunesDocs) {
            messageLabel.text = NSLocalizedString(@"You haven't added any documents yet.\nConnect the device to a computer, go to iTunes and add files under the Shared Files section", nil);
        }else{
            messageLabel.text = NSLocalizedString(@"No Albums", nil);
        }
        messageLabel.textColor = [UIColor blackColor];
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        [messageLabel sizeToFit];
        
        self.tableView.backgroundView = messageLabel;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return 1;
    //return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.items.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
    [cell.imageView setImage:nil];

    // Configure the cell...
    if ([[[self.items objectAtIndex:indexPath.row] class] isSubclassOfClass:[NSString class]]) {
        // Docs
        cell.textLabel.text = [self.items objectAtIndex:indexPath.row];
        [cell.imageView setImage:[UIImage imageNamed:@"galleryCircle"]];
    }else{
        NSNumber* cnt = (NSNumber*)[self.items objectAtIndex:indexPath.row][2];
        NSString* countString;
        if (cnt.integerValue == NSNotFound) {
            countString = @"";
            cell.textLabel.text = [NSString stringWithFormat:@"%@", [self.items objectAtIndex:indexPath.row][0]];
        }else{
            countString = [cnt stringValue];
            cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", [self.items objectAtIndex:indexPath.row][0], countString];
        }
        //cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", [self.items objectAtIndex:indexPath.row][0], countString];
        [cell.imageView setImage:[self.items objectAtIndex:indexPath.row][1]];
    }

    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

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


#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    
    if ([[[self.items objectAtIndex:indexPath.row] class] isSubclassOfClass:[NSString class]]) {
        // Open preview
        //QLPreviewController *previewController=[[QLPreviewController alloc]init];
        DocsViewController *previewController=[[DocsViewController alloc]init];
        previewController.items = self.items;
        previewController.delegate=previewController;
        previewController.dataSource=previewController;
        [previewController setCurrentPreviewItemIndex:indexPath.row];
        
        //[previewController.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:nil]];
        
        [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:previewController animated:YES completion:^{
                //int i = self.items.count;
        }];//:previewController animated:YES];
        
        
    }else{
        [[GlobalRouter sharedManager] finishedWithCurrentView:YES];
        [self.caller showGroup:[self.items objectAtIndex:indexPath.row][0]];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 3;
}

#pragma mark - QLPreviewControllerDataSource

-(NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller
{
    return self.items.count; // Preview one file, no next-prev
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    NSString* path = [NSString stringWithFormat:@"%@/%@", documentsPath, self.items[index]];
    return [NSURL fileURLWithPath:path];
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
