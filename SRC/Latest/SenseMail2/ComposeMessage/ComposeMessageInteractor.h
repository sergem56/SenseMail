//
//  ComposeMessageInteractor.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CommonStuff.h"

@class FullMessageEntity;
#if !LITE
@class OneTimeCert;
#endif

@interface ComposeMessageInteractor : NSObject <AsyncLoader>

-(BOOL)sendMessage:(FullMessageEntity*)message pin:(NSMutableString*)pin;
-(void)removeAttachmentFromMessage:(FullMessageEntity*)message attachment:(UIImage*)att;

-(void)requestSendMessageFor:(FullMessageEntity*)item PIN:(NSMutableString*)pin;

#if !LITE
-(OneTimeCert*)checkForOTC:(FullMessageEntity*)message;
#endif
@end
