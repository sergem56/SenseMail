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

#import "ModalDialogViewController.h"
//#import <AssetsLibrary/AssetsLibrary.h>

@implementation GlobalRouter

@synthesize currentBox, currentBoxPath, otherFolders, currentFilter, pin, currentSettingNo;

#pragma mark - Init and setup

+(GlobalRouter*)sharedManager {
    static GlobalRouter *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

-(id)init
{
    if(self = [super init]){
        //listPresenter = [[ListPresenter alloc] init];
        messageRouter = [[MessageViewRouter alloc]init];
        userData = [[UserInfoDataManager alloc]init];
        settingsRouter = [[SettingsRouter alloc] init];
        attRouter = [[AttachmentViewRouter alloc] init];
        addrRouter = [[AddressBookRouter alloc]init];
        compRouter = [[ComposeMessageRouter alloc] init];
        addAttRouter = [[AddAttachmentRouter alloc] init];
        listRouter = [[MessageListRouter alloc] init];
        galleryRouter = [[GalleryRouter alloc] init];
        helpRouter = [[HelpRouter alloc] init];
        notesRouter = [[NotesRouter alloc] init];
        
        //assets = [DataManager defaultAssetsLibrary];
        
        [DataManager deleteTempFiles];
        
        mainAppQueue = dispatch_queue_create("Network Queue",NULL);
        shouldCancel = NO;
        currentBox = btEmpty;
        self.currentAccount = @"";
        
        self.otherFolders = [[NSMutableDictionary alloc] init];
        self.currentFilter = @"";
        
        currentSettingNo = 0;
        self.keepInBg = NO;
    }
    
    return self;
}

-(UINavigationController*)getNavController
{
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    
    return navController;
}

-(dispatch_queue_t)getQ
{
    if (mainAppQueue == nil) {
        mainAppQueue = dispatch_queue_create("Network Queue",NULL);
    }
    
    return mainAppQueue;
}

-(void)cancelQ
{
    shouldCancel = YES;
    
    if(messageRouter.dataStore != nil)
        [messageRouter.dataStore cancelSessionOps];
    else if(listRouter.dataStore != nil)
        [listRouter.dataStore cancelSessionOps];
}

-(BOOL)isCancelled
{
    return shouldCancel;
}

-(void)restartQ
{
    shouldCancel = NO;
}

/*
-(ListPresenter*)getListPresenter
{
    return listPresenter;
}
 */

-(Encryptor*)getEncoderForPin:(NSString *)pinStr salt:(NSString *)forSalt
{
    BOOL doNotSearch = NO;
    if (encs == nil) {
        encs = [[NSMutableDictionary alloc] init];
        doNotSearch = YES;
    }
    Encryptor* enc;
    NSString* tmp = [NSString stringWithFormat:@"%@%@", pinStr, forSalt];
    NSString* pinHash = [Encryptor getHashForString:tmp];
    if (doNotSearch) {
        enc = [[Encryptor alloc] initWithKey:pinStr salt:forSalt];
        [encs setObject:enc forKey:pinHash];
    }else{
        enc = [encs objectForKey:pinHash];
        if (enc == nil) {
            enc = [[Encryptor alloc] initWithKey:pinStr salt:forSalt];
            [encs setObject:enc forKey:pinHash];
        }
    }
    
    return enc;
}

-(NSString*)pin
{
    if (pin == nil) {
        if(![NSThread isMainThread]){
            // Waiting alert but shouldn't be on main thread
            condition = [NSCondition new];
            questionAnswered = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self askForPin];
            });
            [condition lock];
            while (! questionAnswered) [condition wait];
            questionAnswered = NO;
            [condition unlock];
        }else{
            NSLog(@"On main thread");
            condition = nil;
            [self askForPin];
        }
    }
    return pin;
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

#pragma mark - Assets

-(NSMutableArray*)getAssets
{
    if (assets == nil || assets.count == 0) {
        assets = [DataManager defaultAssetsLibrary];
    }
    return assets;
}

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
    [listRouter showListInNavController:[self getNavController] forBox:btInbox];
}

-(void)doShowEmpty
{
    currentBox = btEmpty;
    dispatch_async(dispatch_get_main_queue(), ^{
        [listRouter showListInNavController:[self getNavController] forBox:btEmpty];
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        [listRouter.dataStore checkSessionForBox:btEmpty];
    });
}

-(void)initialPush
{
    // Ask for pin
    if ([userData isPasswordNeeded]) {
        //[self askForPin];
        if([GlobalRouter sharedManager].pin == nil){
            // Need to access pin, so it will ask for it blocking execution
        }
        [self doShowEmpty];
    }else{
        [self doShowInbox];
        
    }
}

-(void)askForPin
{
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter PIN",nil) message:NSLocalizedString(@"Application PIN is time-outed",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Done",nil),nil];
    alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [alert setTag:100];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100)
    {
        if (buttonIndex == 0)
        {
            exit(0);
        }else{
            [GlobalRouter sharedManager].pin = [[alertView textFieldAtIndex:0] text];
            //[self doShowEmpty];
        }
        
        questionAnswered = YES;
        if(condition)
            [condition signal];
        //[condition unlock];
    }
}

-(void)needSearch
{
    NSLog(@"Showing search window");
}

-(int)getNewMessagesCount
{
    __block int ret = 0;
    DataManager* dataMan = [[DataManager alloc] init];
    
    if (pin == nil) {
        return 0;
    }
    //pin = @"11"; // ????????????????????????
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        ret = [dataMan readNewMessagesCount];
        dispatch_semaphore_signal(sema);
    });
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    return ret;
}

-(void)needShowInbox
{
    currentBox = btInbox;
    [GlobalRouter sharedManager].currentBoxPath = @"";
    currentBoxPath = @"";
    /*
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    [listRouter showListInNavController:navController forBox:currentBox];
    */
    [listRouter showListInNavController:[self getNavController] forBox:currentBox];
    
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
    currentBox = btSent;
    [GlobalRouter sharedManager].currentBoxPath = @"";
    /*
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    [listRouter showListInNavController:navController forBox:currentBox];
    */
    [listRouter showListInNavController:[self getNavController] forBox:currentBox];
    
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
    currentBox = btFavourites;
    [GlobalRouter sharedManager].currentBoxPath = @"";
    /*
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    [listRouter showListInNavController:navController forBox:currentBox];
    */
    [listRouter showListInNavController:[self getNavController] forBox:currentBox];
    
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
    currentBox = btSpam;
    [GlobalRouter sharedManager].currentBoxPath = @"";
    
    /*
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    [listRouter showListInNavController:navController forBox:currentBox];
    */
    [listRouter showListInNavController:[self getNavController] forBox:currentBox];
    
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
    currentBox = btUseName;
    //[GlobalRouter sharedManager].currentBoxPath = @"";
    /*
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    [listRouter showListInNavController:navController forBox:currentBox];
    */
    
    [listRouter showListInNavController:[self getNavController] forBox:currentBox];
}

#pragma mark - Toolbar & misc

-(void)sos
{
    NSLog(@"Deleting everything");
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
    [settingsRouter showSettingsInNavController:[self getNavController]];
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
    
    [messageRouter showMessageInNavController:[self getNavController] message:item];
    //self.navigationController.toolbarHidden = YES;
}

-(void)needShowAttachment:(NSObject*)attachment
{
    /*
    AppDelegate *appDelegate = (AppDelegate*) [[UIApplication sharedApplication] delegate];
    UINavigationController *navController = (UINavigationController *)appDelegate.window.rootViewController;
    */
    //ALAssetRepresentation*defaultRep = [attachment defaultRepresentation];
    //UIImage *image = [UIImage imageWithCGImage:[defaultRep fullResolutionImage] scale:[defaultRep scale] orientation:0];
    UIImage* image = [CommonProcs getFullImage:attachment];
    
    [attRouter showAttachmentInNavController:[self getNavController] :image];
}

-(void)needShowSecureImage:(UIImage*)image
{
    [attRouter showAttachmentInNavController:[self getNavController] :image];
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
    [CommonProcs spawnProcWithProgress:@selector(showBookInNavController:) object:addrRouter withParam:[self getNavController]];
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
    [addAttRouter showViewInNavController:[self getNavController]];
}

-(void)needShowAddressBook
{
    [self needShowAddressBookWithCaller:nil];
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
    [compRouter showComposerInNavController:[self getNavController] message:message includeAttachments:includeAttachments forward:forward];
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
    [galleryRouter openGalleryInNavController:[self getNavController]];
}

-(void)needShowHelp
{
    [helpRouter showHelpInNavController:[self getNavController]];
}

-(void)needShowPP
{
    [helpRouter showHelpInNavController:[self getNavController] file:NSLocalizedString(@"PrivacyPolicy", nil)];
}

-(void)needShowNotes
{
    [notesRouter showNotesInNavController:[self getNavController]];
}

-(void)finishedWithCurrentView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self getNavController] popViewControllerAnimated:NO];
    });
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
    UIWindow* currentWindow = [[[UIApplication sharedApplication] delegate] window]; //[UIApplication sharedApplication].keyWindow;
    return currentWindow;
}

@end
