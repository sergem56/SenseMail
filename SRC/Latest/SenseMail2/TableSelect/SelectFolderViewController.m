//
//  SelectFolderViewController.m
//  SenseMailShare
//
//  Created by Sergey on 14.07.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "SelectFolderViewController.h"
#import "GlobalRouter.h"
#import "TableSelectViewController.h"
#import "FolderInfo.h"

@interface SelectFolderViewController ()

@end

@implementation SelectFolderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    //self.items = [[[GlobalRouter sharedManager].otherFolders valueForKey:self.accountName] allKeys];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationItem.hidesBackButton = YES;
    //self.navigationController.toolbarHidden = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    //[self.navigationController setNavigationBarHidden:NO animated:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return self.items.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FolderName" forIndexPath:indexPath];
    
    // Configure the cell...
    //cell.textLabel.text = self.items[indexPath.row];
    UILabel* cellText = (UILabel*)[cell.contentView viewWithTag:302];
    UIImageView* cellImage = (UIImageView*)[cell.contentView viewWithTag:301];
    cellText.text = self.items[indexPath.row];
    
    //FolderInfo* fi = (FolderInfo*)([[[GlobalRouter sharedManager].otherFolders valueForKey:self.accountName] valueForKey:self.items[indexPath.row]]);
    FolderInfo* fi = (FolderInfo*)([[[GlobalRouter sharedManager].otherFolders objectForKey:self.accountName] valueForKey:self.items[indexPath.row]]);
    if ([cellText.text isEqualToString:@"INBOX"]) {
        cellImage.image = [UIImage imageNamed:@"inboxCircle"];
    }else if (fi.folderType == btFavourites){
        cellImage.image = [UIImage imageNamed:@"starCircle"];
    }else if (fi.folderType == btSpam){
        cellImage.image = [UIImage imageNamed:@"spamCircle"];
    }else if (fi.folderType == btSent){
        cellImage.image = [UIImage imageNamed:@"outboxCircle"];
    }else if (fi.folderType == btAllMail){
        cellImage.image = [UIImage imageNamed:@"allMailCircle"];
    }else if (fi.folderType == btDeleted){
        cellImage.image = [UIImage imageNamed:@"deletedCircle"];
    }else if (fi.folderType == btDrafts){
        cellImage.image = [UIImage imageNamed:@"writeMail"];
    }else if (fi.folderType == btImportant){
        cellImage.image = [UIImage imageNamed:@"importantCircle"];
    }else{
        cellImage.image = [UIImage imageNamed:@"moreCircle"];
    }
    
    return cell;
}

-(IBAction)cancel:(id)sender
{
    //[self.navigationController setNavigationBarHidden:YES];
    [self.navigationController popViewControllerAnimated:YES];// dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    //FolderInfo* fi = (FolderInfo*)([[[GlobalRouter sharedManager].otherFolders valueForKey:self.accountName] valueForKey:self.items[indexPath.row]]);
    FolderInfo* fi = (FolderInfo*)([[[GlobalRouter sharedManager].otherFolders objectForKey:self.accountName] objectForKey:self.items[indexPath.row]]);
    self.selectedValue = fi.folderPath;
    [self.navigationController popViewControllerAnimated:YES];// dismissViewControllerAnimated:NO completion:^{
        [self.parent itemSelected:self.selectedValue title:self.items[indexPath.row]];
    //}];
    //self.parent.selectedItem = self.selectedValue;
    
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
