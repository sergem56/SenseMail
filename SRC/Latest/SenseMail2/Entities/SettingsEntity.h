//
//  SettingsEntity.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MCOConstants.h>

#define GENERAL_SETTINGS @"SM1LG"

@interface SettingsEntity : NSObject <NSCopying>

@property (nonatomic, getter=settingsName) NSString* settingsName;
@property (nonatomic) NSString* userName;
@property (nonatomic) NSString* password;
@property (nonatomic) NSString* userNick;
@property (nonatomic) NSString* imapServer;
@property (nonatomic) NSString* smtpServer;
@property (nonatomic) NSInteger smtpPort;
@property (nonatomic) NSString* imapPrefix;
//@property (nonatomic) NSString* pinCode;
@property (nonatomic) float compression;
@property (nonatomic) NSString* checksum;
@property (nonatomic,assign) BOOL keepInBg;
@property (nonatomic) NSInteger checkPeriod;
@property (nonatomic) NSString* signature;
@property (nonatomic) NSInteger nMessages;
@property (nonatomic,assign) BOOL useBioID;
@property (nonatomic,assign) BOOL largeFont;
@property (nonatomic,assign) BOOL sortAll;
@property (nonatomic,assign) NSInteger sortOrder;
@property (nonatomic,assign) BOOL clearOnBG;
@property (nonatomic,assign) BOOL doNotHideAccount;

// New ver addition
@property (nonatomic) NSInteger imapPort;

/** It's the MCOConnectionType from MCOConstants.h */
typedef NS_OPTIONS(NSInteger, SMConnectionType) {
    /** Clear-text connection for the protocol.*/
    SMConnectionTypeClear             = 1 << 0,
    /** Clear-text connection at the beginning, then switch to encrypted connection using TLS/SSL*/
    /** on the same TCP connection.*/
    SMConnectionTypeStartTLS          = 1 << 1,
    /** Encrypted connection using TLS/SSL.*/
    SMConnectionTypeTLS               = 1 << 2,
};
@property (nonatomic) SMConnectionType connectionTypeIMAP; // SSL/TLS-STARTTLS
@property (nonatomic) SMConnectionType connectionTypeSMTP; // SSL/TLS-STARTTLS

@property (nonatomic) NSInteger bgColor;
@property (nonatomic, strong) NSString* erasePIN;

#ifdef STRONG
@property (nonatomic, assign) int pos;
#endif

@property (nonatomic, assign) MCOAuthType SMTPAuthType;

@property (nonatomic, strong) NSDate* silentFrom;
@property (nonatomic, strong) NSDate* silentTo;
@property (nonatomic,assign) BOOL useShortcuts;

// VPN settings
@property (nonatomic, assign) BOOL enableVPN;
@property (nonatomic, strong) NSString* vpnUsername;
@property (nonatomic, strong) NSString* vpnPassword; // Keychain reference name
@property (nonatomic, strong) NSString* vpnServer;
@property (nonatomic, strong) NSString* vpnRemoteID;
@property (nonatomic, strong) NSString* vpnLocalID;
@property (nonatomic, strong) NSString* vpnSharedSecret; // Keychain reference name
@property (nonatomic, strong) NSString* vpnProtocol;
@property (nonatomic, assign) NSInteger /*NEVPNIKEAuthenticationMethod*/ vpnAuthMethod;
@property (nonatomic, assign) BOOL vpnUseExtAuth;

-(SettingsEntity*)initWithGenericGeneral;

-(NSString*)settingsName;
-(SMConnectionType)getTypeFromString:(NSString*)sType;

-(MCOAuthType)getAuthTypeFromString:(NSString*)aType;
+(NSArray*) authTypeTitles;
+(NSString*)getStringFromAuthType:(MCOAuthType)aType;

@end
