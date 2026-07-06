//
//  AddressBookEntity.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "AddressBookEntity.h"

@implementation AddressBookEntity

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] alloc] init];
    
    if (copy) {
        // Copy NSObject subclasses
        [copy setName:[self.name copyWithZone:zone]];
        [copy setAddress:[self.address copyWithZone:zone]];
        [copy setNote:[self.note copyWithZone:zone]];
        [copy setUid:[self.uid copyWithZone:zone]];
        //[copy setKey:[self.key copyWithZone:zone]];
        [copy setKey: self.key];
        [copy setGroupID:[self.groupID copyWithZone:zone]];
        [copy setIsGroup:self.isGroup];
    }
    
    return copy;
}

-(NSComparisonResult)compare:(id)otherObject {
    if ([otherObject isKindOfClass:[self class]]){
        AddressBookEntity* otherItem = (AddressBookEntity*)otherObject;
        return [self.name compare:otherItem.name];
    }else
        return NSOrderedAscending;
}


@end
