//
//  OneTimeCertInteractor.h
//  SenseMailShare
//
//  Created by Sergey on 26.10.2017.
//  Copyright © 2017 Sergey. All rights reserved.
//

// Try a new concept, strip VIPER, leave only viewController, interactor and possibly a presenter.
// Interactor is a router+interactor in a VIPER concept. Presenter seems to be redundant as well...
// The brand-new interactor processes user input, prepares data to display and knows where to
// re-route requests. View controller needs a view in which it shows itself. We call interactor
// with a view to simplify re-use. It is called from the GlobalRouter.
// We'll see how it works in this config...

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <MultipeerConnectivity/MultipeerConnectivity.h>

@class OneTimeCert;

@interface OneTimeCertInteractor : NSObject <MCSessionDelegate, MCBrowserViewControllerDelegate>
{
    int keysCount;
    NSMutableArray* certsEntities;
    NSData* dataToSend;
    NSString* otherPartyEmail;
    BOOL dataSent;
}

@property (nonatomic, strong) MCPeerID* _Nullable peerID;

NS_ASSUME_NONNULL_BEGIN
@property (nonatomic, strong) MCSession* session;
@property (nonatomic, strong) MCAdvertiserAssistant* _Nullable assistant;
@property (nonatomic, strong) MCBrowserViewController* _Nullable browser;

@property (nonatomic, strong) NSString* yourEmail;
@property (nonatomic, strong) NSString* _Nullable otherEmail;

@property (nonatomic, assign) BOOL resending;

-(int)presentViewInNavController:(UINavigationController*)vc;
-(int)presentTapViewInNavController:(UINavigationController *)vc;

-(BOOL)convertAndSaveDataToCerts:(NSData*)data;
-(BOOL)deleteExpired;
-(BOOL)deleteCertWithID:(NSString* _Nonnull )certId from:( NSString* _Nonnull )fromAddress;
-(BOOL)deleteAll;
-(BOOL)deleteAllForAddress:(NSString*)toAddress from:(NSString*)fromAddress;
-(void)deleteTheList:(NSArray*)list;
-(void)reSendTheList:(NSArray*)list;
-(void)changeOTCsAddresses:(NSString*)from to:(NSString*)to oldFrom:(NSString*)oldFrom oldTo:(NSString*)oldTo;

//-(BOOL)vacuum; // sqlite3_exec(db,"VACUUM",....) // clear deleted records
-(OneTimeCert*)getNextCertForAddress:(NSString*)toAddress fromAddress:(NSString*)fromAddress;
-(OneTimeCert*)getCertWithID:(NSString*)uid from:(NSString*)fromAddress; // from address is to avoid ID-collisions since ID is 6-symbol
-(BOOL)setExpirationTimeForCert:(NSString*)certID expiration:(NSDate*)date dateUsed:(NSDate*) dateUsed from:(NSString*)fromAddress;
NS_ASSUME_NONNULL_END

-(void)startAdvertisingFromEmail:(NSString* _Nonnull)fromEmail;
-(void)stopAdvertising;
-(void)sendData:(NSData*_Nullable)data;
-(void)startReceiving;

-(void)showUseOTCDialog:(OneTimeCert*_Nullable)cert completion:(void (^_Nullable)(void))completionBlock;
-(void)showManageOTCs;

@end
