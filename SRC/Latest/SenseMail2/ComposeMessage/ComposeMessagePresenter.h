//
//  ComposeMessagePresenter.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CommonStuff.h"

@class FullMessageEntity;
@class ComposeMessageViewController;
#if !LITE
@class OneTimeCert;
#endif

@interface ComposeMessagePresenter : NSObject <CanGetAddressFromBook, UIActionSheetDelegate, AddAttachmentReceiver>{
    ComposeMessageViewController* viewController;
#if !LITE
    OneTimeCert* cert;
#endif
}

@property (nonatomic, assign) BOOL sending;

-(ComposeMessageViewController*)showMessage:(FullMessageEntity*)message;
-(void)attachmentTapped:(int)ind;
-(BOOL)needSendMessage:(FullMessageEntity*)message pin:(NSMutableString*)pin;

-(void)needToAddAttachment;
-(void)needAddress;

-(void)sendingResult:(NSString*)result;
-(void)minimizeComposerAnimated:(BOOL)animated;

-(BOOL)isMinimized;

#if !LITE
-(OneTimeCert*)checkForOTC:(FullMessageEntity*)message;
#endif

-(BOOL)checkFromAndReplyTo:(NSString*)from replyTo:(NSString*)replyTo;
-(void)restoreVC:(ComposeMessageViewController*)vc;
-(void)checkAttachmentsValidity;

@end
