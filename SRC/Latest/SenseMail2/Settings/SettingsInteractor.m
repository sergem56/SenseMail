//
//  SettingsInteractor.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "SettingsInteractor.h"
#import "SettingsEntity.h"
#import "UserInfoDataManager.h"
#import "GlobalRouter.h"
#import "CommonProcs.h"
#import "DataManager.h"
#import "Encryptor.h"

@implementation SettingsInteractor

-(NSArray*)getSettings:(NSMutableString*)pin
{
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    
    //[dataMan saveKeyForAddress:@"ebox1357@gmail.com" yourPin:@"22" otherPin:@"222" key:[@"fucking long password - 12&^KJ09*!bde)=+" dataUsingEncoding:NSUTF8StringEncoding]];
    
    return [dataMan getSettings:pin];
}

-(BOOL)saveSettings:(SettingsEntity *)settings :(NSMutableString*)pin
{
    if([settings.userName isEqualToString:GENERAL_SETTINGS]){
        /*
        // Test read. Need to enable password as well
        NSMutableDictionary *returnDictionary00 = [[NSMutableDictionary alloc] init];
        
        [returnDictionary00 setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [returnDictionary00 setObject:@"SMService" forKey:(__bridge id)kSecAttrService];
        [returnDictionary00 setObject:@"SMAccount" forKey:(__bridge id)kSecAttrAccount];
        [returnDictionary00 setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnData];
        [returnDictionary00 setObject:@"Touch ID" forKey:(__bridge id)kSecUseOperationPrompt];
        CFDataRef passwordData = NULL;
        OSStatus err00 = SecItemCopyMatching((__bridge CFDictionaryRef)returnDictionary00, (CFTypeRef *)&passwordData);
        if(err00 != errSecSuccess) {
            //Check the error
        }
        if (passwordData) {
            NSData* pd = (__bridge NSData*)passwordData;
            NSString* stored = [[NSString alloc] initWithData:pd encoding:NSUTF8StringEncoding];
            NSString* kkk = [[UIDevice currentDevice].identifierForVendor UUIDString];
            Encryptor* cryptor = [[Encryptor alloc] initWithSimpleKey:kkk];
            stored = [cryptor decryptFromBase64:stored];
            NSLog(@"Stored value %@", stored);
        }
        // End test read
        */
        
        // Save pin to keychain if touchID or FaceID is needed
        NSString* toSave;
        if (settings.useBioID) {
            NSString* kkk = [[UIDevice currentDevice].identifierForVendor UUIDString];
            Encryptor* cryptor = [[Encryptor alloc] initWithSimpleKey:kkk];
            toSave = [cryptor encryptToBase64:[GlobalRouter sharedManager].pin];
        }else{
            toSave = @"";
        }
        // First delete the key
        NSMutableDictionary *returnDictionary0 = [[NSMutableDictionary alloc] init];
        
        [returnDictionary0 setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
        [returnDictionary0 setObject:@"SMService" forKey:(__bridge id)kSecAttrService];
        [returnDictionary0 setObject:@"SMAccount" forKey:(__bridge id)kSecAttrAccount];
        /*OSStatus err0 = */SecItemDelete((__bridge CFDictionaryRef)returnDictionary0);
        
        if(settings.useBioID){
            SecAccessControlRef access = SecAccessControlCreateWithFlags(NULL,  // Use the default allocator.
                                                            //kSecAttrAccessibleWhenUnlocked,
                                                            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                            kSecAccessControlUserPresence,
                                                            NULL);
            
            NSMutableDictionary *returnDictionary = [[NSMutableDictionary alloc] init];
            
            [returnDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
            [returnDictionary setObject:[toSave dataUsingEncoding:NSUTF8StringEncoding]
                                 forKey:(__bridge id)kSecValueData];
            [returnDictionary setObject:(__bridge id _Nonnull)(access) forKey:(__bridge id)kSecAttrAccessControl];
            [returnDictionary setObject:@"SMService" forKey:(__bridge id)kSecAttrService];
            [returnDictionary setObject:@"SMAccount" forKey:(__bridge id)kSecAttrAccount];
            OSStatus err = SecItemAdd((__bridge CFDictionaryRef)returnDictionary, nil);
            //let status = SecItemAdd(query, nil)
            if(err != errSecSuccess) {
                //We check the error code
                NSLog(@"%@", [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil].localizedDescription);
            }
        }
        
        // Save erase PIN
        if (![settings.erasePIN isEqualToString:@""]) {
            //[[NSUserDefaults standardUserDefaults] setObject:[Encryptor getHashForString:settings.erasePIN] forKey: SOSPINSIG];
            [CommonProcs saveToKeychainAlways:[Encryptor getHashForString:settings.erasePIN] account:SOSPINSIG service:@"SM"];
        }
    }
    
    
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    
    return [dataMan saveSettings:settings :pin];
}

-(BOOL)deleteSetting:(SettingsEntity *)settings
{
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    BOOL ret = [dataMan deleteSetting:settings];
    
    if (ret) {
        // Clean up authorisation if any
        DataManager* man = [[DataManager alloc] init];
        [man settingsWasDeletedForAddress:settings.userName];
    }
    return ret;
}

-(BOOL)resetKey
{
    NSLog(@"Key reset");
    return YES;
}

-(BOOL)updateKey:(NSString*)key
{
    NSLog(@"Key updated");
    return YES;
}

-(BOOL)setupPin
{
    // Here we need to:
    // 1. Re-encrypt settings
    // 2. Re-encrypt address book
    // 3. Re-encrypt secure gallery
    // 4. Re-encrypt notes
    // 5. Re-encrypt certificates
    // 6. Re-encrypt One-Time Certs
    
    [[[GlobalRouter sharedManager] getSettingsRouter] showBusy:0 :10];
    [[GlobalRouter sharedManager]restartQ];
    
    //dispatch_queue_t pinQueue = dispatch_queue_create("PinChange Queue",NULL);
    
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    dispatch_async([[GlobalRouter sharedManager] getQ], ^{
        
        UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
        
        NSArray* allSettings = [dataMan getSettings:[GlobalRouter sharedManager].oldPin];
        //SettingsEntity* sett = [[dataMan getSettings:[GlobalRouter sharedManager].oldPin] firstObject];
        for (SettingsEntity* sett in allSettings){
            if(sett)
                [dataMan saveSettings:sett :[GlobalRouter sharedManager].pin];
        }
        
        // Address book
        NSArray* book = [dataMan getAddressBook:[GlobalRouter sharedManager].oldPin groupsOnly:NO];
        [dataMan saveAddressBook:book pin:[GlobalRouter sharedManager].pin];
        
        // Gallery
        [dataMan saveGalleryWithNewPin:[GlobalRouter sharedManager].pin oldPin:[GlobalRouter sharedManager].oldPin];
        
        // Notes
        [dataMan saveNotesWithNewPin:[GlobalRouter sharedManager].pin oldPin:[GlobalRouter sharedManager].oldPin];
#if !LITE
        // Certs
        [dataMan saveAllKeysWithNewPin:[GlobalRouter sharedManager].pin oldPin:[GlobalRouter sharedManager].oldPin];
        
        // One-Time Certs
        [dataMan saveOTCsWithNewPIN:[GlobalRouter sharedManager].pin oldPIN:[GlobalRouter sharedManager].oldPin];
#endif
        dispatch_async(dispatch_get_main_queue(), ^{
            if(![[GlobalRouter sharedManager] isCancelled]){
                //[[[GlobalRouter sharedManager] getSettingsRouter] showBusy:10 :10];
                [CommonProcs hideProgress];
            }else{
                [[GlobalRouter sharedManager]restartQ];
            }
        });
        
    });
    
    return YES;
}

@end
