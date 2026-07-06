//
//  MessageViewRouter.h
//  SenseMail2
//
//  Created by Sergey on 31.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#ifndef SenseMail2_MessageViewRouter_h
#define SenseMail2_MessageViewRouter_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
//#import "GlobalRouter.h"

@class GlobalRouter;
@class ShortMessageEntity;
@class MessageViewPresenter;
@class FullMessageEntity;
@class MessageViewInteractor;
@class DataManager;
@class DataStorage;

@interface MessageViewRouter : NSObject{
    MessageViewPresenter* presenter;
    ShortMessageEntity* curMessage;
    UINavigationController* nav;
    BOOL needUpdateOnExit;
}

@property (nonatomic, strong) MessageViewInteractor* interactor;
@property (nonatomic, strong) DataManager* manager;
@property (nonatomic, strong) DataStorage* dataStore;

-(void)showMessageInNavController:(UINavigationController*)vc message:(ShortMessageEntity*)message;
-(void)finished;

-(void)wantReplyToMessage:(FullMessageEntity*)item;
-(void)wantForwardMessage:(FullMessageEntity*)item;
-(void)wantMarkMessage:(FullMessageEntity*)item;
-(void)wantDeleteMessage:(FullMessageEntity*)item;
-(void)wantShowAttachment:(NSObject*)item;

-(void)messageReceivedCallback:(FullMessageEntity*)message error:(NSString*)error;

@end

#endif