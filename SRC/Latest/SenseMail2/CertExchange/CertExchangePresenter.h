//
//  CertExchangePresenter.h
//  SenseMailShare
//
//  Created by Sergey on 06.04.16.
//  Copyright © 2016 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CertExchangeViewController;
@class AddressBookEntity;

@interface CertExchangePresenter : NSObject{
    CertExchangeViewController* viewController;
    dispatch_semaphore_t sem;
    NSString* savedCert;
    NSString* presentationPwd;
}

-(CertExchangeViewController*)getCertView:(AddressBookEntity*)addr;
-(void)needSaveCert:(NSString*)certString pwd:(NSString*)pwd;
-(void)wantCloseCert:(NSString*)cert;
-(void)setSavedCertString:(NSString*)certString;

-(NSArray*)encryptCertForPresentation:(NSData*)cert;

@end
