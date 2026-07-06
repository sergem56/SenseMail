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

@interface AppDelegate ()

@end

@implementation AppDelegate


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
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[GlobalRouter sharedManager] initialPush];
    });
    //[[GlobalRouter sharedManager] initialPush];
    
    // The app will be killed after 10 minutes in bg, but I hope it'll be recalled to fetch data. This brings the pin-code issue...
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:660];//UIApplicationBackgroundFetchIntervalMinimum];
    
    // These are for iOS 8.0 and later...
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
        [[UIApplication sharedApplication] registerForRemoteNotifications];
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes: (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories: nil]];
    }
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"Fetch!");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if ([GlobalRouter sharedManager].pin == nil) {
            //[GlobalRouter sharedManager].pin = @"qq";
            NSString* kkk = [[UIDevice currentDevice].identifierForVendor UUIDString];
            Encryptor* cryptor = [[Encryptor alloc] initWithSimpleKey:kkk];
            [GlobalRouter sharedManager].pin = [cryptor decryptFromBase64: [[NSUserDefaults standardUserDefaults] objectForKey:@"salt"]];
        }
        [UIApplication sharedApplication].applicationIconBadgeNumber = [[GlobalRouter sharedManager] getNewMessagesCount];
        completionHandler(UIBackgroundFetchResultNewData);
    });
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    if(![GlobalRouter sharedManager].keepInBg){
        [GlobalRouter sharedManager].pin = nil;
    }else{
        // Should keep pin somehow to get it later in bg mode... it's a big security breach, but if a user agree, who cares!
        // OMG...
        NSString* kkk = [[UIDevice currentDevice].identifierForVendor UUIDString];
        Encryptor* cryptor = [[Encryptor alloc] initWithSimpleKey:kkk];
        
        NSString* toStore = [cryptor encryptToBase64:[GlobalRouter sharedManager].pin];
        [[NSUserDefaults standardUserDefaults] setObject:toStore forKey:@"salt"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [[[GlobalRouter sharedManager] getListRouter] clearList];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
}

@end
