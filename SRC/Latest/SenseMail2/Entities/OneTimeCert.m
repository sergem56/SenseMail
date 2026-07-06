//
//  OneTimeCert.m
//  SenseMailShare
//
//  Created by Sergey on 12.07.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

#import "OneTimeCert.h"

@implementation OneTimeCert

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [aCoder encodeObject:self.bundleID forKey:@"bundleID"];
    [aCoder encodeObject:self.certID forKey:@"certID"];
    [aCoder encodeObject:self.certData forKey:@"certData"];
    [aCoder encodeObject:self.dateUsed forKey:@"dateUsed"];
    [aCoder encodeObject:self.expirationDate forKey:@"expirationDate"];
    [aCoder encodeObject:self.yourEmail forKey:@"yourEmail"];
    [aCoder encodeObject:self.otherEmail forKey:@"otherEmail"];
    [aCoder encodeObject:self.yourEmailHash forKey:@"yourEmailHash"];
    [aCoder encodeObject:self.otherEmailHash forKey:@"otherEmailHash"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    if(self = [super init]){
        self.bundleID = [aDecoder decodeObjectForKey:@"bundleID"];
        self.certID = [aDecoder decodeObjectForKey:@"certID"];
        self.certData = [aDecoder decodeObjectForKey:@"certData"];
        self.dateUsed = [aDecoder decodeObjectForKey:@"dateUsed"];
        self.expirationDate = [aDecoder decodeObjectForKey:@"expirationDate"];
        self.yourEmail = [aDecoder decodeObjectForKey:@"yourEmail"];
        self.otherEmail = [aDecoder decodeObjectForKey:@"otherEmail"];
        self.yourEmailHash = [aDecoder decodeObjectForKey:@"yourEmailHash"];
        self.otherEmailHash = [aDecoder decodeObjectForKey:@"otherEmailHash"];
    }
    return self;
}

-(NSMutableString*)getCertString
{
    
    return [NSMutableString stringWithString: [self.certData base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength]];
}

-(NSDate*)getUsedDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [dateFormatter dateFromString:self.dateUsed];
}

-(NSDate*)getExpirationDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [dateFormatter dateFromString:self.expirationDate];
}

+(NSString*)getStringForDate:(NSDate*)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [dateFormatter stringFromDate:date];
}

+(NSDate*)getDateForString:(NSString*)dateString
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    return [dateFormatter dateFromString:dateString];
}

@end
