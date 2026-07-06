//
//  CommonStuff.h
//  SenseMail2
//
//  Created by Sergey on 31.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#ifndef SenseMail2_CommonStuff_h
#define SenseMail2_CommonStuff_h

// Simple obfuscator, but be careful since it changes names
#ifndef DEBUG
#define MyClass aqwe
#define myMethod oikl
#endif

static NSString* signature = @"SM@1L";
static NSString* signatureCert = @"SM@1C";
static NSString* signatureTransferCert = @"SM@1T";
static NSString* signatureRequestCert = @"SM@1R";

#define INVALID_CERT @"CERT_INVALID_STOP_IT_AND_ASK"
#define MESSAGE_INVALID_PWD @"MESSAGE_INVALID_PASSWORD"

typedef NS_ENUM(NSInteger, boxTypes){
    btInbox,
    btSent,
    btSpam,
    btFavourites,
    btEmpty,
    btUseName
};

typedef NS_ENUM(NSInteger, encryptionType){
    enTypePassword,
    enTypeCertificate,
    enTypePasswordForCert,
    enTypeNone
};

typedef NS_ENUM(NSInteger, messageType){
    mtRegular,
    mtCertificate,
    mtCertificateRequest
};

@class AddressBookEntity;

@protocol CanGetAddressFromBook <NSObject>

-(void)setToAddress:(AddressBookEntity*)address;

@end

@protocol AddAttachmentReceiver <NSObject>

// Convert AddCollectionViewCell to ALAsset
-(void)setAttachments:(NSArray*)attachments;

@end

@protocol AsyncLoader <NSObject>

-(void)dataReady:(NSArray*)data error:(NSString*)error;
-(void)setProgress:(int)progress max:(int)max;

@end

@protocol userInfoNotificationReceiver <NSObject>

-(void)userInfoFinishedTask:(BOOL)res;

@end

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#endif
