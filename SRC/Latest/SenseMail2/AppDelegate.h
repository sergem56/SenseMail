//
//  AppDelegate.h
//  SenseMail2
//
//  Created by Sergey on 05.02.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GlobalRouter.h"

@class KeychainWrapper;

static BOOL locked = YES;
static BOOL initForBG = NO;

@protocol OIDAuthorizationFlowSession;

@interface AppDelegate : UIResponder <UIApplicationDelegate>
{
    //KeychainWrapper* smKeychain;
}

@property (strong, nonatomic, nullable) UIWindow *window;

@property (nonatomic, weak, nullable) IBOutlet GlobalRouter* router;

/*! @brief The authorization flow session which receives the return URL from
 \SFSafariViewController.
 @discussion We need to store this in the app delegate as it's that delegate which receives the
 incoming URL on UIApplicationDelegate.application:openURL:options:. This property will be
 nil, except when an authorization flow is in progress.
 */
@property(nonatomic, strong, nullable) id<OIDAuthorizationFlowSession> currentAuthorizationFlow;

@property (nonatomic, copy, nonnull) void (^gotUnseen)(UIBackgroundFetchResult);
-(void)gotUnseenMessages:(int)unseen recent:(int)recent dbgMessage:( NSString* _Nullable )msg;
-(void)clearForBG;
-(void)cleanUp;

+(BOOL)isLocked;
+(void)setLocked:(BOOL)lockedState;

@end

