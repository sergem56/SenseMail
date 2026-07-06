//
//  AppDelegate.m
//  SenseMail2
//
//  Created by Sergey on 05.02.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "AppDelegate.h"
#import "GlobalRouter.h"
#import "Encryptor.h"
#import "CommonStuff.h"
#import "DataManager.h"
#import "GTMAppAuth.h"
#import "OIDAuthorizationService.h"
#import "KeychainWrapper.h"
#import "Pin/PinInteractor.h"

#import "CommonProcs.h"
#import "Gallery/GalleryCollectionViewController.h"
#import "SettingsEntity.h"

#import "UITextViewWorkaround.h"

#if USESEC
#import <NetworkExtension/NetworkExtension.h>
#endif

@interface AppDelegate ()

@end

@implementation AppDelegate

//#define smSavedPinAccount @"smSalt"

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    /*
     UIViewController *vc1 = ...;
     UIViewController *vc2 = ...;
     UITabBarController *tbc = [[UITabBarController alloc] init]; tbc.viewControllers = [NSArray arrayWithObjects: vc1, vc2, ..., nil]; [vc1 release]; [vc2 release];
     [window addSubview:tbc.view];
     [window makeKeyAndVisible];
     
     */
    
    //UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    //UIViewController *thisController = [storyboard instantiateViewControllerWithIdentifier:@"MessageList"];
    //[[GlobalRouter sharedManager] pushView:thisController];
    
/////////////////////////
////////////////////////
    
#pragma mark Receipt-migration to an in-app purchase
    /*
    // To test that one need to add a sandbox tester user in iTunes Connect and login with that user
    // to a device (iTunes and AppStore)
    NSData *dataReceipt = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] appStoreReceiptURL]];
    if (dataReceipt == nil) {
        exit(173); // That is for test purpose, the system should auto-install a receipt
    }
    NSString *receipt = [dataReceipt base64EncodedStringWithOptions:0];
     //original_application_version
     //https://stackoverflow.com/questions/37566579/ios-test-app-receipt-validation?rq=1
    */
#pragma mark End receipt
    
    if(application.applicationState == UIApplicationStateBackground){
        
    }else{
        [GlobalRouter sharedManager];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //[[GlobalRouter sharedManager] initialPush];
        });
        
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //    [[GlobalRouter sharedManager] initialPush];
        //});
    }
    
    
    //[[GlobalRouter sharedManager] doShowEmpty];
    
    //[[GlobalRouter sharedManager] initialPush];
    
    // The app will be killed after 10 minutes in bg, but I hope it'll be recalled to fetch data. This brings the pin-code issue...
#if PERIODIC_CHECK == 2
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
#endif
    
    // These are for iOS 8.0 and later...
#if PERIODIC_CHECK
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
        //[[UIApplication sharedApplication] registerForRemoteNotifications];
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes: (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories: nil]];
    }
#endif
    /*
    dispatch_queue_t pingQueue = dispatch_queue_create("Ping Queue",NULL);
    dispatch_async(pingQueue,^{
        [CommonProcs startPing];
    });
    */
    
    //smKeychain = [[KeychainWrapper alloc] init];
    
    // Xcode 11.2 bug workaround. Crashed with error:
    // 'Could not instantiate class named _UITextLayoutView because no class named _UITextLayoutView was found; the class needs to be defined in source code or linked in from a library (ensure the class is part of the correct target)'
    //[UITextViewWorkaround executeWorkaround];
    
    // Set the preferred language, looks like an empty array returns to the system prefs - NO! it makes the en to be the only language. Also it corrupts system preferred languages in settings. Do not do this.
    //[[NSUserDefaults standardUserDefaults] setObject:@[@"Base"]/*[NSArray arrayWithObjects:@"ru", @"en", @"fr", nil]*/ forKey:@"AppleLanguages"];
    //[[NSUserDefaults standardUserDefaults] synchronize];
    
    //NSString * language = [NSLocale preferredLanguages][0];// preferredLanguages] firstObject];
    //NSLog(@"System lang is %@", language);
    
    return YES;
}

-(void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings

{
    if (notificationSettings.types != 0) {
#if PERIODIC_CHECK == 1
        [[UIApplication sharedApplication] registerForRemoteNotifications];
#endif
    }
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    char* token = (char*)deviceToken.bytes;
    NSString* tockStr = @"";
    for (int i=0;i<deviceToken.length; i++) {
        tockStr = [tockStr stringByAppendingString:[NSString stringWithFormat:@"%02.2hhx", token[i]]];
    }
    
#ifdef DEBUG
    NSLog(@"Device token = %@", tockStr);
#endif
    
    [self httpPostDevID:tockStr];
}

-(void) httpPostDevID:(NSString*)devID
{
    NSURLSessionConfiguration *defaultConfigObject = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration: defaultConfigObject delegate: nil delegateQueue: [NSOperationQueue mainQueue]];
    
    NSURL *url = [NSURL URLWithString:@"https://sensemail.link/refreshID.php"];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    NSString *params = [NSString stringWithFormat:@"devid=%@&per=%i&submit=true", devID, 40];// @"name=Ravi&loc=India&age=31&submit=true";
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionDataTask *dataTask =[defaultSession dataTaskWithRequest:urlRequest
                                                       completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
#ifdef DEBUG
           NSLog(@"Response:%@ %@\n", response, error);
#endif
           if(error == nil)
           {
#ifdef DEBUG
               NSString * text = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
               NSLog(@"Data = %@",text);
#endif
           }
           
       }];
    [dataTask resume];
    
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Failed to register - %@", error.localizedDescription);
    
    // TEST
    [self httpPostDevID:@"TEST DEV ID"];
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    // Do nothing if in foreground...
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive){
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }
    
    NSDictionary* aps = userInfo[@"aps"];
    long res = ((NSString*)(aps[@"content-available"])).integerValue;

    if (res == 1) {
#ifdef DEBUG
        NSLog(@"Remote Fetch!");
#endif
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //if ([GlobalRouter sharedManager].pin == nil) {
            //[GlobalRouter sharedManager].pin = @"qq";
            NSString* kkk = [[UIDevice currentDevice].identifierForVendor UUIDString];
            Encryptor* cryptor = [[Encryptor alloc] initWithSimpleKey:kkk];
            
        NSString* savedPin = [CommonProcs getStringFromKeychain:smSavedPinAccount service:@"SM"]; //[CommonProcs getStringFromKeychainForAccount:smSavedPinAccount]; //[smKeychain getKeychainDataForAccount:smSavedPinAccount];
            //NSLog(@"Saved pin = %@", savedPin);
            
            if (savedPin != nil) {
                [GlobalRouter sharedManager].pin = [cryptor decryptFromBase64:savedPin]; //[[NSUserDefaults standardUserDefaults] objectForKey:@"salt"]];
            }else{
                completionHandler(UIBackgroundFetchResultNoData);
                return;
            }
        //}
    
        [[GlobalRouter sharedManager] getNewMessagesCount];
        self.gotUnseen = completionHandler;
        //});
    }else{
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

-(void)gotUnseenMessages:(int)unseen recent:(int)recent dbgMessage:(NSString*)msg
{
    // Need to check the last unseen count and if it differs, show notification
    // Need a more reliable way to do it. Sometimes it cannot get the message count for one account and
    // returns less messages than it is. Next time it's OK and the message count is much higher and fires
    // a false notification.
    // Recent messages are better, but not all servers support it.
    
    //long lastUnseen = [(NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"lastun"] integerValue];
    //[UIApplication sharedApplication].applicationIconBadgeNumber;
    if (recent != 0 && unseen != [UIApplication sharedApplication].applicationIconBadgeNumber && unseen != -2) {
        // Clear the notifications, should set the badge to 0 to make it work
        if(unseen != -2){ // -2 means timeout, do not change the badge
            [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
            [[UIApplication sharedApplication] cancelAllLocalNotifications];
        }
        
        UILocalNotification *notification = [[UILocalNotification alloc] init];
        notification.fireDate = [[NSDate date] dateByAddingTimeInterval:1];
        if (recent == -1) { // there were changes, but no idea what
            notification.alertBody = [msg isEqualToString:@""]?NSLocalizedString(@"There are changes in your inbox", nil):msg;
        }else{
            notification.alertBody = [msg isEqualToString:@""]?[NSString stringWithFormat: recent == 1?NSLocalizedString(@"%li new message",nil):NSLocalizedString(@"%li new messages",nil), recent]:msg;
        }
        notification.alertTitle = NSLocalizedString(@"SenseMail",nil);
        
        // Check if it's night now. Need to get it to the settings, but for the time being it's OK here.
        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:[NSDate date]];
        NSInteger currentHour = [components hour];
        NSInteger currentMinute = [components minute];
        NSInteger currentSecond = [components second];

        long fH = 22, fM = 0, tH = 8, tM = 0;
        if ([GlobalRouter sharedManager].allSettings.count > 0) {
            SettingsEntity* set = [GlobalRouter sharedManager].allSettings[0];
            NSDateComponents *componentsFrom = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:set.silentFrom];
            if (componentsFrom) {
                fH = [componentsFrom hour];
                fM = [componentsFrom minute];
            }
            
            NSDateComponents *componentsTo = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:set.silentTo];
            if(componentsTo){
                tH = [componentsTo hour];
                tM = [componentsTo minute];
            }
        }
        
        if ((currentHour < tH || (currentHour == tH && currentMinute < tM)) || (currentHour > fH || (currentHour == fH && (currentMinute > fM || currentSecond > 0)))) {
            // Night
            notification.soundName = nil;
        }else{
            notification.soundName = UILocalNotificationDefaultSoundName;
        }
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
        [GlobalRouter sharedManager].needToReloadOnStart = YES;
    }
    //[[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%i",unseen] forKey:@"lastun"];
    if(unseen != -2){ // not timeout
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].applicationIconBadgeNumber = unseen;
        });
    }
    NSLog(@"Count = %i", unseen);
    if(self.gotUnseen != nil){
        self.gotUnseen(UIBackgroundFetchResultNewData);
    }else{
        
    }
    // Prevent a collision when fetch ends after going to foreground
    if(([AppDelegate isLocked] && [GlobalRouter sharedManager].clearOnBGSetting) || ([AppDelegate isLocked] && [GlobalRouter sharedManager].needToClearBG)){
        [self clearForBG];
    }else{
        
    }
}

-(void)clearForBG
{
    /*
    [CommonProcs saveToKeychainAlways:@"Test string" account:smSavedPinAccount service:@"SM"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString* savedPin = [CommonProcs getStringFromKeychain:smSavedPinAccount service:@"SM"];
        NSLog(@"Saved data clear = %@", savedPin);
    });
    */
    
    //[GlobalRouter sharedManager].pin = @"0000 0000 0000 0000 0000 0000 0000"; // That does not actually overwrites the data, just moves a pointer...
    //NSMutableString* test = [NSMutableString stringWithString:@"test654"];
    //[CommonProcs wipeString:test];
    
    if([GlobalRouter sharedManager].allSettings){
        [CommonProcs wipeString:[GlobalRouter sharedManager].pin];
        [GlobalRouter sharedManager].pin = nil;
        [[[GlobalRouter sharedManager] getListRouter] clearList];
    }else{
        NSLog(@"Pin not cleared, it is empty");
    }
    // Clear sessions?
    [[[GlobalRouter sharedManager] getListRouter].manager clearSessions];
    
    // Clear saved accounts names
    [[GlobalRouter sharedManager].accountsNames removeAllObjects];
    //[GlobalRouter sharedManager].allSettings = [[NSArray alloc] init]; // Bugs
    [[GlobalRouter sharedManager].otherFolders removeAllObjects]; // Works OK!
    
    // Clear Encryptors' cash
    [[GlobalRouter sharedManager] clearEncoders];
    
    //[GlobalRouter sharedManager].currentFilter = nil;
    [[[GlobalRouter sharedManager] getListRouter] clearFilter];
    
    [[GlobalRouter sharedManager].possibleAddresses removeAllObjects];
    [GlobalRouter sharedManager].possibleAddresses = nil;
    
    [GlobalRouter sharedManager].allSettings = nil;
    
    [[[GlobalRouter sharedManager] getSettingsRouter] clearMemory];
    [[[GlobalRouter sharedManager] getListRouter] cleanUp];
    
    [GlobalRouter sharedManager].needToClearBG = NO;
}

#if PERIODIC_CHECK == 2
// disabled as it is not working as required - check period is unpredicted
- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    /*
    if ([GlobalRouter sharedManager].waitingForPin) {
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }
     */
    NSLog(@"Fetch!");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //if ([GlobalRouter sharedManager].pin == nil) {
            //[GlobalRouter sharedManager].pin = [NSMutableString stringWithString:@"11"];
        
        //Temporarily commented out for testing
        NSString* kkk = [[UIDevice currentDevice].identifierForVendor UUIDString];
        Encryptor* cryptor = [[Encryptor alloc] initWithSimpleKey:kkk];
        
        NSString* savedPin = [CommonProcs getStringFromKeychain:smSavedPinAccount service:@"SM"];//[CommonProcs getStringFromKeychainForAccount:smSavedPinAccount]; //[smKeychain getKeychainDataForAccount:smSavedPinAccount];
        //NSLog(@"Saved pin = %@", savedPin);
#if DEBUG
        NSLog(@"Saved PIN is %@",savedPin);
#endif
        
        if (savedPin != nil) {
            // GlobalRouter needs to init on main
            dispatch_async(dispatch_get_main_queue(), ^{
                initForBG = YES;
                // if there's no global router, keep no router on finish
                if ([GlobalRouter notInited]) {
                    [GlobalRouter sharedManager].needToClearBG = YES;
                }
                //[GlobalRouter sharedManager].needToClearBG = YES;
                initForBG = NO;
                [GlobalRouter sharedManager].pin = [cryptor decryptFromBase64:savedPin];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    //if([GlobalRouter sharedManager].needVPN) [[GlobalRouter sharedManager] connectVPNSync];
                    [[GlobalRouter sharedManager] getNewMessagesCountBG];
                    completionHandler(UIBackgroundFetchResultNewData);
                });
            });
             //[[NSUserDefaults standardUserDefaults] objectForKey:@"salt"]];
        }else{
            completionHandler(UIBackgroundFetchResultNoData);
            return;
        }
    });
}
#endif

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
    /*
    if(![GlobalRouter sharedManager].keepInBg){
        [CommonProcs saveToKeychainAlways:@"" account:smSavedPinAccount service:@"SM"];
    }else{
        // Should keep pin somehow to get it later in bg mode... it's a big security breach, but if a user agree, who cares!
        // OMG...
        
        // Move it to keychain!!!
        NSString* kkk = [[UIDevice currentDevice].identifierForVendor UUIDString];
        Encryptor* cryptor = [[Encryptor alloc] initWithSimpleKey:kkk];
        
        NSString* toStore = [cryptor encryptToBase64:[GlobalRouter sharedManager].pin];
        
        [CommonProcs saveToKeychainAlways:toStore account:smSavedPinAccount service:@"SM"];
    }
     
     */
    
    // Update stored max modSec number for new messages detection. Might slow down going to bg, need to test
    // Commented out 
    //[[GlobalRouter sharedManager] updateNumbers];
    
    // fill screen with our own colour
    UIView *colourView = [[UIView alloc]initWithFrame:self.window.frame];
    if (@available(iOS 13.0, *)) {
        colourView.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        // Fallback on earlier versions
        colourView.backgroundColor = [UIColor whiteColor];
    }
    colourView.tag = 1234;
    colourView.alpha = 1;
    [self.window addSubview:colourView];
    [self.window bringSubviewToFront:colourView];
    UIImageView *colourViewImage = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"logo"]];
    [colourView addSubview:colourViewImage];
    colourViewImage.center = colourView.center;
}

-(void)cleanUp
{
    [GlobalRouter sharedManager].goingToBG = YES;
    
    [[GlobalRouter sharedManager] finishedWithDetailView:NO];
    
    [[[GlobalRouter sharedManager] getNotesRouter] appWillGoToBG];
    
    // Moved those here as bringing any message box mess the app. Or double home tap...
    [[GlobalRouter sharedManager] composerWillEnterForeground]; // Background, actually!
    
    if ([GlobalRouter sharedManager].waitingForPin) {
        // Need cancel pin dialog
        if ([GlobalRouter sharedManager].pinAlert) {
            [[GlobalRouter sharedManager] cancelPinDialog];// resetPinDialog];
        }
    }
    
     // This mode is not OK for mail fetch since it does the job for the first time
     // and after it quits anyway - solved by push
    if(![GlobalRouter sharedManager].keepInBg){
        // Clear saved pwd if any. Should we do it here? Logging in with different pin will erase the saved pin...
        //[CommonProcs saveToKeychainAlways:@"" account:smSavedPinAccount service:@"SM"];
    }else{
        // Should keep pin somehow to get it later in bg mode... it's a big security breach, but if a user agree, who cares!
        // OMG...
        
        /*
        NSString* kkk = [[UIDevice currentDevice].identifierForVendor UUIDString];
        Encryptor* cryptor = [[Encryptor alloc] initWithSimpleKey:kkk];
        
        NSString* toStore = [cryptor encryptToBase64:[GlobalRouter sharedManager].pin];
        
        // Do not save it here, save it in the settings...
        [CommonProcs saveToKeychainAlways:toStore account:smSavedPinAccount service:@"SM"];
        */
        
        // DBG
        //[smKeychain mySetObject:@"TEST KEY" forKey:(__bridge id)kSecValueData forAccount:@"Current account-2"];
        //[smKeychain writeToKeychain];
        
        //NSString* savedPin = [smKeychain getKeychainDataForAccount:@"Current account-2"];
        //NSString* savedPin = [CommonProcs getStringFromKeychainForAccount:smSavedPinAccount];
        //NSLog(@"Saved pin = %@", savedPin);
        
        //NSString* saved = [smKeychain getKeychainDataForAccount:smSavedPinAccount];
        //NSLog(@"Saved-1 = %@", saved);
        // DBG END
        
        //[[NSUserDefaults standardUserDefaults] setObject:toStore forKey:@"salt"];
        //[[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [self clearForBG];
     
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if(![NSThread isMainThread]){
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[GlobalRouter sharedManager] getDetailNavController] popToRootViewControllerAnimated:NO];
            });
        }else{
            [[[GlobalRouter sharedManager] getDetailNavController] popToRootViewControllerAnimated:NO];
        }

    }
    locked = YES;
    [GlobalRouter cleanUp];
}
 
- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
#if USESEC
    if([NEVPNManager sharedManager].connection.status == NEVPNStatusConnected){
        //[[[GlobalRouter sharedManager] getListRouter].manager clearSessions];
        [[NEVPNManager sharedManager].connection stopVPNTunnel];
        [NEVPNManager sharedManager].enabled = NO;
    }
#endif
    // Do force cleanUp every 2 days?
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay fromDate:[NSDate date]];
    if (![GlobalRouter sharedManager].clearOnBGSetting && [components day]%2 == 0) {
        NSString* lastDay = [CommonProcs getStringFromKeychain:@"lsNumbMsg" service:@"SM"];
        if (!lastDay || [lastDay intValue] != [components day]) {
            [CommonProcs saveToKeychainAlways:[NSString stringWithFormat:@"%li", (long)[components day]] account:@"lsNumbMsg" service:@"SM"];
            [self cleanUp];
            return;
        }
    }
    
    if (![GlobalRouter sharedManager].clearOnBGSetting && ![GlobalRouter sharedManager].needToClearBG) {
        locked = YES;
        return;
    }
    [self cleanUp];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    
    // Cancel PIN dialog, if any?
    if([GlobalRouter sharedManager].clearOnBGSetting){
        if ([GlobalRouter sharedManager].needToClearBG) {
            [GlobalRouter sharedManager].pin = nil;
        }
        PinInteractor* pInt = [[GlobalRouter sharedManager] getPinInteractor];
        if(pInt)[[GlobalRouter sharedManager] cancelPinDialog]; //[pInt cancelPinDialog];
    }
//    // Test commented out, since sometimes after night it will not call initialPush, locked
//    // is somehow set to NO. At night wi-fi is very poor.
//    if (locked) {
//        locked = NO;
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            [[GlobalRouter sharedManager] initialPush];
//        });
//    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    /* // This is not allowed in the AppStore - private API...
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), //center
                                    (void*)self, // observer
                                    displayStatusChanged, // callback
                                    CFSTR("com.apple.springboard.lockcomplete"), // event name
                                    NULL, // object
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    */
    
    // Test commented out, since sometimes after night it will not call initialPush, locked
    // is somehow set to NO. At night wi-fi is very poor.
    __block BOOL pushScheduled = NO;
    if (locked) {
        locked = NO;
        if([GlobalRouter sharedManager].clearOnBGSetting || ![[[GlobalRouter sharedManager] getListRouter] isFullyLoaded] || [GlobalRouter sharedManager].needToReloadOnStart){
            pushScheduled = YES;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [[GlobalRouter sharedManager] initialPush];
            });
        }else{
            // Connect VPN
#if USESEC
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                if (![GlobalRouter sharedManager].waitingForPin && [GlobalRouter sharedManager].needVPN) {
                    [[GlobalRouter sharedManager] connectVPNSync];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        // Need to reconnect sessions
                        [[[GlobalRouter sharedManager] getListRouter].manager reconnectAll];
                    });
                    
                    //[[GlobalRouter sharedManager] checkSessions];
                }
            });
#endif
        }
    }
    
    // grab a reference to our coloured view
    UIView *colourView = [self.window viewWithTag:1234];
    if(!colourView && !pushScheduled){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[GlobalRouter sharedManager] initialPush];
        });
    }else{
        // fade away colour view from main view
        [UIView animateWithDuration:0.1 animations:^{
            colourView.alpha = 0;
        } completion:^(BOOL finished) {
            // remove when finished fading
            [colourView removeFromSuperview];
        }];
    }
    
    // Clean the notifications, need to set badge to 0 first.
    long badge = [UIApplication sharedApplication].applicationIconBadgeNumber;
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: badge];

    //[GlobalRouter sharedManager].resumedFromBG = YES;
}

/*
static void displayStatusChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    
    //NSLog(@"Locked");
    //if(![GlobalRouter sharedManager].keepInBg){
        [GlobalRouter sharedManager].pin = nil;
        locked = YES;
    //}
}
*/
- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
//    // Clear saved pin
//    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"salt"];
//    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self cleanUp];// clearForBG];
    
    // Disconnect VPN?
#if USESEC
    if([NEVPNManager sharedManager].connection.status == NEVPNStatusConnected){
        [[NEVPNManager sharedManager].connection stopVPNTunnel];
    }
#endif
}

/*! @brief Handles inbound URLs. Checks if the URL matches the redirect URI for a pending
 AppAuth authorization request.
 */
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *, id> *)options
{
    // Sends the URL to the current authorization flow (if any) which will process it if it relates to
    // an authorization response.
    if ([_currentAuthorizationFlow resumeAuthorizationFlowWithURL:url]) {
        _currentAuthorizationFlow = nil;
        return YES;
    }
    
    // Your additional URL handling (if any) goes here.
    
    return NO;
}

/*! @brief Forwards inbound URLs for iOS 8.x and below to @c application:openURL:options:.
 @discussion When you drop support for versions of iOS earlier than 9.0, you can delete this
 method. NB. this implementation doesn't forward the sourceApplication or annotations. If you
 need these, then you may want @c application:openURL:options to call this method instead.
 */
/*
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation
{
    return [self application:application openURL:url options:@{}];
}
*/

+(BOOL)isLocked
{
    return locked;
}

+(void)setLocked:(BOOL)lockedState
{
    locked = lockedState;
}

@end
