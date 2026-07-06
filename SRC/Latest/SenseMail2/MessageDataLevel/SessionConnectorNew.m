//
//  SessionConnectorNew.m
//  SenseMailShare
//
//  Created by Sergey on 13.12.16.
//  Copyright © 2016 Sergey. All rights reserved.
//

#import "SessionConnectorNew.h"

#import "AppDelegate.h"
#import "DataStorage.h"
#import "ShortMessageEntity.h"
#import "UserInfoDataManager.h"
#import "SettingsEntity.h"
#import "GlobalRouter.h"
#import "DataManager.h"
#import "FullMessageEntity.h"
#import "CommonProcs.h"
#import "FolderInfo.h"
#import "Encryptor.h"

//#import "GTMOAuth2SignIn.h"

#import "GTMAppAuth.h"
#import "AppAuth.h"
#import "GTMSessionFetcherService.h"

#define CLIENT_ID @"1093441457257-3htrj10go6k05g1lf28ad53vl1v98buj.apps.googleusercontent.com"
#define CLIENT_ID_NEW @"995285298308-58b8vkh81mtcna8s5r7sinbec4oal44c.apps.googleusercontent.com"
#define CLIENT_SECRET nil

#define CLIENT_ID_YAHOO @"dj0yJmk9Z25yaGFFVEFYV01mJmQ9WVdrOWNERXllVmRsTjJzbWNHbzlNQS0tJnM9Y29uc3VtZXJzZWNyZXQmeD1hYw--"
#define CLIENT_SECRET_YAHOO @"70f985e1cd1592d2d31a694d31b267df4fce87dc"

#define CLIENT_ID_OUTLOOK @"0e6e7366-e977-4046-acdc-131dbc97bd94"
#define CLIENT_SECRET_OUTLOOK @"bzlXN28314%)~xztsKFNAD;"

#define KEYCHAIN_ITEM_NAME @"SenseMail OAuth20 %@"
#define KEYCHAIN_ITEM_NAME_NEW @"SenseMail AppAuth2 %@"

static NSString *const kRedirectURI = @"com.googleusercontent.apps.995285298308-58b8vkh81mtcna8s5r7sinbec4oal44c:/oauthredirect";
static NSString *const kIssuer = @"https://accounts.google.com";
static NSString* const gmailScope = @"https://mail.google.com";

static NSString* const yahIssuer = @"https://api.login.yahoo.com";
static NSString* const yahRedirectURI = @"oob";
static NSString* const yahGetAccessToken = @"https://api.login.yahoo.com/oauth2/get_token";
static NSString* const yahScope = @"mail-x";

// Looks like microsoft graph api does not give access to IMAP
static NSString* const outIssuer = @" https://login.microsoftonline.com/0e6e7366-e977-4046-acdc-131dbc97bd94"; //@"msal0e6e7366-e977-4046-acdc-131dbc97bd94://auth";// @"https://login.microsoftonline.com/common/oauth2/authorize"
static NSString* const outRedirectURI = @"com.googleusercontent.apps.0e6e7366-e977-4046-acdc-131dbc97bd94://oauth2redirect";//@"appauth://0e6e7366-e977-4046-acdc-131dbc97bd94";//@"https://login.microsoftonline.com/common/oauth2/nativeclient";//@"msal0e6e7366-e977-4046-acdc-131dbc97bd94://auth"; //@"urn:ietf:wg:oauth:2.0:oob";
static NSString* const outGetAccessToken = @"https://login.microsoftonline.com/common/oauth2/nativeclient";
static NSString* const outScope = @"https://outlook.office.com/Mail.ReadWrite";//@"https://graph.microsoft.com/Mail.ReadWrite";

#define TIMEOUT 10*NSEC_PER_SEC

@interface SessionConnectorNew () <OIDAuthStateChangeDelegate, OIDAuthStateErrorDelegate>

@end

@implementation SessionConnectorNew

-(id)initWithSettings:(SettingsEntity*)sett
{
    if (self = [super init]) {
        settings = sett;
        waitingForAuth = NO;
    }
    return self;
}

-(void)connectIMAPSessionWithCheckAndCompletionHandler:(BOOL)check handler:(void (^)(NSError *))handler
{
    NSString* hash = [Encryptor getUUIDofLength:16];
    if (!handlers) {
        handlers = [[NSMutableDictionary alloc] init];
    }
    [handlers setObject:[handler copy] forKey:hash];
    
    /*
    if ([GlobalRouter sharedManager].needVPN) {
        [[GlobalRouter sharedManager] connectVPNSync];
    }*/
    
    //_IMAPCompletionHandler = [handler copy];
    if (self.imapSession == nil || !self.imapSession.username) {
        [self connectNewIMAPSession:check hash:hash];
    }else{
        @try {
            MCOIMAPOperation *noopOperation = [self.imapSession noopOperation];
            //NSLog(@"----- Noop hash is %lu -----", (unsigned long)noopOperation.hash);
            noopOperation.urgent = YES;
            [noopOperation start:^(NSError *error) {
                if (error) {
                    if ([error.domain isEqual:(MCOErrorDomain)] && error.code == 1 && !check) {
                        // This is the connection error, probably the server is unreachable, try reconnecting with forced check, perhaps the server is up already
                        [self connectNewIMAPSession:YES hash:hash];
                    }else{
                        //NSLog(@"Connect IMAP Session error %@", error.domain);
                        [self connectNewIMAPSession:check hash:hash];
                    }
                }else{
                    [self IMAPReady:error hash:hash];
                }
            }];
        } @catch (NSException *exception) {
            NSLog(@"Got an exception %@", exception.description);
        }
    }
}

-(void)connectIMAPSessionWithCompletionHandler:(void (^)(NSError *))handler
{
    //@synchronized (self.imapSession) {
        [self connectIMAPSessionWithCheckAndCompletionHandler:NO handler:handler];
    //}
}

-(void)connectNewIMAPSession:(BOOL)check hash:(NSString*)hash
{
    if([settings.userName containsString:@"@gmail.com"]){
        [self startOAuth2:NO scope:gmailScope hash:hash];//@"https://mail.google.com"];
        
    // Looks like outlook does not support IMAP access via OAuth, cuz I can authorize
    // connection, but when I try to connect IMAP session, I get a error (cannot authenticate...)
    // Also found an answer https://stackoverflow.com/questions/29747477/imap-auth-in-office-365-using-oauth2
    // Need to use REST API to work with messages, but it's a bit too much...
        
    //}else if([settings.userName containsString:@"@outlook.com"]){
    //    [self startOAuth2:NO scope:outScope];//@"https://mail.google.com"];
    //}else if([settings.userName containsString:@"@yahoo.com"]){
    //    [self startOAuth2:NO scope:yahScope];
    }else{
        if ([settings.imapServer isEqualToString:@""]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                NSMutableDictionary* details = [NSMutableDictionary dictionary];
                [details setValue:@"IMAP server setting is empty" forKey:NSLocalizedDescriptionKey];
                NSError* error = [NSError errorWithDomain:@"SenseMail" code:120 userInfo:details];
                [self IMAPReady:error hash:hash];
                return;
            });
        }
        MCOIMAPSession* tmp = [[MCOIMAPSession alloc] init];
        self.imapSession = tmp;
        tmp.hostname = settings.imapServer;
        if (settings.imapPort == 0) {
            tmp.port = 993;
        }else{
            tmp.port = (int)settings.imapPort;
        }
        
        tmp.username = settings.userName;
        tmp.password = settings.password;
        //tmp.connectionType = MCOConnectionTypeTLS;
        tmp.connectionType = (MCOConnectionType)settings.connectionTypeIMAP;
        if(tmp.connectionType == 0) // Don't allow unprotected connection
            tmp.connectionType = MCOConnectionTypeTLS;
        
        // Check cert. Need to check it
        [tmp setCheckCertificateEnabled:YES];
        
// !!!!!!!!! Conection Logger
        /*
        [tmp setConnectionLogger:^(void * connectionID, MCOConnectionLogType type, NSData * data)
        {
            NSLog(@"START = %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
        }];
        
        */
        if (settings.userName != nil) {
            [[GlobalRouter sharedManager].accountsNames setObject:settings.settingsName forKey:settings.userName];
        }
        if(check){
            MCOIMAPOperation* imapCheckOp = [tmp checkAccountOperation];
            [imapCheckOp start:^(NSError *error) {
                if (error) {
                    NSLog(@"Error connecting IMAP session %@",error.localizedDescription);
                }
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                    [self IMAPReady:error hash:hash];
                });
            }];
        }else{
            [self IMAPReady:nil hash:hash];
        }
    }
}

-(void)connectSMTPSessionWithCompletionHandler:(void (^)(NSError *))handler
{
    [self connectSMTPSessionWithCheckAndCompletionHandler:NO handler:handler];
}

-(void)connectSMTPSessionWithCheckAndCompletionHandler:(BOOL)check handler:(void (^)(NSError *))handler
{
    _SMTPCompletionHandler = [handler copy];
    
    self.smtpSession = [[MCOSMTPSession alloc] init];
    
    self.smtpSession.hostname = settings.smtpServer;
    self.smtpSession.port = (uint)settings.smtpPort;
    
    self.smtpSession.username = settings.userName;
    self.smtpSession.connectionType = (MCOConnectionType)settings.connectionTypeSMTP;
    if(self.smtpSession.connectionType == 0) // Don't allow unprotected connection
        self.smtpSession.connectionType = MCOConnectionTypeTLS;
    
#if DEBUG
    [self.smtpSession setConnectionLogger:^(void * connectionID, MCOConnectionLogType type, NSData * data) {
        //NSLog(@"event logged: %li withData: %@", (long)type, data);
        NSLog(@"MCOIMAPSession: [%li] %@", (long)type, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }];
#endif
    
    if([settings.userName containsString:@"gmail.com"]){
        [self startOAuth2:YES scope:gmailScope hash:nil];//@"https://mail.google.com"];
    //}else if([settings.userName containsString:@"outlook.com"]){
    //    [self startOAuth2:YES scope:outScope];
    }else{
        
        self.smtpSession.password = settings.password;
        // Temp to migrate to SMTPAuthType
        if (settings.SMTPAuthType == 0) {
            settings.SMTPAuthType = MCOAuthTypeSASLLogin;
        }
        self.smtpSession.authType = settings.SMTPAuthType; //MCOAuthTypeSASLLogin;//(MCOAuthTypeSASLPlain | MCOAuthTypeSASLLogin);
        
        // DO NOT check connection since some mail servers allow only one message per connection
        // to get rid of spam messages. Checking a connection counts...
        if(check){
            MCOSMTPOperation * op = [self.smtpSession checkAccountOperationWithFrom:[MCOAddress addressWithMailbox:settings.userName]];
            [op start:^(NSError * error) {
                if(error){
                    NSLog(@"smtp done: %@", error);
                    self.smtpSession.authType = MCOAuthTypeSASLLogin;
                }
                [self SMTPReady:error];
            }];
        }else{
            [self SMTPReady:nil];
        }
    }
}

/*
That should be used to cancel everything before shutting down,
not before starting a new operation, since it gonna zero-out
the session on disconnect and the cancelling op is not sync
 */
-(void)cancellAllOps
{
    [self cancellAllOpsWithClean:NO];
}

-(void)cancellAllOpsWithClean:(BOOL)clean
{
    //dispatch_semaphore_t dsem = dispatch_semaphore_create(0);
    if (self.imapSession != nil) {
        @synchronized (self.imapSession) {
            //[self.imapSession cancelAllOperations];
            if (self.currentOperation) {
                [self.currentOperation cancel];
            }
            __weak __typeof__(self) weakSelf = self;
            MCOIMAPOperation* op = [self.imapSession disconnectOperation];
            [op start:^(NSError * __nullable error) {
                //session = nil;
                __strong __typeof__(self) strongSelf = weakSelf;
    #if DEBUG
                if (error) {
                    NSLog(@"Session cancelled with the error %@", error.localizedDescription);
                }else{
                    NSLog(@"%@: Session cancelled successfully", strongSelf?strongSelf->settings.userName:@"Deleted");
                }
    #endif
                
                strongSelf->waitingForAuth = NO;
                self.imapSession = nil;
                strongSelf->handlers = nil;
                self.currentOperation = nil;
                self.smtpSession = nil;
                //dispatch_semaphore_signal(dsem);
            }];
            
            // Wait? no
            /*long res = dispatch_semaphore_wait(dsem, dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC));
            if (res != 0) {
                // Timeout!
                NSLog(@"Cancel timeout");
            }*/
        }
    }
    /*
    waitingForAuth = NO;
    self.imapSession = nil;
    handlers = nil;
    self.currentOperation = nil;
    self.smtpSession = nil;
     */
    if(clean){
        settings = nil;
        // Cannot delete the sessions since it might be used somewhere in a lengthy op. Disconnecting doesn't cancel callbacks.
        /*@synchronized ([[GlobalRouter sharedManager] getListRouter].dataStore.imapSessions) {
            [[[GlobalRouter sharedManager] getListRouter].dataStore.imapSessions removeObject:self];
        }*/
    }
}

-(void)disconnectSession
{
    if (self.imapSession != nil) {
        //@synchronized (self.imapSession) {
            if (self.currentOperation) {
                [self.currentOperation cancel];
            }
            __weak __typeof__(self) weakSelf = self;
            MCOIMAPOperation* op = [self.imapSession disconnectOperation];
            [op start:^(NSError * __nullable error) {
                __strong __typeof__(self) strongSelf = weakSelf;
    #if DEBUG
                if (error) {
                    NSLog(@"Session disconnected with the error %@", error.localizedDescription);
                }else{
                    NSLog(@"%@: Session disconnected successfully",strongSelf? strongSelf->settings.userName:@"Null'ed");
                }
    #endif
                strongSelf->waitingForAuth = NO;
                self.imapSession = nil;
                strongSelf->handlers = nil;
                self.currentOperation = nil;
            }];
        //}
    }
}

#pragma mark -OAuth 2.0

// Threading model:
// We have two semaphores - authSem and conSem.
// authSem handles access to web-form to login to GMAIL service, so that the form is displayed one at a time.
// We can have several authentication semaphores if there is a condition then an access token has been revoked.
// In that case
// conSem handles connection, so that if the session is lost, it reconnects the session before going further.

-(void)doRevokeFromServer
{
    if(self.authorization.authState.refreshToken == nil)return;
    
    GTMSessionFetcherService* fetcherService = [[GTMSessionFetcherService alloc] init];
    
    NSString *urlStr = @"https://accounts.google.com/o/oauth2/revoke";
    
    GTMSessionFetcher *myFetcher = [fetcherService fetcherWithURLString:urlStr];
    myFetcher.retryEnabled = YES;
    myFetcher.comment = @"Revoke auth";

    myFetcher.bodyData = [[NSString stringWithFormat:@"token=%@", self.authorization.authState.refreshToken] dataUsingEncoding:NSUTF8StringEncoding];

    [myFetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
        if (error != nil) {
          // Server status code or network error.
          //
          // If the domain is kGTMSessionFetcherStatusDomain then the error code
          // is a failure status from the server.
            NSLog(@"Error = %@", error.localizedDescription);
        } else {
          // Fetch succeeded.
            NSLog(@"Revoked");
        }
    }];

}

-(void)revokeAuth
{
    GTMAppAuthFetcherAuthorization* auth =
    [GTMAppAuthFetcherAuthorization authorizationFromKeychainForName:[NSString stringWithFormat:KEYCHAIN_ITEM_NAME_NEW, settings.userName]];
    
    if(auth){
        // Revoke from server
        [self doRevokeFromServer];
        
        // Remove from keychain. It is here, not in the server success part to be sure that the invalid stuff
        // can be removed from the keychain
        [GTMOAuth2KeychainCompatibility removeAuthFromKeychainForName:[NSString stringWithFormat:KEYCHAIN_ITEM_NAME_NEW, settings.userName]];
    }
}

// For GMAIL only...
- (void) startOAuth2:(BOOL)forSMTP scope:(NSString*)mailScope hash:(NSString*)hash
{
    if (waitingForAuth) {
        return;
    }
    
    waitingForAuth = YES;
    
    [self loadState];
    __weak __typeof(self) weakSelf = self;
    if (_authorization.canAuthorize){
        [self.authorization authorizeRequest:nil completionHandler:^(NSError * _Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if(error){
                if(error.domain == OIDOAuthTokenErrorDomain){
                    // Need to re-authorize, token is invalid or has been revoked
                    [strongSelf setGtmAuthorization:nil];
                    [strongSelf authWithAutoCodeExchange:forSMTP mailScope:mailScope hash:hash];
                }else{
                    // Try again
                    // Here is a strange bug - returning from bg mode it says that connection is lost...
                    // if try again the same - it's OK
                    strongSelf->waitingForAuth = NO;
                    [strongSelf startOAuth2:forSMTP scope:mailScope hash:hash];
                }
                NSLog(@"ERROR - %@", error.localizedDescription);
            }else{
                if(!strongSelf)return;
                if(forSMTP){
                    // Send
                    strongSelf.smtpSession.authType = MCOAuthTypeXOAuth2;
                    strongSelf.smtpSession.OAuth2Token = strongSelf->_authorization.authState.lastTokenResponse.accessToken;
                    [strongSelf SMTPReady:nil];
                }else{
                    [strongSelf setGtmAuthorization:strongSelf->_authorization];
                    [strongSelf loadAccount2:strongSelf->_authorization hash:hash];
                }
            }
        }];
        //[self loadAccount2:self.authorization];
    }else{
        [self authWithAutoCodeExchange:forSMTP mailScope:mailScope hash:hash];
    }
    
}

-(void)doNothing
{
    GTMSessionFetcherService *fetcherService = [[GTMSessionFetcherService alloc] init];
    fetcherService.authorizer = self.authorization;
    
    // Creates a fetcher for the API call.
    NSURL *userinfoEndpoint = [NSURL URLWithString:@"https://accounts.google.com/o/oauth2/v2/auth"];
    GTMSessionFetcher *fetcher = [fetcherService fetcherWithURL:userinfoEndpoint];
    [fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
        // Checks for an error.
        if (error) {
            NSLog(@"Nothing error %@",error.localizedDescription);
        }else{
            
        }
    }];

}

#pragma mark GTMAppAuth

-(void)authWithAutoCodeExchange:(BOOL)forSMTP mailScope:(NSString*)mailScope hash:(NSString*)hash
{
    NSURL *issuer;
    NSURL *redirectURI;
    NSString* CLIENT;
    NSString* clientSecret = nil;
    NSArray* scopes;
    __weak __typeof__(self) weakSelf = self;
    
    if([mailScope isEqualToString:gmailScope]){
        issuer = [NSURL URLWithString:kIssuer];
        redirectURI = [NSURL URLWithString:kRedirectURI];
        CLIENT = CLIENT_ID_NEW;
        scopes = @[OIDScopeOpenID, OIDScopeEmail,mailScope];
    }else if([mailScope isEqualToString:outScope]){
        issuer = [NSURL URLWithString:outIssuer];
        redirectURI = [NSURL URLWithString:outRedirectURI];
        CLIENT = CLIENT_ID_OUTLOOK;
        clientSecret = CLIENT_SECRET_OUTLOOK;
        scopes = @[OIDScopeOpenID, OIDScopeEmail, OIDScopeProfile, @"offline_access", mailScope ,@"https://outlook.office.com/Mail.Send"];
    }
    /*else{ // YAHOO mail is not working yet, cannot select a mail scope registering application...
        issuer = [NSURL URLWithString:yahIssuer];
        redirectURI = [NSURL URLWithString:yahRedirectURI];
        CLIENT = CLIENT_ID_YAHOO;
    }*/
    
    //[self logMessage:@"Fetching configuration for issuer: %@", issuer];
    
    // discovers endpoints
    [OIDAuthorizationService discoverServiceConfigurationForIssuer:issuer
    completion:^(OIDServiceConfiguration *_Nullable configuration, NSError *_Nullable error) {
        __strong __typeof__(self) strongSelf = weakSelf;
        if (!configuration) {
            //[self logMessage:@"Error retrieving discovery document: %@", [error localizedDescription]];
            //[self setGtmAuthorization:nil];
            //return;
            
            NSURL *authorizationEndpoint =
            [NSURL URLWithString:@"https://login.microsoftonline.com/common/oauth2/v2.0/authorize"];
            NSURL *tokenEndpoint =
            [NSURL URLWithString:@"https://login.microsoftonline.com/common/oauth2/v2.0/token"];
            configuration =
            [[OIDServiceConfiguration alloc] initWithAuthorizationEndpoint:authorizationEndpoint
                                                             tokenEndpoint:tokenEndpoint];
        }
        
        //[self logMessage:@"Got configuration: %@", configuration];
        
        // builds authentication request
        OIDAuthorizationRequest *request =
        [[OIDAuthorizationRequest alloc] initWithConfiguration:configuration
                                                      clientId:CLIENT//CLIENT_ID_NEW
                                                  //clientSecret:clientSecret
                                                        scopes:scopes
                                                   redirectURL:redirectURI
                                                  responseType:OIDResponseTypeCode
                                          additionalParameters:@{@"login_hint":strongSelf->settings.userName /*, @"nonce":CLIENT_SECRET_YAHOO*/}];
        // performs authentication request
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        //[self logMessage:@"Initiating authorization request with scope: %@", request.scope];
        
        //__weak __typeof(self) weakSelf = self;
        appDelegate.currentAuthorizationFlow =
        [OIDAuthState authStateByPresentingAuthorizationRequest:request
                                       presentingViewController:[[GlobalRouter sharedManager] getDetailNavController] //getTopViewController] //self
                                           callback:^(OIDAuthState *_Nullable authState,
                                                      NSError *_Nullable error) {
                                                __strong __typeof__(self) strongSelf = weakSelf;
                                               if (authState) {
                                                   GTMAppAuthFetcherAuthorization *authorization =
                                                   [[GTMAppAuthFetcherAuthorization alloc] initWithAuthState:authState];
                                                   
                                                   if(!authState.lastTokenResponse.accessToken){
                                                       NSLog(@"ERROR: NO Access Token");
                                                   }
                                                   
                                                   if(![authorization.userEmail isEqualToString:strongSelf->settings.userName]){
                                                       //[CommonProcs showMessage:NSLocalizedString(@"The user not found", nil) title:NSLocalizedString(@"Error", nil)];
                                                       NSLog(@"Error: the User is different");
                                                       [weakSelf setGtmAuthorization:nil];
                                                       // Cancel check and enable button
                                                       NSError *errMsg = [NSError errorWithDomain:@"SessionCheck" code:1001 userInfo:@{
                                                       NSLocalizedDescriptionKey:@"User not found" }];
                                                       if(forSMTP){
                                                           [weakSelf SMTPReady:errMsg];
                                                       }else{
                                                           [weakSelf IMAPReady:errMsg hash:hash];
                                                       }
                                                       return;
                                                   }
                                                   
                                                   [weakSelf setGtmAuthorization:authorization];
                                                   [self.authorization authorizeRequest:nil completionHandler:^(NSError * _Nullable error) {
                                                       __strong typeof(weakSelf) strongSelf = weakSelf;
                                                       if(error){
                                                           NSLog(@"ERROR %@",error.localizedDescription);
                                                       }
                                                       if(forSMTP){
                                                           // Send
                                                           strongSelf.smtpSession.authType = MCOAuthTypeXOAuth2;
                                                           strongSelf.smtpSession.OAuth2Token = strongSelf->_authorization.authState.lastTokenResponse.accessToken;
                                                           [strongSelf SMTPReady:nil];
                                                       }else{
                                                           [strongSelf setGtmAuthorization:authorization];
                                                           [strongSelf loadAccount2:authorization hash:hash];
                                                       }
                                                   }];
                                                   
                                                   //[self logMessage:@"Got authorization tokens. Access token: %@", authState.lastTokenResponse.accessToken];
                                               } else {
                                                   [weakSelf setGtmAuthorization:nil];
                                                   //[self logMessage:@"Authorization error: %@", [error localizedDescription]];
                                                   NSError *errMsg = [NSError errorWithDomain:@"SessionCheck" code:1002 userInfo:@{
                                                   NSLocalizedDescriptionKey:@"Cancelled",
                                                   NSLocalizedFailureReasonErrorKey:@"No alert"
                                                   }];
                                                   if(forSMTP){
                                                       [weakSelf SMTPReady:errMsg];
                                                   }else{
                                                       [weakSelf IMAPReady:errMsg hash:hash];
                                                   }
                                                   return;
                                               }
                                           }];
    }];
}

- (void)loadAccount2:(GTMAppAuthFetcherAuthorization *)oauth hash:(NSString*)hash
{
    MCOIMAPSession* tmp = [[MCOIMAPSession alloc] init];
    self.imapSession = tmp;
    tmp.hostname = settings.imapServer;
    //tmp.port = 993;
    if (settings.imapPort == 0) {
        tmp.port = 993;
    }else{
        tmp.port = (int)settings.imapPort;
    }
    tmp.username = settings.userName;
    tmp.password = nil;
    //tmp.connectionType = MCOConnectionTypeTLS;
    tmp.connectionType = (MCOConnectionType)settings.connectionTypeIMAP;
    if(tmp.connectionType == 0) // Don't allow unprotected connection
        tmp.connectionType = MCOConnectionTypeTLS;
    
    tmp.OAuth2Token = oauth.authState.lastTokenResponse.accessToken;
    tmp.authType = MCOAuthTypeXOAuth2;
    
    // Check cert. Need to check it
    [tmp setCheckCertificateEnabled:YES];
    
    if (tmp.username != nil && [GlobalRouter sharedManager].accountsNames && settings.settingsName) {
        [[GlobalRouter sharedManager].accountsNames setObject:settings.settingsName forKey:tmp.username];
    }
    
    //CFMutableArrayRef certs = [self.imapSession ge
    
    //MCOIMAPOperation* imapCheckOp = [tmp checkAccountOperation];
    //[imapCheckOp start:^(NSError *error) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            [self IMAPReady:nil hash:hash];
        });
    //}];
    
    return;
    /*/
    MCOIMAPOperation* imapCheckOp = [tmp checkAccountOperation];
    [imapCheckOp start:^(NSError *error) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            [self IMAPReady:error];
        });
    }];
     */
}

/*! @brief Saves the @c GTMAppAuthFetcherAuthorization to @c NSUSerDefaults.
 */
- (void)saveState {
    if (_authorization.canAuthorize) {
        BOOL res = [GTMAppAuthFetcherAuthorization saveAuthorization:_authorization
                                        toKeychainForName:[NSString stringWithFormat:KEYCHAIN_ITEM_NAME_NEW, settings.userName]];
        NSLog(@"Auth saved with res %@", res?@"YES":@"NO");
    } else {
        [GTMAppAuthFetcherAuthorization removeAuthorizationFromKeychainForName:[NSString stringWithFormat:KEYCHAIN_ITEM_NAME_NEW, settings.userName]];
    }
}

/*! @brief Loads the @c GTMAppAuthFetcherAuthorization from @c NSUSerDefaults.
 */
- (void)loadState {
    
    GTMAppAuthFetcherAuthorization* authorization =
    [GTMAppAuthFetcherAuthorization authorizationFromKeychainForName:[NSString stringWithFormat:KEYCHAIN_ITEM_NAME_NEW, settings.userName]];
    
    // If no data found in the new format, try to deserialize data from GTMOAuth2
    if (!authorization) {
        // Tries to load the data serialized by GTMOAuth2 using old keychain name.
        // If you created a new client id, be sure to use the *previous* client id and secret here.
        authorization =
        [GTMOAuth2KeychainCompatibility authForGoogleFromKeychainForName:[NSString stringWithFormat:KEYCHAIN_ITEM_NAME, settings.userName]
                                                                clientID:CLIENT_ID
                                                            clientSecret:CLIENT_SECRET];
        if (authorization) {
            // Remove previously stored GTMOAuth2-formatted data.
            [GTMOAuth2KeychainCompatibility removeAuthFromKeychainForName:[NSString stringWithFormat:KEYCHAIN_ITEM_NAME, settings.userName]];
            // Serialize to Keychain in GTMAppAuth format.
            [GTMAppAuthFetcherAuthorization saveAuthorization:(GTMAppAuthFetcherAuthorization *)authorization
                                            toKeychainForName:[NSString stringWithFormat:KEYCHAIN_ITEM_NAME_NEW, settings.userName]];
        }
    }
    
    [self setGtmAuthorization:(GTMAppAuthFetcherAuthorization*)authorization];
}

- (void)setGtmAuthorization:(GTMAppAuthFetcherAuthorization*)authorization {
    if ([_authorization isEqual:authorization] && authorization != nil) {
        return;
    }
    _authorization = authorization;
    [self stateChanged];
}

- (void)stateChanged {
    [self saveState];
}

- (void)didChangeState:(OIDAuthState *)state {
    [self stateChanged];
}

- (void)authState:(OIDAuthState *)state didEncounterAuthorizationError:(NSError *)error {
    //[self logMessage:@"Received authorization error: %@", error];
}

-(BOOL)isLoggedIn
{
    GTMAppAuthFetcherAuthorization* auth =
    [GTMAppAuthFetcherAuthorization authorizationFromKeychainForName:[NSString stringWithFormat:KEYCHAIN_ITEM_NAME_NEW, settings.userName]];
    
    // Return auth non-nil to be able to clear invalid auth from keychain 
    return auth != nil;// auth.canAuthorize;
}

// Connection ready, call-back needed
-(void)SMTPReady:(NSError*)error
{
    waitingForAuth = NO;
    _SMTPCompletionHandler(error);
}

-(void)IMAPReady:(NSError*)error hash:(NSString*)hash
{
    waitingForAuth = NO;
    self.lastError = error;
    if (error) {
        NSLog(@"%@: Error connecting session %@", settings.userName, error.localizedDescription);
    }else{
        NSLog(@"Session connected successfully for %@ (%@)", settings.userName, self.imapSession.description);
    }
    //_IMAPCompletionHandler(error);
    if (hash) {
        void (^handler)(NSError*) = [handlers objectForKey:hash];
        if(handler){
            handler(error);
            [handlers removeObjectForKey:hash];
        }
    }
}


#pragma mark -------------

-(BOOL)isThisForAddress:(NSString *)address
{
    return [settings.userName isEqualToString:address];
}

-(NSString*)getSettingsName
{
    return settings.settingsName?settings.settingsName:@"";
}

-(NSString*)getEmailAddress
{
    return settings.userName?settings.userName:@"";
}

-(SettingsEntity*)getSettings
{
    return settings;
}

@end
