//
//  FullMessageEntity.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "FullMessageEntity.h"


@implementation FullMessageEntity

@synthesize messageBody, attachments, readyToSend;

-(id)init
{
    if (self = [super init]) {
    }
    return self;
}

-(id)initWithShortMessage:(ShortMessageEntity*)shortMessage
{
    if (self = [super init]) {
        
    }
    return self;
}


@end
