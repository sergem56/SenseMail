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
    NSString* addressToDelCert;
}

//@property (nonatomic, assign) BOOL hideAddButtons;

-(AddressBookViewController*)showBook :(NSMutableString*)pin;
-(AddressBookViewController*)showBook :(NSMutableString*)pin groupsOnly:(BOOL)gOnly;
-(BOOL)needSaveBook;
-(BOOL)needSaveBook:(NSArray*)book pin:(NSMutableString*)pin;
-(void)needAddItemToBook:(AddressBookEntity*)item;

-(void)needShowAddItem;
-(void)needEditItem:(AddressBookEntity*)item;
-(AddViewController*)showAddItem:(AddressBookEntity*)item;

-(void)needNewMailTo:(AddressBookEntity*)recipient;

#if !LITE
-(void)needToSendCertTo:(NSString*)address existing:(BOOL)existing;
-(BOOL)needDeleteCertFor:(NSString*)address;
#endif

-(void)needUpdateList;
-(void)deleteItem:(AddressBookEntity*)item;

-(void)filterGroupAndShow:(NSString*)group;
-(void)removeContactFromGroup:(AddressBookEntity*)item fromGroup:(NSString*)group;

@end
