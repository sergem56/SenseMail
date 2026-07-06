//
//  SessionConnectorNew.h
//  SenseMailShare
//
//  Created by Sergey on 13.12.16.
//  Copyright © 2016 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MailCore/MailCore.h>
#import <UIKit/UIKit.h>
#import "CommonStuff.h"

@class SettingsEntity;
@class GTMAppAuthFetcherAuthorization;

#define ERROR_CANCELLED -3
#define ERROR_NO_SUCH_USER -2
#define ERROR_CHECK -1


NS_ASSUME_NONNULL_BEGIN

@interface SessionConnectorNew : NSObject //UIViewController //NSObject
{
    //GTMOAuth2ViewControllerTouch* authViewController;
    //MCOSMTPSession* currentSMTPSession;
    SettingsEntity* settings;
    
    void (^_IMAPCompletionHandler)(NSError* error);
    void (^_SMTPCompletionHandler)( NSError* _Nullable  error);
    BOOL waitingForAuth;
    NSMutableDictionary* handlers;
}

@property(nonatomic, nullable) GTMAppAuthFetcherAuthorization *authorization;

@property (nonatomic, strong, nullable) MCOIMAPSession* imapSession;
@property (nonatomic, strong, nullable) MCOSMTPSession* smtpSession;
@property (nonatomic, strong) NSError* lastError;
@property (nonatomic, retain, nullable) dispatch_semaphore_t working;// = dispatch_semaphore_create(0);BOOL working;

@property (nonatomic, weak) MCOOperation* currentOperation;

-(id)initWithSettings:(SettingsEntity*)sett;
-(void)connectIMAPSessionWithCompletionHandler:(void(^)(NSError*))handler;
-(void)connectIMAPSessionWithCheckAndCompletionHandler:(BOOL)check handler:(void (^)(NSError *))handler;
-(void)connectSMTPSessionWithCompletionHandler:(void(^)(NSError*))handler;
-(void)connectSMTPSessionWithCheckAndCompletionHandler:(BOOL)check handler:(void (^)(NSError *))handler;
-(BOOL)isThisForAddress:(NSString*)address;
-(NSString*)getSettingsName;
-(SettingsEntity*)getSettings;
-(NSString*)getEmailAddress;

-(void)revokeAuth;
-(BOOL)isLoggedIn;
-(void)cancellAllOps;
-(void)cancellAllOpsWithClean:(BOOL)clean;
-(void)disconnectSession;

NS_ASSUME_NONNULL_END
@end
