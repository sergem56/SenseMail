//
//  KeychainWrapper.h
//  Apple's Keychain Services Programming Guide
//
//  Created by Tim Mitra on 11/17/14.
//  Copyright (c) 2014 Apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

@interface KeychainWrapper : NSObject

//- (void)mySetObject:(id)inObject forKey:(id)key;
- (void)mySetObject:(id)inObject forKey:(id)key forAccount:(NSString*)account;
- (id)myObjectForKey:(id)key;
- (void)writeToKeychain;
- (NSString*)getKeychainDataForAccount:(NSString*)key;

@end
