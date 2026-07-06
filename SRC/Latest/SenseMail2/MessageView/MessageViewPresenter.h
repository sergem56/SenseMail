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

@interface MessageViewPresenter : NSObject {// <selectedFolderReceiver> {
    MessageViewController* messageViewController;
    BOOL isMoving;
    int savedAttchments;
    dispatch_block_t alertBlock;
    int showingAttIndex;
}

@property (nonatomic) ShortMessageEntity* currentItem;
@property (nonatomic, assign) BOOL needToSendRR;

-(MessageViewController*)showMessageFor:(ShortMessageEntity*)item PIN:(NSMutableString*)pin;
-(void)setMessage:(FullMessageEntity*)message error:(NSString*)error;

-(void)wantReplyToMessage:(FullMessageEntity*)item;
-(void)wantForwardMessage:(FullMessageEntity*)item;
-(void)wantMarkMessage:(FullMessageEntity*)item;
-(void)wantDeleteMessage:(FullMessageEntity*)item;
-(void)wantShowAttachment:(NSObject*)item atIndex:(int)index;
//-(void)wantShowNextAttachment:(BOOL)nextOrPrev;

-(BOOL)wantSaveAll:(FullMessageEntity*)item;
-(void)wantToAddContactFor:(NSString*)name address:(NSString*)address;

-(void)wantShowNextMessageFor:(ShortMessageEntity*)item;
-(void)wantShowPrevMessageFor:(ShortMessageEntity*)item;

-(void)finished;
-(void)itemSaved: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *)contextInfo;

-(FullMessageEntity*)getFullMessage;
-(void)setReadFlagForFullMessage;

-(void)wantOpenURL:(NSURLRequest*)request;

-(void)switchView;

@end
