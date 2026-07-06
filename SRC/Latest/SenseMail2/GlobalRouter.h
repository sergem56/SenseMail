//
//  GlobalRouter.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//
// Keeps reference to other routers

#import <Foundation/Foundation.h>
#import <UIKit/UINavigationController.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <StoreKit/StoreKit.h>
#import "ListPresenter.h"
#import "MessageViewRouter.h"
//#import "PinRouter.h"
#import "UserInfoDataManager.h"
#import "SettingsRouter.h"
#import "AttachmentViewRouter.h"
#import "AddressBookRouter.h"
#import "ComposeMessageRouter.h"
#import "AddAttachmentRouter.h"
#import "MessageListRouter.h"
#import "GalleryRouter.h"
#import "HelpRouter.h"
#import "NotesRouter.h"
#if !LITE
    #import "CertExchangeRouter.h"
    @class OneTimeCertInteractor;
#endif
#import "CommonStuff.h"

@class FullMessageEntity;
@class Encryptor;
@class DetailViewController;
@class ListInteractor;

@class SearchInteractor;
@class PinInteractor;

#ifdef DEBUG
#   define NSLog(...) NSLog(__VA_ARGS__)
#else
#   define NSLog(...)
#endif

@interface AutocompleteItem: NSObject

@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* email;

@end

#define SOSPINSIG @"SMUserPrefs"

@interface GlobalRouter :  UINavigationController <userInfoNotificationReceiver, SKStoreProductViewControllerDelegate>{
    // Routers
    //ListPresenter* listPresenter;
    MessageViewRouter* messageRouter;
    //PinRouter* pinRouter;
    UserInfoDataManager* userData;
    SettingsRouter* settingsRouter;
    AttachmentViewRouter* attRouter;
    AddressBookRouter* addrRouter;
    ComposeMessageRouter* compRouter;
    AddAttachmentRouter* addAttRouter;
    MessageListRouter* listRouter;
    GalleryRouter* galleryRouter;
    HelpRouter* helpRouter;
    NotesRouter* notesRouter;
#if !LITE
    CertExchangeRouter* certRouter;
#endif
    SearchInteractor* searchInteractor;
    PinInteractor* pinInteractor;
    // Q
    dispatch_queue_t mainAppQueue;
    //BOOL shouldCancel;
    
    //TEMP
    NSMutableArray* assets;
    
    NSMutableDictionary* /* PinHash-Encryptor* */ encs;
    
    NSCondition* condition;
    BOOL questionAnswered;
    UIView* pinDimView;
    UITextField* pinDialogField;
    
    dispatch_semaphore_t vpnSemaphore;
}

+(GlobalRouter*)sharedManager;

@property (nonatomic, strong, setter=setPin:) NSMutableString* pin;
@property (nonatomic, strong) NSMutableString* oldPin;
@property (nonatomic, assign) BOOL waitingForPin;
@property (nonatomic, assign) BOOL needStartWithSettings;
@property (nonatomic, assign) BOOL thisIsTheFirstRun;
@property (nonatomic, assign) int nMessagesToLoad;

@property (nonatomic, assign) BOOL shouldCancel;

@property (nonatomic, assign) BOOL keepInBg;
@property (nonatomic, assign) float compression;

@property (nonatomic, assign) boxTypes currentBox;
@property (nonatomic, strong) NSString* currentBoxPath;
@property (nonatomic, strong) NSString* currentAccount;
@property (nonatomic, strong) NSString* currentFilter;
@property (nonatomic, assign) int currentSettingNo;

@property (nonatomic, assign) int newMessages; // new in currently shown
@property (nonatomic, assign) int newMessagesTotal;
@property (nonatomic, assign) int totalMessages;
@property (nonatomic, assign) int loadedMessages;

@property (nonatomic, weak) DetailViewController* detailVC;

//@property (nonatomic, strong) NSMutableDictionary* settingsNames;
@property (nonatomic, strong) NSArray* allSettings;

// Autocomplete. Array of AutocompleteItems
@property (nonatomic, strong) NSMutableArray* possibleAddresses;

#ifdef STRONG
// Key stuff for ver.2
@property (nonatomic, assign) int currentPos;
//@property (nonatomic, assign) int keyID;
#endif

@property (nonatomic, strong) NSMutableDictionary* otherFolders; // dictionary [account name+dict] of dictionary [folder name+path]

@property (nonatomic, strong) NSMutableDictionary* accountsNames; // accName+emailAddress

@property (nonatomic, assign) BOOL connectionCancelled;

@property (nonatomic, assign) BOOL pinAlert;
#if !LITE
@property (nonatomic, strong) OneTimeCertInteractor* oneTimeCertInteractor;
#endif
@property (nonatomic, assign) BOOL goingToBG;
@property (nonatomic, assign) BOOL needToClearBG; // Force clean up
@property (nonatomic, assign) BOOL clearOnBGSetting;
@property (nonatomic, assign) BOOL needToReloadOnStart;
@property (nonatomic, assign) BOOL doNotHideAccountInNotification;
@property (nonatomic, assign) BOOL showShortcuts;

@property (nonatomic, assign) BOOL needVPN;
@property (nonatomic, strong) ShortMessageEntity* currentFetchingMessage;

+(void)cleanUp;
+(BOOL)notInited;
-(void)resetPinDialog;

-(UINavigationController*)getNavController;
-(UINavigationController*)getDetailNavController;
//-(UINavigationController*)getNavController2;
-(UIViewController *)getTopViewController;
-(UIViewController*)getRootVC;

-(void)pushView:(UIViewController *)viewController;

-(void)initialPush;
-(void)updateCurrentList;
-(dispatch_queue_t)getQ;
-(void)cancelQ;
-(void)restartQ;
-(BOOL)isCancelled;


-(int)getNewMessagesCount;
-(int)getNewMessagesCountBG;
-(int)getNewMessagesCountForFolder:(NSString*)folder address:(NSString*)address;

//-(ListPresenter*) getListPresenter;
-(MessageViewRouter*) getMessageRouter;
//-(PinRouter*)getPinRouter;
-(SettingsRouter*)getSettingsRouter;
-(AttachmentViewRouter*)getAttachmentRouter;
-(AddressBookRouter*)getBookRouter;
-(ComposeMessageRouter*)getComposeRouter;
-(AddAttachmentRouter*)getAddAttRouter;
-(MessageListRouter*)getListRouter;
-(GalleryRouter*)getGalleryRouter;
-(HelpRouter*)getHelpRouter;
-(NotesRouter*)getNotesRouter;
#if !LITE
-(CertExchangeRouter*)getCertRouter;
#endif
-(PinInteractor*)getPinInteractor;

//-(NSMutableArray*) getAssets;
-(void)setAssets:(NSMutableArray*)assetsToSet;

-(Encryptor*)getEncoderForPin:(NSMutableString*)pin; //salt:(NSString*)forSalt;
-(void)clearEncoders;

-(void)doShowEmpty;

-(void)newMessage;
-(void)needSettings;
//-(void)needSettingsWithNew;
-(void)needSettingsWithNew:(NSString*)email password:(NSString*)password;
-(void)needSaveSettings:(SettingsEntity *)settings;
-(void)needSearch;
-(void)needSearchWithString:(NSString*)searchStr;
-(void)needAdvancedSearch;

-(void)needShowInbox;
-(void)needShowSent;
-(void)needShowFavs;
-(void)needShowSpam;
-(void)needShowOtherBox;
-(void)sos;
-(void)needShowGallery;
-(void)needShowHelp;
-(void)needShowNotes;
-(void)needShowPP;
-(void)needShowWhatsNew;
-(void)needShare;
-(void)needExit;

//
-(void)needPassword:(ShortMessageEntity*)item;
-(void)needShowMessage:(ShortMessageEntity*)item;
-(void)needShowAttachment:(NSObject*)attachment atIndex:(int)index showSaveButton:(BOOL)showSave;
-(void)needShowSecureImage:(UIImage*)image;
-(void)needShowAddressBook;
-(void)needShowAddressBookWithCaller:(id<CanGetAddressFromBook>) caller;
-(void)needShowAddContactFor:(NSString*)name address:(NSString*)address;
-(void)needAddAttachmentWithCaller:(id<AddAttachmentReceiver>) caller;
-(void)needAddSecureAttachmentWithCaller:(id<AddAttachmentReceiver>) caller;
-(void)needShowSendCertificate:(FullMessageEntity *)message;
#if !LITE
-(void)needShowCertExchange:(AddressBookEntity*)addr;
#endif
-(void)needShowComposeMessage:(FullMessageEntity*)message includeAttachments:(BOOL)includeAttachments forward:(BOOL)forward;
-(void)composerWillEnterForeground;

-(void)finishedWithCurrentView;
-(void)finishedWithCurrentView:(BOOL)animated;
-(void)finishedWithDetailView:(BOOL)animated;

-(UIView*)getCurrentView;
//-(void)addButton:(NSString*)buttonName;

-(void)requestCreateFolder:(NSString*)newFolderName;
-(void)requestDeleteFolder:(NSString*)folderName;
-(void)requestRenameFolder:(NSString*)folderName newName:(NSString*)newFolderName;

-(ShortMessageEntity*)getNextShortMessageFor:(ShortMessageEntity*)item;
-(ShortMessageEntity*)getPrevShortMessageFor:(ShortMessageEntity*)item;

-(void)checkSessions;
-(BOOL)checkConnection:(SettingsEntity*)sett completion:(void (^)(BOOL))compl;//(dispatch_block_t)compl;
//-(BOOL)checkSMTPConnection:(SettingsEntity*)sett completion:(dispatch_block_t)compl;
-(int)checkSMTPConnection:(SettingsEntity*)sett completion:(void (^)(int))compl;

-(SettingsEntity*)getSettingForAddress:(NSString*)address;

-(void)openStoreProductViewControllerWithITunesItemIdentifier:(NSInteger)iTunesItemIdentifier;

-(void)showMessageInfo:(NSString*)info;

-(void)showAddMaster;

-(void)initPossibleAddresses;
-(void)addPossibleAddressFromShortMessage:(ShortMessageEntity*)item;

-(void)checkNewVersion;
-(void)updateNumbers;

-(void)cancelPinDialog;

-(BOOL)canClearCurrentBox;

#if USESEC
-(BOOL)connectVPNSync;
#endif

@end
