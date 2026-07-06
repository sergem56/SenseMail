//
//  OneTimeCert.h
//  SenseMailShare
//
//  Created by Sergey on 12.07.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OneTimeCert : NSObject <NSCoding>

@property (nonatomic, strong) NSString* bundleID;
@property (nonatomic, strong) NSData* certData;
@property (nonatomic, strong) NSString* yourEmail;
@property (nonatomic, strong) NSString* otherEmail;
@property (nonatomic, strong) NSString* yourEmailHash;
@property (nonatomic, strong) NSString* otherEmailHash;
@property (nonatomic, strong) NSString* dateUsed; // Date as a string
@property (nonatomic, strong) NSString* certID; // non-encrypted
@property (nonatomic, strong) NSString* expirationDate; // Date as a string

-(NSMutableString*)getCertString;
-(NSDate*)getUsedDate;
-(NSDate*)getExpirationDate;
+(NSString*)getStringForDate:(NSDate*)date;
+(NSDate*)getDateForString:(NSString*)dateString;

@end
