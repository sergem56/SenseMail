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

static NSString* signature              = @"SM@1L";
static NSString* signatureCert          = @"SM@1C";
static NSString* signatureMutableCert   = @"SM@2C";
static NSString* signatureTransferCert  = @"SM@1T";
static NSString* signatureRequestCert   = @"SM@1R";
static NSString* signatureOTC           = @"SM@1O";
static NSString* signatureMutable       = @"SM@1M";
static NSString* signatureMutable2      = @"SM@2M"; // Drastically increase mutation number
static NSString* signatureOTCPwd        = @"SM@1N";
#define mutationLength 4 // not used, hardcoded to 4 on data level
#define mutationOffset 250000 // the minimum number of iterations to add
#define mutationOffset2 750000 // the minimum number of iterations to add for high mutation
#define mutationBase 456976
#define mutationBase2 1679616 // Base-36
#ifdef STRONG
static NSString* signatureSt            = @"SM@2L";
#endif


static NSString* filterUnread       = @"smFilterUnread";
static NSString* filterStarred      = @"smFilterStarred";
static NSString* filterAnswered     = @"smFilterAnswered";
static NSString* filterLarge        = @"smFilterLarge";
static NSString* filterSince        = @"smFilterSince";
static NSString* filterBefore       = @"smFilterBefore";
static NSString* filterOn           = @"smFilterOn";
static NSString* filterIn           = @"smFilterIn"; // In a specified month
static NSString* filterBetween      = @"smFilterBw"; // Between dates
static NSString* filterAttachments  = @"smFilterAtt";
static NSString* filterProtected    = @"smFilterProtected";
static NSString* filterImportant    = @"smFilterImportant";
static NSString* filterFromF        = @"smFilterFrom";
static NSString* filterTo           = @"smFilterTo";
static NSString* filterLargerThan   = @"smFilterLarger";
static NSString* filterSmallerThan  = @"smFilterSmaller";

#define INVALID_CERT @"CERT_INVALID_STOP_IT_AND_ASK"
#define MESSAGE_INVALID_PWD @"MESSAGE_INVALID_PASSWORD"

#define FILTER_UNSEEN_ONLY @"Filter_unseen_only"

typedef NS_ENUM(NSInteger, boxTypes){
    btInbox,
    btSent,
    btSpam,
    btFavourites,
    btEmpty,
    btUseName,
    btDeleted,
    btAllMail,
    btDrafts,
    btImportant,
    btUnknown,
    btNo
};

typedef NS_ENUM(NSInteger, encryptionType){
    enTypePassword,
    enTypeCertificate,
    enTypePasswordForCert,
    enTypeOTC,
    enTypeNone,
    enTypeMutablePassword,
    enTypeMutableCertificate,
    enTypeMutablePassword2,
    enTypeOTCPassword
};

typedef NS_ENUM(NSInteger, messageType){
    mtRegular,
    mtCertificate,
    mtCertificateRequest
};

typedef NS_ENUM(NSInteger, searchTypes){
    stUnread,
    stAnswered,
    stLarge,
    stWithAttachments,
    stFlagged,
    stProtected,
    stNone,
    stUserInput,
    stDate,
    stDateBefore,
    stDateAfter,
    stImportant,
    stLastWeek,
    stLastMonth,
    stInTheMonth,
    stBwDates,
    stFrom,
    stTo,
    stSizeLess,
    stSizeMore
};

typedef NS_ENUM(NSInteger, sortType){
    sotDate,
    sotNew,
    sotSender
};

typedef NS_ENUM(NSInteger, listSortOrder){
    lsDate,
    lsDateNewOnTop,
    lsAccount,
    lsAccountNewOnTop,
    lsDateEverything
};

typedef NS_ENUM(NSInteger, shortcutCommands){
    scSpam,
    scFavs,
    scSent,
    scCustomFolder,
    scFilter
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

@protocol selectedFolderReceiver <NSObject>

-(void)itemSelected:(NSString*)itemPath title:(NSString*)title;

@end

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

#endif
