//
//  OTCsListViewController.m
//  SenseMailShare
//
//  Created by Sergey on 16/01/2019.
//  Copyright © 2019 Sergey. All rights reserved.
//

#import "OTCsListViewController.h"
#import "GlobalRouter.h"
#import "OneTimeCert.h"
#import "OneTimeCertInteractor.h"

@interface OTCsListViewController ()

@end

@implementation OTCsListViewController

@synthesize showingDetails, currentSection;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UINib *nib = [UINib nibWithNibName:@"OTCTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"OTCCell"];
    
    flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(cancel:)];
    
    deleteAllButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteAllFromTheList:)];
    resendButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Resend", @"") style:UIBarButtonItemStylePlain target:self action:@selector(reSend:)];
    //editButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit", @"") style:UIBarButtonItemStylePlain target:self action:@selector(edit:)];
    editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(edit:)];
    
    [self setToolbarItems:[NSArray arrayWithObjects: flexibleItem, doneButton, nil]];
    
    self.noData.hidden = self.items.count != 0;
    
    //self.tableView.estimatedRowHeight = 80;
    //self.tableView.rowHeight = UITableViewAutomaticDimension;
}

// Change to and from addresses
-(IBAction)edit:(id)sender
{
    OneTimeCert* cert = (OneTimeCert*)(((NSArray*)[self.items valueForKey:self.items.allKeys[currentSection]])[0]);
    
    NSString* toAddr = cert.otherEmail;
    NSString* fromAddr = cert.yourEmail;
    
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:NSLocalizedString(@"Edit",nil)
                                 message:NSLocalizedString(@"Edit from and to addresses for the all listed OTCs", @"")
                                 preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = fromAddr;
        textField.secureTextEntry = NO;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = toAddr;
        textField.secureTextEntry = NO;
    }];
    UIAlertAction* canSend = [UIAlertAction
                              actionWithTitle:NSLocalizedString(@"Save", nil)
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
                                  //__strong __typeof__(self) strongSelf = weakSelf;
                                  [[GlobalRouter sharedManager].oneTimeCertInteractor changeOTCsAddresses:[alert textFields][0].text to:[alert textFields][1].text oldFrom:fromAddr oldTo:toAddr];
                              }];
    [alert addAction:canSend];
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"Cancel",nil)
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 
                             }];
    [alert addAction:cancel];
    
    UIView* pView = self.view; //[[GlobalRouter sharedManager] getCurrentView];
    alert.popoverPresentationController.sourceView = pView;
    alert.popoverPresentationController.sourceRect = pView.frame;
    [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
}

-(IBAction)cancel:(id)sender
{
    if(showingDetails){
        showingDetails = NO;
        currentSection = 0;
        
        [UIView transitionWithView: self.tableView
                          duration: 0.45f
                           options: UIViewAnimationOptionTransitionCrossDissolve
                        animations: ^(void)
         {
             [self.tableView reloadData];
         }
                        completion: nil];
        
        [self setToolbarItems:[NSArray arrayWithObjects: flexibleItem, doneButton, nil]];

    }else{
        [[GlobalRouter sharedManager] finishedWithDetailView:YES];// finishedWithCurrentView];
    }
}

-(void)deleteAllFromTheList:(id)sender
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:NSLocalizedString(@"Warning",nil)
                                 message:NSLocalizedString(@"All the certificates from the list will be deleted. Do you want to continue?",nil)
                                 preferredStyle:UIAlertControllerStyleAlert];
    __weak __typeof__(self) weakSelf = self;
    UIAlertAction* deleteAll = [UIAlertAction
                              actionWithTitle:NSLocalizedString(@"Delete them", nil)
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction * action)
                              {
                                  __strong __typeof__(self) strongSelf = weakSelf;
                                  [[GlobalRouter sharedManager].oneTimeCertInteractor deleteTheList:(NSArray*)[self.items valueForKey:self.items.allKeys[strongSelf->currentSection]]];
                                  NSMutableDictionary* temp = [[NSMutableDictionary alloc] initWithDictionary:self.items];
                                  [temp removeObjectForKey:self.items.allKeys[strongSelf->currentSection]];
                                  self.items = temp;
                                  //[self.tableView reloadData];
                                  [self cancel:nil];
                              }];
    [alert addAction:deleteAll];
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"No",nil)
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 
                             }];
    [alert addAction:cancel];
    
    UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
    alert.popoverPresentationController.sourceView = pView;
    alert.popoverPresentationController.sourceRect = pView.frame;
    [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
}

-(void)reSend:(id)sender
{
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:NSLocalizedString(@"Warning",nil)
                                 message:NSLocalizedString(@"To resend the OTCs you need to place both devices near each other and start the OTC exchange on the second device as a receiver. To do so go to the address book, choose the desired sender, tap \"Exchange OTC\" and tap \"I will be a receiver\".\nDo you want to continue?",nil)
                                 preferredStyle:UIAlertControllerStyleAlert];
    __weak __typeof__(self) weakSelf = self;
    UIAlertAction* resend = [UIAlertAction
                                actionWithTitle:NSLocalizedString(@"Resend", nil)
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action)
                                {
                                    __strong __typeof__(self) strongSelf = weakSelf;
                                    [[GlobalRouter sharedManager].oneTimeCertInteractor reSendTheList:(NSArray*)[self.items valueForKey:self.items.allKeys[strongSelf->currentSection]]];
                                }];
    [alert addAction:resend];
    
    UIAlertAction* cancel = [UIAlertAction
                             actionWithTitle:NSLocalizedString(@"No",nil)
                             style:UIAlertActionStyleCancel
                             handler:^(UIAlertAction * action)
                             {
                                 
                             }];
    [alert addAction:cancel];
    
    UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
    alert.popoverPresentationController.sourceView = pView;
    alert.popoverPresentationController.sourceRect = pView.frame;
    [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
}

-(void)loadOTCs
{
    self.items = @{@"test1":@[@"1",@"2",@"3",@"4"],
                   @"rest":@[@"1r",@"2r",@"3r"],
                   @"best":@[@"1b",@"2b"]
                   };
}

-(void)setNoData
{
    self.noData.hidden = NO;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"OTCCell" forIndexPath:indexPath];
    if (self.items.allKeys.count == 0) {
        return nil;
    }
    
    if(showingDetails){
        OneTimeCert* cert = (OneTimeCert*)(((NSArray*)[self.items valueForKey:self.items.allKeys[currentSection]])[indexPath.row]);
        cell.textLabel.text = cert.certID;
        
        if (cert.dateUsed == nil || [cert.dateUsed isEqualToString:@""]) {
            cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"For %@\nnot used",nil),cert.otherEmail];
            cell.imageView.image = [UIImage imageNamed:@"doubleLockBig"];
        }else{
            if (cert.expirationDate == nil || [cert.expirationDate isEqualToString:@""]) {
                cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"For %@\nused on %@",nil),cert.otherEmail, cert.dateUsed];
                cell.imageView.image = [UIImage imageNamed:@"doubleLockBigUsed"];
            }else{
                cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"For %@\nused on %@\nexpires on %@",nil),cert.otherEmail, cert.dateUsed, cert.expirationDate];
                cell.imageView.image = [UIImage imageNamed:@"doubleLockBigExp"];
            }
        }
        
        cell.accessoryType = UITableViewCellAccessoryNone;
    }else{
        cell.textLabel.text = self.items.allKeys[indexPath.section];
        // Get the last use time
        NSString* key = self.items.allKeys[indexPath.section];
        NSString* lastUsed = @"";
        if(key){
            OneTimeCert* cert = [self.items objectForKey:key][0];
            lastUsed = cert.dateUsed;
        }
        if ([lastUsed isEqualToString:@""]) {
            cell.detailTextLabel.text = self.topItems[indexPath.section];
        }else{
            cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@\nLast use on %@",nil), self.topItems[indexPath.section],lastUsed];
        }
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.imageView.image = [UIImage imageNamed:@"doubleLockBig"];
    }
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return showingDetails?((NSArray*)[self.items valueForKey:self.items.allKeys[currentSection]]).count:1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    if (self.items.count > 0) {
        self.noData.hidden = YES;
    }else{
        self.noData.hidden = NO;
    }
    if (showingDetails) {
        return 1;
    }
    return self.items.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(!showingDetails)return nil;
    if(currentSection >= self.items.allKeys.count) return @"";
    NSArray* sectionItems = [self.items valueForKey:self.items.allKeys[currentSection]];
    int used = 0;
    for (OneTimeCert* cert in sectionItems) {
        if (!(cert.dateUsed == nil || [cert.dateUsed isEqualToString:@""])) {
            used++;
        }
    }
    NSString* header;
    if (used > 0) {
        header = [NSString stringWithFormat:@"%@, used %i of %lu", self.items.allKeys[currentSection], used, (unsigned long)sectionItems.count];
    }else{
        header = [NSString stringWithFormat:@"%@, %lu available", self.items.allKeys[currentSection], (unsigned long)sectionItems.count];
    }
    return header;//@"Header";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"";
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(showingDetails)return;
    showingDetails = YES;
    currentSection = (int)indexPath.section;
    
    [UIView transitionWithView: self.tableView
                      duration: 0.45f
                       options: UIViewAnimationOptionTransitionCrossDissolve
                    animations: ^(void)
        {
            [self.tableView reloadData];
        }
                    completion: nil
     ];
    
    // TODO: add buttons to delete all and resend certs
    [self setToolbarItems:[NSArray arrayWithObjects:deleteAllButton, resendButton, editButton, flexibleItem, doneButton, nil]];
    
}

// Automatic dimension with subtitle cell type does not work with iOS, lower than 11
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")){
        return UITableViewAutomaticDimension;
    }else{
        return 80;
    }
}

//-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    return 80;
//}

//- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
//    <#code#>
//}
//
//- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection {
//    <#code#>
//}
//
//- (void)preferredContentSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container {
//    <#code#>
//}
//
//- (CGSize)sizeForChildContentContainer:(nonnull id<UIContentContainer>)container withParentContainerSize:(CGSize)parentSize {
//    <#code#>
//}
//
//- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:(nonnull id<UIContentContainer>)container {
//    <#code#>
//}
//
//- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator {
//    <#code#>
//}
//
//- (void)willTransitionToTraitCollection:(nonnull UITraitCollection *)newCollection withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator {
//    <#code#>
//}
//
//- (void)didUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context withAnimationCoordinator:(nonnull UIFocusAnimationCoordinator *)coordinator {
//    <#code#>
//}
//
//- (void)setNeedsFocusUpdate {
//    <#code#>
//}
//
//- (BOOL)shouldUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context {
//    <#code#>
//}
//
//- (void)updateFocusIfNeeded {
//    <#code#>
//}

@end
