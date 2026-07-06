//
//  AddressBookPresenter.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonStuff.h"
//#import "AddressBookViewController.h"

@class AddressBookViewController;
@class AddressBookEntity;
@class AddViewController;

@interface AddressBookPresenter : NSObject <CanGetAddressFromBook>{
    AddressBookViewController* viewController;
    AddressBookViewController* groupViewController;
    AddressBookViewController* addToGroupViewController;
    AddViewController* addViewController;
    NSMutableArray* oldBook;
}

-(AddressBookViewController*)showBook :(NSString*)pin;
-(AddressBookViewController*)showBook :(NSString*)pin groupsOnly:(BOOL)gOnly;
-(BOOL)needSaveBook;
-(BOOL)needSaveBook:(NSArray*)book pin:(NSString*)pin;
-(void)needAddItemToBook:(AddressBookEntity*)item;

-(void)needShowAddItem;
-(void)needEditItem:(AddressBookEntity*)item;
-(AddViewController*)showAddItem:(AddressBookEntity*)item;

-(void)needNewMailTo:(AddressBookEntity*)recipient;
-(void)needToSendCertTo:(NSString*)address existing:(BOOL)existing;
-(BOOL)needDeleteCertFor:(NSString*)address;

-(void)needUpdateList;
-(void)deleteItem:(AddressBookEntity*)item;

-(void)filterGroupAndShow:(NSString*)group;
-(void)removeContactFromGroup:(AddressBookEntity*)item fromGroup:(NSString*)group;

@end
