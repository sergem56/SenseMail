//
//  FolderInfo.h
//  SenseMailShare
//
//  Created by Sergey on 29.07.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonStuff.h"

@interface FolderInfo : NSObject

@property (nonatomic, strong) NSString* folderPath;
@property (nonatomic, assign) boxTypes folderType;
@property (nonatomic, assign) int unseenCount;
@property (nonatomic, assign) int totalCount;

@end
