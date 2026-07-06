//
//  SettingsEntity.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "SettingsEntity.h"

@implementation SettingsEntity

@synthesize settingsName, userName, password, userNick;
@synthesize imapServer, imapPrefix, smtpServer, smtpPort;
@synthesize compression, checksum, keepInBg, checkPeriod;

@end