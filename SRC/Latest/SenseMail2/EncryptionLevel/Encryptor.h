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
    //NSData* currentSalt;
    //NSData* headerSalt;
    NSData* signKey;
}

@property (nonatomic, assign) BOOL isMail;
#ifdef STRONG
@property (nonatomic, strong) NSFileHandle* file;

#endif

-(id)initWithKey:(id)key; //salt:(NSString*)salt;
-(id)initWithMutableKey:(id)key mutations:(UInt32) nMutations;
-(id)initWithSimpleKey:(id)key;
-(id)initWithStrongerKey:(id)key;// salt:(NSString*)salt;

-(void)clearKeys;

-(NSData*)encryptAESString:(NSString*)input;
-(NSMutableString*)decryptAESString:(NSData*)input;

-(NSData*)encryptAESData:(NSData*)input;
-(NSData*)decryptAESData:(NSData*)input;

-(NSMutableString*)base64FromData:(NSData*)data;
-(NSData*)dataFromBase64:(NSString*)string;

-(NSMutableString*)encryptToBase64:(NSString*)input;
-(NSMutableString*)decryptFromBase64:(NSString*)input;

#ifdef STRONG
-(bool)shuffleKeyFiles:(NSString*)fileName;
#endif

+(NSString*)getHashForString:(NSString*)item;
+(NSString*)getSlowHashForString:(NSString*)item;
#if !LITE
+(NSString*)generateCert:(id)caller;
#endif
+(NSString*)generateSalt8Bytes;

+(NSString*)generateSimplePassword:(int)len;
+(NSString*)generatePassword:(int)len;
+(NSString*)generatePassword:(int)len simple:(BOOL)simple;
+(NSString*)generatePhrase:(int)len;
+(NSString*)generateWord:(int)len;

+(NSMutableArray*)makeCertsFromRawData:(NSData*)data;
+(NSMutableArray*)make100CertsFromRawData:(NSData*)data;

+(NSString*)getUUIDofLength:(int)len;
+(NSString*)getTheNumberBase26:(int)number;
+(int)intFromBase26:(NSString*)str;
+(NSString*)getTheNumberBase36:(int)number;
+(int)intFromBase36:(NSString*)str;

+(NSString*)getUUIDHashForString:(NSString*)item;

@end
