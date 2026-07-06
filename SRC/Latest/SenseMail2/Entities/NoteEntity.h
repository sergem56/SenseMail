//
//  NoteEntity.h
//  SenseMail2
//
//  Created by Sergey on 08.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NoteEntity : NSObject <NSCopying>

@property (nonatomic, strong) NSString* uid;
@property (nonatomic, strong) NSDate* date;
@property (nonatomic, strong) NSString* dateString;
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSString* body;

@end
