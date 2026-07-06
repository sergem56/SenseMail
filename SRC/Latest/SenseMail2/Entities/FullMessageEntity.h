//
//  FullMessageEntity.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ShortMessageEntity.h"

@interface FullMessageEntity : ShortMessageEntity

@property (nonatomic) NSString* messageBody;

// These are ALAssets* entities for outgoing mail and NSString* path to
// temp files for incoming messsage to save memory
@property (nonatomic) NSMutableArray* attachments;

@property (nonatomic, assign) BOOL readyToSend;
@property (nonatomic, assign) BOOL doNotCheckServerCertificate;

-(id)initWithShortMessage:(ShortMessageEntity*)shortMessage;

@end
