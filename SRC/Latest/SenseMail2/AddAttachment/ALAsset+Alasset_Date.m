//
//  ALAsset+Alasset_Date.m
//  SenseMail2
//
//  Created by Sergey on 09.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "ALAsset+Alasset_Date.h"

@implementation ALAsset (Alasset_Date)

- (NSDate *) date
{
    return [self valueForProperty:ALAssetPropertyDate];
}

@end
