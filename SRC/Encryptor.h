//
//  Encryptor.h
//  SenseMail2
//
//  Created by Sergey on 03.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Encryptor : NSObject{
    NSData* currentKey;
    NSData* currentSalt;
    NSData* headerSalt;
    NSData* signKey;
}

-(id)initWithKey:(NSString*)key salt:(NSString*)salt;
-(id)initWithSimpleKey:(NSString*)key;
-(id)initWithStrongerKey:(NSString*)key salt:(NSString*)salt;

-(NSData*)encryptAESString:(NSString*)input;
-(NSString*)decryptAESString:(NSData*)input;

-(NSData*)encryptAESData:(NSData*)input;
-(NSData*)decryptAESData:(NSData*)input;

-(NSString*)base64FromData:(NSData*)data;
-(NSData*)dataFromBase64:(NSString*)string;

-(NSString*)encryptToBase64:(NSString*)input;
-(NSString*)decryptFromBase64:(NSString*)input;

+(NSString*)getHashForString:(NSString*)item;
+(NSString*)generateCert;
+(NSString*)generateSalt8Bytes;

@end
