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

@interface ComposeMessagePresenter : NSObject <CanGetAddressFromBook, UIActionSheetDelegate, AddAttachmentReceiver>{
    ComposeMessageViewController* viewController;
}

-(ComposeMessageViewController*)showMessage:(FullMessageEntity*)message;
-(void)attachmentTapped:(int)ind;
-(BOOL)needSendMessage:(FullMessageEntity*)message pin:(NSString*)pin;

-(void)needToAddAttachment;
-(void)needAddress;

-(void)sendingResult:(NSString*)result;

@end
