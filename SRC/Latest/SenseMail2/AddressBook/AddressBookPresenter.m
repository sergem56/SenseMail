//
//  AddressBookPresenter.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "AddressBookPresenter.h"
#import "AddressBookViewController.h"
#import "AddressBookInteractor.h"
#import "AddViewController.h"
#import "GlobalRouter.h"
#import "AddressBookEntity.h"
//#import "FullMessageEntity.h"
#import "CommonProcs.h"

AddressBookInteractor* interactor;

@implementation AddressBookPresenter

-(AddressBookViewController*)showBook :(NSMutableString*)pin
{
    return [self showBook:pin groupsOnly:NO];
}

-(AddressBookViewController*)showBook :(NSMutableString*)pin groupsOnly:(BOOL)gOnly
{
    AddressBookInteractor* addrIn = [[AddressBookInteractor alloc] init];
    NSMutableArray* book = [addrIn getBook :pin groupsOnly:gOnly];
    
    if(viewController == nil)
    {
        viewController = [[AddressBookViewController alloc] initWithNibName:@"AddressBookViewController" bundle:nil];
    }
    
    //viewController.presenter = self;
    viewController.book = book;//[NSMutableArray arrayWithArray:book];
    [viewController setCurrentBook];
    
    return viewController;
}

// Add item to group - show filtered list of items that are not in the group yet
-(void)filterGroupAndShow:(NSString*)group
{
    NSMutableArray* filteredBook = [[NSMutableArray alloc] init];
    
    
    id<CanGetAddressFromBook> callerID;
    if (![group isEqualToString:@""]) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.groupID contains[c] %@", group];
        [filteredBook addObjectsFromArray:[viewController.book filteredArrayUsingPredicate:predicate]];
        oldBook = viewController.book;
        
        if(groupViewController == nil)
        {
            groupViewController = [[AddressBookViewController alloc] initWithNibName:@"AddressBookViewController" bundle:nil];
        }
        
        //groupViewController.presenter = self;
        groupViewController.book = filteredBook;
        [groupViewController setCurrentBook];
        
        groupViewController.showingGroup = YES;
        [groupViewController setCurrentGroup:group];
        callerID = nil;
        [groupViewController enableAdding:NO];
        groupViewController.addingToGroup = NO;
        [[[GlobalRouter sharedManager] getBookRouter] showGroupBook:groupViewController toGroup:callerID];
    }else{
        // show all
        if(addToGroupViewController == nil)
        {
            addToGroupViewController = [[AddressBookViewController alloc] initWithNibName:@"AddressBookViewController" bundle:nil];
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"NOT SELF.groupID contains[c] %@ AND SELF.isGroup == NO", groupViewController.currentGroup];
        [filteredBook addObjectsFromArray:[viewController.book filteredArrayUsingPredicate:predicate]];
        
        if (filteredBook.count == 0) {
            [CommonProcs showMessage:@"" title:NSLocalizedString(@"Nothing to add",nil)];
            //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Nothing to add",nil) message:@"" delegate:nil cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles: nil];
            //alert.tag = 10000;
            //[alert show];
            return;
        }else{
            addToGroupViewController.book = filteredBook;//viewController.book;
            [addToGroupViewController setCurrentBook];
            callerID = self;
            addToGroupViewController.addingToGroup = YES;
            addToGroupViewController.presenter = self;
            [[[GlobalRouter sharedManager] getBookRouter] showGroupBook:addToGroupViewController toGroup:callerID];
        }
    }
}

-(void)needUpdateList
{
    [viewController setCurrentBook];
}

-(BOOL)needSaveBook
{
    return [self needSaveBook:viewController.book pin:[GlobalRouter sharedManager].pin];
}

-(BOOL)needSaveBook:(NSArray*)book pin:(NSMutableString*)pin
{
    [CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Saving...", nil) stopButton:NO];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AddressBookInteractor* addrIn = [[AddressBookInteractor alloc] init];
        __block BOOL res = [addrIn saveBook:book pin:pin];
        dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs hideProgress];
            if (!res) {
                // Error
            }
        });
    });
    
    return YES;
}

-(void)needAddItemToBook:(AddressBookEntity*)item
{
    
    AddressBookInteractor* addrIn = [[AddressBookInteractor alloc] init];
    viewController.book = [addrIn addItemToBook:item];
    [viewController setCurrentBook];
}

-(void)needShowAddItem
{
#ifdef DEMO
    if (viewController.book.count >= 5) {
        [CommonProcs thisFeatureIsInFull:@"Unlimited Address Book"];
        return;
    }
#endif

    [[[GlobalRouter sharedManager] getBookRouter] showAddItem:nil];
}

-(void)needEditItem:(AddressBookEntity*)item
{
    [[[GlobalRouter sharedManager] getBookRouter] showAddItem:item];
}

-(AddViewController*)showAddItem:(AddressBookEntity*)item
{
    if(addViewController == nil)
    {
        addViewController = [[AddViewController alloc] initWithNibName:@"AddViewController" bundle:nil];
    }
    
    addViewController.presenter = self;
    addViewController.item = item;
    
    [addViewController updateItem];
    
    return addViewController;
}

-(void)needNewMailTo:(AddressBookEntity *)recipient
{
    AddressBookInteractor* addrIn = [[AddressBookInteractor alloc] init];
    [addrIn sendMessageForAddress:recipient.address];
}

#if !LITE
-(void)needToSendCertTo:(NSString *)address existing:(BOOL)existing
{
    //interactor = [[AddressBookInteractor alloc] init];
    //[interactor sendCertificateForAddress:address existing:existing];
    
    [[GlobalRouter sharedManager] needShowCertExchange: addViewController.item];//address];
}
#endif

-(void)deleteItem:(AddressBookEntity *)item
{
    //NSMutableArray* tmp = [NSMutableArray arrayWithArray:[viewController book]];
    //[tmp removeObject:item];
    //viewController.book = tmp;
    [viewController.book removeObject:item];
    if (item.isGroup) {
        for (AddressBookEntity* rec in viewController.book) {
            rec.groupID = [rec.groupID stringByReplacingOccurrencesOfString:item.name withString:@""];
            rec.groupID = [rec.groupID stringByReplacingOccurrencesOfString:@"  " withString:@" "];
        }
    }
    
    AddressBookInteractor* addrIn = [[AddressBookInteractor alloc] init];
    [addrIn deleteItemFromBook:item];
}

-(void)setToAddress:(AddressBookEntity *)address
{
    if (!address) {
        return;
    }
    address.groupID = [NSString stringWithFormat:@"%@ %@", address.groupID, groupViewController.currentGroup];
    [self needSaveBook:viewController.book pin:[GlobalRouter sharedManager].pin];
    [groupViewController.book addObject:address];
    [groupViewController setCurrentBook];
}

-(void)removeContactFromGroup:(AddressBookEntity *)item fromGroup:(NSString *)group
{
    item.groupID = [item.groupID stringByReplacingOccurrencesOfString:group withString:@""];
    item.groupID = [item.groupID stringByReplacingOccurrencesOfString:@"  " withString:@" "];
    [groupViewController.book removeObject:item];
    [self needSaveBook:viewController.book pin:[GlobalRouter sharedManager].pin];
}

#if !LITE
-(BOOL)needDeleteCertFor:(NSString *)address
{
    addressToDelCert = address;
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs askYesNoAndDoWithTitle:NSLocalizedString(@"Are you sure?",nil) text:NSLocalizedString(@"Delete certificate?",nil) blockYes:^{
            __strong __typeof__(self) strongSelf = weakSelf;
            if(strongSelf->addressToDelCert != nil){
                [CommonProcs setMessageInProgress:NSLocalizedString(@"Deleting...",nil)];
                AddressBookInteractor* addrIn = [[AddressBookInteractor alloc] init];
                [addrIn deleteCertFor:strongSelf->addressToDelCert];
                strongSelf->addressToDelCert = nil;
                [CommonProcs hideProgress];
                // Disable del cert
                strongSelf->addViewController.deleteButton.enabled = NO;
                strongSelf->addViewController.item.key = NO;
            }
        } blockNo:^{
            [CommonProcs hideProgress];
        }];
        
        /*
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure?",nil) message:NSLocalizedString(@"Delete certificate?",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"No",nil) otherButtonTitles:NSLocalizedString(@"Yes",nil),nil];
        [alert setTag:100];
        [alert show];*/
    });
    
    return YES;
}
#endif
/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100)
    {
        if (buttonIndex == 0)
        {
            [CommonProcs hideProgress];
            
        }else{
            if(addressToDelCert != nil){
                [CommonProcs setMessageInProgress:NSLocalizedString(@"Deleting...",nil)];
                AddressBookInteractor* addrIn = [[AddressBookInteractor alloc] init];
                [addrIn deleteCertFor:addressToDelCert];
                addressToDelCert = nil;
                [CommonProcs hideProgress];
                // Disable del cert
                addViewController.deleteButton.enabled = NO;
                addViewController.item.key = NO;
            }
        }
    }
}
*/

@end
