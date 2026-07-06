//
//  GlobalRouter.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//


/*
 UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Yourstoryboard" bundle:nil];
 
 UINavigationController *thisController = [storyboard instantiateViewControllerWithIdentifier:@"YourID"];
 
 mytabBarController.viewControllers = @[phoneViewController];
 */

#import "GlobalRouter.h"
#import <UIKit/UIStoryboard.h>
#import "AppDelegate.h"
#import "ListPresenter.h"
#import "MessageViewRouter.h"
#import "DataManager.h"
#import "DataStorage.h"
#import "CommonProcs.h"
#import "Encryptor.h"
#import "AddressBookEntity.h"
#import "ListInteractor.h"
#import "SettingsEntity.h"

#import "ModalDialogViewController.h"
#import "DetailViewController.h"

#import "WelcomeContentViewController.h"
//#import <AssetsLibrary/AssetsLibrary.h>
#import "Search/SearchInteractor.h"

#import <LocalAuthentication/LocalAuthentication.h>

#import "MessageInfoInteractor.h"

#import "EasySetupInteractor.h"

#import "DocsViewController.h"
#import "WindowMinimizer/WindowMinimizer.h"
#if !LITE
#import "OneTimeCert/OneTimeCertInteractor.h"
#endif
#import "Pin/PinInteractor.h"

#import <Contacts/Contacts.h>
#import "FolderInfo.h"

#import "Settings2Interactor.h"

#if USESEC
#import <NetworkExtension/NetworkExtension.h>
#endif

@implementation AutocompleteItem
@synthesize name, email;

@end

@implementation GlobalRouter

@synthesize currentBox, currentBoxPath, otherFolders, currentFilter, pin = _pin, currentSettingNo;

#pragma mark - Init and setup

static GlobalRouter *sharedMyManager = nil;
static dispatch_once_t onceToken;
+(GlobalRouter*)sharedManager {
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

+(void)cleanUp
{
    @synchronized(self) {
        sharedMyManager = nil;
        onceToken = 0;
    }
}

+(BOOL)notInited
{
    return onceToken == 0;
}

-(void)clearTempFiles
{
    if(![AppDelegate isLocked]){
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = screenRect.size.width;
        
        __block UIActivityIndicatorView *activity;
        __block UILabel* textLabel;
        dispatch_async(dispatch_get_main_queue(), ^{
            // Show clean up progress
            activity = [[UIActivityIndicatorView alloc]  initWithFrame:CGRectMake(screenWidth/2-20, screenRect.size.height/2-40, 40, 40)];
            textLabel = [[UILabel alloc] initWithFrame:CGRectMake(screenWidth/2-100, screenRect.size.height/2, 200, 40)];
            [activity setBackgroundColor:[UIColor clearColor]];
            [activity setActivityIndicatorViewStyle: UIActivityIndicatorViewStyleWhiteLarge];
            [[self getCurrentView] addSubview: activity];
            [activity startAnimating];
            [textLabel setTextColor:[UIColor lightGrayColor]];
            [textLabel setText:NSLocalizedString(@"Cleaning up...", nil)];
            [textLabel setTextAlignment:NSTextAlignmentCenter];
            [[self getCurrentView] addSubview:textLabel];
        });
        
        [DataManager deleteTempFiles];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [activity stopAnimating];
            [activity removeFromSuperview];
            [textLabel removeFromSuperview];
        });
    }
}

-(id)init
{
    if(self = [super init]){
        //listPresenter = [[ListPresenter alloc] init];
        messageRouter = [[MessageViewRouter alloc]init];
        userData = [[UserInfoDataManager alloc]init];
        settingsRouter = [[SettingsRouter alloc] init];
        listRouter = [[MessageListRouter alloc] init];
        
        // Looks like the below is not needed for BG check
        if(!initForBG){
            attRouter = [[AttachmentViewRouter alloc] init];
            addrRouter = [[AddressBookRouter alloc]init];
            compRouter = [[ComposeMessageRouter alloc] init];
            addAttRouter = [[AddAttachmentRouter alloc] init];
            galleryRouter = [[GalleryRouter alloc] init];
            helpRouter = [[HelpRouter alloc] init];
            notesRouter = [[NotesRouter alloc] init];
#if !LITE
            certRouter = [[CertExchangeRouter alloc] init];
            self.oneTimeCertInteractor = [[OneTimeCertInteractor alloc] init];
#endif
            [self clearTempFiles];
        }else{
#if DEBUG
            NSLog(@"Initialising for BG");
#endif
        }
        mainAppQueue = dispatch_queue_create("Network Queue",NULL);
        self.shouldCancel = NO;
        currentBox = btEmpty;
        self.currentAccount = @"";
        
        self.otherFolders = [[NSMutableDictionary alloc] init];
        self.currentFilter = @"";
        
        currentSettingNo = 0;
        self.keepInBg = NO;
        self.waitingForPin = NO;
        self.nMessagesToLoad = 10;
        
        self.goingToBG = NO;
        //self.resumedFromBG = NO;
        
        //self.settingsNames = [[NSMutableDictionary alloc] init];
        id clearOnBGid = [[NSUserDefaults standardUserDefaults] objectForKey:@"clearOnBG"];
        if (clearOnBGid) {
            self.clearOnBGSetting = [clearOnBGid boolValue];
        }else{
            self.clearOnBGSetting = YES;
        }
        self.needToReloadOnStart = NO;
        self.doNotHideAccountInNotification = NO;
        
#ifdef STRONG
        self.currentPos = 0;
        //self.keyID = [[[NSUserDefaults standardUserDefaults] objectForKey:@"callID"] intValue];
        /*
         NSFileManager *fileManager = [NSFileManager defaultManager];
         NSString* destPath = [CommonProcs getPathIntoDocs:@"dataFile.dat"];
         if (![fileManager fileExistsAtPath:destPath]) {
             // No key file, ask for a password to create one
             [CommonProcs askToMakeKeyFile];
         }
         */
#endif
    }
    
    return self;
}

-(void)setPin:(NSMutableString *)pin
{
    _pin = pin;
}

-(id<UIApplicationDelegate>)getAppDelegate
{
    __block id<UIApplicationDelegate> appDel;
    __block BOOL gotDelegate = NO;
    NSCondition* conditionForDelegate;
    if(![NSThread isMainThread]){
        conditionForDelegate = [NSCondition new];
        gotDelegate = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            appDel = [[UIApplication sharedApplication] delegate];
            gotDelegate = YES;
            if (conditionForDelegate) {
                [conditionForDelegate signal];
            }
        });
        [conditionForDelegate lock];
        while (!gotDelegate && conditionForDelegate != nil){
            [conditionForDelegate wait];
        }
        gotDelegate = NO;
        [conditionForDelegate unlock];
    }else{
        appDel = [[UIApplication sharedApplication] delegate];
    }
    
    return appDel;
}

-(UIViewController*)getRootVC
{
    return [self getRootVCForDelegate:(AppDelegate*) [self getAppDelegate]];
}

-(UIViewController*)getRootVCForDelegate:(AppDelegate*)delegate
{
    __block UIViewController* vc;
    __block BOOL gotDelegate = NO;
    NSCondition* conditionForDelegate;
    if(![NSThread isMainThread]){
        conditionForDelegate = [NSCondition new];
        gotDelegate = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            vc = delegate.window.rootViewController;
            gotDelegate = YES;
            if (conditionForDelegate) {
                [conditionForDelegate signal];
            }
        });
        [conditionForDelegate lock];
        while (!gotDelegate && conditionForDelegate != nil){
            [conditionForDelegate wait];
        }
        [conditionForDelegate unlock];
        //gotDelegate = NO;
    }else{
        vc = delegate.window.rootViewController;
    }
    
    return vc;
}

-(UINavigationController*)getNavController
{
    AppDelegate *appDelegate = (AppDelegate*) [self getAppDelegate]; //[[UIApplication sharedApplication] delegate];
    
    UINavigationController *navController;// = (UINavigationController *)appDelegate.window.rootViewController;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        //UISplitViewController* spvc = (UISplitViewController*)appDelegate.window.rootViewController;
        UISplitViewController* spvc = (UISplitViewController*)[self getRootVCForDelegate:appDelegate];
        navController = (UINavigationController *)spvc.viewControllers[0];// .navigationController;
    }else{
        navController = (UINavigationController *)[self getRootVCForDelegate:appDelegate];
        //navController = (UINavigationController *)appDelegate.window.rootViewController;
    }
    return navController;
}

-(UINavigationController*)getDetailNavController
{
    AppDelegate *appDelegate = (AppDelegate*)[self getAppDelegate]; // [[UIApplication sharedApplication] delegate];
    
    UINavigationController *navController;// = (UINavigationController *)appDelegate.window.rootViewController;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
        //UISplitViewController* spvc = (UISplitViewController*)appDelegate.window.rootViewController;
        UISplitViewController* spvc = (UISplitViewController*)[self getRootVCForDelegate:appDelegate];
        navController = (UINavigationController *)spvc.viewControllers[1];// .navigationController;
        
        // Why is this here? Don't remember... - to hide the master window when you open a message, for example.
        if ([GlobalRouter sharedManager].detailVC != nil) {
            [[GlobalRouter sharedManager].detailVC performSelectorOnMainThread:@selector(hideMasterAndRestore) withObject:nil waitUntilDone:YES];
        }
    }else{
        //navController = (UINavigationController *)appDelegate.window.rootViewController;
        navController = (UINavigationController *)[self getRootVCForDelegate:appDelegate];
    }
    
    // Cancel all animations
    @try {
        dispatch_async(dispatch_get_main_queue(), ^{
            [navController.view.layer removeAllAnimations];
        });
    } @catch (NSException *exception) {
        NSLog(@"Exception cancelling animations %@", exception);
    } @finally {
    }
    
    return navController;
}

// We use a detail nav controller since nav controller (left panel) might be hidden
-(UIViewController *)getTopViewController
{
    UIViewController *topViewController = [[GlobalRouter sharedManager] getDetailNavController];
    while (topViewController.presentedViewController){
        topViewController = topViewController.presentedViewController;
    }
    
    return topViewController;
}

-(dispatch_queue_t)getQ
{
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0);
    
    /*
    if (mainAppQueue == nil) {
        mainAppQueue = dispatch_queue_create("Network Queue",NULL);
    }
    
    return mainAppQueue;
     */
}

-(void)cancelQ
{
    [GlobalRouter sharedManager].shouldCancel = YES;
    
    if(listRouter && listRouter.dataStore)
        [listRouter.dataStore cancelSessionOps];
}

-(BOOL)isCancelled
{
    return [GlobalRouter sharedManager].shouldCancel;
}

-(void)restartQ
{
    [GlobalRouter sharedManager].shouldCancel = NO;
}

/*
-(ListPresenter*)getListPresenter
{
    return listPresenter;
}
 */

-(Encryptor*)getEncoderForPin:(NSMutableString*)pinStr // salt:(NSString *)forSalt
{
    BOOL doNotSearch = NO;
    if (encs == nil) {
        encs = [[NSMutableDictionary alloc] init];
        doNotSearch = YES;
    }
    if (!pinStr) {
        NSLog(@"Nil string for encoder");
    }
    Encryptor* enc;
    //NSString* tmp = [NSString stringWithFormat:@"%@%@", pinStr, forSalt];
    NSString* pinHash = [Encryptor getHashForString:pinStr];//tmp];
    if (doNotSearch) {
        enc = [[Encryptor alloc] initWithKey:pinStr]; //salt:forSalt];
        [encs setObject:enc forKey:pinHash];
    }else{
        enc = [encs objectForKey:pinHash];
        if (enc == nil) {
            enc = [[Encryptor alloc] initWithKey:pinStr]; //salt:forSalt];
            [encs setObject:enc forKey:pinHash];
        }
    }
    
    return enc;
}

-(void)clearEncoders
{
    for (NSString* pinHash in encs.allKeys) {
        Encryptor* enc = [encs objectForKey:pinHash];
        [enc clearKeys];
        enc = nil;
    }
    [encs removeAllObjects];
    encs = nil;
}

-(NSString*)pin
{
    if([GlobalRouter sharedManager].goingToBG /*|| [AppDelegate isLocked]*/){
        return @"";
    }
    
    if (_pin == nil) {
        // Check if already waiting???
        // Check if thisIsTheFirstRun is set?
        
        [GlobalRouter sharedManager].waitingForPin = YES;
        //if([AppDelegate isLocked]){
        //    return @""; // TEST THAT FOR BG!
        //}
        if(![NSThread isMainThread]){
            // Waiting alert but shouldn't be on main thread
            if (condition) {
                NSLog(@"Condition is not null");
                [condition signal];
                [condition unlock];
                condition = nil;
            }
            condition = [NSCondition new];
            questionAnswered = NO;
            [condition lock];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self askForPin];
            });
            while (!questionAnswered && condition != nil){
                [condition wait];
            }
            [condition unlock];
            questionAnswered = NO;
        }else{
            NSLog(@"On main thread");
            //condition = nil;
            [self askForPin];
        }
        [self processPinForSos];
    }
    //if(pin != nil)
    //    [GlobalRouter sharedManager].waitingForPin = NO;
    
    return _pin;
}

-(void)processPinForSos
{
    if(!_pin || [_pin isEqualToString:@""])return;
    NSString* phash = [Encryptor getHashForString:_pin];
    if (phash) {
        //NSString* savedPH = [[NSUserDefaults standardUserDefaults] stringForKey:SOSPINSIG];
        NSString* savedPH = [CommonProcs getStringFromKeychain:SOSPINSIG service:@"SM"];
        if (savedPH && [savedPH isEqualToString:phash]) {
            NSLog(@"Panic!!!");
            //exit(-1);
            [[GlobalRouter sharedManager] sos];
        }
    }
}

-(void)resetPinDialog
{
    questionAnswered = YES;
    if(condition){
        [condition signal];
        //[condition unlock];
        condition = nil;
    }
    [GlobalRouter sharedManager].waitingForPin = NO;
    [GlobalRouter sharedManager].pinAlert = NO;
    //[pinInteractor cancelPinDialog];
}

#pragma mark - Routers

-(MessageViewRouter*)getMessageRouter
{
    return messageRouter;
}

-(SettingsRouter*)getSettingsRouter
{
    return settingsRouter;
}

-(AttachmentViewRouter*)getAttachmentRouter
{
    return attRouter;
}

-(AddressBookRouter*)getBookRouter
{
    return addrRouter;
}

-(ComposeMessageRouter*)getComposeRouter
{
    return compRouter;
}

-(AddAttachmentRouter*)getAddAttRouter
{
    return addAttRouter;
}

-(GalleryRouter*)getGalleryRouter
{
    return galleryRouter;
}

-(HelpRouter*)getHelpRouter
{
    return helpRouter;
}

-(MessageListRouter*)getListRouter
{
    return listRouter;
}

-(NotesRouter*)getNotesRouter
{
    return notesRouter;
}

#if !LITE
-(CertExchangeRouter*)getCertRouter
{
    return certRouter;
}
#endif

-(PinInteractor*)getPinInteractor
{
    return pinInteractor;
}

#pragma mark - Assets

/*
-(NSMutableArray*)getAssets
{
    if (assets == nil || assets.count == 0) {
        assets = [DataManager defaultAssetsLibrary];
    }
    return assets;
}
*/
-(void)setAssets:(NSMutableArray*)assetsToSet
{
    assets = assetsToSet;
}

-(void)pushView:(UIViewController *)viewController
{
    /*
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
     */
    //[[self getNavController] pushViewController:viewController animated:YES];
}

#pragma mark - Boxes

-(void)doShowInbox
{
    //UIViewController* ret = [listPresenter showListOfType:btInbox];
    //[self pushView:ret];
    
    self.currentBox = btInbox;
    
    //AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    //UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    //[listRouter showListInNavController:navController forBox:btInbox];
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [strongSelf->listRouter showListInNavController:[self getNavController] forBox:btInbox];
    });
}

-(void)doShowEmpty
{
    currentBox = btEmpty;
    [GlobalRouter sharedManager].currentFilter = @"";
    __weak __typeof__(self) weakSelf = self;
    
    // This will init the left pane
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [strongSelf->listRouter showListInNavController:[strongSelf getNavController] forBox:btEmpty];
    });
    
    // Need to add a delay, otherwise it may not show the oauth page... donna why, looks like the main thread finishes something, probable animation or whatever.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), //dispatch_get_main_queue(), ^{
        dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        if(weakSelf && ![GlobalRouter sharedManager].waitingForPin && ![GlobalRouter sharedManager].goingToBG && ![GlobalRouter sharedManager].thisIsTheFirstRun){
                __strong __typeof__(self) strongSelf = weakSelf;
                //[listRouter.dataStore readShortMessagesForBox:btEmpty];
                [strongSelf->listRouter.manager getShortMessagesForBox:btEmpty];
        }
    });
    /*
    if(![GlobalRouter sharedManager].waitingForPin && [GlobalRouter sharedManager].pin != nil){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            __strong __typeof__(self) strongSelf = weakSelf;
            //[listRouter.dataStore readShortMessagesForBox:btEmpty];
            [strongSelf->listRouter.manager getShortMessagesForBox:btEmpty];
        });
    }
     */
}

-(void)needShowWhatsNew
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[GlobalRouter sharedManager] getHelpRouter] showHelpInNavController:[[GlobalRouter sharedManager] getDetailNavController] file:NSLocalizedString(@"WhatsNew", nil)];
    });
}

-(void)checkNewVersion
{
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString* lastKnownVersion = (NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"lastKnownVersion"];
    if (lastKnownVersion == nil) {
        lastKnownVersion = @"0";
    }
    if ([appVersion compare:lastKnownVersion options:NSNumericSearch] == NSOrderedDescending) {
        // lastKnown version is lower than the app version
        //Need to show differences
        NSLog(@"Showing new features");
        [self needShowWhatsNew];
        [[NSUserDefaults standardUserDefaults] setObject:appVersion forKey:@"lastKnownVersion"];
    }
}

#if USESEC
-(void)didChangeVPNStatus
{
    NEVPNManager * vpnManager = [NEVPNManager sharedManager];
    switch (vpnManager.connection.status) {
        case NEVPNStatusInvalid:
            dispatch_semaphore_signal(vpnSemaphore);
            break;
        case NEVPNStatusDisconnected:
            break;
        case NEVPNStatusConnecting:
            break;
        case NEVPNStatusConnected:
            dispatch_semaphore_signal(vpnSemaphore);
            break;
        case NEVPNStatusReasserting:
            break;
        case NEVPNStatusDisconnecting:
            break;
    }
}

-(BOOL)connectVPNSync
{
    SettingsEntity* sett;// = [GlobalRouter sharedManager].allSettings[0];
    for (SettingsEntity* sss in [GlobalRouter sharedManager].allSettings) {
        if ([sss.settingsName isEqualToString:GENERAL_SETTINGS]) {
            sett = sss;
            break;
        }
    }
    if(!sett || [sett.vpnUsername isEqualToString:@""] || [sett.vpnServer isEqualToString:@""]){
        //[CommonProcs showMessage:@"Cannot find settings" title:@"Error connecting to VPN"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs showVanishingErrorMessage:@"Error connecting to VPN"];
        });
        return NO;
    }
    
    vpnSemaphore = dispatch_semaphore_create(0);
    __block BOOL ret = NO;
    __block BOOL creatingNew = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        NEVPNManager* manager = [NEVPNManager sharedManager];
        __weak typeof(self) weakSelf = self;
        [manager loadFromPreferencesWithCompletionHandler:^(NSError *error) {
            if(error) {
                NSLog(@"Load error: %@", error);
                ret = NO;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                        __strong typeof(self) strongSelf = weakSelf;
                        dispatch_semaphore_signal(strongSelf->vpnSemaphore);
                });
            }else{
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeVPNStatus) name:NEVPNStatusDidChangeNotification object:nil];
                if (!manager.protocolConfiguration) {
                    NSLog(@"No config");
                    manager.enabled = YES;
                    
                    /*
                    NEVPNProtocolIKEv2 *p = [[NEVPNProtocolIKEv2 alloc] init];
                    p.username = @"purevpn0s357292";
                    p.passwordReference = (__bridge NSData * _Nullable)([CommonProcs getPersistentDataFromKeychain:@"VPNPassword" service:@"SM-VPN"]);
                    p.serverAddress = @"vleu-be1.pointtoserver.com";
                    p.authenticationMethod = NEVPNIKEAuthenticationMethodNone;
                    p.remoteIdentifier = @"pointtoserver.com";
                    p.useExtendedAuthentication = YES;
                    p.disconnectOnSleep = YES;
                    
                    [manager setProtocolConfiguration:p];
                    
                    [manager setOnDemandEnabled:NO];
                    NEOnDemandRuleConnect* rules = [[NEOnDemandRuleConnect alloc] init];
                    rules.interfaceTypeMatch = NEOnDemandRuleInterfaceTypeAny;
                    manager.onDemandRules = @[rules];
                    
                    */
                    
                    // To add a new config it will ask for a phone's password and will switch the app to BG and start the proc over causing the app to crash. So we need to release the semaphore
                    __strong typeof(self) strongSelf = weakSelf;
                    dispatch_semaphore_signal(strongSelf->vpnSemaphore);
                    creatingNew = YES;
                    
                    if ([sett.vpnProtocol isEqualToString:@"IKEv2"]) {
                        NEVPNProtocolIKEv2* p = [[NEVPNProtocolIKEv2 alloc] init];
                        
                        p.username = sett.vpnUsername;
                        p.passwordReference = (__bridge NSData * _Nullable)([CommonProcs getPersistentDataFromKeychain:@"VPNPassword" service:@"SM-VPN"]);
                        p.sharedSecretReference = (__bridge NSData * _Nullable)([CommonProcs getPersistentDataFromKeychain:@"VPNSS" service:@"SM-VPN"]);
                        p.serverAddress = sett.vpnServer;
                        p.authenticationMethod = sett.vpnAuthMethod;
                        p.remoteIdentifier = sett.vpnRemoteID;
                        p.localIdentifier = sett.vpnLocalID;
                        p.useExtendedAuthentication = sett.vpnUseExtAuth;
                        p.disconnectOnSleep = YES;
                        
                        [manager setProtocolConfiguration:p];
                    }else{
                        NEVPNProtocolIPSec* p = [[NEVPNProtocolIPSec alloc] init];
                        p.username = sett.vpnUsername;
                        p.passwordReference = (__bridge NSData * _Nullable)([CommonProcs getPersistentDataFromKeychain:@"VPNPassword" service:@"SM-VPN"]);
                        p.sharedSecretReference = (__bridge NSData * _Nullable)([CommonProcs getPersistentDataFromKeychain:@"VPNSS" service:@"SM-VPN"]);
                        p.serverAddress = sett.vpnServer;
                        p.authenticationMethod = sett.vpnAuthMethod;
                        p.remoteIdentifier = sett.vpnRemoteID;
                        p.localIdentifier = sett.vpnLocalID;
                        p.useExtendedAuthentication = sett.vpnUseExtAuth;
                        p.disconnectOnSleep = YES;
                        
                        [manager setProtocolConfiguration:p];
                    }
                    
                    [manager setOnDemandEnabled:NO];
                    /*
                    NEOnDemandRuleConnect* rules = [[NEOnDemandRuleConnect alloc] init];
                    rules.interfaceTypeMatch = NEOnDemandRuleInterfaceTypeAny;
                    manager.onDemandRules = @[rules];
                     */
                    [manager setLocalizedDescription:@"SM VPN"];
                    NSLog(@"Connection desciption: %@", manager.localizedDescription);
                    [manager saveToPreferencesWithCompletionHandler:^(NSError *error) {
                       if(error) {
                          NSLog(@"Save error: %@", error);
                       }
                        // Do  not start here?
                        NSError *startError;
                        [manager.connection startVPNTunnelAndReturnError:&startError];
                        if(startError) {
                           NSLog(@"Start error: %@", startError.localizedDescription);
                        }
                    }];
                }else{
                    NSError *startError;
                    manager.enabled = YES;
                    [manager.connection startVPNTunnelAndReturnError:&startError];
                    if(startError) {
                        NSLog(@"Start error: %@", startError.localizedDescription);
                    }
                    if(manager.connection.status == NEVPNStatusConnected){
                        [self didChangeVPNStatus];
                    }
                }
            }
        }];
    });
    
    if(!initForBG){
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs showWheelinView:[[GlobalRouter sharedManager] getCurrentView] message:NSLocalizedString(@"Connecting to VPN", nil) stopButtonVisible:YES withBlock:^{
                __strong typeof(self) strongSelf = weakSelf;
                dispatch_semaphore_signal(strongSelf->vpnSemaphore);
            }];
        });
    }
    //__strong typeof(self) strongSelf = weakSelf;
    dispatch_semaphore_wait(vpnSemaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)));
    [NSThread sleepForTimeInterval:0.600];
    if ([NEVPNManager sharedManager].connection.status == NEVPNStatusConnected) {
        ret = YES;
    }
    if(!initForBG)[CommonProcs hideProgressAlways];
    
    if(!ret && !initForBG){
        //__weak typeof(self) weakSelf = self;
        dispatch_semaphore_t askSem = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_main_queue(), ^{
            //__strong typeof(self) strongSelf = weakSelf;
            //strongSelf->vpnSemaphore = dispatch_semaphore_create(0);
            if(creatingNew){/*
                [CommonProcs askAndDoWithTitle:NSLocalizedString(@"Connecting to VPN...", nil) text:NSLocalizedString(@"Tap OK ", nil) block:^{
                    dispatch_semaphore_signal(askSem);
                }];*/
                //[CommonProcs showMessage:NSLocalizedString(@"Connecting to VPN...", nil) title:@""];
            }else {
                [CommonProcs askYesNoAndDoWithTitle:NSLocalizedString(@"Cannot connect to VPN", nil) text:NSLocalizedString(@"Continue without VPN?", nil) blockYes:^{
                    //__strong typeof(self) strongSelf = weakSelf;
                    dispatch_semaphore_signal(askSem);
                } blockNo:^{
                    //__strong typeof(self) strongSelf = weakSelf;
                    [[GlobalRouter sharedManager] needExit];
                    dispatch_semaphore_signal(askSem);
                }];
            }
        });
        
        dispatch_semaphore_wait(askSem, DISPATCH_TIME_FOREVER);
        
        if (creatingNew && [NEVPNManager sharedManager].connection.status == NEVPNStatusConnected) {
            [CommonProcs showVanishingMessage:@"Connected"];
        }
    }
    
    return ret;
}
#endif

-(void)initialPush
{
    [GlobalRouter sharedManager].loadedMessages = 0;
    [GlobalRouter sharedManager].totalMessages = 0;
    [GlobalRouter sharedManager].newMessages = 0;
    [listRouter.dataStore resetMessages];
    
    [AppDelegate setLocked:NO];
    [self clearTempFiles];
    
    /*////////////////////////
    //[CommonProcs saveToKeychainAlways:@"-----" account:@"VPNPassword" service:@"SM-VPN"];
    /////////////////////////*/
    
    // Ask for pin - access pin, and if no pin, it will bring the pin dialog
    // Should be checked for nil only here due to the BG cleaning
    if ([userData isPasswordNeeded]) {
        if([GlobalRouter sharedManager].pin == nil){
            // Need to access pin, so it will ask for it blocking execution
        }
        
        [GlobalRouter sharedManager].waitingForPin = NO;
        // if we press cancel in PIN dialog
        if ([GlobalRouter sharedManager].goingToBG) {
            return;
        }
        if(![GlobalRouter sharedManager].thisIsTheFirstRun){
            UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
            [GlobalRouter sharedManager].allSettings = [dataMan getSettings:[GlobalRouter sharedManager].pin];
#if USESEC
            if([GlobalRouter sharedManager].needVPN){
                [self connectVPNSync];
            }
#endif
        }
        [self doShowEmpty];
#if !LITE
        [[GlobalRouter sharedManager].oneTimeCertInteractor deleteExpired];
#endif
    }else{
        [self doShowInbox];
    }
    
    [self checkNewVersion];
    [GlobalRouter sharedManager].needToReloadOnStart = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIButton* restore = [[[GlobalRouter sharedManager] getRootVC].view viewWithTag:888888];
        if (restore) {
            if (restore.allTargets.count > 0) {
                // Check if we need to show that button
                WindowMinimizer* miz = restore.allTargets.allObjects[0];
                if(![miz isKindOfClass:[NSNull class]]){
                    BOOL ress = [miz.minimizedVC checkRestore:[Encryptor getSlowHashForString:[GlobalRouter sharedManager].pin]];
                    //if(!ress){
                    restore.hidden = !ress;
                    //}
                }else{
                    restore.hidden = YES;
                }
            }
        }
    });
    
#ifdef STRONG
    NSString* res = (NSString*)[[NSUserDefaults standardUserDefaults] objectForKey:@"callMe"];
    if ([res isEqualToString:@"YES"]) {
        // Hey, attention! Security breach!
        [CommonProcs showMessage:NSLocalizedString(@"Security alert", nil) title:NSLocalizedString(@"Security alert title", nil)];
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString* destPath = [CommonProcs getPathIntoDocs:@"dataFile.dat"];
    if (![fileManager fileExistsAtPath:destPath]) {
        // No key file, ask for a password to create one
        [CommonProcs askToMakeKeyFile];
    }
#endif
}

-(void)askForPin
{
    if([GlobalRouter sharedManager].thisIsTheFirstRun)return;
    
    // Check for null defaults, ask to restart
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    if (!defaults) {
        [CommonProcs askYesNoAndDoWithTitles:NSLocalizedString(@"Error",nil) text:NSLocalizedString(@"We have detected a problem launching the app that may corrupt the appearance settings, please run it again",nil) button1Title:NSLocalizedString(@"Re-run", nil) button2Title:NSLocalizedString(@"Ignore", nil) blockYes:^{
            exit(0);
        } blockNo:^{
            
        }];
        //[CommonProcs askAndDoWithTitle:@"Error" text:NSLocalizedString(@"We have detected a problem launching the app that may corrupt the appearance settings, please run it again",nil) block:^{
        //    exit(0);
        //}];
    }
    
    // Detect first run. All the stuff with the defaults is for the compatibility purpose, since we migrate to the keychain because of the rear bug that could clear the default's values
    static NSString* const hasRunAppOnceKey = @"hasRunAppOnceKey";
    NSString* aMessage;
    NSString* hasKeyKC = [CommonProcs getStringFromKeychain:hasRunAppOnceKey service:@"SM"];
    BOOL firstrunkey = NO;
    if(!hasKeyKC){
        // No value in keychain, try userdefaults
        firstrunkey = [[NSUserDefaults standardUserDefaults] boolForKey:hasRunAppOnceKey];
        if (firstrunkey) {
            // Add to keychain
            [CommonProcs saveToKeychainAlways:@"1" account:hasRunAppOnceKey service:@"SM"];
        }
    }else{
        firstrunkey = [hasKeyKC boolValue];
    }
    //NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    //if ([defaults boolForKey:hasRunAppOnceKey] == NO)
    if(!firstrunkey)
    {
        aMessage = NSLocalizedString(@"Create a PIN-code for the application", nil);
        
        /*
        // Show welcome page
        //dispatch_semaphore_t welcomeSem = dispatch_semaphore_create(0);
        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"welcome" bundle:nil];
        WelcomeContentViewController *wcvc = [sb instantiateViewControllerWithIdentifier:@"Welcome01"];
        //wcvc.sem = welcomeSem;
        AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
        
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [appDelegate.window.rootViewController presentViewController:wcvc animated:YES completion:nil];
        });
        //dispatch_semaphore_wait(welcomeSem, DISPATCH_TIME_FOREVER);
        [GlobalRouter sharedManager].pin = [wcvc getPin];
        
        WelcomeContentViewController *wcvc2 = [sb instantiateViewControllerWithIdentifier:@"Welcome02"];
        //welcomeSem = dispatch_semaphore_create(0);
        //wcvc2.sem = welcomeSem;
        [appDelegate.window.rootViewController presentViewController:wcvc2 animated:YES completion:nil];
        //dispatch_semaphore_wait(welcomeSem, DISPATCH_TIME_FOREVER);
        
        self.needStartWithSettings = [wcvc2 areSettingsNeeded];
        */
        //[defaults setBool:YES forKey:hasRunAppOnceKey];
        // Add it here? If you tap cancel in the setup master, it will consider the first run done.
        [CommonProcs saveToKeychainAlways:@"1" account:hasRunAppOnceKey service:@"SM"];
        
        ////////
        [GlobalRouter sharedManager].thisIsTheFirstRun = YES;
        questionAnswered = YES;
        if(condition)
            [condition signal];
        return;
        
        //[[NSUserDefaults standardUserDefaults] synchronize]; // No need to call it ASAP
    }else{
        aMessage = NSLocalizedString(@"Application PIN is time-outed",nil);
    }
    /*
    // Disabled it since we present it modally
    if ([GlobalRouter sharedManager].pinAlert) {
        return;
    }
     */
    // Dim da view
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    pinDimView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenRect.size.width, screenRect.size.height)];
    pinDimView.backgroundColor = [UIColor blackColor];
    //[[self getCurrentView] addSubview:pinDimView];
    
#pragma mark Touch ID code is here
    // Touch ID authentication - keep PIN in keychain and get it upon authentication
    // Can keep just one PIN - giving a choice of accounts will reveal all of them
    // that compromises security - no hidden accounts are possible then.
    // So, to use touch id you need to enable it on the settings page and set a PIN that is going to be
    // protected by touch id.
    // Need to set access control to read value only after touch id auth!
    //
    // Not sure if I need that... Keychain can be hacked if jailbroken, so the PIN can be revealed...
    
    self.pinAlert = YES;
    
    pinInteractor = [[PinInteractor alloc] init];
    __weak __typeof__(self) weakSelf = self;// [GlobalRouter sharedManager];
    
    // Cancel all animations
    @try {
        [[[GlobalRouter sharedManager] getDetailNavController].view.layer removeAllAnimations];
    } @catch (NSException *exception) {
        NSLog(@"Exception cancelling animations %@", exception);
    } @finally {
    }
    
    //dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    __strong __typeof__(self) strongSelf = weakSelf;
    @try{
        [strongSelf->pinInteractor showDialogWithTitle:NSLocalizedString(@"Enter PIN",nil) message:aMessage okBlock:^{
            if(weakSelf){
                __strong __typeof__(self) strongSelf = weakSelf;
                // Need to stop app until pin is entered
                strongSelf->questionAnswered = YES;

                //[self doShowEmpty];
                [GlobalRouter sharedManager].waitingForPin = NO;
                [strongSelf->pinDimView removeFromSuperview];
                [GlobalRouter sharedManager].pinAlert = NO;
                if(strongSelf->condition)
                    [strongSelf->condition signal];
            }else{
                NSLog(@"ASK FOR PIN no self");
            }
        }];
    }@catch (NSException *exception) {
        strongSelf->questionAnswered = YES;
        [GlobalRouter sharedManager].waitingForPin = NO;
        [strongSelf->pinDimView removeFromSuperview];
        [GlobalRouter sharedManager].pinAlert = NO;
        if(strongSelf->condition)
        [strongSelf->condition signal];
    }
    //});
    
}


/* TOUCH ID Keychain example
 
 override func viewDidAppear(_ animated: Bool) {
 super.viewDidAppear(animated)
 
 //  This two values identify the entry, together they become the
 //  primary key in the database
 let myAttrService = "app_name"
 let myAttrAccount = "first_name"
 
 // DELETE keychain item (if present from previous run)
 
 let delete_query: NSDictionary = [
 kSecClass: kSecClassGenericPassword,
 kSecAttrService: myAttrService,
 kSecAttrAccount: myAttrAccount,
 kSecReturnData: false
 ]
 let delete_status = SecItemDelete(delete_query)
 if delete_status == errSecSuccess {
 print("Deleted successfully.")
 } else if delete_status == errSecItemNotFound {
 print("Nothing to delete.")
 } else {
 print("DELETE Error: \(delete_status).")
 }
 
 // INSERT keychain item
 
 let valueData = "The Top Secret Message V1".data(using: .utf8)!
 let sacObject =
 SecAccessControlCreateWithFlags(kCFAllocatorDefault,
 kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
 .userPresence,
 nil)!
 
 let insert_query: NSDictionary = [
 kSecClass: kSecClassGenericPassword,
 kSecAttrAccessControl: sacObject,
 kSecValueData: valueData,
 kSecUseAuthenticationUI: kSecUseAuthenticationUIAllow,
 kSecAttrService: myAttrService,
 kSecAttrAccount: myAttrAccount
 ]
 let insert_status = SecItemAdd(insert_query as CFDictionary, nil)
 if insert_status == errSecSuccess {
 print("Inserted successfully.")
 } else {
 print("INSERT Error: \(insert_status).")
 }
 
 DispatchQueue.global().async {
 // RETRIEVE keychain item
 
 let select_query: NSDictionary = [
 kSecClass: kSecClassGenericPassword,
 kSecAttrService: myAttrService,
 kSecAttrAccount: myAttrAccount,
 kSecReturnData: true,
 kSecUseOperationPrompt: "Authenticate to access secret message"
 ]
 var extractedData: CFTypeRef?
 let select_status = SecItemCopyMatching(select_query, &extractedData)
 if select_status == errSecSuccess {
 if let retrievedData = extractedData as? Data,
 let secretMessage = String(data: retrievedData, encoding: .utf8) {
 
 print("Secret message: \(secretMessage)")
 
 // UI updates must be dispatched back to the main thread.
 
 DispatchQueue.main.async {
 self.messageLabel.text = secretMessage
 }
 
 } else {
 print("Invalid data")
 }
 } else if select_status == errSecUserCanceled {
 print("User canceled the operation.")
 } else {
 print("SELECT Error: \(select_status).")
 }
 }
 }
*/

-(void)changeKeyboard
{
    if (pinDialogField.keyboardType == UIKeyboardTypeNumberPad) {
        [pinDialogField setKeyboardType:UIKeyboardTypeAlphabet];
    }else{
        [pinDialogField setKeyboardType:UIKeyboardTypeNumberPad];
    }
    [pinDialogField reloadInputViews];
}

-(void)openStoreProductViewControllerWithITunesItemIdentifier:(NSInteger)iTunesItemIdentifier
{
    //[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    SKStoreProductViewController *storeViewController = [[SKStoreProductViewController alloc] init];
    
    storeViewController.delegate = self;
    
    [[[GlobalRouter sharedManager] getNavController] presentViewController:storeViewController animated:YES completion:nil];
    
    NSNumber *identifier = [NSNumber numberWithInteger:iTunesItemIdentifier];
    
    NSDictionary *parameters = @{SKStoreProductParameterITunesItemIdentifier:identifier};
    
    //UIViewController *viewController = self.window.rootViewController;
    [storeViewController loadProductWithParameters:parameters
                                   completionBlock:^(BOOL result, NSError *error) {
                                       //[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                                       if (result){
                                           // Moved it up to get rid of a delay to load data
                                           //[[[GlobalRouter sharedManager] getNavController] presentViewController:storeViewController animated:YES completion:nil];
                                       }else{
                                           NSLog(@"SKStoreProductViewController: %@", error);
                                           // Didmiss view controller since we have showed it before loading
                                           [storeViewController dismissViewControllerAnimated:YES completion:nil];
                                       }
                                   }];
    
}

#pragma mark - SKStoreProductViewControllerDelegate

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [viewController dismissViewControllerAnimated:YES completion:nil];
}


-(void)needSearch
{
    //NSLog(@"Showing search window");
    [[[GlobalRouter sharedManager] getListRouter] needSearch];
}

-(void)needSearchWithString:(NSString *)searchStr
{
    [[[GlobalRouter sharedManager] getListRouter] needSearchWithString:searchStr];
}

-(void)needAdvancedSearch
{
    searchInteractor = [[SearchInteractor alloc] init];
    [searchInteractor showSearchInVC:[[GlobalRouter sharedManager] getDetailNavController]];
}

-(int)getNewMessagesCountBG
{
    __block int ret = 0;
    DataManager* dataMan = [[DataManager alloc] init];
    
    if (_pin == nil) {
        return 0;
    }
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ret = [dataMan readNewMessagesCountBG];
        dispatch_semaphore_signal(sema);
    });
    
    // Limit the waiting time to 20 secs
    long res = dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, 28*NSEC_PER_SEC));
    if (res != 0) {
        // Timeout, clear sessions. If you get here and don't clean up, no password needed to launch the app.
        // Prevent a collision when fetch ends after going to foreground
        if([AppDelegate isLocked]){
            [(AppDelegate*)[self getAppDelegate] clearForBG];
        }
    }
    
    return ret;
}

-(int)getNewMessagesCount
{
    __block int ret = 0;
    DataManager* dataMan = [[DataManager alloc] init];
    
    if (_pin == nil) {
        return 0;
    }
    //pin = @"11"; // ????????????????????????
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ret = [dataMan readNewMessagesCount];
        dispatch_semaphore_signal(sema);
    });
    
    //if([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    //    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    //else{
    // Limit the waiting time to 20 secs
        dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, 20*NSEC_PER_SEC));
    //}
    
    return ret;
}

-(int)getNewMessagesCountForFolder:(NSString*)folder address:(NSString*)address
{
    return [[[GlobalRouter sharedManager] getListRouter].manager readNewMessagesCountForFolder:folder address:address];
}

-(void)needShowInbox
{
        /*
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    [listRouter showListInNavController:navController forBox:currentBox];
    */
    //[listRouter showListInNavController:[self getNavController] forBox:currentBox];
    
    //Clear list
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[GlobalRouter sharedManager] getListRouter] clearList];
    });
    
    [GlobalRouter sharedManager].currentBox = btInbox;
    [GlobalRouter sharedManager].currentBoxPath = @"";
    currentBoxPath = @"";

    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [strongSelf->listRouter.interactor requestMessagesForBox:strongSelf.currentBox];
    });
    
    /*
    UIViewController* ret = [listPresenter showListOfType:btInbox]; //[incomingList showListOfType:btInbox];
    //BOOL needToPush = false;
    @try {
        [self popToViewController:ret animated:YES];
    }
    @catch (NSException *exception) {
        //needToPush = TRUE;
        [self pushView:ret];
    }
    @finally {
    }
     */
    
    /*
     AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
     UITabBarController *tabController = (UITabBarController *)appDelegate.window.rootViewController;
     tabController.selectedIndex = 1;
     
     */

}

-(void)needShowSent
{
    [GlobalRouter sharedManager].currentBox = btSent;
    [GlobalRouter sharedManager].currentBoxPath = @"";
    /*
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    [listRouter showListInNavController:navController forBox:currentBox];
    */
    //[listRouter showListInNavController:[self getNavController] forBox:currentBox];
    
    [listRouter.interactor requestMessagesForBox:currentBox];
    
    /*
    //NSLog(@"Showing sent");
    UIViewController* ret = [listPresenter showListOfType:btSent]; //[incomingList showListOfType:btInbox];
    //BOOL needToPush = false;
    @try {
        [self popToViewController:ret animated:YES];
    }
    @catch (NSException *exception) {
        //needToPush = TRUE;
        [self pushView:ret];
    }
    @finally {
    }
*/
}

-(void)needShowFavs
{
    // seems better to find starred messages, not to show btFavourites since
    // Yahoo, for example, doesn't have a starred folder, it sets a star to a message
    // But there's a problem with a search folder - set it to inbox and you won't see
    // starred messages from other boxes
    
    [GlobalRouter sharedManager].currentBox = btFavourites;
    [GlobalRouter sharedManager].currentBoxPath = @"";
    
    [listRouter.interactor requestMessagesForBox:currentBox];
    
    /*
    NSLog(@"Showing favs");
    UIViewController* ret = [listPresenter showListOfType:btFavourites];
    @try {
        [self popToViewController:ret animated:YES];
    }
    @catch (NSException *exception) {
        [self pushView:ret];
    }
     */
}

-(void)needShowSpam
{
    [GlobalRouter sharedManager].currentBox = btSpam;
    [GlobalRouter sharedManager].currentBoxPath = @"";
    
    /*
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    [listRouter showListInNavController:navController forBox:currentBox];
    */
    //[listRouter showListInNavController:[self getNavController] forBox:currentBox];
    
    [listRouter.interactor requestMessagesForBox:currentBox];
    
    /*
    NSLog(@"Showing spam");
    UIViewController* ret = [listPresenter showListOfType:btFavourites];
    @try {
        [self popToViewController:ret animated:YES];
    }
    @catch (NSException *exception) {
        [self pushView:ret];
    }
     */
}

-(void)needShowOtherBox
{
    [GlobalRouter sharedManager].currentBox = btUseName;
    //[GlobalRouter sharedManager].currentBoxPath = @"";
    /*
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    [listRouter showListInNavController:navController forBox:currentBox];
    */
    
    //[listRouter showListInNavController:[self getNavController] forBox:currentBox];
    
    [listRouter.interactor requestMessagesForBox:currentBox];
}

#pragma mark - Toolbar & misc

// Deletes everything sync
-(void)sos
{
    if([NSThread isMainThread]){
        AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
        [appDelegate clearForBG];
        [userData panic];
        NSLog(@"Deleting everything");
        exit(-1);
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
            [appDelegate clearForBG];
            [self->userData panic];
            NSLog(@"Deleting everything");
            exit(-1);
        });
    }
}

-(void)newMessage
{
    //NSLog(@"Showing new message");
    [self needShowComposeMessage:nil includeAttachments:NO forward:NO];
}

-(void)needSettings
{
    //NSLog(@"Showing settings");
    
    /*
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    
    [settingsRouter showSettingsInNavController:navController];
     */
    //[settingsRouter showSettingsInNavController:[self getDetailNavController]];
    Settings2Interactor* sInt = [[Settings2Interactor alloc] init];
    [sInt showSettingsInNavController:[self getDetailNavController] addNew:NO];
}

-(void)needSettingsWithNew:(NSString*)email password:(NSString*)password
{
    Settings2Interactor* sInt = [[Settings2Interactor alloc] init];
    [sInt showSettingsInNavController:[self getDetailNavController] addNew:NO];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [sInt needAddSettingsWithEmail:email password:password];
    });
    
    //[sInt showSettingsInNavController:[self getDetailNavController] addNew:YES];
}

-(void)needSaveSettings:(SettingsEntity *)settings
{
    //[settingsRouter saveSettings:settings];
    Settings2Interactor* sInt = [[Settings2Interactor alloc] init];
    [sInt saveSettings:settings :[GlobalRouter sharedManager].pin];
}

-(void)needPassword:(ShortMessageEntity*)item
{
    //NSLog(@"Showing password input");
    /*
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    */
    //[pinRouter showPinInNavController:[self getNavController] message:item];

}

-(void)needShowMessage:(ShortMessageEntity *)item
{
    //NSLog(@"Showing message");
    /*
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    
    [messageRouter showMessageInNavController:navController message:item];
    */
#if !LITE
    // Check OTP first so that not to load message. Here is a duplicated code. If the OTC is OK, it will be
    // requested twice. Need to pass the OTC to showMessageInNavController.
    if (item && item.encType == enTypeOTC) {
        // Get the key ID and read that key
        // KeyID is stored... where? In the subject line, after the signature, 6 symbols
        OneTimeCert* otc = [[GlobalRouter sharedManager].oneTimeCertInteractor getCertWithID:item.keyID from:item.toAddress];
        if (!otc) {
            [CommonProcs showMessage:NSLocalizedString(@"Cannot find a One-Time Certificate for the message.\nMost likely it is expired and has been deleted.", nil) title:NSLocalizedString(@"Error",nil)];
            otc = nil;
            return;
        }
    }
#endif
    [messageRouter showMessageInNavController:[self getDetailNavController] message:item];
    //self.navigationController.toolbarHidden = YES;
}

-(void)needShowAttachment:(NSObject*)attachment atIndex:(int)index showSaveButton:(BOOL)showSave
{
    /*
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    */
    //ALAssetRepresentation*defaultRep = [attachment defaultRepresentation];
    //UIImage *image = [UIImage imageWithCGImage:[defaultRep fullResolutionImage] scale:[defaultRep scale] orientation:0];
    if ([attachment isKindOfClass:[NSArray class]]) {
        DocsViewController *previewController=[[DocsViewController alloc]init];
        previewController.showSaveButton = showSave;
        previewController.deleteOnExit = NO;
        NSMutableArray* items = [[NSMutableArray alloc] init];
        for (NSString* att in (NSArray*)attachment) {
            [items addObject:[NSURL fileURLWithPath:(NSString*)att]];
        }
        previewController.items = [NSArray arrayWithArray:items];
        previewController.delegate=previewController;
        previewController.dataSource=previewController;
        [previewController setCurrentPreviewItemIndex:index];
        [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:previewController animated:YES completion:^{}];
        return;
    }
    UIImage* image = nil;
    if ([attachment isKindOfClass:[PHAsset class]]) {
        PHAsset* asset = (PHAsset*)attachment;
        if(asset.mediaType == PHAssetMediaTypeImage){
            image = [CommonProcs getFullImage:attachment];
            if (image != nil) {
                [attRouter showAttachmentInNavController:[self getDetailNavController] :image];
                return;
            }
        }else if(asset.mediaType == PHAssetMediaTypeVideo){
            if (asset.mediaSubtypes&PHAssetMediaSubtypeVideoHighFrameRate) {
                NSLog(@"Slow-mo");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [CommonProcs showWheelinView:[[GlobalRouter sharedManager] getCurrentView] message:NSLocalizedString(@"Loading...", nil) stopButtonVisible:YES];
                });
                
                PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
                options.networkAccessAllowed = YES;
                [options setProgressHandler:^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
                        [CommonProcs setProgress:progress*100 max:100 title:@"Loading..."];
                }];
                
                [[PHImageManager defaultManager] requestExportSessionForVideo:asset options:options exportPreset:AVAssetExportPresetPassthrough resultHandler:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {
                    if (!exportSession) {
                        [CommonProcs hideProgress];
                        return;
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [CommonProcs addStopButtonInView:[[GlobalRouter sharedManager] getCurrentView] withBlock:^{
                            [exportSession cancelExport];
                        }];
                    });
                    NSString* path = [CommonProcs getTempPathForDoc:@"mov"];
                    
                    exportSession.outputURL = [NSURL fileURLWithPath:path];
                    exportSession.outputFileType = AVFileTypeQuickTimeMovie;
                    //exportSession.shouldOptimizeForNetworkUse = YES;
                                        
                    [exportSession exportAsynchronouslyWithCompletionHandler:^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [CommonProcs hideProgress];
                            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                                //dispatch_async(dispatch_get_main_queue(), ^{
                                    DocsViewController *previewController=[[DocsViewController alloc]init];
                                    previewController.showSaveButton = showSave;
                                    previewController.items = @[exportSession.outputURL];
                                    previewController.delegate=previewController;
                                    previewController.dataSource=previewController;
                                    [previewController setCurrentPreviewItemIndex:0];
                                    previewController.deleteOnExit = YES;
                                    [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:previewController animated:YES completion:^{
                                        
                                    }];
                                //});
                            }
                        });
                    }];
                }];
            }else{
                __block NSURL* url;
                //BOOL wait = asset.mediaType == PHAssetMediaTypeVideo;
            
                PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
                options.networkAccessAllowed = YES;
                
                [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset *avAsset, AVAudioMix *audioMix, NSDictionary *info) {
                    url = (NSURL *)[[(AVURLAsset *)avAsset URL] fileReferenceURL];
                    
                    NSString* path = [CommonProcs getTempPathForDoc:[url.path pathExtension]];
                    NSError *error;
                    AVURLAsset *avurlasset = (AVURLAsset*) avAsset;
                    
                    // Write to documents folder
                    NSURL *fileURL = [NSURL fileURLWithPath:path];
                    if ([[NSFileManager defaultManager] copyItemAtURL:avurlasset.URL
                                                                toURL:fileURL
                                                                error:&error]) {
                        NSLog(@"Copied correctly");
                    }
                    
                    // Showing doesn't work on a device, permission problem, seems to be a bug.
                    // To show it we need to copy it to the temp dir.
                    if(![NSThread isMainThread]){ // Guess it is always on the BG thread and no need to check
                        dispatch_async(dispatch_get_main_queue(), ^{
                            DocsViewController *previewController=[[DocsViewController alloc]init];
                            previewController.showSaveButton = showSave;
                            previewController.items = @[fileURL];
                            previewController.delegate=previewController;
                            previewController.dataSource=previewController;
                            [previewController setCurrentPreviewItemIndex:0];
                            previewController.deleteOnExit = YES;
                            [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:previewController animated:YES completion:^{
                                
                            }];
                        });
                    }else{
                        DocsViewController *previewController=[[DocsViewController alloc]init];
                        previewController.showSaveButton = showSave;
                        previewController.items = @[fileURL];
                        previewController.delegate=previewController;
                        previewController.dataSource=previewController;
                        [previewController setCurrentPreviewItemIndex:0];
                        previewController.deleteOnExit = YES;
                        [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:previewController animated:YES completion:^{
                            
                        }];
                    }
                }];
            }
            
            /*
            // Can it deadlock?
            if(wait){
                while (!url) {
                    sleep(1);
                }
            }
            */
            
            return;
        }
    }
    //UIImage* image = [CommonProcs getFullImage:attachment];
    if (image != nil) { // No way to get here?
        //[attRouter showAttachmentInNavController:[self getDetailNavController] :image];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *url = [NSURL fileURLWithPath:(NSString*)attachment];
            DocsViewController *previewController=[[DocsViewController alloc]init];
            previewController.showSaveButton = showSave;
            previewController.deleteOnExit = NO;
            previewController.items = @[url];
            previewController.delegate=previewController;
            previewController.dataSource=previewController;
            [previewController setCurrentPreviewItemIndex:0];
            [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:previewController animated:YES completion:^{}];
        });
    }else if([attachment isKindOfClass:[NSString class]]){
        /*
        NSURL *url = [NSURL fileURLWithPath:(NSString*)attachment];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        UIWebView* tmpw = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
        [tmpw loadRequest:request];
        [[[GlobalRouter sharedManager] getCurrentView] addSubview:tmpw];
         */
        //[helpRouter showOtherFileInNavController:[self getDetailNavController] file:(NSString*)attachment];
        dispatch_async(dispatch_get_main_queue(), ^{
            NSURL *url = [NSURL fileURLWithPath:(NSString*)attachment];
            DocsViewController *previewController=[[DocsViewController alloc]init];
            previewController.showSaveButton = showSave;
            previewController.deleteOnExit = NO;
            previewController.items = @[url];
            previewController.delegate=previewController;
            previewController.dataSource=previewController;
            [previewController setCurrentPreviewItemIndex:0];
            [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:previewController animated:YES completion:^{}];
        });
    }
    
}

-(void)needShowSecureImage:(UIImage*)image
{
    [attRouter showAttachmentInNavController:[self getDetailNavController] :image secure:YES];
}

-(void)needShowAddressBookWithCaller:(id<CanGetAddressFromBook>)caller //(UIView*)caller
{
    /*
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    */
    //[CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Loading...", nil) stopButton:NO];
    
    /*
    dispatch_queue_t myQ = dispatch_queue_create("myQ", DISPATCH_QUEUE_SERIAL);
    dispatch_async(myQ, ^{
        addrRouter.caller = caller;
        [addrRouter showBookInNavController:[self getNavController]];
    });
     */
    addrRouter.caller = caller;
    //[addrRouter performSelectorInBackground:@selector(showBookInNavController:) withObject:[self getNavController]];
    [CommonProcs spawnProcWithProgress:@selector(showBookInNavController:) object:addrRouter withParam:[self getDetailNavController] onMain:YES];
    /*
    NSOperationQueue* myQ = [[NSOperationQueue alloc] init];
    myQ.maxConcurrentOperationCount = 1;
    [myQ addOperationWithBlock:^{
        addrRouter.caller = caller;
        [addrRouter showBookInNavController:[self getNavController]];
    }];
    */
}

-(void)userInfoFinishedTask:(BOOL)res
{
    //[CommonProcs showProgress:10 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    [CommonProcs hideProgress];
}

-(void)needAddAttachmentWithCaller:(id<AddAttachmentReceiver>) caller
{
    /*
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    */
    addAttRouter.caller = caller;
    [addAttRouter showViewInNavController:[self getDetailNavController]];
}

-(void)needAddSecureAttachmentWithCaller:(id<AddAttachmentReceiver>)caller
{
    galleryRouter.caller = caller;
    [galleryRouter openGalleryInNavController:[[GlobalRouter sharedManager] getDetailNavController]];
}

-(void)needShowAddressBook
{
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [strongSelf needShowAddressBookWithCaller:nil];
    });
    
}

-(void)needShowAddContactFor:(NSString*)name address:(NSString*)address
{
    
}

-(void)needShowComposeMessage:(FullMessageEntity *)message includeAttachments:(BOOL)includeAttachments forward:(BOOL)forward
{
    /*
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    */
    [compRouter showComposerInNavController:[self getDetailNavController] message:message includeAttachments:includeAttachments forward:forward];
}

-(void)composerWillEnterForeground
{
    // Check if composer window is active and if so, minimize it
    //UIViewController * topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    //UIView* cv = [[GlobalRouter sharedManager] getCurrentView];
    if (compRouter.currentMessage != nil) {
        [compRouter minimizeComposer];
    }
}

-(void)needShowSendCertificate:(FullMessageEntity *)message
{
    /*
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    */
    [compRouter showCertComposerInNavController:[self getNavController] message:message];
}

-(void)needShowGallery
{
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [strongSelf->galleryRouter openGalleryInNavController:[strongSelf getDetailNavController]];
    });
}

-(void)needShowHelp
{
    [helpRouter showHelpInNavController:[self getDetailNavController]];
}

-(void)needShowPP
{
    [helpRouter showHelpInNavController:[self getDetailNavController] file:NSLocalizedString(@"PrivacyPolicy", nil)];
}

-(void)needShowNotes
{
#ifdef DEMO
    [CommonProcs thisFeatureIsInFull:@"Secure Notes functionality"];
#else
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [strongSelf->notesRouter showNotesInNavController:[strongSelf getDetailNavController]];
    });
    
#endif
}

#if !LITE
-(void)needShowCertExchange:(AddressBookEntity*)addr
{
    [certRouter showViewInNavController:[self getDetailNavController] forAddress:addr];
}
#endif

-(void)finishedWithCurrentView:(BOOL)animated
{
    // Check if it's on the main, since if you are on the main thread, enqueueing it to the main
    // thread again will put it at the end of the Q. And that will cause a problem if you close
    // the view and open the new one - closing will be put at the end of the q, then you open a view and
    // after that it will come a turn to close it...
    
    ////TODO: check if we really need navController, not detailNavController!
    //// or leave it to developer
    if(![NSThread isMainThread]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self getNavController] popViewControllerAnimated:animated];
        });
    }else{
        [[self getNavController] popViewControllerAnimated:animated];
    }
}

-(void)finishedWithDetailView:(BOOL)animated
{
    // Check if it's on the main, since if you are on the main thread, enqueueing it to the main
    // thread again will put it at the end of the Q. And that will cause a problem if you close
    // the view and open the new one - closing will be put at the end of the q, then you open a view and
    // after that it will come a turn to close it...
    
    // Check if we are already showing the list of messages...
    UIViewController* topVC = [[GlobalRouter sharedManager] getTopViewController];
    if ([topVC isKindOfClass:[MessageListViewController class]]) {
        return;
    }
    
    if ([[GlobalRouter sharedManager].getListRouter isShowingMenu]) {
        // Need to remove the menu - disabled since this logic is confusing
        //[[GlobalRouter sharedManager].getListRouter dismissMenu];
        //return;
    }
    
    if(![NSThread isMainThread]){
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self getDetailNavController] popViewControllerAnimated:animated];
        });
    }else{
        [[self getDetailNavController] popViewControllerAnimated:animated];
    }
}



-(void)finishedWithCurrentView
{
    [self finishedWithCurrentView:NO];
}

-(void)updateCurrentList
{
    //[listPresenter updateList];
    [listRouter needUpdateList];
}

-(UIView*)getCurrentView
{
    // Getting window from delegate works better that keyWindow in case of ActionSheet - then dismiss
    // it, the key windows seems to be dismissed too and my dimView is also being dismissed.
    __block UIWindow* currentWindow;// = [[[UIApplication sharedApplication] delegate] window];
    if(![NSThread isMainThread]){
        // Waiting alert but shouldn't be on main thread
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        //__weak __typeof__(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            //__strong __typeof__(self) strongSelf = weakSelf;
            currentWindow = [[[UIApplication sharedApplication] delegate] window];
            dispatch_semaphore_signal(sema);
        });
        dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)));
        
    }else{
        currentWindow = [[[UIApplication sharedApplication] delegate] window]; //[UIApplication sharedApplication].keyWindow;
    }
    return currentWindow;
}

-(void)requestCreateFolder:(NSString *)newFolderName
{
    [listRouter.dataStore createFolder:newFolderName];
}

-(void)requestDeleteFolder:(NSString *)folderName
{
    [listRouter.dataStore deleteFolder:folderName];
}

-(void)requestRenameFolder:(NSString*)folderName newName:(NSString*)newFolderName
{
    [listRouter.dataStore renameFolder:folderName newName:newFolderName];
}

-(ShortMessageEntity*)getNextShortMessageFor:(ShortMessageEntity*)item
{
    return [[[GlobalRouter sharedManager] getListRouter] getNextShortMessageFor:item];
}

-(ShortMessageEntity*)getPrevShortMessageFor:(ShortMessageEntity*)item
{
    return [[[GlobalRouter sharedManager] getListRouter] getPrevShortMessageFor:item];
}

-(void)needShare
{
    NSString *shareString = NSLocalizedString(@"ShareMessage", nil);
    //UIImage *shareImage = [UIImage imageNamed:@"logoToShare.jpg"];
    NSURL *shareUrl = [NSURL URLWithString:@"http://www.creepytwolabs.com"];
    
    NSArray *activityItems = [NSArray arrayWithObjects:shareString, /*shareImage,*/ shareUrl, nil];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    
    // tell the activity view controller which activities should NOT appear
    activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList];
    
    // display the options for sharing
    activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    if ( [activityViewController respondsToSelector:@selector(popoverPresentationController)] ) {
        // iOS8
        activityViewController.popoverPresentationController.sourceView = [self getCurrentView];
    }
    [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:activityViewController animated:YES completion:nil];
}

-(void)needExit
{
    [CommonProcs showWheelinView:[[GlobalRouter sharedManager] getCurrentView]  message:NSLocalizedString(@"Cleaning up...", nil) stopButtonVisible:NO];
    [DataManager deleteTempFiles];
    
    if(![GlobalRouter sharedManager].clearOnBGSetting){
        //AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
        //[appDelegate cleanUp];
        //[CommonProcs hideProgress];
        //[[UIApplication sharedApplication] performSelector:@selector(suspend)];
        [GlobalRouter sharedManager].needToClearBG = YES;
    }
    if([GlobalRouter sharedManager].keepInBg){
        [[UIApplication sharedApplication] performSelector:@selector(suspend)];
        [CommonProcs hideProgress];
    }else{
        //AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
        //[appDelegate clearForBG]; // NO! not here!
        [CommonProcs hideProgress];
        [[UIApplication sharedApplication] performSelector:@selector(suspend)];
        //exit(0);
    }
}

-(void)checkSessions
{
    [listRouter clearList];
    [listRouter.dataStore resetMessages];
    [GlobalRouter sharedManager].otherFolders = nil;
    [listRouter.manager checkMailSessions];
}

-(BOOL)checkConnection:(SettingsEntity*)sett completion:(void (^)(BOOL))compl//(dispatch_block_t)compl
{
    __block BOOL ret = YES;
    //[CommonProcs showProgressWithTitle:1 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Checking IMAP account...", nil) stopButton:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL res = [[[GlobalRouter sharedManager] getListRouter].manager checkConnection:sett];
        if(res){
            dispatch_async(dispatch_get_main_queue(), ^{
                //[CommonProcs setMessageInProgress:@"OK"];
                compl(res);
            });
            //NSLog(@"SUCCESS");
        }else{
            compl(res);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //[CommonProcs hideProgress];
        });
        
    });
    
    return ret;
}

-(int)checkSMTPConnection:(SettingsEntity*)sett completion:(void (^)(int))compl//(dispatch_block_t)compl
{
    __block int ret = 0;
    //[CommonProcs showProgressWithTitle:1 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Checking SMTP account...", nil) stopButton:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        int res = [[[GlobalRouter sharedManager] getListRouter].manager checkSMTPConnection:sett];
        if(res == 0){
            dispatch_async(dispatch_get_main_queue(), ^{
                //[CommonProcs setMessageInProgress:@"OK"];
                compl(res);
            });
            //NSLog(@"SUCCESS");
        }else{
            compl(res);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            //[CommonProcs hideProgress];
        });
    });
    
    return ret;
}

-(SettingsEntity*)getSettingForAddress:(NSString*)address
{
    for (SettingsEntity* sett in [GlobalRouter sharedManager].allSettings) {
        if ([sett.userName isEqualToString:address]) {
            return sett;
        }
    }
    
    return nil;
}

-(void)showMessageInfo:(NSString *)info
{
    MessageInfoInteractor* mii = [[MessageInfoInteractor alloc] init];
    [mii presentViewInNavController:[self getDetailNavController] messageInfo:info];
    [CommonProcs hideSmallWheel]; // The wheel was shown at CommonProcs wantMessageInfo
}

-(void)showAddMaster
{
    dispatch_async(dispatch_get_main_queue(), ^{
        EasySetupInteractor* esi = [[EasySetupInteractor alloc] init];
        [esi showMasterInNC:[[GlobalRouter sharedManager] getNavController]];
    });
}

-(void)initPossibleAddresses
{
    if ([GlobalRouter sharedManager].possibleAddresses == nil) {
        [GlobalRouter sharedManager].possibleAddresses = [[NSMutableArray alloc] init];
    }else{
        [[GlobalRouter sharedManager].possibleAddresses removeAllObjects];
    }
    
    // Fill it from the address book
    CNContactStore *store = [[CNContactStore alloc] init];
    [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted == YES) {
            //keys with fetching properties
            NSArray *keys = @[CNContactFamilyNameKey, CNContactGivenNameKey, CNContactMiddleNameKey, CNContactEmailAddressesKey];
            CNContactFetchRequest *request = [[CNContactFetchRequest alloc] initWithKeysToFetch:keys];
            NSError *error;
            /*BOOL success = */[store enumerateContactsWithFetchRequest:request error:&error usingBlock:^(CNContact * __nonnull contact, BOOL * __nonnull stop) {
                if (error) {
                    NSLog(@"error fetching contacts %@", error);
                } else {
                    if(contact.emailAddresses.count > 0){
                        for (CNLabeledValue* email in contact.emailAddresses) {
                            NSString* emstr = email.value;
                            NSString* fullName;
                            if ([contact.middleName isEqualToString:@""]) {
                                fullName = [NSString stringWithFormat:@"%@ %@", contact.familyName, contact.givenName];
                            }else{
                                fullName = [NSString stringWithFormat:@"%@ %@ %@", contact.familyName, contact.middleName, contact.givenName];
                            }
                            if(emstr && ![emstr isEqualToString:@""]){
                                // Check if it's already there
                                BOOL found = NO;
                                for (AutocompleteItem* aItem in [GlobalRouter sharedManager].possibleAddresses) {
                                    if ([aItem.email isEqualToString:emstr]) {
                                        found = YES;
                                        break;
                                    }
                                }
                                if (!found) {
                                    AutocompleteItem* au = [[AutocompleteItem alloc] init];
                                    au.name = fullName;
                                    au.email = emstr;
                                    [[GlobalRouter sharedManager].possibleAddresses addObject:au];
                                }
                            }
                        }
                    }
                }
            }];
        }
    }];
}

-(void)addPossibleAddressFromShortMessage:(ShortMessageEntity*)item
{
    if(!item)return;
    if (!item.fromAddress || [item.fromAddress isEqualToString:@""]) {
        return;
    }
    
    BOOL found = NO;
    for (AutocompleteItem* aItem in [GlobalRouter sharedManager].possibleAddresses) {
        if ([aItem.email isEqualToString:item.fromAddress]) {
            found = YES;
            break;
        }
    }
    if (!found) {
        AutocompleteItem* au = [[AutocompleteItem alloc] init];
        au.email = item.fromAddress;
        au.name = item.fromName;
        [[GlobalRouter sharedManager].possibleAddresses addObject:au];//item.fromAddress];
    }
}

-(void)updateNumbers
{
    [[[GlobalRouter sharedManager] getListRouter].dataStore updateStoredHighestModSecForAll];
}

-(void)cancelPinDialog
{
    [GlobalRouter sharedManager].waitingForPin = NO;
    [pinDimView removeFromSuperview];
    [GlobalRouter sharedManager].pinAlert = NO;
    questionAnswered = YES;
    if(condition)
        [condition signal];
    //else
    [pinInteractor cancelPinDialog];
}

-(BOOL)canClearCurrentBox
{
    NSDictionary* folderDict = [[GlobalRouter sharedManager].otherFolders objectForKey:[GlobalRouter sharedManager].currentAccount];
    for (FolderInfo* fi in [folderDict allValues]) {
        if ([fi.folderPath isEqualToString:[GlobalRouter sharedManager].currentBoxPath]) {
            return fi.folderType == btDeleted || fi.folderType == btSpam;
        }
    }
    
    return NO;
}

@end
