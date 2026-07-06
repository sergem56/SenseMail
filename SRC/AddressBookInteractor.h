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

@interface AddressBookInteractor : NSObject <UIAlertViewDelegate, userInfoNotificationReceiver>{
    FullMessageEntity* messageTo;
}

-(NSMutableArray*)getBook:(NSString*)pin groupsOnly:(BOOL)gOnly;
-(BOOL)saveBook:(NSArray*)book pin:(NSString*)pin;

-(NSMutableArray*)addItemToBook:(AddressBookEntity*)item;

-(void)sendCertificateForAddress:(NSString*)address existing:(BOOL)existing;
-(void)sendMessageForAddress:(NSString*)address;

-(BOOL)deleteCertFor:(NSString*)address;

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;

@end
