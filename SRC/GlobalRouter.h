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
#import "CommonStuff.h"

@class FullMessageEntity;
@class Encryptor;

@interface GlobalRouter :  UINavigationController <userInfoNotificationReceiver>{
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
    
    // Q
    dispatch_queue_t mainAppQueue;
    BOOL shouldCancel;
    
    //TEMP
    NSMutableArray* assets;
    
    NSMutableDictionary* /* PinHash-Encryptor* */ encs;
    
    NSCondition* condition;
    BOOL questionAnswered;
}

+(GlobalRouter*)sharedManager;
@property (nonatomic, strong) NSString* pin;
@property (nonatomic, strong) NSString* oldPin;
@property (nonatomic, assign) BOOL keepInBg;

@property (nonatomic, assign) boxTypes currentBox;
@property (nonatomic, assign) NSString* currentBoxPath;
@property (nonatomic, strong) NSString* currentAccount;
@property (nonatomic, strong) NSString* currentFilter;
@property (nonatomic, assign) int currentSettingNo;

@property (nonatomic, assign) int newMessages;
@property (nonatomic, assign) int totalMessages;

@property (nonatomic, strong)NSMutableDictionary* otherFolders; // dictionary [account name+dict] of dictionary [folder name+path]

@property (nonatomic, strong) NSMutableDictionary* accountsNames; // accName+emailAddress

-(UINavigationController*)getNavController;
//-(UINavigationController*)getNavController2;

-(void)pushView:(UIViewController *)viewController;

-(void)initialPush;
-(void)updateCurrentList;
-(dispatch_queue_t)getQ;
-(void)cancelQ;
-(void)restartQ;
-(BOOL)isCancelled;


-(int)getNewMessagesCount;

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

-(NSMutableArray*) getAssets;
-(void)setAssets:(NSMutableArray*)assetsToSet;

-(Encryptor*)getEncoderForPin:(NSString*)pin salt:(NSString*)forSalt;

-(void)newMessage;
-(void)needSettings;
-(void)needSearch;

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

//
-(void)needPassword:(ShortMessageEntity*)item;
-(void)needShowMessage:(ShortMessageEntity*)item;
-(void)needShowAttachment:(NSObject*)attachment;
-(void)needShowSecureImage:(UIImage*)image;
-(void)needShowAddressBook;
-(void)needShowAddressBookWithCaller:(id<CanGetAddressFromBook>) caller;
-(void)needShowAddContactFor:(NSString*)name address:(NSString*)address;
-(void)needAddAttachmentWithCaller:(id<AddAttachmentReceiver>) caller;
-(void)needShowSendCertificate:(FullMessageEntity *)message;

-(void)needShowComposeMessage:(FullMessageEntity*)message includeAttachments:(BOOL)includeAttachments forward:(BOOL)forward;

-(void)finishedWithCurrentView;

-(UIView*)getCurrentView;
//-(void)addButton:(NSString*)buttonName;

@end
