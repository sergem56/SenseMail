//
//  AddressBookEntity.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AddressBookEntity : NSObject <NSCopying>

@property (nonatomic, strong) NSString* uid;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* address;
@property (nonatomic, strong) NSString* note;
@property (nonatomic, assign) BOOL key;
@property (nonatomic, assign) BOOL isGroup;
@property (nonatomic, strong) NSString* groupID;

@end
