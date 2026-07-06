//
//  OneTimeCertInteractor.m
//  SenseMailShare
//
//  Created by Sergey on 26.10.2017.
//  Copyright © 2017 Sergey. All rights reserved.
//

#import "OneTimeCertInteractor.h"
#import "TapGeneratorViewController.h"
#import "GlobalRouter.h"
#import "Encryptor.h"
#import "CertPeerExchangerViewController.h"
#import "OneTimeCert.h"
#import "UserInfoDataManager.h"
#import "useOTCViewController.h"
#import "OTCsListViewController.h"

@implementation OneTimeCertInteractor

-(int)presentViewInNavController:(UINavigationController *)vc
{
    CertPeerExchangerViewController* ret = [[CertPeerExchangerViewController alloc] initWithNibName:@"startOTCExchange" bundle:nil];//@"CertPeerExchangerViewController" bundle:nil];
    
    BOOL onStack = NO;
    
    for (UIViewController* item in vc.viewControllers) {
        if ([ret isEqual:item]) {
            onStack = YES;
            break;
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        if (onStack) {
            [vc popToViewController:ret animated:YES];
        }else{
            
            @try {
                [vc pushViewController:ret animated:YES];
            }
            @catch (NSException *exception) {
                [vc popToViewController:ret animated:YES];
            }
        }
        if (self.otherEmail) {
            ret.otherEmailString = self.otherEmail;
        }
    });
    return 1;
}


-(int)presentTapViewInNavController:(UINavigationController *)vc
{
    // First ask how many keys are needed. Default is 100.
    // ...
    keysCount = 100;
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_semaphore_t semap = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [TapGeneratorViewController showTapDialog:semap bytesToCollect:32*strongSelf->keysCount];
    });
    dispatch_semaphore_wait(semap, DISPATCH_TIME_FOREVER);
    
    NSMutableData* userInput = [TapGeneratorViewController getResult];
    if (userInput == nil) {
        return 0;
    }
    
    [self processData:userInput];
    
    return 1;
}

-(BOOL)processData:(NSMutableData*)data
{
    // 1. Get raw data for 100 keys of 32 bytes each. If needed, expand the user-supplied data with SecRandomCopyBytes
    // 2. Get the keys with PBKDF2
    // 3. Store keys in a db with an empty date stamp
    // 4. Present a QR-form of the keys or send data via peer-to-peer messaging
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs showWheelinView:[[GlobalRouter sharedManager] getCurrentView] message:NSLocalizedString(@"Processing certificates...", @"") stopButtonVisible:NO];
    });
    NSMutableArray* certs = [Encryptor make100CertsFromRawData:data];
    // Make OneTimeCert Entity from the data
    certsEntities = [[NSMutableArray alloc] initWithCapacity:100];
    for(int i=0;i<100;i++) {
        OneTimeCert* cert = [[OneTimeCert alloc] init];
        cert.certData = certs[i];
        cert.certID = [Encryptor getUUIDofLength:6];//[[NSUUID UUID] UUIDString];
        if (!cert.certID) {
            cert.certID = [Encryptor getUUIDofLength:6];
        }
        cert.yourEmail = self.yourEmail;
        cert.otherEmail = self.otherEmail;
        cert.dateUsed = @"";
        cert.expirationDate = @"";
        [certsEntities addObject:cert];
    }
    
    // Encrypt certs before sending? Well, I guess there's no use, since the transmission
    // channel is already encrypted. But the paranoid voice tells me to encrypt nagging something
    // about Wi-Fi security... maybe, later on.
    
    NSLog(@"Got %lu certificates", (unsigned long)certs.count);
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs hideProgress];
    });
    self.resending = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs showWheelinView:[[GlobalRouter sharedManager] getCurrentView] message:NSLocalizedString(@"Started advertising...", @"") stopButtonVisible:YES withBlock:^{
            [self stopAdvertising];
            [CommonProcs hideProgress];
        }];
    });
    // Add the email address to know for whom those certs are
    if(self.otherEmail)[certsEntities addObject:self.otherEmail]; //@"from@email.com"];
    dataToSend = [NSKeyedArchiver archivedDataWithRootObject: certsEntities];
    [self startAdvertisingFromEmail:self.yourEmail];
    
    return YES;
}

-(BOOL)convertAndSaveDataToCerts:(NSData*)data
{
    NSArray* certs = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if(!certs)return NO;
    NSLog(@"Restored %lu certificates from %@", (unsigned long)certs.count-1, [certs lastObject]);
    // We are the receiver, so we need to swap to and from addresses
    for (int i=0;i<certs.count-1;i++) {
        OneTimeCert* cert = (OneTimeCert*)certs[i];
        if(cert){
            NSString* temp = cert.otherEmail;
            cert.otherEmail = cert.yourEmail;
            cert.yourEmail = temp;
            
            temp = cert.otherEmailHash;
            cert.otherEmailHash = cert.yourEmailHash;
            cert.yourEmailHash = temp;
        }
    }
    
    // Save here
    UserInfoDataManager* manager = [[UserInfoDataManager alloc] init];
    [manager saveCerts:certs pin:[GlobalRouter sharedManager].pin];
    
    return YES;
}

-(BOOL)deleteExpired
{
    UserInfoDataManager* manager = [[UserInfoDataManager alloc] init];
    return [manager deleteExpired];
}

-(BOOL)deleteCertWithID:(NSString*)certId from:(NSString*)fromAddress
{
    UserInfoDataManager* manager = [[UserInfoDataManager alloc] init];
    return [manager deleteCertWithID:certId from:fromAddress];
}

-(BOOL)deleteAll
{
    UserInfoDataManager* manager = [[UserInfoDataManager alloc] init];
    return [manager deleteAll];
}

-(BOOL)deleteAllForAddress:(NSString*)toAddress from:(NSString*)fromAddress
{
    UserInfoDataManager* manager = [[UserInfoDataManager alloc] init];
    return [manager deleteAllForAddress:toAddress from:fromAddress];
}

-(void)deleteTheList:(NSArray *)list
{
    UserInfoDataManager* manager = [[UserInfoDataManager alloc] init];
    return [manager deleteTheList:list];
}

/*
 // Included an option while adding a persistent store coordinator to vacuum db on every launch
-(BOOL)vacuum // sqlite3_exec(db,"VACUUM",....) // clear deleted records
{
    return NO;
}
*/
-(OneTimeCert*)getNextCertForAddress:(NSString*)toAddress fromAddress:(NSString*)fromAddress
{
    UserInfoDataManager* manager = [[UserInfoDataManager alloc] init];
    return [manager getNextCertFor:toAddress from:fromAddress];
}
-(OneTimeCert*)getCertWithID:(NSString*)uid from:(NSString*)fromAddress
{
    if (!uid || !fromAddress) {
        return nil;
    }
    UserInfoDataManager* manager = [[UserInfoDataManager alloc] init];
    OneTimeCert* cert = [manager getCertWithID:uid from:fromAddress];
    NSLog(@"Cert used date=%@, expiration on=%@",cert.dateUsed, cert.expirationDate);
    if(!cert.certData) cert = nil;
    return cert;
}

-(BOOL)setExpirationTimeForCert:(NSString*)certID expiration:(NSDate*)date dateUsed:(NSDate*) dateUsed from:(NSString*)fromAddress
{
    UserInfoDataManager* manager = [[UserInfoDataManager alloc] init];
    return [manager setExpirationTimeForCert:certID expiration:date dateUsed:dateUsed from:fromAddress];
}

#pragma mark "Peers for cert exchange"

static NSString * const SenseMailServiceType = @"comcr2labssm";

-(void)startAdvertisingFromEmail:(NSString* _Nonnull)fromEmail
{
    dataSent = NO;
    self.peerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    self.session = [[MCSession alloc]  initWithPeer:self.peerID];
    //self.session = [[MCSession alloc] initWithPeer:self.peerID securityIdentity:nil encryptionPreference:MCEncryptionNone];//  initWithPeer:self.peerID];
    self.session.delegate = self;
    self.assistant = [[MCAdvertiserAssistant alloc] initWithServiceType:SenseMailServiceType discoveryInfo:@{@"from":fromEmail} session:self.session];
    [self.assistant start];

    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs showWheelinView:[[GlobalRouter sharedManager] getCurrentView] message:NSLocalizedString(@"Transmission started...", @"") stopButtonVisible:YES withBlock:^{
            [self stopAdvertising];
            [CommonProcs hideProgress];
        }];
    });
}

-(void)stopAdvertising
{
    [self.assistant stop];
    self.assistant = nil;
}

-(void)sendData:(NSData*)data
{
    NSError* error;
    [self.session sendData:data toPeers:self.session.connectedPeers withMode:MCSessionSendDataReliable error:&error];
    if (error) {
        NSLog(@"Error sending data: %@",error.localizedDescription);
        dataSent = NO;
    }else{
        // Save certs after ACK in didReceiveData
    }
}

-(void)startReceiving
{
    //[self.peerID setValue:@"receiver@mail.com" forKey:@"email"];
    dataSent = NO;
    self.peerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice] name]];
    self.session = [[MCSession alloc]  initWithPeer:self.peerID];
    //self.session = [[MCSession alloc] initWithPeer:self.peerID securityIdentity:nil encryptionPreference:MCEncryptionNone];//  initWithPeer:self.peerID];
    self.session.delegate = self;
    self.browser = [[MCBrowserViewController alloc] initWithServiceType:SenseMailServiceType session:self.session];
    self.browser.delegate = self;
    self.browser.maximumNumberOfPeers = 2;
    [[[GlobalRouter sharedManager] getNavController] presentViewController:self.browser animated:YES completion:nil];
}

#pragma mark "MCSessionDelegate methods"
// This is for both, sender and reciever

- (void)session:(nonnull MCSession *)session didFinishReceivingResourceWithName:(nonnull NSString *)resourceName fromPeer:(nonnull MCPeerID *)peerID atURL:(nullable NSURL *)localURL withError:(nullable NSError *)error
{
}

- (void)session:(nonnull MCSession *)session didReceiveData:(nonnull NSData *)data fromPeer:(nonnull MCPeerID *)peerID
{
    NSLog(@"Received data from %@, size %lu", peerID.displayName, (unsigned long)data.length);
    if(self.browser != nil){
        // RECEIVER
        __weak __typeof__(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof__(self) strongSelf = weakSelf;
            [self.browser dismissViewControllerAnimated:YES completion:nil];
            self.browser = nil;
            [self convertAndSaveDataToCerts:data];
            strongSelf->dataSent = YES;
            [self sendData:[@"ACK" dataUsingEncoding:NSUTF8StringEncoding]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.session disconnect];
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [CommonProcs showMessage:NSLocalizedString(@"Data received", @"") title:@""];
            });
        });
    }else{
        // SENDER
        NSString* newStr = [NSString stringWithUTF8String:[data bytes]];
        if ([newStr isEqualToString:@"ACK"]) {
            NSLog(@"Save certs here!");
            __weak __typeof__(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong __typeof__(self) strongSelf = weakSelf;
                [CommonProcs showMessage:NSLocalizedString(@"ACK received-data sent successfully", @"") title:@""];
                if(!self.resending){
                    // Save here
                    UserInfoDataManager* manager = [[UserInfoDataManager alloc] init];
                    [manager saveCerts:strongSelf->certsEntities pin:[GlobalRouter sharedManager].pin];
                }
            });
            dispatch_async(dispatch_get_main_queue(), ^{
                [CommonProcs hideProgress];
            });
        }
    }
}

- (void)session:(nonnull MCSession *)session didReceiveStream:(nonnull NSInputStream *)stream withName:(nonnull NSString *)streamName fromPeer:(nonnull MCPeerID *)peerID
{
}

- (void)session:(nonnull MCSession *)session didStartReceivingResourceWithName:(nonnull NSString *)resourceName fromPeer:(nonnull MCPeerID *)peerID withProgress:(nonnull NSProgress *)progress
{
}

- (void)session:(nonnull MCSession *)session peer:(nonnull MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSLog(@"Changed state: %@, peer:%@ (self peerID %@), state:%ld", session.description, peerID.displayName, self.peerID.displayName, (long)state);
    if (state == MCSessionStateConnected) {
        if(self.assistant != nil){
            [self stopAdvertising];
            [self sendData:dataToSend];
            dataSent = YES;
            [CommonProcs hideProgress];
        }
    }else if(state == MCSessionStateNotConnected){
        NSLog(@"Not connected: %@", peerID.displayName);
    }
}

#pragma mark "MCBrowserViewController"

- (void)browserViewControllerDidFinish:(nonnull MCBrowserViewController *)browserViewController
{
    [self.browser dismissViewControllerAnimated:YES completion:nil];
    self.browser = nil;
}

- (void)browserViewControllerWasCancelled:(nonnull MCBrowserViewController *)browserViewController
{
    [self.session disconnect];
    [self.browser dismissViewControllerAnimated:YES completion:nil];
    self.browser = nil;
}

// No need for this, use standard alert? No, need to ask for the expiration date
-(void)showUseOTCDialog:(OneTimeCert*)cert completion:(void (^)(void))completionBlock
{
    useOTCViewController* ret = [[useOTCViewController alloc] initWithNibName:@"useOTCViewController" bundle:nil];
    ret.completionBlock = completionBlock;
    ret.cert = cert;
    [[[GlobalRouter sharedManager] getDetailNavController] pushViewController:ret animated:YES];
}

-(void)showManageOTCs
{
    OTCsListViewController* ret = [[OTCsListViewController alloc] initWithNibName:@"OTCsListViewController" bundle:nil];
    //[ret loadOTCs];
    ret.items = [self readAllOTCs];
    ret.topItems = [self makeTopOTCList:ret.items];
    
    [[[GlobalRouter sharedManager] getDetailNavController] pushViewController:ret animated:YES];
}

-(NSDictionary*)readAllOTCs
{
    UserInfoDataManager* manager = [[UserInfoDataManager alloc] init];
    NSArray* unsorted = [manager getAllAvailableCertsForPIN:[GlobalRouter sharedManager].pin];
    NSMutableDictionary* ret = [[NSMutableDictionary alloc] init];
    for (OneTimeCert* cert in unsorted) {
        NSMutableArray* arr = [ret valueForKey:[NSString stringWithFormat:@"%@ ↔︎ %@",cert.yourEmail, cert.otherEmail]];
        if (!arr) {
            arr = [ret valueForKey:[NSString stringWithFormat:@"%@ ↔︎ %@",cert.otherEmail, cert.yourEmail]];
            if(!arr){
                arr = [[NSMutableArray alloc] init];
                [ret setObject:arr forKey:[NSString stringWithFormat:@"%@ ↔︎ %@",cert.yourEmail, cert.otherEmail]];
            }
        }
        [arr addObject:cert];
    }
    // Sort by used
    for (int i=0;i<ret.allKeys.count;i++) {
        NSArray* certs = [ret objectForKey:ret.allKeys[i]];
        NSArray* sortedArray = [certs sortedArrayUsingDescriptors:
                                @[
                                  [NSSortDescriptor sortDescriptorWithKey:@"dateUsed" ascending:NO],
                                  [NSSortDescriptor sortDescriptorWithKey:@"yourEmail" ascending:YES]
                                  ]];
        [ret setObject:sortedArray forKey:ret.allKeys[i]];
    }
    
    return ret;
}

-(NSArray*)makeTopOTCList:(NSDictionary*)items
{
    NSMutableArray* ret = [NSMutableArray arrayWithArray:items.allKeys];
    for (int i=0;i<ret.count;i++) {
        NSString* str = ret[i];
        NSArray* itms = items[str];
        int used = 0;
        for (OneTimeCert* cert in itms){
            if (!(cert.dateUsed == nil || [cert.dateUsed isEqualToString:@""])) {
                used++;
            }
        }
        ret[i] = [NSString stringWithFormat:NSLocalizedString(@"Used %i of %lu",nil), used, (unsigned long)itms.count];
    }
    return ret;
}

-(void)reSendTheList:(NSArray *)list
{
    if (list.count == 0) {
        return;
    }
    NSLog(@"Got %lu certificates", (unsigned long)list.count);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs showWheelinView:[[GlobalRouter sharedManager] getCurrentView] message:NSLocalizedString(@"Started advertising...",nil) stopButtonVisible:YES withBlock:^{
            [self stopAdvertising];
            [CommonProcs hideProgress];
        }];
    });
    self.resending = YES;
    
    // Add the email address to know for whom those certs are
    NSMutableArray* certs = [NSMutableArray arrayWithArray:list];
    OneTimeCert* crt = list[0];
    if(crt && crt.otherEmail) [certs addObject:crt.otherEmail];
    dataToSend = [NSKeyedArchiver archivedDataWithRootObject: certs];
    [self startAdvertisingFromEmail:crt.yourEmail];
}

-(void)changeOTCsAddresses:(NSString*)from to:(NSString*)to oldFrom:(NSString*)oldFrom oldTo:(NSString*)oldTo
{
    if ([from isEqualToString:@""] && [to isEqualToString:@""]) {
        return;
    }
    
    if ([from isEqualToString:@""]) {
        from = oldFrom;
    }
    if ([to isEqualToString:@""]) {
        to = oldTo;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs showWheelinView:[[GlobalRouter sharedManager] getCurrentView] message:NSLocalizedString(@"Saving...",nil)  stopButtonVisible:NO];
    });
    UserInfoDataManager* manager = [[UserInfoDataManager alloc] init];
    [manager saveOTCsWithNewAddresses:oldFrom oldTo:oldTo newFrom:from newTo:to];
    dispatch_async(dispatch_get_main_queue(), ^{
        [CommonProcs hideProgress];
    });
}

@end
