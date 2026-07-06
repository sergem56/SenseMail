//
//  MessageViewInteractor.h
//  SenseMail2
//
//  Created by Sergey on 30.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShortMessageEntity.h"
#import "FullMessageEntity.h"
#import "CommonStuff.h"

@interface MessageViewInteractor : NSObject <AsyncLoader>

-(void)markMessageAsRead:(ShortMessageEntity*)item;

-(FullMessageEntity*)getFullMessageFor:(ShortMessageEntity*)item PIN:(NSString*)pin;

-(void)requestFullMessageFor:(ShortMessageEntity*)item PIN:(NSString*)pin;

-(BOOL)saveAllAttachments:(FullMessageEntity*)item;

-(void)addContactFor:(NSString*)name address:(NSString*)address;

@end
