//
//  ShortcutEntity.m
//  SenseMailShare
//
//  Created by Sergey on 28.01.2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

#import "ShortcutEntity.h"

@implementation ShortcutEntity

- (id)copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] alloc] init];
    
    if (copy) {
        // Copy NSObject subclasses
        [copy setShortcutPosition:self.shortcutPosition];
        [copy setShortcutName:[self.shortcutName copyWithZone:zone]];
        [copy setShortcutCommand:[self.shortcutCommand copyWithZone:zone]];
        [copy setShortcutID:[self.shortcutID copyWithZone:zone]];
    }
    
    return copy;
}

@end
