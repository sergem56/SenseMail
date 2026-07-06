//
//  CertEntity.h
//  SenseMailShare
//
//  Created by Sergey on 04.10.16.
//  Copyright © 2016 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CertEntity : NSObject

@property (nonatomic, strong) NSData* keyData;
//@property (nonatomic, strong) NSData* keyFrom;
@property (nonatomic, strong) NSString* forAddress;
@property (nonatomic, strong) NSDate* forDate;
@property (nonatomic, strong) NSString* note;

@end
