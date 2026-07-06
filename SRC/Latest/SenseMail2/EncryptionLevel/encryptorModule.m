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

#include "TapGeneratorViewController.h"
#include "CertExchangeViewController.h"

@implementation Encryptor

// Number of rounds to get the key and salt. These would take about 0.08 seconds altogether on
// MacBook Pro - too slow to bruteforce. Need to check how long it would take on iPhone 4S.
// ADD:
// 1 sec on iPhone 4S requires about 50 000 rounds.
#define rounds 88888
#define saltRounds 88
#define MIN_GZIP_LENGTH 128

+(NSString*)getHashForString:(NSString*)item
{
    if (item == nil || [item isEqualToString:@""]) {
        return @"";
    }
    uint8_t hash[32];
    NSData* data = [[item lowercaseString] dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA256(data.bytes, (CC_LONG)data.length, hash);
    
    return [[NSData dataWithBytes:&hash length:32] base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
}

+(NSString*)generateCertInBG
{
#define certLength 32
    
    dispatch_semaphore_t semap = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_main_queue(), ^{
        [TapGeneratorViewController showTapDialog:semap];
    });
    dispatch_semaphore_wait(semap, DISPATCH_TIME_FOREVER);
    
    NSMutableData* userInput = [TapGeneratorViewController getResult];
    if (userInput == nil) {
        return nil;//@"---";
    }
    
    [CommonProcs showProgressWithTitle:1 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Processing...",nil) stopButton:NO];
    
    uint8_t salt[certLength];
    int cpRet = SecRandomCopyBytes(kSecRandomDefault, certLength, salt);
    if(cpRet == -1){
        arc4random_buf(salt, sizeof(salt));
    }
    
    uint8_t retBytes[certLength];
    CCKeyDerivationPBKDF(kCCPBKDF2, (const char*)userInput.bytes, userInput.length, (const uint8_t*)&salt, sizeof(salt), kCCPRFHmacAlgSHA512, 5*rounds, (uint8_t*)&retBytes, sizeof(retBytes));
    
    NSData* ret = [NSData dataWithBytes:&retBytes length:sizeof(retBytes)];
    NSString* retBase = [ret base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
    
    [CommonProcs hideProgress];
    
    return retBase;
}

+(NSString*) generateCert:(id)caller
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString* ret = [Encryptor generateCertInBG];
        if ([caller respondsToSelector:@selector(setCert:keepOld:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [caller setCert:ret keepOld:ret==nil];
            });
        }
    });
    
    return nil;
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

-(id)initWithKey:(NSString*)key
{
    if(self = [super init])
    {
        NSArray* keys = [self makeKey:key roundsToGo:rounds];
        currentKey = [keys objectAtIndex:0];
        signKey = [keys objectAtIndex:1];
    }
    
    return self;
}

-(id)initWithSimpleKey:(NSString*)key
{
    if(self = [super init])
    {
        NSArray* keys = [self makeKey:key roundsToGo:10];
        currentKey = [keys objectAtIndex:0];
        signKey = [keys objectAtIndex:1];
    }
    
    return self;
}

-(id)initWithStrongerKey:(NSString*)key
{
    if(self = [super init])
    {
        NSArray* keys = [self makeKey:key roundsToGo:rounds*3];
        currentKey = [keys objectAtIndex:0];
        signKey = [keys objectAtIndex:1];
    }
    
    return self;
}

#pragma mark Keys
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
    
    NSMutableString* saltInput = [NSMutableString stringWithString:[key uppercaseString]];
    
    NSData* inputData = [key dataUsingEncoding:NSUTF8StringEncoding];
    NSData* inputSaltData = [saltInput dataUsingEncoding:NSUTF8StringEncoding];
    
    CC_SHA256(inputSaltData.bytes, (CC_LONG)inputSaltData.length, salt);
    CC_SHA256(salt, 32, salt);
    //NSLog(@"Salt=%@",[self getHex:[NSMutableData dataWithBytes:&salt length:32]]);
    
    // How many rounds to use so that it takes 0.05s ? On desktop mac it's about 50.000 rounds
    //int rounds2 = CCCalibratePBKDF(kCCPBKDF2, inputData.length, 32, kCCPRFHmacAlgSHA512, 32, 1000); NSLog(@"Need %d",rounds2);
    
    uint8_t retBytes[64];
    CCKeyDerivationPBKDF(kCCPBKDF2, inputData.bytes, inputData.length, (const uint8_t*)&salt, 32, kCCPRFHmacAlgSHA512, roundsToGo, (uint8_t*)&retBytes, 64);
    
    // Here is a problem: we use half of the key to get HMAC. Later, we apply AONT. To attack the key we need to
    // unAONT the message, but to attack the HMAC, we don't need to do unAONT.
    // So, we can get a password, calculate a key and then
    // calculate HMAC and check it. If it is OK, the password is OK and we don't need our AONT... just one more HMAC...
    // In other words it is easier to attack HMAC then to attack encryption on large files. AONT is almost useless. But
    // lets keep it for the word "almost" :) AONT adds two or more AES rounds, HMAC attack needs two more hashes.
    // We can add a few more PBKDF2 rounds on HMAC key to make it harder to attack. This would matter for weak passwords -
    // use certificates instead!
    NSData* encKey = [NSData dataWithBytes:&retBytes length:32];
    NSData* sigKey = [NSData dataWithBytes:(uint8_t*)&retBytes+32 length:32];
    
    salt[0] = 0xe1;
    salt[1] = 0xe2;
    CC_SHA256(salt, 32, salt);
    int nHR = roundsToGo/10; // 8K rounds more for normal encryption
    if(nHR < 2)nHR = 2;
    CCKeyDerivationPBKDF(kCCPBKDF2, sigKey.bytes, sigKey.length, (const uint8_t*)&salt, 32, kCCPRFHmacAlgSHA256, nHR, (uint8_t*)&retBytes, 32);
    sigKey = [NSData dataWithBytes:&retBytes length:32];
    
    return @[encKey, sigKey];
}

#pragma mark --------

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
    CC_SHA256(cHMAC, CC_SHA256_DIGEST_LENGTH, cHMACHash); // Why? - compare hashes to make them equal length. anyway - why?
    
    [dataSrc getBytes:cHMACUser range:NSMakeRange(dataSrc.length-CC_SHA256_DIGEST_LENGTH, CC_SHA256_DIGEST_LENGTH)];
    CC_SHA256(cHMACUser, CC_SHA256_DIGEST_LENGTH, cHMACUserHash);
    
    for (int i = 0; i<CC_SHA256_DIGEST_LENGTH; i++) {
        if (cHMACHash[i] != cHMACUserHash[i]) {
            ret = NO;
            //break; // DO not break! remember a timing attack!
        }
    }
    return ret;
}

-(NSData*)encryptAESString:(NSString*)input
{
    NSMutableData* ret;
    // 1. Compress data
    NSMutableData* res = [self gzipDeflate: [NSMutableData dataWithData:[input dataUsingEncoding:NSUTF8StringEncoding]]];
    
    // 1-B. AONT
    res = [self doAONT:res];
    
    // 2. Encrypt in chunks
    ret = [self AES256EncryptWithKey:currentKey data:res];
    
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
    NSMutableData* res = [self AES256DecryptWithKey:currentKey data:tmp];//[NSMutableData dataWithData:input]];
    
    // 1-B
    res = [self doUnAONT:res];
    
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
    
    // 1-B. AONT
    res = [self doAONT:res];
    
    // 2. Encrypt !!! a KEY SHOULD BE 32-bytes long!!!
    ret = [self AES256EncryptWithKey:currentKey data:res];
    
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
    NSMutableData* res = [self AES256DecryptWithKey:currentKey data:[NSMutableData dataWithData:tmp]];//input]];
    
    // 1-B
    res = [self doUnAONT:res];
    
    // 2. Uncompress
    ret = [self gzipInflate:res];
    
    return ret;
}

- (NSMutableData*)gzipInflate :(NSMutableData*) data
{
    if ([data length] == 0) return data;
    
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
    
    return compressed;//[NSData dataWithData:compressed];
}

-(NSMutableData*)doAONT:(NSMutableData*) data
{
    if ([data length] == 0)
        return data;
    
    // 1. Get random key
    // 2. Encrypt with key
    // 3. Get hashes of encrypted data with counter
    // 4. XOR key and hashes
    // 5. Append p.4 to encrypted data
    
    // 1.
    NSData* rKey = [self getSalt32];
    // 2.
    NSMutableData* ret = [self AES256EncryptWithKey:rKey data:data];
    // 3 & 4
    
    uint8_t keyBlock[32];
    uint8_t dataBlock[68];
    uint8_t hashBlock[32];
    uint8_t retBlock[32];
    
    memset(&retBlock, 0, 32);
    memset(&hashBlock, 0, 32);
    [rKey getBytes:&keyBlock length:32];
    
    uLong blocks = ret.length/32;
    for (int i=0; i<blocks; i++) {
        memset(&dataBlock, 0, 68);
        [ret getBytes:&dataBlock range:NSMakeRange(i*32, 32)];
        *(uint8_t*)(&dataBlock[32]) = i;
        if (i > 0) {
            memcpy(&dataBlock[36], &hashBlock, 32);
        }
        CC_SHA256(dataBlock, 68, hashBlock);
        for (int j=0; j<32; j++) {
            retBlock[j] ^= hashBlock[j];
        }
    }
    for (int j=0; j<32; j++) {
        retBlock[j] ^= keyBlock[j];
    }
    
    [ret appendBytes:retBlock length:32];
    
    return ret;
}

-(NSMutableData*)doUnAONT:(NSMutableData*) data
{
    if (data == nil)
        return data;
    if ([data length] < 64) // this is definetely not our data and we cannot unAONT it
        return data;
    
    //NSMutableData* processed;
    // 1. Cut out the last block
    // 2. Get hashes of data, except for the last block
    // 3. XOR last block and hashes - get the key
    // 4. Decrypt with the key
    uint8_t retBlock[32];
    uint8_t dataBlock[68];
    uint8_t hashBlock[32];
    memset(&hashBlock, 0, 32);
    
    [data getBytes:&retBlock range:NSMakeRange(data.length-32, 32)];
    [data setLength:data.length-32];
    
    uLong blocks = data.length/32;
    for (int i=0; i<blocks; i++) {
        memset(&dataBlock, 0, 68);
        [data getBytes:&dataBlock range:NSMakeRange(i*32, 32)];
        *(uint8_t*)(&dataBlock[32]) = i;
        if (i > 0) {
            memcpy(&dataBlock[36], &hashBlock, 32);
        }
        CC_SHA256(dataBlock, 68, hashBlock);
        for (int j=0; j<32; j++) {
            retBlock[j] ^= hashBlock[j];
        }
    }
    
    NSMutableData* ret = [self AES256DecryptWithKey:[NSData dataWithBytes:&retBlock length:32] data:data];
    
    return ret;
}

#pragma mark Encryption
////////////////////////////////////////////////////////////////
#define kChunkSizeBytes (32)
-(NSMutableData*) doCipherWithKey:(NSData*)key salt:(NSData*)salt operation:(CCOperation)operation data:(NSMutableData*) data
{
    // The key should be 32 bytes for AES256
    char keyPtr[kCCKeySizeAES256 + 1];
    bzero(keyPtr, sizeof(keyPtr));
    
    CCCryptorRef cryptor;
    CCCryptorStatus cryptStatus = CCCryptorCreate(operation, kCCAlgorithmAES, kCCOptionPKCS7Padding,
                                                  [key bytes], kCCKeySizeAES256,
                                                  [salt bytes],
                                                  &cryptor);
    
    if (cryptStatus != kCCSuccess) {
        return FALSE;
    }
    
    size_t dataOutMoved;
    size_t dataInLength = kChunkSizeBytes;
    size_t dataOutLength = kChunkSizeBytes;//32;
    
    size_t totalLength = 0;
    size_t outputPtr = 0;   // output buffer
    NSInteger startByte;    // input buffer
    
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
        
        //if (dataOutMoved != dataOutLength) {
            //NSLog(@"dataOutMoved (%zu) != dataOutLength (%zu)", dataOutMoved, dataOutLength);
        //}
        
        if ( cryptStatus != kCCSuccess)
        {
            NSLog(@"Failed CCCryptorUpdate: %d", cryptStatus);
        }
        
        bytesRange = NSMakeRange(outputPtr, (NSUInteger) dataOutMoved);
        [data replaceBytesInRange:bytesRange withBytes:dataOut];
        totalLength += dataOutMoved;
        
        outputPtr += dataOutMoved;
    }
    
    // Finalize encryption/decryption.
    cryptStatus = CCCryptorFinal(cryptor, dataOut, dataOutLength, &dataOutMoved);
    totalLength += dataOutMoved;
    
    if ( cryptStatus != kCCSuccess)
    {
        NSLog(@"Failed CCCryptorFinal: %d", cryptStatus);
    }
    
    [data setLength:totalLength];
    
    // Add data from final op
    NSRange bytesRange = NSMakeRange(outputPtr, (NSUInteger) dataOutMoved);
    [data replaceBytesInRange:bytesRange withBytes:dataOut];
    
    CCCryptorRelease(cryptor);
    
    free(dataIn);
    free(dataOut);
    dataIn = nil;
    dataOut = nil;
    
    return data;
}

-(NSMutableString*)getHex:(NSMutableData*)data
{
    NSMutableString *sbuf = [NSMutableString stringWithCapacity:data.length*2];
    const unsigned char *buf = data.bytes;
    NSInteger i;
    for (i=0; i<data.length; ++i) {
        [sbuf appendFormat:@"%02lX", (unsigned long)buf[i]];
    }
    
    return sbuf;
}

-(NSMutableData*)getSalt
{
    NSMutableData* ret;
    
    uint8_t salt[16];
    int cpRet = SecRandomCopyBytes(kSecRandomDefault, 16, salt);
    if (cpRet == -1) {
        arc4random_buf(salt, sizeof(salt));
    }
    ret = [NSMutableData dataWithBytes:&salt length:sizeof(salt)];
    //NSLog(@"SALT = %@", [self getHex:ret]);
    
    return ret;
}

-(NSMutableData*)getSalt32
{
    NSMutableData* ret;
    
    uint8_t salt[32];
    
    int cpRet = SecRandomCopyBytes(kSecRandomDefault, 32, salt);
    if (cpRet == -1) {
        arc4random_buf(salt, sizeof(salt));
    }
    ret = [NSMutableData dataWithBytes:&salt length:sizeof(salt)];
    //NSLog(@"SALT = %@", [self getHex:ret]);
    
    return ret;
}

-(NSMutableData*)AES256EncryptWithKey:(NSData*)key data:(NSMutableData*)data
{
    if (data.length == 0) {
        return data;
    }
    
    NSMutableData* ret = [self getSalt];
    //NSLog([self getHex:ret]);
    
    //NSMutableData* retData = [self doCipherWithKey:key salt:salt operation:kCCEncrypt data:data];
    NSMutableData* retData = [self doCipherWithKey:key salt:[ret mutableCopy] operation:kCCEncrypt data:data];
    [ret appendData:retData];
    
    return ret;
}

-(NSMutableData*)AES256DecryptWithKey:(NSData*)key data:(NSMutableData*)data
{
    if (data.length == 0) {
        return data;
    }
    
    uint8_t inSalt[16];
    [data getBytes:&inSalt length:sizeof(inSalt)];
    NSMutableData* dSalt = [NSMutableData dataWithBytes:&inSalt length:sizeof(inSalt)];
    //NSLog([self getHex:dSalt]);
    
    [data replaceBytesInRange:NSMakeRange(0, 16) withBytes:NULL length:0];
    
    NSMutableData* ret = [self doCipherWithKey:key salt:dSalt operation:kCCDecrypt data:data];
    
    return ret;
}
/////////////////

#pragma mark ----------------

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
