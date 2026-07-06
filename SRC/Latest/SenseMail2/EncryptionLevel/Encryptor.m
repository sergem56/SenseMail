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
#if !LITE
#include "TapGeneratorViewController.h"
#include "CertExchangeViewController.h" //ComposeMessageViewController.h"
#endif

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
    uint8_t hash[32];
    NSData* data = [[item lowercaseString] dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA256(data.bytes, (CC_LONG)data.length, hash);
    
    return [[NSData dataWithBytes:&hash length:32] base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
}

+(NSString*)getSlowHashForString:(NSString*)item
{
    if (item == nil || [item isEqualToString:@""]) {
        return @"";
    }
    uint8_t hash[32];
    NSString* trimmedItem = [item stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSData* data = [[trimmedItem lowercaseString] dataUsingEncoding:NSUTF8StringEncoding];
    NSData* salt = [[trimmedItem uppercaseString] dataUsingEncoding:NSUTF8StringEncoding];
    
    CC_SHA256(data.bytes, (CC_LONG)data.length, hash);// Why?
    
    CCKeyDerivationPBKDF(kCCPBKDF2, data.bytes, data.length, (const uint8_t*)salt.bytes, salt.length, kCCPRFHmacAlgSHA256, 10*saltRounds, (uint8_t*)&hash, sizeof(hash));
    
    return [[NSData dataWithBytes:&hash length:32] base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
}

#if !LITE
+(NSString*)generateCertInBG
{
#define certLength 32
    
    dispatch_semaphore_t semap = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_main_queue(), ^{
        [TapGeneratorViewController showTapDialog:semap bytesToCollect:32];
    });
    dispatch_semaphore_wait(semap, DISPATCH_TIME_FOREVER);
    
    NSMutableData* userInput = [TapGeneratorViewController getResult];
    if (userInput == nil) {
        return nil;//@"---";
    }
    
    //unsigned char buf[certLength];
    //arc4random_buf(buf, sizeof(buf));
    
    [CommonProcs showProgressWithTitle:1 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Processing...",nil) stopButton:NO];
    
    uint8_t salt[certLength];
    int cpRet = SecRandomCopyBytes(kSecRandomDefault, certLength, salt);
    if(cpRet == -1){
        arc4random_buf(salt, sizeof(salt));
    }
    //arc4random_buf(salt, sizeof(salt));
    
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
    
    return nil;//@"--";
}
#endif

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

-(id)initWithKey:(id)key// salt:(NSString *)salt
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
        if(keys){
            currentKey = [keys objectAtIndex:0];
            signKey = [keys objectAtIndex:1];
        }else{
            NSLog(@"Error initializing encryptor");
        }
        //currentSalt = [self makeSalt:salt];
        //headerSalt = [self makeHeaderSalt:salt];
        
        self.isMail = NO;
        
        //dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs setMessageInProgress:oldMessage];
        //});
    }
    
    return self;
}

-(id)initWithMutableKey:(id)key mutations:(UInt32) nMutations
{
    if(self = [super init])
    {
        __block NSString* oldMessage;
        //dispatch_async(dispatch_get_main_queue(), ^{
        oldMessage = [CommonProcs getMessageInProgress];
        [CommonProcs setMessageInProgress:NSLocalizedString(@"Loading key...", nil)];
        //});
        //currentKey = [self makeKey:key];
        NSArray* keys = [self makeKey:key roundsToGo:rounds+nMutations];
        currentKey = [keys objectAtIndex:0];
        signKey = [keys objectAtIndex:1];
        //currentSalt = [self makeSalt:salt];
        //headerSalt = [self makeHeaderSalt:salt];
        
        self.isMail = NO;
        
        //dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs setMessageInProgress:oldMessage];
        //});
    }
    
    return self;
}

-(id)initWithSimpleKey:(id)key
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
        //currentSalt = [self makeSimpleSalt:key];
        //headerSalt = [self makeSimpleHeaderSalt:key];
        
        self.isMail = NO;
        //dispatch_async(dispatch_get_main_queue(), ^{
            //[CommonProcs setMessageInProgress:oldMessage];
        //});
    }
    
    return self;
}

-(id)initWithStrongerKey:(id)key// salt:(NSString*)salt
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
        //currentSalt = [self makeSalt:salt roundsToGo:saltRounds*2];
        //headerSalt = [self makeHeaderSalt:key roundsToGo:saltRounds*2];
        
        self.isMail = NO;
        //dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs setMessageInProgress:oldMessage];
        //});
    }
    
    return self;
}

-(void)clearKeys
{
    // overwrite keys
    @try {
        [CommonProcs wipeData:currentKey];
        [CommonProcs wipeData:signKey];
        // Below memset works fine! Just moved it to CommonProcs for reuse
        //memset((void *)[currentKey bytes], 0, currentKey.length);
        //memset((void *)[signKey bytes], 0, signKey.length);
    } @catch (NSException *exception) {
#if DEBUG
        NSLog(@"Exception overwriting keys %@", exception.description);
#endif
    }
    
    currentKey = nil;
    signKey = nil;
}

-(void)dealloc
{
    [self clearKeys];
}

// Use slow hash to get the AES key
// See http://www.codeproject.com/Articles/704865/Salted-Password-Hashing-Doing-it-Right

-(NSArray*)/*(NSData*)*/makeKey:(id)key
{
    return [self makeKey:key roundsToGo:rounds];
}

-(NSArray*)/*(NSData*)*/makeSimpleKey:(id)key
{
    return [self makeKey:key roundsToGo:10];
}

// Key might be NSString or NSData
-(NSArray*)/*(NSData*)*/makeKey:(id)key roundsToGo:(int)roundsToGo
{
    if (!key) {
        return nil;
    }
    uint8_t salt[32];
    //unsigned char hashedChars2[32];
    
    NSMutableString* saltInput = [NSMutableString stringWithString:[key uppercaseString]];
    
    NSData* inputData;
    if ([key isKindOfClass:[NSString class]]) {
        inputData = [key dataUsingEncoding:NSUTF8StringEncoding];
    }else{ // NSData
        inputData = key;
    }
    
    NSData* inputSaltData = [saltInput dataUsingEncoding:NSUTF8StringEncoding];
    
    CC_SHA256(inputSaltData.bytes, (CC_LONG)inputSaltData.length, salt);
    CC_SHA256(salt, 32, salt);
        //NSLog(@"Salt=%@",[self getHex:[NSMutableData dataWithBytes:&salt length:32]]);
    
    //CCHmac(kCCHmacAlgSHA256, &salt, 32, (__bridge const void *)(inputData), 32, hashedChars2);
    
    // How many rounds to use so that it takes 0.05s ? On desktop mac it's about 40.000 rounds
    // New data:
    //  - iPhone 6 ~550K rounds for a second
    //  - iPhone XR ~1200K rounds
    //int rounds2 = CCCalibratePBKDF(kCCPBKDF2, inputData.length, 32, kCCPRFHmacAlgSHA512, 64, 1000); NSLog(@"Need %d rounds for a sec",rounds2);

    uint8_t retBytes[64];
    CCKeyDerivationPBKDF(kCCPBKDF2, inputData.bytes, inputData.length, (const uint8_t*)&salt, 32, kCCPRFHmacAlgSHA512, roundsToGo, (uint8_t*)&retBytes, 64);
    
    // Here is a problem: we use half of the key to get HMAC. Later, we apply AONT. To attack the key we need to
    // unAONT the message, but to attack the HMAC, we don't need to do unAONT.
    // So, we can get a password, calculate a key and then
    // calculate HMAC and check it. If it is OK, the password is OK and we don't need our AONT... just one more HMAC...
    // In other words it is easier to attack HMAC then to attack encryption on large files. AONT is almost useless. But
    // lets keep it for the word "almost" :) AONT adds two or more AES rounds, HMAC attack needs two more hashes.
    // We can add a few more PBKDF2 rounds on HMAC key to make it harder to attack. This would matter for weak passwords -
    // use certificates!
    NSData* encKey = [NSData dataWithBytes:&retBytes length:32];
    NSData* sigKey = [NSData dataWithBytes:(uint8_t*)&retBytes+32 length:32];
    
    
    // Will do it in the next release, put it to the settings page,
    // something like "Additional HMAC protection rounds"
    
//#warning Breaks compatibility!
    salt[0] = 0xe1;
    salt[1] = 0xe2;
    CC_SHA256(salt, 32, salt);
    int nHR = roundsToGo/10;
    if(nHR < 2)nHR = 2;
    CCKeyDerivationPBKDF(kCCPBKDF2, sigKey.bytes, sigKey.length, (const uint8_t*)&salt, 32, kCCPRFHmacAlgSHA256, nHR, (uint8_t*)&retBytes, 32);
    sigKey = [NSData dataWithBytes:&retBytes length:32];
    
    return @[encKey, sigKey];
}

// Make a set of 32-byte certs from data
// Returns an array of 32-bytes NSData certs
+(NSMutableArray*)makeCertsFromRawData:(NSData*)data
{
    NSMutableArray* ret = [[NSMutableArray alloc] init];
    
    uint8_t salt[32];
    uint8_t keyRawData[32];
    uint8_t cert[32];
    
    memset(&keyRawData, 0, 32);
    memset(&cert, 0, 32);
    arc4random_buf(salt, sizeof(salt));
    int i=0;
    while(i<data.length){
        [data getBytes:&keyRawData range:NSMakeRange(i,data.length-i<32?data.length-i:32)];
        CCKeyDerivationPBKDF(kCCPBKDF2, (const char*)&keyRawData, 32, (const uint8_t*)&salt, 32, kCCPRFHmacAlgSHA256, rounds, (uint8_t*)&cert, 32);
        i+=32;
        [ret addObject:[NSData dataWithBytes:&cert length:32]];
    }
    
    return ret;
}

// Make a set of 32-byte certs from data
// Returns an array of 32-bytes NSData certs
+(NSMutableArray*)make100CertsFromRawData:(NSData*)data
{
    NSMutableArray* ret = [[NSMutableArray alloc] init];
    
    uint8_t salt[32];
    uint8_t keyRawData[32];
    uint8_t cert[32];
    
    memset(&keyRawData, 0, 32);
    memset(&cert, 0, 32);
    arc4random_buf(salt, sizeof(salt));
    int i=0;
    uint rawDataPerCert = (uint)data.length/100;
    
    while(i<100){
        if(SecRandomCopyBytes(kSecRandomDefault, 32, &keyRawData) != 0){
            memset(&keyRawData, 0, 32);
        }
        [data getBytes:&keyRawData range:NSMakeRange(i*rawDataPerCert,rawDataPerCert>32?32:rawDataPerCert)];
        CCKeyDerivationPBKDF(kCCPBKDF2, (const char*)&keyRawData, 32, (const uint8_t*)&salt, 32, kCCPRFHmacAlgSHA256, rounds, (uint8_t*)&cert, 32);
        i++;
        [ret addObject:[NSData dataWithBytes:&cert length:32]];
    }
    
    return ret;
}

/*
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
    
    if (key == nil) {
        key = @"Salt";
    }
    
    NSMutableString* saltString = [NSMutableString stringWithString:[key uppercaseString]];
    NSData * inputData = [saltString dataUsingEncoding:NSUTF8StringEncoding];
    
    CC_SHA256(inputData.bytes, (CC_LONG)inputData.length, salt);
    CC_SHA512(inputData.bytes, (CC_LONG)inputData.length, data);
    
    uint8_t retBytes[32];
    // Make it lossy - use 48 bytes of 64 initial. Just to make it different from salt and unlink from the key.
    // Don't care about collisions, it's a salt. I'm pretty sure it is redundant but anyway...
    CCKeyDerivationPBKDF(kCCPBKDF2, (const char*)&data, 48, (const uint8_t*)&salt, 32, kCCPRFHmacAlgSHA256, roundsToGo, (uint8_t*)&retBytes, 32);
    
    return [NSData dataWithBytes:&retBytes length:32];
}
 
 */

/*

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
 
 */

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
    // Why one more hash? To eliminate a chosen-ciphertext attack...
    
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

-(NSMutableString*)decryptAESString:(NSData*)input
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
        return [NSMutableString stringWithString:MESSAGE_INVALID_PWD];
    }
    
    return [[NSMutableString alloc] initWithData:ret encoding:NSUTF8StringEncoding];
}

-(NSData*)encryptAESData:(NSData*)input
{
    NSMutableData* ret;
    // 1. Compress data
    NSMutableData* res = [self gzipDeflate: [NSMutableData dataWithData:input]];
    
    // 1-B. AONT
    res = [self doAONT:res];
    
    // 2. Encrypt !!! KEY SHOULD BE 32-bytes long!!!
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

/*
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
 */

/*
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
    uint8_t salt2[32];
    
    @try {
        [data getBytes:sBuffer range:(NSRange){bytesToDo,2}];
    }
    @catch (NSException *exception) {
        sBuffer[0] = 8;
    }
    CC_SHA256(sBuffer, 2, salt);
    CC_SHA256(sBuffer, 2, salt2);
    free(sBuffer);
    
    //CCCrypt(op, kCCAlgorithmAES, kCCOptionPKCS7Padding, headerSalt.bytes, 32, currentSalt.bytes, aBuffer, bytesToDo,bBuffer, 16, &moved);
    CCCrypt(op, kCCAlgorithmAES, kCCOptionPKCS7Padding, headerSalt.bytes, 32, nil, aBuffer, bytesToDo,bBuffer, 16, &moved);
    [data replaceBytesInRange:range withBytes:NULL length:0];
    [data replaceBytesInRange:NSMakeRange(0, 0) withBytes:bBuffer length:moved];
    
    // Hide last bytes
    if (data.length < bytesToDoEnd) {
        return;
    }
    NSRange range2 = {data.length-bytesToDoEnd-1, bytesToDoEnd};
    [data getBytes:aBuffer range:range2];
    
    CCCrypt(op, kCCAlgorithmAES, kCCOptionPKCS7Padding, headerSalt.bytes, 32, nil, aBuffer, bytesToDo,bBuffer, 16, &moved);
    
    [data replaceBytesInRange:range2 withBytes:NULL length:0];
    [data replaceBytesInRange:NSMakeRange(data.length-1, 0) withBytes:bBuffer length:moved];
    
    free(aBuffer);
    free(bBuffer);
}
*/

- (NSMutableData*)gzipInflate :(NSMutableData*) data
{
    if ([data length] == 0) return data;
    
    //[self processHeaders:data];
    //[self processHeaders2:data :kCCDecrypt];
    
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
    //[self processHeaders2:compressed :kCCEncrypt];
    
    return compressed;//[NSData dataWithData:compressed];
}

-(NSMutableData*)doAONT:(NSMutableData*) data
{
    if ([data length] == 0)
        return data;
    
    //NSMutableData* processed;
    
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
        //*(uint8_t*)(&dataBlock[32]) = i;
        dataBlock[32] = (uint8_t)i;
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
        //*(uint8_t*)(&dataBlock[32]) = i;
        dataBlock[32] = (uint8_t)i;
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
        dataIn = nil;
        dataOut = nil;
        
        return data;
    }
}

#ifdef STRONG
-(NSMutableData*)applyCoder:(NSMutableData*)data decoding:(BOOL)decoding
{
    // Quick key file, for testing only:
    // dd if=/dev/random of=<file_name> bs=XX count=XX
    NSString *path = [CommonProcs getPathIntoDocs:@"dataFile.dat"];
    //NSString* path = [[NSBundle mainBundle] pathForResource:@"dataFile" ofType:@"dat"];
    if (self.file == nil) {
        NSFileHandle* file = [NSFileHandle fileHandleForReadingAtPath: path];
        
        if (file == nil){
            NSLog(@"Failed to open file. Recovery process: copying...");
            [self shuffleKeyFiles:nil];
            file = [NSFileHandle fileHandleForReadingAtPath: path];
            if(file == nil){
                NSLog(@"Still failed to open file, giving up...");
                return data;
            }
        }
        self.file = file;
        [GlobalRouter sharedManager].currentPos = (int)[[[NSUserDefaults standardUserDefaults] objectForKey:@"pos"] integerValue];
    }
    [self.file seekToFileOffset:0];
    NSData* keyIDdata = [self.file readDataOfLength:8]; // Read more and get hash??
    NSString* currentKeyID = [keyIDdata base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
    if(currentKeyID.length > 8)
        currentKeyID = [currentKeyID substringToIndex:8];
    
    int posToRead = [GlobalRouter sharedManager].currentPos+2;
    int subtr = 0;
    if (decoding) {
        //Get pos and strip pos info
        NSRange bytesRange = NSMakeRange((NSUInteger)data.length - 8, 8);
        char *dataIn = malloc(9);
        [data getBytes:dataIn range:bytesRange];
        dataIn[8] = 0; // NULL-terminated string!
        NSString* strPos = [NSString stringWithUTF8String:dataIn];
        posToRead = [strPos intValue];//*(int*)dataIn;
        
        // Key ID
        bytesRange = NSMakeRange((NSUInteger)data.length - 16, 8);
        [data getBytes:dataIn range:bytesRange];
        dataIn[8] = 0; // NULL-terminated string!
        NSString* keyIDstr = [NSString stringWithUTF8String:dataIn];
        [data setLength: data.length-16];
        free(dataIn);
        //posToRead = CFSwapInt32BigToHost(posToRead);
        //NSLog(@"Position = %08x", posToRead);
        if([currentKeyID isEqualToString:keyIDstr] && posToRead + (int)data.length > [GlobalRouter sharedManager].currentPos){
            //NSLog(@"Updating pos %d->%d", [GlobalRouter sharedManager].currentPos, posToRead+(int)data.length);
            [GlobalRouter sharedManager].currentPos = posToRead + (int)data.length;
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[GlobalRouter sharedManager].currentPos] forKey:@"pos"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }else{
            //NSLog(@"No update");
        }
    }else{
        // Check if the key is off
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:path error:nil];
        unsigned long long size = [fileAttributes fileSize];
        static BOOL isShown = NO;
        if ([GlobalRouter sharedManager].currentPos + data.length > size) {
            if (!isShown) {
                isShown = YES;
                [CommonProcs showMessage:NSLocalizedString(@"Security alert", nil) title:NSLocalizedString(@"Security alert title", nil)];
            }
            
            NSLog(@"Key is off... selecting random offset");
            posToRead = arc4random()%(size - data.length - 32);
            [[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"callMe"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }else{
            [GlobalRouter sharedManager].currentPos += (int)data.length;
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[GlobalRouter sharedManager].currentPos] forKey:@"pos"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        //Add key pos to the end of data
        NSString* poss = [NSString stringWithFormat:@"%8@%08d",currentKeyID, posToRead];
        //uint32_t theInt = htonl((uint32_t)posToRead); // well, this is questionable, since we use iOS only...
        [data appendBytes:[poss UTF8String] length:16];
        subtr = 16;
        NSLog(@"Position = %08x, %@", posToRead,poss);
    }
    
    NSMutableData* ret = data;
    
    //Do a XOR cycle from posToRead in file
    char *dataIn = malloc(kChunkSizeBytes);
    char *dataOut = malloc(kChunkSizeBytes);
    int dataInLength = kChunkSizeBytes;
    [self.file seekToFileOffset:posToRead];
    
    for (int startByte = 0; startByte <= [data length]-subtr; startByte += kChunkSizeBytes) {
        if ((startByte + kChunkSizeBytes) > [data length]-subtr) {
            dataInLength = (int)[data length]-subtr - startByte;
        }
        else {
            dataInLength = kChunkSizeBytes;
        }
        
        // Get the chunk to be encoded from the input buffer
        NSRange bytesRange = NSMakeRange((NSUInteger) startByte, (NSUInteger) dataInLength);
        [data getBytes:dataIn range:bytesRange];
        
        // Read bytes from dataFile and XOR it to dataIn
        NSData* kData = [self.file readDataOfLength:kChunkSizeBytes];
        char* kDataBytes = (char*)[kData bytes];
        for (int i=0; i<dataInLength; i++) {
            dataOut[i] = dataIn[i] ^ kDataBytes[i];
        }
        //dataOut = dataIn;
        
        [data replaceBytesInRange:bytesRange withBytes:dataOut];
    }

    free(dataIn);
    free(dataOut);
    
    //NSLog(@"STRONG VER");
    return ret;
}

-(bool)shuffleKeyFiles:(NSString*)fileName
{
    if(fileName == nil){
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *error;
        NSBundle *applicationBundle = [NSBundle mainBundle];
        NSString* filePath = [applicationBundle pathForResource:@"dataFile" ofType:@"dat"];
        NSString* destPath = [CommonProcs getPathIntoDocs:@"dataFile.dat"];
        if ([fileManager fileExistsAtPath:destPath]) {
            [fileManager removeItemAtPath:destPath error:&error];
        }
        [fileManager copyItemAtPath:filePath toPath:destPath error:&error];
        return true;
    }
    
    int chunkSizeForReadingData = 1024*1024;//8*4096;
    bool ret = true;
    NSBundle *applicationBundle = [NSBundle mainBundle];
    NSString* filePath = [applicationBundle pathForResource:fileName ofType:@"dat"];
    
    // Declare needed variables
    //CFStringRef result = NULL;
    CFReadStreamRef readStream = NULL;
    CFWriteStreamRef writeStream = NULL;
    
    // Get the file URL
    CFURLRef fileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (__bridge CFStringRef)filePath,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    
    if (!fileURL){
        return false;
    }//goto done;
    
    // Create and open the read stream
    readStream = CFReadStreamCreateWithFile(kCFAllocatorDefault,
                                            (CFURLRef)fileURL);
    if (!readStream){
        if (fileURL) {
            CFRelease(fileURL);
        }
        return false;
    }//goto done;
    bool didSucceed = (bool)CFReadStreamOpen(readStream);
    if (!didSucceed){
        if (readStream) {
            CFReadStreamClose(readStream);
            CFRelease(readStream);
        }
        if (fileURL) {
            CFRelease(fileURL);
        }
        return false;
    }//goto done;
    
    // Get the file URL
    NSString* writeFileName = [CommonProcs getPathIntoDocs:[NSString stringWithFormat:@"%@.dat", fileName]];
    CFURLRef wfileURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault,
                                  (__bridge CFStringRef)writeFileName,
                                  kCFURLPOSIXPathStyle,
                                  (Boolean)false);
    
    if (!wfileURL){
        if (readStream) {
            CFReadStreamClose(readStream);
            CFRelease(readStream);
        }
        if (fileURL) {
            CFRelease(fileURL);
        }
        return false;
    }//goto done;
    // Create and open the read stream
    writeStream = CFWriteStreamCreateWithFile(kCFAllocatorDefault,(CFURLRef)wfileURL);
    if (!writeStream){
        if (readStream) {
            CFReadStreamClose(readStream);
            CFRelease(readStream);
        }
        if (fileURL) {
            CFRelease(fileURL);
        }
        if (wfileURL) {
            CFRelease(wfileURL);
        }
        return false;
    }//goto done;
    bool didSucceedWrite = (bool)CFWriteStreamOpen(writeStream);
    if (!didSucceedWrite){
        if (readStream) {
            CFReadStreamClose(readStream);
            CFRelease(readStream);
        }
        if (writeStream) {
            CFWriteStreamClose(writeStream);
            CFRelease(writeStream);
        }
        if (fileURL) {
            CFRelease(fileURL);
        }
        if (wfileURL) {
            CFRelease(wfileURL);
        }
        return false;
    }//goto done;
    
    bool hasMoreData = true;
    NSMutableData* res;
    NSMutableData* tempData;
    NSRange bytesRange = NSMakeRange(0, chunkSizeForReadingData);
    
    uint8_t* buffer = malloc(chunkSizeForReadingData);//[chunkSizeForReadingData];
    BOOL firstRound = YES;
    long done = 0;
    while (hasMoreData) {
        @autoreleasepool {
            CFIndex readBytesCount = CFReadStreamRead(readStream,
                                                      (UInt8 *)buffer, chunkSizeForReadingData);
                                                      //(CFIndex)sizeof(buffer));
            if (readBytesCount == -1) break;
            if (readBytesCount == 0) {
                hasMoreData = false;
                continue;
            }
            
            if([tempData length]>0)
                [tempData replaceBytesInRange:bytesRange withBytes:buffer length:chunkSizeForReadingData];
            else
                tempData = [NSMutableData dataWithBytes :buffer length:chunkSizeForReadingData];
            
            res = [self doCipherWithKey:currentKey salt:res operation:kCCEncrypt data:tempData]; //[self AES256EncryptWithKey:currentKey /*salt:firstRound?currentSalt:res*/ data:tempData];
            firstRound = NO;
            [res getBytes:buffer length:chunkSizeForReadingData];
            CFIndex writeBytesCount = CFWriteStreamWrite(writeStream, (UInt8*)buffer, chunkSizeForReadingData);// (CFIndex)sizeof(buffer));
            if(writeBytesCount == 0)
                NSLog(@"No write");
            //res = nil;
            tempData = nil;
            done += writeBytesCount;
        }
    }
        free(buffer);
    //}
    
done:
    
    if (readStream) {
        CFReadStreamClose(readStream);
        CFRelease(readStream);
    }
    if (writeStream) {
        CFWriteStreamClose(writeStream);
        CFRelease(writeStream);
    }
    if (fileURL) {
        CFRelease(fileURL);
    }
    if (wfileURL) {
        CFRelease(wfileURL);
    }
    
    return ret;
}


#endif


#pragma mark Encryption

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
    //arc4random_buf(salt, sizeof(salt));
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
    //arc4random_buf(salt, sizeof(salt));
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
    return [self AES256EncryptWithKey:key data:data isMail:self.isMail];
}

-(NSMutableData*)AES256DecryptWithKey:(NSData*)key data:(NSMutableData*)data
{
    return [self AES256DecryptWithKey:key data:data isMail:self.isMail];
}

-(NSMutableData*)AES256EncryptWithKey:(NSData*)key data:(NSMutableData*)data isMail:(BOOL)isMail
{
    if (data.length == 0) {
        return data;
    }
#ifdef STRONG
    if(isMail){
        data = [self applyCoder:data decoding:NO];
    }
#endif
    
    NSMutableData* ret = [self getSalt];
    //NSLog([self getHex:ret]);
    
    //NSMutableData* retData = [self doCipherWithKey:key salt:salt operation:kCCEncrypt data:data];
    NSMutableData* retData = [self doCipherWithKey:key salt:[ret mutableCopy] operation:kCCEncrypt data:data];
    [ret appendData:retData];
    
    return ret;
}

-(NSMutableData*)AES256DecryptWithKey:(NSData*)key data:(NSMutableData*)data isMail:(BOOL)isMail
{
    if (data.length == 0) {
        return data;
    }
    
    uint8_t inSalt[16];
    [data getBytes:&inSalt length:sizeof(inSalt)];
    NSMutableData* dSalt = [NSMutableData dataWithBytes:&inSalt length:sizeof(inSalt)];
    //NSLog([self getHex:dSalt]);
    
    [data replaceBytesInRange:NSMakeRange(0, 16) withBytes:NULL length:0];
    
    //NSMutableData* ret = [self doCipherWithKey:key salt:salt operation:kCCDecrypt data:data];
    NSMutableData* ret = [self doCipherWithKey:key salt:dSalt operation:kCCDecrypt data:data];
#ifdef STRONG
    if(isMail){
        ret = [self applyCoder:ret decoding:YES];
    }
#endif
    
    return ret;//[self doCipherWithKey:key salt:salt operation:kCCDecrypt data:data];
}
/////////////////

#pragma mark ----------------

-(NSMutableString*)base64FromData:(NSData*)data
{
    return [NSMutableString stringWithString:[data base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength]];
}

-(NSData*)dataFromBase64:(NSString *)string
{
    if(string == nil) return nil;
    
    return [[NSData alloc] initWithBase64EncodedString:string options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

-(NSMutableString*)encryptToBase64:(NSString*)input
{
    return [self base64FromData:[self encryptAESString:input]];
}

-(NSMutableString*)decryptFromBase64:(NSString*)input
{
    return [self decryptAESString:[self dataFromBase64:input]];
}

+(NSString*)generateSimplePassword:(int)len
{
    // No separators, no digits
    // 55*15*4 = 3300 letters
    // 3 letters = 35*10^9 ~ 5-6 symbol pwd
    
    return [Encryptor generatePassword:len simple:YES];
}

+(NSString*)generatePassword:(int)len
{
    return [Encryptor generatePassword:len simple:NO];
}

+(NSString*)generatePassword:(int)len simple:(BOOL)simple
{
    NSString* ret = @"";
    // 55*15*4 = 3300 "letters"+23 separators + 2x100 numbers
    // 3 words -> 3300^3*100*100*23 = 8.27*10^15 ~ 8-symbol pwd
    
    // These are for 55*15*3+23
    // if use 7 words -> 1.3*10^25 ~ 13-symbol password
    // if use 6 words -> 5.3*10^21 vars ~11-symbol password of lower+upper+digits+specials
    // if use 5 words -> 2.1*10^18 ~ 9-symbol password
    // if use 4 words -> 8.6*10^14 ~ 7-8-symbol password
    // if use 3 words -> 3.5*10^11 ~ 6-symbol password
    NSArray* sep = @[@"!",@"#",@"$",@"&",@"*",@">",@"<",@".",@",",@"?",@";",@"-",@"/",@"@",@":",@"|",@"(",@")",@"+",@"=",@"{",@"}",@"'"];
    //NSArray* sepR = @[@"!",@"#",@"$",@"&",@"*",@">",@"<",@".",@",",@"?",@"-",@"@",@":",@"+",@"="];
    
    NSArray* words = @[@"one",@"two",@"you",@"and",@"ass",@"act",@"age",@"ago",@"any",@"are",@"bad",@"bag",@"dog",@"cry",@"dry",
   @"cut",@"cue",@"eat",@"elm",@"ear",@"eye",@"fan",@"far",@"fog",@"fat",@"fax",@"fox",@"fix",@"for",@"gag",
   @"gun",@"gas",@"got",@"hat",@"hit",@"him",@"ham",@"his",@"her",@"hen",@"how",@"hug",@"hot",@"hog",@"hut",
    @"ice",@"icy",@"inn",@"ink",@"ion",@"jig",@"jaw",@"jab",@"jar",@"jet",@"job",@"joy",@"keg",@"key",@"kit",
    @"lab",@"lad",@"log",@"lot",@"law",@"let",@"loo",@"lux",@"mac",@"mad",@"man",@"mew",@"max",@"may",@"mem",
    @"mic",@"mix",@"mom",@"mud",@"mag",@"mug",@"nag",@"nap",@"nop",@"nod",@"not",@"now",@"nut",@"oak",@"oat",
   @"odd",@"orc",@"orb",@"ooh",@"owl",@"own",@"pac",@"pal",@"pan",@"pen",@"pay",@"pee",@"pet",@"pig",@"pot",
   @"rag",@"rat",@"ray",@"row",@"sad",@"see",@"saw",@"sky",@"tan",@"ten",@"top",@"too",@"urn",@"van",@"was",
   @"add",@"ace",@"aid",@"aim",@"air",@"amp",@"ant",@"ape",@"app",@"arc",@"art",@"ash",@"arm",@"ask",@"axe",
   @"ban",@"bar",@"bat",@"bay",@"bee",@"bed",@"beg",@"bet",@"bid",@"bit",@"big",@"bot",@"bow",@"box",@"boy",
   @"bro",@"bug",@"bun",@"bum",@"bus",@"buy",@"but",@"bye",@"can",@"car",@"cap",@"cat",@"cob",@"cod",@"cog",
   @"cop",@"cow",@"dad",@"day",@"did",@"die",@"dot",@"duo",@"eel",@"egg",@"ego",@"elf",@"emu",@"end",@"era",
   @"ern",@"err",@"eve",@"fag",@"few",@"flu",@"fly",@"fry",@"fog",@"fun",@"fur",@"gal",@"gay",@"gin",@"gum",
   @"gym",@"gut",@"guy",@"hex",@"hey",@"heh",@"hmm",@"hon",@"hop",@"hoy",@"hub",@"hue",@"huh",@"ill",@"ivy",
   @"jee",@"ken",@"lag",@"lap",@"leg",@"lex",@"lid",@"lie",@"lip",@"low",@"map",@"mat",@"moo",@"nog",@"net",
   @"new",@"nil",@"nit",@"nor",@"nun",@"noo",@"off",@"oil",@"old",@"ore",@"our",@"out",@"oxy",@"pad",@"paw",
   @"pie",@"pin",@"pit",@"pod",@"poo",@"pop",@"pub",@"pun",@"pus",@"put",@"rap",@"raw",@"rim",@"rip",@"rib",
   @"rid",@"rob",@"rod",@"roe",@"rub",@"rue",@"rye",@"say",@"sea",@"set",@"sex",@"shy",@"sic",@"sin",@"sip",
   @"sir",@"sit",@"six",@"ski",@"sly",@"sob",@"sod",@"son",@"sos",@"sox",@"soy",@"spa",@"spy",@"sub",@"sun",
   @"sum",@"tao",@"tap",@"tar",@"tau",@"tax",@"tea",@"ted",@"tel",@"the",@"tic",@"tie",@"tin",@"tip",@"tit",
   @"toe",@"tom",@"ton",@"tor",@"tow",@"toy",@"try",@"udo",@"umm",@"use",@"vat",@"veg",@"vet",@"var",@"vim",
   @"vow",@"vox",@"wag",@"war",@"wax",@"way",@"web",@"wet",@"who",@"why",@"wig",@"win",@"wok",@"woo",@"wow",
                       
   @"ad",@"at",@"am",@"as",@"by",@"en",@"et",@"hi",@"if",@"in",@"it",@"no",@"of",@"oh",@"on",
   @"or",@"ox",@"si",@"so",@"to",@"uh",@"us",@"we",@"ya",@"yo",@"eh",@"er",@"ex",@"un",@"up",
@"abba",@"able",@"aces",@"acid",@"acre",@"aero",@"aged",@"ages",@"alas",@"alfa",@"alma",@"aloe",@"also",@"amen",@"ammo",
@"amok",@"anis",@"anon",@"anti",@"anus",@"apex",@"aqua",@"arch",@"area",@"army",@"arty",@"atom",@"aunt",@"auto",@"away",
@"back",@"bail",@"bang",@"bark",@"blow",@"boil",@"boom",@"born",@"brew",@"baby",@"bait",@"bald",@"ball",@"balm",@"band",
@"bank",@"bard",@"bare",@"barn",@"base",@"bass",@"bath",@"bawl",@"beam",@"bean",@"bear",@"beef",@"beep",@"beer",@"beet",
@"bell",@"belt",@"bend",@"best",@"beta",@"bias",@"bice",@"bike",@"bill",@"bios",@"bird",@"bisk",@"bite",@"blag",@"blob",
@"bloc",@"blog",@"blue",@"blur",@"boar",@"boat",@"bock",@"body",@"bolo",@"bolt",@"bomb",@"bone",@"bond",@"bonk",@"bony",
@"book",@"boot",@"bore",@"bork",@"boss",@"both",@"bowl",@"bozo",@"bran",@"bras",@"brat",@"brie",@"brig",@"brin",@"brow",
@"buck",@"bulb",@"bulk",@"bull",@"bump",@"bury",@"bush",@"busy",@"butt",@"buzz",@"byte",@"cafe",@"cane",@"calf",@"call",
@"calm",@"camp",@"cant",@"carb",@"card",@"care",@"case",@"cash",@"cask",@"cast",@"cart",@"cave",@"ceil",@"cell",@"cent",
@"cage",@"cake",@"cook",@"cool",@"chop",@"chew",@"come",@"copy",@"crop",@"curl",@"chao",@"chap",@"char",@"chat",@"chef",
@"chic",@"chin",@"chip",@"chow",@"city",@"clam",@"clan",@"claw",@"clay",@"clip",@"clog",@"clot",@"club",@"clue",@"coal",
@"coat",@"coax",@"cobb",@"coca",@"cock",@"coil",@"coin",@"coke",@"cold",@"colt",@"coma",@"comb",@"comp",@"cone",@"cook",
@"cool",@"coop",@"cope",@"cord",@"core",@"cork",@"corn",@"cory",@"cost",@"cozy",@"crab",@"crap",@"crew",@"crib",@"crit",
@"damn",@"dare",@"deny",@"dine",@"doze",@"draw",@"drag",@"drop",@"duck",@"earn",@"exit",@"easy",@"each",@"echo",@"edge",
@"edit",@"eery",@"else",@"envy",@"epic",@"epos",@"eros",@"euro",@"even",@"evil",@"ever",@"exam",@"exec",@"exit",@"expo",
@"emit",@"face",@"fade",@"fake",@"farm",@"fart",@"fear",@"feed",@"feel",@"flag",@"flee",@"free",@"fuel",@"gain",@"gaze",
@"gear",@"glow",@"glue",@"grab",@"grip",@"grin",@"grow",@"hack",@"hand",@"hang",@"hook",@"help",@"hide",@"hike",@"hire",
@"hill",@"hold",@"hole",@"hate",@"hope",@"horn",@"hurt",@"idle",@"itch",@"iron",@"jack",@"juke",@"jump",@"keep",@"kill",
@"kiss",@"knot",@"know",@"lace",@"lead",@"leak",@"lean",@"leap",@"live",@"load",@"list",@"lock",@"look",@"loop",@"love",
@"lube",@"like",@"lurk",@"lust",@"make",@"mail",@"mask",@"mark",@"mate",@"meet",@"meld",@"mess",@"miss",@"mine",@"mock",
@"move",@"muse",@"mute",@"nail",@"name",@"need",@"nest",@"nick",@"obey",@"omit",@"open",@"pace",@"pain",@"pair",@"park",
@"pass",@"plan",@"play",@"plot",@"plug",@"pole",@"pose",@"post",@"pore",@"pour",@"quit",@"race",@"rage",@"rain",@"rape",
@"read",@"reel",@"rely",@"riot",@"ride",@"ring",@"risk",@"rock",@"roll",@"ruin",@"rust",@"sack",@"sick",@"sale",@"save",
@"sake",@"seek",@"scum",@"seal",@"seed",@"seat",@"sell",@"send",@"ship",@"shit",@"shop",@"show",@"sift",@"sign",@"sink",
@"size",@"skew",@"skin",@"skip",@"slap",@"slay",@"slim",@"slip",@"slot",@"slow",@"snag",@"snap",@"snow",@"soak",@"soap",
@"soar",@"sock",@"sole",@"sort",@"spam",@"span",@"spin",@"spit",@"stir",@"stop",@"swap",@"swim",@"tack",@"tail",@"talk",
@"tape",@"tear",@"tell",@"test",@"tick",@"tilt",@"thin",@"tour",@"tree",@"trap",@"trim",@"tune",@"type",@"undo",@"vote",
@"vent",@"view",@"vest",@"void",@"wade",@"wage",@"wait",@"wake",@"wall",@"want",@"warm",@"warn",@"warp",@"wave",@"wear",
@"weep",@"weed",@"well",@"were",@"whip",@"will",@"wine",@"wink",@"wipe",@"wire",@"wish",@"woof",@"work",@"word",@"worm",
@"wabs",@"wack",@"wadd",@"wads",@"waff",@"wags",@"wail",@"wain",@"wair",@"wale",@"walk",@"waly",@"wame",@"wand",@"wane",
@"ward",@"ware",@"wars",@"wart",@"wary",@"wash",@"wasp",@"wast",@"wate",@"watt",@"wauk",@"waul",@"wavy",@"waxy",@"ways",
@"weak",@"weal",@"wean",@"webs",@"weds",@"weel",@"ween",@"weet",@"weld",@"welt",@"wend",@"went",@"wept",@"wert",@"west",
@"wolf",@"womb",@"wonk",@"wood",@"wool",@"wore",@"wort",@"wows",@"wrap",@"yang",@"yard",@"yarn",@"yeah",@"year",@"yeld",
/*58*/@"yelp",@"yoga",@"yolk",@"your",@"zeal",@"zebu",@"zero",@"zest",@"zeta",@"zigs",@"zinc",@"zine",@"zoom",@"zone",@"zouk"];
    /*NSArray* vowels = @[@"a",@"e",@"i",@"o",@"u",@"y",@"ea",@"ou",@"ee",@"ir",@"er",@"!",@"#",@"$",@"%",@"&",@"*",@">",@"<",@".",@",",@"?",@";",@"-",@"/",@"@",@":",@"|"];
     NSArray* cons = @[@"b",@"c",@"d",@"f",@"g",@"h",@"j",@"k",@"l",@"m",@"n",@"p",@"q",@"r",@"s",@"t",@"w",@"x",@"z",@"ch",@"sh",@"kn",@"th"];
     NSString* ret = [cons objectAtIndex:arc4random()%[cons count]];
     for (int i=0; i<4; i++) {
     NSString* one = [vowels objectAtIndex:arc4random()%[vowels count]];
     NSString* two = [cons objectAtIndex:arc4random()%[cons count]];
     if(arc4random()%2 == 0){
     one = [one uppercaseString];
     }
     ret = [NSString stringWithFormat:@"%@%@%@", ret, one, two];
     }
     */
     int ind = arc4random()%[sep count]; //NSLog(@"%d",ind);
    NSString* sep0 = simple?@"-":[sep objectAtIndex:ind];
     ind = arc4random()%[words count]; //NSLog(@"%d",ind);
     ret = [words objectAtIndex:ind];
    int cap = arc4random()%4;
    if(cap == 0){
        ret = [ret uppercaseString];
    }else if(cap == 1) {
        ret = [ret capitalizedString];
    }else if(cap == 2) {
        NSString* lastL = [[ret substringFromIndex:ret.length-1] uppercaseString];
        ret = [NSString stringWithFormat:@"%@%@", [ret substringToIndex:ret.length-1],lastL];
    }
    for (int i=0; i<len-1; i++) {
        ind = arc4random()%[words count]; //NSLog(@"%d",ind);
        NSString* two = [words objectAtIndex:ind];
        int cap = arc4random()%4;
        if(cap == 0){
            two = [two uppercaseString];
        }else if(cap == 1) {
            two = [two capitalizedString];
        }else if(cap == 2) {
            NSString* lastL = [[two substringFromIndex:two.length-1] uppercaseString];
            //NSLog(@"String %@=%@-%@", two,[two substringToIndex:two.length-1],lastL);
            two = [NSString stringWithFormat:@"%@%@", [two substringToIndex:two.length-1],lastL];
        }
        if (simple) {
            ret = [NSString stringWithFormat:@"%@-%@", ret, two];
        }else{
            ret = [NSString stringWithFormat:@"%@%@%@", ret, arc4random()%2==0?[NSString stringWithFormat:@"%d",arc4random()%100]:sep0, two];
        }
    }
     //ind = arc4random()%[sep count]; //NSLog(@"%d",ind);
     //ret = [NSString stringWithFormat:@"%@%d", ret, arc4random()%100];
    
    return ret;
}

+(NSString*)generatePhrase:(int)len
{
    //return [Encryptor generateWord:len];
    
    // Ordinary passwords 26l+26U+10+10
    // 4 - 2.7*10^7
    // 5 - 1.9*10^9
    // 6 - 1.4*10^11
    // 7 - 1*10^13
    // 8 - 7.2*10^14
    // 9 - 5.2*10^16
    
    // 50*15*4 nouns = 3000 vars
    // 50*15*4 adjectives = 3000 vars
    // 3 letters = 238328 vars
    // 6 separators
    // 100 digits
    // 1.28*10^15 ~ 8 symbols
    // Need 8*10^14
    NSString* ret;
    
    NSArray* seps = @[@"-", @"*", @".", @"&", @",", @" "];
    //NSString* letters = @"qwertyuioplkjhgfdsazxcvbnmQWERTYUIOPLKJHGFDSAZXCVBNM";
    NSArray* nouns = @[ @"abo",@"abs",@"ace",@"ach",@"act",@"ade",@"ado",@"aer",@"aga",@"age",@"aha",@"ahu",@"air",@"aka",@"ale",
        @"alp",@"amp",@"amy",@"ana",@"ani",@"ann",@"ant",@"ape",@"app",@"ara",@"arb",@"arc",@"arm",@"art",@"ash",
        @"ass",@"ava",@"awl",@"axe",@"bac",@"bag",@"bam",@"bar",@"bas",@"bat",@"bay",@"bed",@"bee",@"ben",@"bin",
        @"bio",@"bit",@"biz",@"bob",@"bod",@"bog",@"bom",@"bon",@"bot",@"box",@"boy",@"bra",@"bro",@"bud",@"bug",
        @"bum",@"bun",@"bus",@"cab",@"cad",@"cag",@"cal",@"cam",@"can",@"cap",@"car",@"cat",@"caw",@"cay",@"cel",
        @"cig",@"cob",@"cod",@"cog",@"col",@"cot",@"cow",@"cox",@"cub",@"cud",@"cue",@"cup",@"dad",@"dag",@"dam",
        @"dan",@"daw",@"day",@"dee",@"del",@"den",@"dev",@"dew",@"dey",@"dif",@"dna",@"doc",@"dog",@"dom",@"don",
        @"dop",@"dot",@"dub",@"duo",@"ear",@"ebb",@"eel",@"egg",@"ego",@"elf",@"elk",@"elm",@"eme",@"emp",@"emu",
        @"end",@"eng",@"ent",@"eon",@"era",@"eve",@"eye",@"fad",@"fam",@"fan",@"faq",@"fax",@"fay",@"fee",@"fig",
        @"fin",@"fir",@"flu",@"fob",@"foe",@"fog",@"fol",@"fox",@"foy",@"fub",@"fun",@"fur",@"gad",@"gal",@"gap",
        @"gas",@"geo",@"gif",@"gig",@"gin",@"gis",@"git",@"goa",@"gob",@"god",@"gog",@"gum",@"gun",@"gut",@"guy",
        @"gym",@"gyp",@"hag",@"hah",@"ham",@"han",@"hap",@"hat",@"hen",@"hep",@"hip",@"hob",@"hod",@"hog",@"hub",
        @"hud",@"hue",@"hun",@"hut",@"ice",@"ich",@"ile",@"imp",@"ind",@"ink",@"inn",@"ion",@"irp",@"jag",@"jar",
        @"jaw",@"job",@"joe",@"joy",@"jug",@"keg",@"ken",@"key",@"kid",@"kin",@"kit",@"koi",@"lab",@"lac",@"lad",
        @"lap",@"lar",@"law",@"lax",@"leg",@"lex",@"lid",@"lie",@"lim",@"lin",@"lip",@"log",@"loo",@"lop",@"lot",
        @"lum",@"lux",@"mac",@"mag",@"mam",@"man",@"map",@"mat",@"may",@"meg",@"mel",@"mem",@"men",@"mew",@"mic",
        @"mob",@"mom",@"mop",@"mot",@"mow",@"mud",@"mug",@"neg",@"net",@"nil",@"nit",@"nob",@"nog",@"non",@"nun",
        @"nut",@"oaf",@"oak",@"oar",@"oat",@"oil",@"orb",@"orc",@"ord",@"owl",@"pad",@"pal",@"pam",@"pan",@"paw",
        @"pax",@"pea",@"peg",@"pen",@"pet",@"pic",@"pie",@"pig",@"pin",@"pod",@"pos",@"pot",@"pow",@"pox",@"poy",
        @"pub",@"pud",@"pun",@"pup",@"pur",@"pus",@"rad",@"rag",@"ram",@"ran",@"rat",@"ray",@"rec",@"rep",@"res",
        @"rex",@"rib",@"rim",@"rod",@"roe",@"row",@"roy",@"rug",@"rye",@"sax",@"sea",@"sec",@"seg",@"seq",@"sin",
        @"sir",@"six",@"ski",@"sky",@"son",@"sop",@"soy",@"spa",@"spy",@"sub",@"sug",@"sum",@"sun",@"tab",@"tac",
        @"tad",@"tag",@"tar",@"tax",@"tea",@"tec",@"tee",@"tel",@"ten",@"tic",@"tig",@"tin",@"tip",@"tit",@"tob",
        @"tod",@"toe",@"tom",@"ton",@"top",@"tor",@"tot",@"toy",@"tub",@"tun",@"two",@"urn",@"vac",@"van",@"vap",
        @"vat",@"veg",@"vet",@"vox",@"wad",@"wap",@"war",@"wax",@"way",@"web",@"wed",@"wem",@"who",@"why",@"wig",
        @"wit",@"wiz",@"woe",@"wog",@"wok",@"wow",@"yen",@"zax",@"zea",@"zed",@"zen",@"zip",@"zit",@"zoo",@"zax",
            // 4-letter
        @"abba",@"acid",@"acme",@"acne",@"adam",@"agar",@"aide",@"alan",@"alma",@"aloe",@"alps",@"alto",@"amen",@"ammo",@"anis",
        @"apex",@"aqua",@"arch",@"area",@"ares",@"arms",@"army",@"arse",@"asis",@"atom",@"aunt",@"aura",@"auto",@"avis",@"axis",
        @"axle",@"axon",@"babe",@"baby",@"bace",@"back",@"baff",@"bail",@"bain",@"bait",@"ball",@"balm",@"band",@"bang",@"bank",
    /*30*/@"barb",@"bard",@"bark",@"barn",@"base",@"bath",@"bead",@"beam",@"bean",@"beck",@"beef",@"beep",@"beer",@"beet",@"bear",
            @"bell",@"belt",@"berg",@"beta",@"bias",@"bice",@"bike",@"bill",@"bing",@"bint",@"bios",@"bird",@"birk",@"birt",@"blab",
            @"blee",@"blip",@"blob",@"bloc",@"boar",@"boat",@"bock",@"body",@"bolo",@"bolt",@"bomb",@"bond",@"bone",@"book",@"boon",
            @"boot",@"bord",@"boss",@"boul",@"bout",@"bowl",@"brad",@"bran",@"brat",@"brie",@"brig",@"brin",@"brit",@"brow",@"brun",
            @"buck",@"buff",@"bulb",@"bulk",@"bull",@"bush",@"busk",@"bust",@"butt",@"buzz",@"byte",@"cafe",@"cage",@"cake",@"calf",
            @"cali",@"calk",@"camp",@"cand",@"cane",@"cape",@"carb",@"card",@"cark",@"cart",@"case",@"cash",@"cask",@"cate",@"cave",
            @"cell",@"celt",@"cent",@"cess",@"chad",@"chai",@"chef",@"chin",@"chip",@"chub",@"city",@"clam",@"clan",@"claw",@"clay",
            @"clot",@"club",@"clue",@"coag",@"coal",@"coat",@"coca",@"cock",@"coco",@"coda",@"code",@"coin",@"cola",@"cole",@"colp",
            @"colt",@"comp",@"cone",@"coop",@"corb",@"cord",@"core",@"corf",@"cork",@"corn",@"cort",@"cost",@"cove",@"cowl",@"crab",
            @"cran",@"crap",@"craw",@"crew",@"crib",@"crop",@"crow",@"crud",@"cube",@"cull",@"cult",@"curb",@"curd",@"cure",@"cyst",
    /*40*/@"czar",@"dace",@"dale",@"dame",@"darg",@"darn",@"dart",@"data",@"date",@"dawn",@"daze",@"dean",@"debt",@"deck",@"deco",
                        
                @"deed",@"deem",@"deer",@"demo",@"dent",@"dern",@"desk",@"dess",@"deva",@"dice",@"diet",@"dill",@"dime",@"dirt",@"disc",
                @"dish",@"disk",@"dock",@"doer",@"doge",@"doll",@"dolt",@"dome",@"dona",@"dong",@"doom",@"doop",@"door",@"dope",@"dore",
                @"dorm",@"dorn",@"dorp",@"dorr",@"dote",@"dove",@"dowl",@"dram",@"dray",@"drop",@"drub",@"drug",@"drum",@"duck",@"duct",
                @"dude",@"duel",@"duet",@"duff",@"duke",@"dune",@"dunt",@"dusk",@"dust",@"duty",@"dyer",@"dyne",@"eale",@"earl",@"ease",
                @"east",@"ebon",@"eche",@"echo",@"ecus",@"eddy",@"eden",@"edge",@"eger",@"eggy",@"elle",@"elve",@"emir",@"euro",@"evet",
                @"exam",@"exec",@"exit",@"exon",@"expo",@"face",@"fact",@"falk",@"falx",@"fame",@"fane",@"fang",@"fard",@"fare",@"farm",
                @"faro",@"fash",@"fate",@"fats",@"faun",@"faux",@"fave",@"fawn",@"fear",@"feat",@"feds",@"feet",@"fend",@"ferm",@"fess",
                @"fest",@"feta",@"fete",@"fiar",@"fiat",@"fice",@"fico",@"fife",@"fike",@"file",@"film",@"filo",@"fils",@"fink",@"fire",
                @"firk",@"fish",@"fist",@"five",@"fizz",@"flab",@"flag",@"flam",@"flaw",@"flax",@"flea",@"flic",@"flix",@"floe",@"flon",
               /*50*/ @"flue",@"foal",@"foam",@"foge",@"fogy",@"foin",@"folk",@"fone",@"font",@"food",@"fool",@"foot",@"ford",@"fork",@"form"
                
        ];
        
        NSArray* adj = @[ @"abandoned",@"able",@"absolute",@"academic",@"acceptable",@"accurate",@"aching",@"acidic",@"active",@"actual",@"adept",@"admired",@"adored",@"advanced",@"afraid",
                            @"aged",@"agile",@"ajar",@"alert",@"alive",@"all",@"ample",@"amused",@"angry",@"annual",@"another",@"any",@"apt",@"arctic",@"arid",
                            @"aromatic",@"ashamed",@"assured",@"athletic",@"aware",@"awesome",@"awful",@"awkward",@"bad",@"baggy",@"bare",@"basic",@"best",@"better",@"big",
                            @"bitter",@"black",@"bland",@"blank",@"bleak",@"blind",@"blond",@"blue",@"bogus",@"bold",@"bony",@"boring",@"bossy",@"both",@"bouncy",
                            @"brave",@"brief",@"brisk",@"broken",@"brown",@"bulky",@"bubbly",@"bumpy",@"burly",@"busy",@"calm",@"candid",@"capital",@"careful",@"caring",
                            @"cheap",@"cheery",@"chilly",@"chubby",@"circular",@"classic",@"clean",@"clear",@"clever",@"close",@"closed",@"cloudy",@"clumsy",@"cold",@"common",
                            @"complete",@"complex",@"cooked",@"cool",@"corny",@"corrupt",@"costly",@"crafty",@"crazy",@"creamy",@"creepy",@"crisp",@"cruel",@"cuddly",@"curly",
                            @"curvy",@"cute",@"damp",@"damn",@"dapper",@"daring",@"dark",@"darling",@"dead",@"deadly",@"dear",@"decent",@"deep",@"definite",@"delayed",
                            @"delicious",@"delirious",@"dense",@"dental",@"detailed",@"devoted",@"digital",@"dim",@"dimpled",@"direct",@"dirty",@"discrete",@"dismal",@"distant",@"distinct",
                            @"distorted",@"dizzy",@"dopey",@"doting",@"double",@"drab",@"drafty",@"dramatic",@"dreary",@"droopy",@"dry",@"dual",@"dull",@"dutiful",@"each",
                            @"eager",@"early",@"easy",@"edible",@"elastic",@"elated",@"elderly",@"electric",@"elegant",@"eminent",@"empty",@"entire",@"envious",@"equal",@"even",
                            @"every",@"evil",@"exalted",@"excellent",@"excited",@"exotic",@"expert",@"extra",@"XXL",@"XL",@"failing",@"faint",@"fair",@"fake",@"false",
                            @"fancy",@"far",@"fast",@"fat",@"fatal",@"fearful",@"feisty",@"feline",@"female",@"few",@"fickle",@"filthy",@"fine",@"firm",@"first",
                            @"fitting",@"fit",@"fixed",@"flaky",@"flashy",@"flat",@"flawed",@"flawless",@"flimsy",@"flowery",@"fluffy",@"fluid",@"fond",@"foolish",@"forked",
                            @"formal",@"frail",@"frank",@"free",@"fresh",@"friendly",@"frigid",@"frilly",@"frizzy",@"front",@"frosty",@"frozen",@"frugal",@"full",@"funny",
                            @"fussy",@"fuzzy",@"general",@"gentle",@"giant",@"giddy",@"gifted",@"giving",@"glaring",@"glass",@"gleeful",@"gloomy",@"glossy",@"glum",@"golden",
                            @"good",@"gorgeous",@"graceful",@"gracious",@"grand",@"grave",@"gray",@"great",@"greedy",@"green",@"grim",@"grimy",@"gripping",@"grizzled",@"gross",
                            @"grouchy",@"growning",@"grown",@"growing",@"grubby",@"guilty",@"gummy",@"hairy",@"half",@"handy",@"happy",@"hard",@"harmful",@"harmless",@"harsh",
                            @"hasty",@"hateful",@"haunting",@"healthy",@"hearty",@"heavy",@"hefty",@"helpful",@"hidden",@"high",@"hollow",@"homely",@"honest",@"horrible",@"hot",
                            @"huge",@"humble",@"hungry",@"hurtful",@"husky",@"icky",@"icy",@"ideal",@"idiotic",@"idle",@"idolized",@"ill",@"illegal",@"impish",@"impolite",
                            @"impure",@"inborn",@"indolent",@"infamous",@"inferior",@"infinite",@"informal",@"innocent",@"insecure",@"insistent",@"intent",@"internal",@"intrepid",@"ironclad",@"irritating",
                            @"itchy",@"jaded",@"jagged",@"jammed",@"jaunty",@"jealous",@"jittery",@"joint",@"jolly",@"jovial",@"joyful",@"jubilant",@"juicy",@"jumbo",@"jumpy",
                            @"junior",@"keen",@"key",@"kind",@"kindly",@"klutzy",@"knobby",@"knotty",@"knowing",@"known",@"kooky",@"kosher",@"lame",@"lanky",@"large",
                            @"last",@"lasting",@"late",@"lavish",@"lawful",@"lazy",@"leading",@"leafy",@"lean",@"left",@"legal",@"light",@"likely",@"limited",@"limitless",
                            @"limp",@"linear",@"lined",@"liquid",@"little",@"live",@"lively",@"livid",@"lone",@"lonely",@"long",@"loose",@"lost",@"loud",@"lovely",
                            @"low",@"loyal",@"lucky",@"lumpy",@"mad",@"major",@"male",@"mammoth",@"massive",@"mature",@"meager",@"mealy",@"mean",@"measly",@"meaty",
                            @"medical",@"mediocre",@"medium",@"meek",@"mellow",@"melodic",@"merry",@"messy",@"metallic",@"mild",@"milky",@"mindless",@"minor",@"minty",@"misty",
                            @"mixed",@"modern",@"modest",@"moist",@"moral",@"muddy",@"murky",@"mushy",@"musty",@"muted",@"naive",@"narrow",@"nasty",@"natural",@"near",
                            @"neat",@"needy",@"negative",@"new",@"next",@"nice",@"nifty",@"nimble",@"nippy",@"noisy",@"nonstop",@"normal",@"notable",@"noted",@"novel",
            /*30*/          @"numb",@"nutty",@"obese",@"oblong",@"odd",@"oily",@"old",@"only",@"open",@"optimal",@"opulent",@"orange",@"orderly",@"organic",@"original",
                          @"ornate",@"ornery",@"other",@"our",@"oval",@"overdue",@"pale",@"paltry",@"parallel",@"partial",@"past",@"pastel",@"perfect",@"perky",@"pesky",
                          @"petty",@"phony",@"pink",@"pitiful",@"plain",@"plastic",@"playful",@"plump",@"plush",@"pointed",@"polite",@"poised",@"poor",@"posh",@"positive",
                          @"possible",@"potable",@"powerful",@"pretty",@"pricey",@"prickly",@"prime",@"private",@"prize",@"proper",@"proud",@"prudent",@"puny",@"pure",@"purple",
                          @"pushy",@"putrid",@"puzzled",@"quaint",@"quick",@"quiet",@"quirky",@"radiant",@"ragged",@"rapid",@"rare",@"rash",@"raw",@"ready",@"real",
                         
                         /*35*/ @"recent",@"red",@"regal",@"regular",@"reliable",@"remote",@"rich",@"right",@"rigid",@"ringed",@"ripe",@"roasted",@"robust",@"rosy",@"rotating",
                          @"rough",@"round",@"rowdy",@"royal",@"ruddy",@"rude",@"runny",@"rural",@"rusty",@"sad",@"safe",@"salty",@"same",@"sandy",@"sane",
                          @"scaly",@"scarce",@"scared",@"scary",@"scented",@"secret",@"selfish",@"serene",@"serious",@"several",@"severe",@"shabby",@"shady",@"sharp",@"shiny",
                          @"shocked",@"short",@"showy",@"shrill",@"shy",@"sick",@"silent",@"silky",@"silly",@"silver",@"simple",@"sinful",@"single",@"sizzling",@"skinny",
                          @"sleepy",@"slight",@"slim",@"slimy",@"slippery",@"slow",@"slushy",@"small",@"smart",@"smooth",@"smug",@"snappy",@"snarling",@"sneaky",@"snoopy",
                          @"soft",@"soggy",@"solid",@"somber",@"some",@"sore",@"sour",@"sparse",@"spicy",@"spiffy",@"splendid",@"spotless",@"spry",@"square",@"stable",
                          @"staid",@"stained",@"stale",@"stark",@"starry",@"steel",@"steep",@"sticky",@"stiff",@"stingy",@"stormy",@"strict",@"strident",@"striped",@"strong",
                          @"stupid",@"sturdy",@"stylish",@"subtle",@"sudden",@"sugary",@"sunny",@"super",@"superb",@"superior",@"svelte",@"sweaty",@"sweet",@"swift",@"tall",
                          @"tame",@"tan",@"tart",@"tasty",@"taut",@"tedious",@"teeming",@"tender",@"tense",@"tepid",@"terrible",@"terrific",@"testy",@"that",@"these",
                          @"thick",@"thin",@"third",@"thirsty",@"this",@"thorny",@"those",@"thrifty",@"tidy",@"tight",@"timely",@"tinted",@"tiny",@"tired",@"torn",
                         /*45*/ @"total",@"tough",@"tragic",@"trained",@"tricky",@"trim",@"trivial",@"true",@"trusting",@"trusty",@"tubby",@"twin",@"ugly",@"ultimate",@"unfit",
                          @"united",@"unkempt",@"unknown",@"unlawful",@"unlined",@"unlucky",@"unripe",@"unruly",@"untidy",@"untrue",@"unused",@"unusual",@"upbeat",@"upright",@"upset",
                          @"urban",@"usable",@"used",@"useful",@"useless",@"utter",@"vacant",@"vague",@"vain",@"valid",@"vapid",@"vast",@"velvety",@"vibrant",@"vicious",
                          @"vigilant",@"violent",@"violet",@"virtual",@"visible",@"vital",@"vivid",@"wan",@"warm",@"warped",@"wary",@"wastful",@"watery",@"wavy",@"weak",
                          @"wealthy",@"weary",@"webbed",@"wee",@"weekly",@"weepy",@"weird",@"wet",@"which",@"white",@"whole",@"wicked",@"wide",@"wiggly",@"wild",
                          @"willing",@"wilted",@"windy",@"wiry",@"wise",@"witty",@"worn",@"wry",@"wrong",@"yearly",@"yellow",@"young",@"yummy",@"zany",@"zesty"
        ];
        
    /*
        NSArray* verbs = @[ @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
            / *30* /          @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@""
        ];
        
        NSArray* adv =   @[ @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
                            @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",
            / *30* /          @"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@"",@""
        ];*/
    
    int ind = arc4random()%[adj count];
    ret = [adj objectAtIndex:ind];
    int cap = arc4random()%4;
    if(cap == 0){
        ret = [ret uppercaseString];
    }else if(cap == 1) {
        ret = [ret capitalizedString];
    }else if(cap == 2) {
        NSString* lastL = [[ret substringFromIndex:ret.length-1] uppercaseString];
        ret = [NSString stringWithFormat:@"%@%@", [ret substringToIndex:ret.length-1],lastL];
    }
    
    ind = arc4random()%[nouns count];
    NSString* two = [nouns objectAtIndex:ind];
    cap = arc4random()%4;
    if(cap == 0){
        two = [two uppercaseString];
    }else if(cap == 1) {
        two = [two capitalizedString];
    }else if(cap == 2) {
        NSString* lastL = [[two substringFromIndex:two.length-1] uppercaseString];
        two = [NSString stringWithFormat:@"%@%@", [two substringToIndex:two.length-1],lastL];
    }
    
    NSString* sep = [seps objectAtIndex:(arc4random()%seps.count)];
    ret = [NSString stringWithFormat:@"%@%@%@%@%@%d",[Encryptor getUUIDofLength:3],sep, ret, sep, two, arc4random_uniform(100)];
    
    return ret;
}

+(NSString*)generateWord:(int)len
{
    // Ordinary passwords 26l+26U+10+10
    // 4 - 2.7*10^7
    // 5 - 1.9*10^9
    // 6 - 1.4*10^11
    // 7 - 1*10^13
    // 8 - 7.2*10^14
    // 9 - 5.2*10^16
    
    // 55 cons
    // 34 vowels
    // 4 syllables = 55*34*55*34 = 3.496.900 vars
    // 6 separators
    // 100 digits
    // 7.33*10^15 ~ 8 symbols
    // Need 8*10^14
    NSString* ret;
    
    NSArray* seps = @[@"-", @"*", @".", @"&", @",", @" "];
    
    NSArray* cons = @[@"b",@"c",@"d",@"f",@"g",@"h",@"j",@"k",@"l",@"m",@"n",@"p",@"q",@"r",@"s",@"t",@"v",@"w",@"x",@"z",@"sm",@"sn",@"st",@"sw",@"sk",@"sl",@"sp",@"th",@"dw",@"tw",@"thr",@"dr",@"tr",@"cr",@"cl",@"pr",@"fr",@"br",@"gr",@"pl",@"fl",@"bl",@"gl",@"sh",@"shr",@"ch",@"sch",@"ck",@"kn",@"qu",@"ng",@"ph",@"ss",@"wh",@"wr"];
    NSArray* vowels = @[@"a",@"e",@"i",@"o",@"u",@"y",@"ai",@"ay",@"ae",@"ee",@"ei",@"ea",@"ey",@"ie",@"oa",@"oe",@"aw",@"ou",@"ow",@"oo",@"ue",@"ua",@"ew",@"oi",@"oy",@"au",@"yo",@"er",@"ir",@"igh",@"ah",@"ia",@"ar",@"or"];
    
    NSString* sep = [seps objectAtIndex:(arc4random_uniform((int)seps.count))];
    ret = [NSString stringWithFormat:@"%i%@", arc4random_uniform(100),sep];
    for(int i=0;i<len;i++){
        int use3 = arc4random_uniform(3);//arc4random()%3;
        int ind = arc4random_uniform((int)[cons count]);//arc4random()%[cons count];
        NSString* one = [cons objectAtIndex:ind];
        ind = arc4random_uniform((int)[vowels count]);//()%[vowels count];
        NSString* two = [vowels objectAtIndex:ind];
        ind = arc4random_uniform((int)[cons count]);//arc4random()%[cons count];
        NSString* three = use3==1?@"":[cons objectAtIndex:ind];
        ind = arc4random_uniform((int)[vowels count]);//arc4random()%[vowels count];
        NSString* four;
        four = use3>=1?@"":[vowels objectAtIndex:ind];
        ret = [NSString stringWithFormat:@"%@%@%@%@%@%@", ret, one, two, three, four, i<len-1?sep:@""];
    }
    
    return ret;
}

+(NSString*)getUUIDofLength:(int)len
{
    NSString* base = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString* randomString = [[NSMutableString alloc] initWithCapacity:len];
    
    for (int i=0;i<len;i++) {
        NSUInteger rand = arc4random_uniform((int)base.length);
        [randomString appendFormat:@"%C",[base characterAtIndex:rand]];
    }
    
    return randomString;
}

+(NSString*)getTheNumberBase26:(int)number
{
    NSMutableString* ret = [[NSMutableString alloc] init];
    NSString* base = @"abcdefghijklmnopqrstuvwxyz";
    if (number < 26) {
        [ret appendFormat:@"%C",[base characterAtIndex:number]];
    }else{
        while(number != 0){
            int r = number%26;
            // add it reversed
            [ret insertString:[NSString stringWithFormat:@"%C",[base characterAtIndex:r]] atIndex:0];
            number = number/26;
        }
    }
    
    return ret;
}

+(int)intFromBase26:(NSString*)str
{
    int ret = 0;
    NSString* base = @"abcdefghijklmnopqrstuvwxyz";
    int nB = 1;
    for (int i=(int)str.length-1; i>=0; i--) {
        unichar ch = [str characterAtIndex:i];
        NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:[NSString stringWithCharacters:&ch length:1]];
        NSRange range = [base rangeOfCharacterFromSet:charSet];
        if (range.location == NSNotFound){
            // ... oops
        }else{
            ret += (int)(range.location)*nB;
            nB *= 26;
        }
    }
    
    return ret;
}

+(NSString*)getTheNumberBase36:(int)number
{
    NSMutableString* ret = [[NSMutableString alloc] init];
    NSString* base = @"abcdefghijklmnopqrstuvwxyz0123456789";
    if (number < 36) {
        [ret appendFormat:@"%C",[base characterAtIndex:number]];
    }else{
        while(number != 0){
            int r = number%36;
            // add it reversed
            [ret insertString:[NSString stringWithFormat:@"%C",[base characterAtIndex:r]] atIndex:0];
            number = number/36;
        }
    }
    return ret;
}

+(int)intFromBase36:(NSString*)str
{
    int ret = 0;
    NSString* base = @"abcdefghijklmnopqrstuvwxyz0123456789";
    int nB = 1;
    for (int i=(int)str.length-1; i>=0; i--) {
        unichar ch = [str characterAtIndex:i];
        NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:[NSString stringWithCharacters:&ch length:1]];
        NSRange range = [base rangeOfCharacterFromSet:charSet];
        if (range.location == NSNotFound){
            // ... oops
        }else{
            ret += (int)(range.location)*nB;
            nB *= 36;
        }
    }
    return ret;
}


// This one might produces lots of collisions since it uses a 80-char charset instead of a 256-char one
// It is used to generate a key for email address to use in the user defaults
//
// Converted it to a 64-chars hex representation
+(NSString*)getUUIDHashForString:(NSString*)item
{
    if (item == nil || [item isEqualToString:@""]) {
        return @"";
    }
    uint8_t hash[32];
    NSData* data = [[item lowercaseString] dataUsingEncoding:NSUTF8StringEncoding];
    CC_SHA256(data.bytes, (CC_LONG)data.length, hash);
    
    NSMutableString* ret = [[NSMutableString alloc] init];
    NSString* base = @"abcdefghijklmnopqrstuvwxyz0123456789ABCDEFJHIJKLMNOPQRSTUVWXYZ-+=)(*&^%$#@!<>,.|";
    for(int i=0;i<32;i++){
        char r = hash[i]%base.length;
        // add it reversed
        [ret insertString:[NSString stringWithFormat:@"%C",[base characterAtIndex:r]] atIndex:0];
        //uint8_t r = hash[i];
        //[ret insertString:[NSString stringWithFormat:@"%02x",r] atIndex:0];
    }
    
    //NSLog(@"UUID Hash is %@", ret);
    return ret;
}

@end
