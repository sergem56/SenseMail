//
//  NoteEntity.m
//  SenseMail2
//
//  Created by Sergey on 08.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "NoteEntity.h"

@implementation NoteEntity

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] alloc] init];
    
    if (copy) {
        // Copy NSObject subclasses
        [copy setTitle:[self.title copyWithZone:zone]];
        [copy setBody:[self.body copyWithZone:zone]];
        [copy setDate:[self.date copyWithZone:zone]];
        [copy setUid:[self.uid copyWithZone:zone]];
        [copy setDateString: [self.dateString copyWithZone:zone]];
    }
    
    return copy;
}

@end
