//
//  AddressBookInteractor.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CommonStuff.h"

@class AddressBookEntity;
@class FullMessageEntity;

@interface AddressBookInteractor : NSObject </*UIAlertViewDelegate,*/ userInfoNotificationReceiver>{
    FullMessageEntity* messageTo;
}

-(NSMutableArray*)getBook:(NSMutableString*)pin groupsOnly:(BOOL)gOnly;
-(BOOL)saveBook:(NSArray*)book pin:(NSMutableString*)pin;
-(BOOL)deleteItemFromBook:(AddressBookEntity*)item;
    
-(NSMutableArray*)addItemToBook:(AddressBookEntity*)item;

//-(void)sendCertificateForAddress:(NSString*)address existing:(BOOL)existing;
-(void)sendMessageForAddress:(NSString*)address;

#if !LITE
-(BOOL)deleteCertFor:(NSString*)address;
#endif
//- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;

@end
