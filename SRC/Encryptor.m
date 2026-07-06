//
//  Encryptor.m
//  SenseMail2
//
//  Created by Sergey on 03.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "Encryptor.h"
#include <zlib.h>
#include <CommonCrypto/CommonCrypto.h>
#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonKeyDerivation.h>
#include "CommonProcs.h"
#include "GlobalRouter.h"

@implementation Encryptor

// Number of rounds to get the key and salt. These would take about 0.08 seconds altogether on
// MacBook Pro - fucking slow to bruteforce. Need to check how long it would take on iPhone 4S.
// ADD:
// 1 sec on iPhone 4S requires about 40 000 rounds.
#define rounds 88888
#define saltRounds 88
#define MIN_GZIP_LENGTH 128

+(NSString*)getHashForString:(NSString*)item
{
    if (item == nil || [item isEqualToString:@""]) {
        return @"";
    }
    uint8_t salt[32];
    NSData* data = [[item lowercaseString] dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA256(data.bytes, (CC_LONG)data.length, salt);
    
    return [[NSData dataWithBytes:&salt length:32] base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
}

+(NSString*)generateCert
{
#define certLength 32
    
    unsigned char buf[certLength];
    arc4random_buf(buf, sizeof(buf));
    
    uint8_t salt[certLength];
    arc4random_buf(salt, sizeof(salt));
    
    uint8_t retBytes[certLength];
    CCKeyDerivationPBKDF(kCCPBKDF2, (const char*)&buf, sizeof(buf), (const uint8_t*)&salt, sizeof(salt), kCCPRFHmacAlgSHA512, rounds, (uint8_t*)&retBytes, sizeof(retBytes));
    
    NSData* ret = [NSData dataWithBytes:&retBytes length:sizeof(retBytes)];
    return [ret base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
}

+(NSString*)generateSalt8Bytes
{
    unsigned char buf[16];
    arc4random_buf(buf, sizeof(buf));
    
    uint8_t salt[16];
    arc4random_buf(salt, sizeof(salt));
    
    uint8_t retBytes[16];
    CCKeyDerivationPBKDF(kCCPBKDF2, (const char*)&buf, sizeof(buf), (const uint8_t*)&salt, sizeof(salt), kCCPRFHmacAlgSHA512, 16 /*rounds*/, (uint8_t*)&retBytes, sizeof(retBytes));
    
    NSData* ret = [NSData dataWithBytes:&retBytes length:sizeof(retBytes)];
    NSString* retStr = [ret base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
    
    retStr = [retStr stringByPaddingToLength:8 withString:retStr startingAtIndex:0];
    
    return retStr;
}

-(id)initWithKey:(NSString*)key salt:(NSString *)salt
{
    if(self = [super init])
    {
        __block NSString* oldMessage;
        //dispatch_async(dispatch_get_main_queue(), ^{
            oldMessage = [CommonProcs getMessageInProgress];
            [CommonProcs setMessageInProgress:NSLocalizedString(@"Loading key...", nil)];
        //});
        //currentKey = [self makeKey:key];
        NSArray* keys = [self makeKey:key roundsToGo:rounds];
        currentKey = [keys objectAtIndex:0];
        signKey = [keys objectAtIndex:1];
        currentSalt = [self makeSalt:salt];
        headerSalt = [self makeHeaderSalt:salt];
        
        //dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs setMessageInProgress:oldMessage];
        //});
    }
    
    return self;
}

-(id)initWithSimpleKey:(NSString*)key
{
    if(self = [super init])
    {
        //__block NSString* oldMessage;
        //dispatch_async(dispatch_get_main_queue(), ^{
            //oldMessage = [CommonProcs getMessageInProgress];
            //[CommonProcs setMessageInProgress:NSLocalizedString(@"Loading key...", nil)];
        //});
        //currentKey = [self makeSimpleKey:key];
        NSArray* keys = [self makeKey:key roundsToGo:10];
        currentKey = [keys objectAtIndex:0];
        signKey = [keys objectAtIndex:1];
        currentSalt = [self makeSimpleSalt:key];
        headerSalt = [self makeSimpleHeaderSalt:key];
        //dispatch_async(dispatch_get_main_queue(), ^{
            //[CommonProcs setMessageInProgress:oldMessage];
        //});
    }
    
    return self;
}

-(id)initWithStrongerKey:(NSString*)key salt:(NSString*)salt
{
    if(self = [super init])
    {
        __block NSString* oldMessage;
        //dispatch_async(dispatch_get_main_queue(), ^{
            oldMessage = [CommonProcs getMessageInProgress];
            [CommonProcs setMessageInProgress:NSLocalizedString(@"Loading key...", nil)];
        //});
        NSArray* keys = [self makeKey:key roundsToGo:rounds*3];
        currentKey = [keys objectAtIndex:0];
        signKey = [keys objectAtIndex:1];
        currentSalt = [self makeSalt:salt roundsToGo:saltRounds*2];
        headerSalt = [self makeHeaderSalt:key roundsToGo:saltRounds*2];
        
        //dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs setMessageInProgress:oldMessage];
        //});
    }
    
    return self;
}

// Use slow hash to get the AES key
// See http://www.codeproject.com/Articles/704865/Salted-Password-Hashing-Doing-it-Right

-(NSArray*)/*(NSData*)*/makeKey:(NSString*)key
{
    return [self makeKey:key roundsToGo:rounds];
}

-(NSArray*)/*(NSData*)*/makeSimpleKey:(NSString*)key
{
    return [self makeKey:key roundsToGo:10];
}

-(NSArray*)/*(NSData*)*/makeKey:(NSString*)key roundsToGo:(int)roundsToGo
{
    uint8_t salt[32];
    //unsigned char hashedChars2[32];
    NSData * inputData = [key dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA256(inputData.bytes, (CC_LONG)inputData.length, salt);
    //CCHmac(kCCHmacAlgSHA256, &salt, 32, (__bridge const void *)(inputData), 32, hashedChars2);
    
    // How many rounds to use so that it takes 0.05s ? On desktop mac it's about 40.000 rounds
    //int rounds2 = CCCalibratePBKDF(kCCPBKDF2, inputData.length, 32, kCCPRFHmacAlgSHA512, 32, 1000); NSLog(@"Need %d",rounds2);

    uint8_t retBytes[64];
    CCKeyDerivationPBKDF(kCCPBKDF2, inputData.bytes, inputData.length, (const uint8_t*)&salt, 32, kCCPRFHmacAlgSHA512, roundsToGo, (uint8_t*)&retBytes, 64);
    
    NSData* encKey = [NSData dataWithBytes:&retBytes length:32];
    NSData* sigKey = [NSData dataWithBytes:(uint8_t*)&retBytes+32 length:32];
    //return [NSData dataWithBytes:&retBytes length:32];
    return @[encKey, sigKey];
}

-(NSData*)makeHeaderSalt:(NSString*)key
{
    return [self makeHeaderSalt:key roundsToGo:saltRounds/2];
}

-(NSData*)makeSimpleHeaderSalt:(NSString*)key
{
    return [self makeHeaderSalt:key roundsToGo:8];
}

-(NSData*)makeHeaderSalt:(NSString*)key roundsToGo:(int)roundsToGo
{
    uint8_t salt[32];
    unsigned char data[64];
    
    NSMutableString* saltString = [NSMutableString stringWithString:[key uppercaseString]];
    NSData * inputData = [saltString dataUsingEncoding:NSUTF8StringEncoding];
    
    CC_SHA256(inputData.bytes, (CC_LONG)inputData.length, salt);
    CC_SHA512(inputData.bytes, (CC_LONG)inputData.length, data);
    
    uint8_t retBytes[32];
    // Make it lossy - use 48 bytes of 64 initial. Just to make it different from salt and unlink from the key.
    // I'm pretty sure it is redundant but anyway...
    CCKeyDerivationPBKDF(kCCPBKDF2, (const char*)&data, 48, (const uint8_t*)&salt, 32, kCCPRFHmacAlgSHA256, roundsToGo, (uint8_t*)&retBytes, 32);
    
    return [NSData dataWithBytes:&retBytes length:32];
}

-(NSData*)makeSalt:(NSString*)key
{
    return [self makeSalt:key roundsToGo:saltRounds];
}

-(NSData*)makeSimpleSalt:(NSString*)key
{
    return [self makeSalt:key roundsToGo:10];
}

-(NSData*)makeSalt:(NSString*)key roundsToGo:(int)roundsToGo
{
    uint8_t salt[32];
    unsigned char data[64];
    
    NSData* inputData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    CC_SHA256(inputData.bytes, (CC_LONG)inputData.length, salt);
    CC_SHA512(inputData.bytes, (CC_LONG)inputData.length, data);
    
    uint8_t retBytes[32];
    // Make it lossy - use 60 bytes instead of 64
    CCKeyDerivationPBKDF(kCCPBKDF2, (const char*)&data, 60, (const uint8_t*)&salt, 32, kCCPRFHmacAlgSHA512, roundsToGo, (uint8_t*)&retBytes, 32);
    
    return [NSData dataWithBytes:&retBytes length:32];
}

-(NSMutableData*)addHMAC:(NSData*)dataSrc
{
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA256, signKey.bytes, signKey.length, dataSrc.bytes, dataSrc.length, cHMAC);
    
    NSMutableData* toRet = [NSMutableData dataWithData:dataSrc];
    [toRet appendBytes:cHMAC length:CC_SHA256_DIGEST_LENGTH];
    
    //NSLog(@"Length %lu -> %lu", (unsigned long)dataSrc.length, (unsigned long)toRet.length);
    
    return toRet;
}

-(BOOL)checkHMAC:(NSData*)dataSrc
{
    if (dataSrc == nil || dataSrc.length < CC_SHA256_DIGEST_LENGTH) {
        return NO;
    }
    
    BOOL ret = YES;
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    unsigned char cHMACHash[CC_SHA256_DIGEST_LENGTH];
    unsigned char cHMACUser[CC_SHA256_DIGEST_LENGTH];
    unsigned char cHMACUserHash[CC_SHA256_DIGEST_LENGTH];
    
    //NSLog(@"Check Length %lu", (unsigned long)dataSrc.length);
    
    CCHmac(kCCHmacAlgSHA256, signKey.bytes, signKey.length, dataSrc.bytes, dataSrc.length-CC_SHA256_DIGEST_LENGTH, cHMAC);
    CC_SHA256(cHMAC, CC_SHA256_DIGEST_LENGTH, cHMACHash);
    
    [dataSrc getBytes:cHMACUser range:NSMakeRange(dataSrc.length-CC_SHA256_DIGEST_LENGTH, CC_SHA256_DIGEST_LENGTH)];
    CC_SHA256(cHMACUser, CC_SHA256_DIGEST_LENGTH, cHMACUserHash);
    
    for (int i = 0; i<CC_SHA256_DIGEST_LENGTH; i++) {
        if (cHMACHash[i] != cHMACUserHash[i]) {
            ret = NO;
            //break;
        }
    }
    return ret;
}

-(NSData*)encryptAESString:(NSString*)input
{
    NSMutableData* ret;
    // 1. Compress data
    NSMutableData* res = [self gzipDeflate: [NSMutableData dataWithData:[input dataUsingEncoding:NSUTF8StringEncoding]]];
    
    // 2. Encrypt in chunks
    ret = [self AES256EncryptWithKey:currentKey salt:currentSalt data:res];
    
    // 3. HMAC
    ret = [self addHMAC:ret];
    
    return ret;
}

-(NSString*)decryptAESString:(NSData*)input
{
    NSMutableData* ret;
    
    // 0. Check HMAC
    if (![self checkHMAC:input]) {
        return nil;
    }
    NSMutableData* tmp = [NSMutableData dataWithBytes:input.bytes length:input.length-CC_SHA256_DIGEST_LENGTH];
    
    // 1. Decrypt data
    NSMutableData* res = [self AES256DecryptWithKey:currentKey salt:currentSalt data:tmp];//[NSMutableData dataWithData:input]];
    
    // 2. Uncompress
    ret = [self gzipInflate:res];
    if (ret == nil) {
        return MESSAGE_INVALID_PWD;
    }
    
    return [[NSString alloc] initWithData:ret encoding:NSUTF8StringEncoding];
}

-(NSData*)encryptAESData:(NSData*)input
{
    NSMutableData* ret;
    // 1. Compress data
    NSMutableData* res = [self gzipDeflate: [NSMutableData dataWithData:input]];
    
    // 2. Encrypt !!! KEY SHOULD BE 32-bytes long!!!
    ret = [self AES256EncryptWithKey:currentKey salt:currentSalt data:res];
    
    // 3. HMAC
    ret = [self addHMAC:ret];
    
    return ret;
}

-(NSData*)decryptAESData:(NSData*)input
{
    // 0. Check HMAC
    if (![self checkHMAC:input]) {
        return nil;
    }
    NSMutableData* tmp = [NSMutableData dataWithBytes:input.bytes length:input.length-CC_SHA256_DIGEST_LENGTH];
    
    NSMutableData* ret;
    // 1. Decrypt data !!! KEY SHOULD BE 32-bytes long!!!
    NSMutableData* res = [self AES256DecryptWithKey:currentKey salt:currentSalt data:[NSMutableData dataWithData:tmp]];//input]];
    
    // 2. Uncompress
    ret = [self gzipInflate:res];
    
    return ret;
}

// Simple XOR'ing - should be OK, but...
-(void)processHeaders:(NSMutableData*)data
{
    // Apply headerSalt to reveal pre-defined gzip header
    unsigned char *aBuffer, *bBuffer;
    NSRange range = {0, 9};
    
    aBuffer = malloc(10);
    bBuffer = malloc(10);
    [data getBytes:aBuffer length:10];
    [headerSalt getBytes:bBuffer length:10];
    
    for (int i=0; i<10; i++) {
        aBuffer[i] ^= bBuffer[i];
    }
    [data replaceBytesInRange:range withBytes:aBuffer];
    
    // Hide last bytes
    NSRange range2 = {data.length-9, 8};
    NSRange rangeH = {20,8};
    [data getBytes:aBuffer range:range2];
    [headerSalt getBytes:bBuffer range:rangeH];
    
    for (int i=0; i<8; i++) {
        aBuffer[i] ^= bBuffer[i];
    }
    [data replaceBytesInRange:range2 withBytes:aBuffer];
    
    free(aBuffer);
    free(bBuffer);

}

// AES encryption. This one is better than simpe XOR, but makes the data grow by 6+8 bytes, but WHO CARES!
-(void)processHeaders2:(NSMutableData*)data :(CCOperation)op
{
    // Apply headerSalt to reveal pre-defined gzip header
    unsigned char *aBuffer, *bBuffer;
    
    int bytesToDo, bytesToDoEnd;
    if (op == kCCEncrypt) {
        bytesToDo = 10;
        bytesToDoEnd = 8;
    }else{
        bytesToDo = 16;
        bytesToDoEnd = 16;
    }
    NSRange range = {0,bytesToDo};

    aBuffer = malloc(16);
    bBuffer = malloc(16);
    [data getBytes:aBuffer length:bytesToDo];
    
    size_t moved = 0;
    
    // Make unique salt somehow??? From the first 2 bytes after header!
    unsigned char *sBuffer = malloc(2);
    uint8_t salt[32];
    
    @try {
        [data getBytes:sBuffer range:(NSRange){bytesToDo,2}];
    }
    @catch (NSException *exception) {
        sBuffer[0] = 8;
    }
    CC_SHA256(sBuffer, 2, salt);
    free(sBuffer);
    
    //CCCrypt(op, kCCAlgorithmAES, kCCOptionPKCS7Padding, headerSalt.bytes, 32, currentSalt.bytes, aBuffer, bytesToDo,bBuffer, 16, &moved);
    CCCrypt(op, kCCAlgorithmAES, kCCOptionPKCS7Padding, headerSalt.bytes, 32, salt, aBuffer, bytesToDo,bBuffer, 16, &moved);
    [data replaceBytesInRange:range withBytes:NULL length:0];
    [data replaceBytesInRange:NSMakeRange(0, 0) withBytes:bBuffer length:moved];
    
    // Hide last bytes
    NSRange range2 = {data.length-bytesToDoEnd-1, bytesToDoEnd};
    [data getBytes:aBuffer range:range2];
    
    CCCrypt(op, kCCAlgorithmAES, kCCOptionPKCS7Padding, headerSalt.bytes, 32, currentSalt.bytes, aBuffer, bytesToDo,bBuffer, 16, &moved);
    
    [data replaceBytesInRange:range2 withBytes:NULL length:0];
    [data replaceBytesInRange:NSMakeRange(data.length-1, 0) withBytes:bBuffer length:moved];
    
    free(aBuffer);
    free(bBuffer);
    
}


- (NSMutableData*)gzipInflate :(NSMutableData*) data
{
    if ([data length] == 0) return data;
    
    //[self processHeaders:data];
    [self processHeaders2:data :kCCDecrypt];
    
    NSUInteger full_length = [data length];
    NSUInteger half_length = [data length] / 2;
    NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
    BOOL done = NO; int status;
    z_stream strm;
    strm.next_in = (Bytef*)[data bytes];
    strm.avail_in = (uInt)[data length];
    strm.total_out = 0;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    if (inflateInit2(&strm, (15+32)) != Z_OK) return nil;
    while (!done) { // Make sure we have enough room and reset the lengths.
        if (strm.total_out >= [decompressed length]) [decompressed increaseLengthBy: half_length];
        strm.next_out = [decompressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt)([decompressed length] - strm.total_out);
        // Inflate another chunk.
        status = inflate (&strm, Z_SYNC_FLUSH);
        if (status == Z_STREAM_END)
            done = YES;
        else if (status != Z_OK)
            break;
    }
    if (inflateEnd (&strm) != Z_OK)
        return nil;
    // Set real length.
    if (done)
    {
        [decompressed setLength: strm.total_out];
        return decompressed;//[NSData dataWithData: decompressed];
    } else
        return nil;
}

- (NSMutableData*) gzipDeflate :(NSMutableData*) data
{
    if ([data length] == 0)
        return data;
    z_stream strm;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.next_in=(Bytef*)[data bytes];
    strm.avail_in = (uInt)[data length];
    // Compresssion Levels:
    // Z_NO_COMPRESSION
    // Z_BEST_SPEED
    // Z_BEST_COMPRESSION
    // Z_DEFAULT_COMPRESSION
    if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK)
        return nil;
    NSMutableData* compressed = [NSMutableData dataWithLength:16384]; // 16K chunks for expansion
    do {
        if (strm.total_out >= [compressed length])
            [compressed increaseLengthBy: 16384];
        strm.next_out = [compressed mutableBytes] + strm.total_out;
        strm.avail_out = (uInt)([compressed length] - strm.total_out);
        deflate(&strm, Z_FINISH);
    } while (strm.avail_out == 0);
    deflateEnd(&strm);
    [compressed setLength: strm.total_out];
    
    //NSLog(@"Output length is %lu", strm.total_out);
    
    // Apply headerSalt to hide pre-defined gzip header (10 bytes) and footer (8 bytes)
    // These bytes are encrypted with AES256.b
    // There is a vulnerability since the salt is used multiple times and I guess it might be abused somehow,
    // but its primary purpose is to fight a known plain-text attack, so it's OK.
    
    //[self processHeaders:compressed];
    [self processHeaders2:compressed :kCCEncrypt];
    
    return compressed;//[NSData dataWithData:compressed];
}

////////////////////////////////////////////////////////////////
#define kChunkSizeBytes (32)
-(NSMutableData*) doCipherWithKey:(NSData*)key salt:(NSData*)salt operation:(CCOperation)operation data:(NSMutableData*) data
{
    @autoreleasepool {
        // The key should be 32 bytes for AES256, will be null-padded otherwise
        char keyPtr[kCCKeySizeAES256 + 1]; // room for terminator (unused)
        bzero(keyPtr, sizeof(keyPtr));     // fill with zeroes (for padding)
        
        CCCryptorRef cryptor;
        CCCryptorStatus cryptStatus = CCCryptorCreate(operation, kCCAlgorithmAES, kCCOptionPKCS7Padding,
                                                      [key bytes], kCCKeySizeAES256,
                                                      [salt bytes],
                                                      &cryptor);
        
        if (cryptStatus != kCCSuccess) { // Handle error here
            return FALSE;
        }
        
        size_t dataOutMoved;
        size_t dataInLength = kChunkSizeBytes;
        size_t dataOutLength = kChunkSizeBytes;//32;
        
        size_t totalLength = 0; // Keeps track of the total length of the output buffer
        size_t filePtr = 0;   // Maintains the file pointer for the output buffer
        NSInteger startByte; // Maintains the file pointer for the input buffer
        
        char *dataIn = malloc(dataInLength);
        char *dataOut = malloc(dataOutLength);
        for (startByte = 0; startByte <= [data length]; startByte += kChunkSizeBytes) {
            if ((startByte + kChunkSizeBytes) > [data length]) {
                dataInLength = [data length] - startByte;
            }
            else {
                dataInLength = kChunkSizeBytes;
            }
            
            // Get the chunk to be ciphered from the input buffer
            NSRange bytesRange = NSMakeRange((NSUInteger) startByte, (NSUInteger) dataInLength);
            [data getBytes:dataIn range:bytesRange];
            cryptStatus = CCCryptorUpdate(cryptor, dataIn, dataInLength, dataOut, dataOutLength, &dataOutMoved);
            
            if (dataOutMoved != dataOutLength) {
                //NSLog(@"dataOutMoved (%zu) != dataOutLength (%zu)", dataOutMoved, dataOutLength);
            }
            
            if ( cryptStatus != kCCSuccess)
            {
                NSLog(@"Failed CCCryptorUpdate: %d", cryptStatus);
            }
            
            // Write the ciphered buffer into the output buffer
            bytesRange = NSMakeRange(filePtr, (NSUInteger) dataOutMoved);
            [data replaceBytesInRange:bytesRange withBytes:dataOut];
            totalLength += dataOutMoved;
            
            filePtr += dataOutMoved;
        }
        
        // Finalize encryption/decryption.
        cryptStatus = CCCryptorFinal(cryptor, dataOut, dataOutLength, &dataOutMoved);
        totalLength += dataOutMoved;
        
        if ( cryptStatus != kCCSuccess)
        {
            NSLog(@"Failed CCCryptorFinal: %d", cryptStatus);
        }
        
        // In the case of encryption, expand the buffer if it required some padding (an encrypted buffer will always be a multiple of 16).
        // In the case of decryption, truncate our buffer in case the encrypted buffer contained some padding
        [data setLength:totalLength];
        
        // Finalize the buffer with data from the CCCryptorFinal call
        NSRange bytesRange = NSMakeRange(filePtr, (NSUInteger) dataOutMoved);
        [data replaceBytesInRange:bytesRange withBytes:dataOut];
        
        CCCryptorRelease(cryptor);
        
        free(dataIn);
        free(dataOut);
        
        return data;
    }
}


-(NSMutableData*)AES256EncryptWithKey:(NSData*)key salt:(NSData*)salt data:(NSMutableData*)data {
    if (data.length == 0) {
        return data;
    }
    
    return [self doCipherWithKey:key salt:salt operation:kCCEncrypt data:data];
    
}

-(NSMutableData*)AES256DecryptWithKey:(NSData*)key salt:(NSData*)salt data:(NSMutableData*)data {
    if (data.length == 0) {
        return data;
    }
    
    return [self doCipherWithKey:key salt:salt operation:kCCDecrypt data:data];
    
}
/////////////////

-(NSString*)base64FromData:(NSData*)data
{
    return [data base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
}

-(NSData*)dataFromBase64:(NSString *)string
{
    if(string == nil) return nil;
    
    return [[NSData alloc] initWithBase64EncodedString:string options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

-(NSString*)encryptToBase64:(NSString*)input
{
    return [self base64FromData:[self encryptAESString:input]];
}

-(NSString*)decryptFromBase64:(NSString*)input
{
    return [self decryptAESString:[self dataFromBase64:input]];
}



@end
