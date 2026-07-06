//
//  MessageVeiwPresenter.h
//  SenseMail2
//
//  Created by Sergey on 30.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "MessageViewController.h"

//@class MessageViewRouter;
@class ShortMessageEntity;

@interface MessageViewPresenter : NSObject{
    MessageViewController* messageViewController;
}

@property (nonatomic) ShortMessageEntity* currentItem;

-(MessageViewController*)showMessageFor:(ShortMessageEntity*)item PIN:(NSString*)pin;
-(void)setMessage:(FullMessageEntity*)message error:(NSString*)error;

-(void)wantReplyToMessage:(FullMessageEntity*)item;
-(void)wantForwardMessage:(FullMessageEntity*)item;
-(void)wantMarkMessage:(FullMessageEntity*)item;
-(void)wantDeleteMessage:(FullMessageEntity*)item;
-(void)wantShowAttachment:(NSObject*)item;

-(BOOL)wantSaveAll:(FullMessageEntity*)item;
-(void)wantToAddContactFor:(NSString*)name address:(NSString*)address;

@end
