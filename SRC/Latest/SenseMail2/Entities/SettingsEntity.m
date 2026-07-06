//
//  SettingsEntity.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "SettingsEntity.h"
#import "CommonStuff.h"

@implementation SettingsEntity

@synthesize settingsName, userName, password, userNick;
@synthesize imapServer, imapPrefix, smtpServer, smtpPort, connectionTypeSMTP, connectionTypeIMAP, imapPort, SMTPAuthType;
@synthesize compression, checksum, keepInBg, checkPeriod, nMessages, useBioID, clearOnBG, doNotHideAccount;

- (id)copyWithZone:(NSZone *)zone
{
    SettingsEntity* copy = [[[self class] alloc] init];
    
    if (copy) {
        [copy setSettingsName:[self.settingsName copyWithZone:zone]];
        copy.password = [self.password copyWithZone:zone];
        copy.userName = [self.userName copyWithZone:zone];
        copy.userNick = [self.userNick copyWithZone:zone];
        copy.imapServer = [self.imapServer copyWithZone:zone];
        copy.smtpServer = [self.smtpServer copyWithZone:zone];
        copy.smtpPort = self.smtpPort;
        copy.imapPort = self.imapPort;
        copy.connectionTypeIMAP = self.connectionTypeIMAP;
        copy.connectionTypeSMTP = self.connectionTypeSMTP;
        copy.SMTPAuthType = self.SMTPAuthType;
        copy.imapPrefix = [self.imapPrefix copyWithZone:zone];
        copy.compression = self.compression;
        copy.checksum = [self.checksum copyWithZone:zone];
        copy.keepInBg = self.keepInBg;
        copy.checkPeriod = self.checkPeriod;
        copy.signature = [self.signature copyWithZone:zone];
        copy.nMessages = self.nMessages;
        copy.useBioID = self.useBioID;
        copy.largeFont = self.largeFont;
        copy.sortAll = self.sortAll;
        copy.bgColor = self.bgColor;
        copy.erasePIN = self.erasePIN;
        copy.sortOrder = self.sortOrder;
        copy.clearOnBG = self.clearOnBG;
        copy.doNotHideAccount = self.doNotHideAccount;
        copy.silentTo = self.silentTo;
        copy.silentFrom = self.silentFrom;
        copy.useShortcuts = self.useShortcuts;
        
        copy.enableVPN = self.enableVPN;
        copy.vpnUsername = [self.vpnUsername copyWithZone:zone];
        copy.vpnPassword = [self.vpnPassword copyWithZone:zone]; // Keychain reference name
        copy.vpnServer = [self.vpnServer copyWithZone:zone];
        copy.vpnRemoteID = [self.vpnRemoteID copyWithZone:zone];
        copy.vpnLocalID = [self.vpnLocalID copyWithZone:zone];
        copy.vpnSharedSecret = [self.vpnSharedSecret copyWithZone:zone]; // Keychain reference name
        copy.vpnProtocol = [self.vpnProtocol copyWithZone:zone];
        copy.vpnAuthMethod = self.vpnAuthMethod;
        copy.vpnUseExtAuth = self.vpnUseExtAuth;
        
#ifdef STRONG
        copy.pos = self.pos;
#endif

    }
    
    return copy;
}

-(SettingsEntity*)initWithGenericGeneral
{
    self.userName = GENERAL_SETTINGS;
    self.password = GENERAL_SETTINGS;
    self.checkPeriod = 60;
    self.keepInBg = NO;
    self.compression = 0.6;
    self.nMessages = 10;
    self.useBioID = NO;
    self.largeFont = NO;
    self.sortAll = NO;
    self.bgColor = 0;
    self.sortOrder = lsDateNewOnTop;
    self.clearOnBG = YES;
    self.doNotHideAccount = NO;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    dateFormatter.dateFormat = @"k:mm";
    NSDate* dttt = [dateFormatter dateFromString:@"00:00"];
    self.silentTo = dttt;
    self.silentFrom = dttt;
    self.useShortcuts = NO;
    
    return self;
}

-(NSString*)settingsName
{
    NSString* ret = settingsName;
    if (ret == nil || [ret isEqualToString:@""]) {
        ret = self.userName;
    }
    
    return ret;
}

-(SMConnectionType)getTypeFromString:(NSString *)sType
{
    SMConnectionType ret = 0;
    if([sType isEqualToString:@"TLS"]){
        ret = SMConnectionTypeTLS;
    }else if([sType isEqualToString:@"StartTLS"]){
        ret = SMConnectionTypeStartTLS;
    }
    
    return ret;
}

-(MCOAuthType)getAuthTypeFromString:(NSString *)aType
{
    MCOAuthType ret = MCOAuthTypeSASLLogin; // the default should be this one
    if ([aType isEqualToString:@"None"]) {
        ret = MCOAuthTypeSASLNone;
    }else if([aType isEqualToString:@"Plain"]){
        ret = MCOAuthTypeSASLPlain;
    }
    return ret;
}

+(NSArray*) authTypeTitles
{
    static NSArray *_authTitles;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _authTitles = @[//@"None",
                    //@"CRAM-MD5",
                    @"Plain",
                    //@"GSSAPI",
                    //@"DIGEST-MD5",
                    @"Login",
                    //@"SRP",
                    //@"NTLM",
                    //@"Kerberos 4"
        ];
    });
    return _authTitles;
}

+(NSString*)getStringFromAuthType:(MCOAuthType)aType
{
    NSString* ret = @"Login";
    if (aType == MCOAuthTypeSASLPlain) {
        ret = @"Plain";
    }else if(aType == MCOAuthTypeSASLNone){
        ret = @"None";
    }
    
    return ret;
}

@end
