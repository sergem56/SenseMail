//
//  SettingsEntity.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>

#define GENERAL_SETTINGS @"SM1LG"

@interface SettingsEntity : NSObject

@property (nonatomic) NSString* settingsName;
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

@end
