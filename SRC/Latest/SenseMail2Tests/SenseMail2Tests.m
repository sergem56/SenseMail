//
//  SenseMail2Tests.m
//  SenseMail2Tests
//
//  Created by Sergey on 05.02.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "Encryptor.h"

@interface SenseMail2Tests : XCTestCase

@end

@implementation SenseMail2Tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void)testEncryption
{
    ////// TEST encrypt-decrypt image and string
    
    Encryptor* cryptor = [[Encryptor alloc] initWithKey:@"111122223333444455556666777788"];
    cryptor.isMail = YES;
    UIImage* test = [UIImage imageNamed:@"test"];
    
    Encryptor* wrongCryptor = [[Encryptor alloc] initWithKey:@"111122223333444455556666"];
    wrongCryptor.isMail = YES;

    
    // UIImage test
    NSData* jpeg = UIImageJPEGRepresentation(test, 0.6);
    NSData* encoded = [cryptor encryptAESData:jpeg];
    NSData* decoded = [cryptor decryptAESData:encoded];
    NSData* wDecoded = [wrongCryptor decryptAESData:encoded];
    
    XCTAssertEqualObjects(jpeg, decoded);
    XCTAssertNotEqualObjects(jpeg, wDecoded);
    
    // String test
    NSString* testString = @"Test string!!";
    NSData* encString = [cryptor encryptAESString:testString];
    NSString* encString64 = [cryptor base64FromData:encString];
    NSData* toDec64 = [cryptor dataFromBase64:encString64];
    NSString* decString = [cryptor decryptAESString:toDec64];
    NSString* wString = [wrongCryptor decryptAESString:toDec64];
    
    XCTAssertEqualObjects(testString, decString);
    XCTAssertNotEqualObjects(testString, wString);
    
    NSString* test2 = @"Test one proc";
    NSString* res1 = [cryptor encryptToBase64:test2];
    NSString* res2 = [cryptor decryptFromBase64:res1];
    XCTAssertEqualObjects(test2, res2);
}

-(void)testEncryptionShortKey
{
    ////// TEST encrypt-decrypt image and string
    
    Encryptor* cryptor = [[Encryptor alloc] initWithKey:@"111"];
    UIImage* test = [UIImage imageNamed:@"test"];
    
    // UIImage test
    NSData* jpeg = UIImageJPEGRepresentation(test, 0.6);
    NSData* encoded = [cryptor encryptAESData:jpeg];
    NSData* decoded = [cryptor decryptAESData:encoded];
    
    XCTAssertEqualObjects(jpeg, decoded);
    
    // String test
    NSString* testString = @"Test string!";
    NSData* encString = [cryptor encryptAESString:testString];
    NSString* encString64 = [cryptor base64FromData:encString];
    NSData* toDec64 = [cryptor dataFromBase64:encString64];
    NSString* decString = [cryptor decryptAESString:toDec64];
    
    XCTAssertEqualObjects(testString, decString);
    
    NSString* test2 = @"Test one proc";
    NSString* res1 = [cryptor encryptToBase64:test2];
    NSString* res2 = [cryptor decryptFromBase64:res1];
    XCTAssertEqualObjects(test2, res2);
}

- (void)testEncryptionSetupPerformance{
    
    [self measureBlock:^{
        Encryptor* cryptor = [[Encryptor alloc] initWithKey:@"111122223333444455556666777788"];
        cryptor = nil;
    }];

}

- (void)testEncryptionPerformance{
    // This is an example of a performance test case.
    Encryptor* cryptor = [[Encryptor alloc] initWithKey:@"111122223333444455556666777788"];
    UIImage* test = [UIImage imageNamed:@"test"];
    NSData* jpeg = UIImageJPEGRepresentation(test, 0.6);

    [self measureBlock:^{
        // UIImage test
        NSData* encoded = [cryptor encryptAESData:jpeg];
        NSData* decoded = [cryptor decryptAESData:encoded];
        decoded = nil;
    }];
}

@end
