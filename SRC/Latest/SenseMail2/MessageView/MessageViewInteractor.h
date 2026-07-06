//
//  MessageViewInteractor.h
//  SenseMail2
//
//  Created by Sergey on 30.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ShortMessageEntity.h"
#import "FullMessageEntity.h"
#import "CommonStuff.h"

@class MessageViewPresenter;

@interface MessageViewInteractor : NSObject <AsyncLoader, UIPrintInteractionControllerDelegate>
{
    UIAlertController* controller;
}

-(void)markMessageAsRead:(ShortMessageEntity*)item;

-(FullMessageEntity*)getFullMessageFor:(ShortMessageEntity*)item PIN:(NSMutableString*)pin;

-(void)requestFullMessageFor:(ShortMessageEntity*)item PIN:(NSMutableString*)pin;

-(BOOL)saveAllAttachments:(FullMessageEntity*)item caller:(MessageViewPresenter*) caller;

-(void)addContactFor:(NSString*)name address:(NSString*)address;

-(void)checkReadReceipt:(ShortMessageEntity*)message;

-(void)reEncryptMessage:(FullMessageEntity*)message;

-(void)printHTMLContent:(FullMessageEntity*)message fromRect:(CGRect)rect inView:(UIView*)inView;

@end
