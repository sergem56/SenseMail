//
//  ShortMessageEntity.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonStuff.h"

typedef NS_OPTIONS(NSInteger, messageFlags){
    mfNone          = 0,
    mfFavourite     = 1,
    mfDeleted       = 1 << 1,
    mfImportant     = 1 << 2,
    mfHasAttachment = 1 << 3,
    mfNew           = 1 << 4,
    mfSimple        = 1 << 5,
    mfNonEncrypted  = 1 << 6
};

@interface ShortMessageEntity : NSObject

@property (nonatomic) NSString* settingsID;
@property (nonatomic) NSString* messageID;
@property (nonatomic) NSString* fromName;
@property (nonatomic) NSString* fromAddress;
@property (nonatomic) NSString* toAddress;
@property (nonatomic) NSString* subject;
@property (nonatomic) NSDate* date;
@property (nonatomic, assign) messageFlags flags;
@property (nonatomic, assign) UInt32 size;

@property (nonatomic) encryptionType encType;
@property (nonatomic) NSString* salt;

@end
