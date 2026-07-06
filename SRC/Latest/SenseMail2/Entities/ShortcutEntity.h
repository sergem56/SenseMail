//
//  ShortcutEntity.h
//  SenseMailShare
//
//  Created by Sergey on 28.01.2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ShortcutEntity : NSObject

@property (nonatomic, assign) int shortcutPosition;
@property (nonatomic, strong) NSString* shortcutID;
@property (nonatomic, strong) NSString* shortcutName;
@property (nonatomic, strong) NSString* shortcutCommand;

@end

NS_ASSUME_NONNULL_END
