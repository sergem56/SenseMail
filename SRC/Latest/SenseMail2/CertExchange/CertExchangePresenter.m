//
//  CertExchangePresenter.m
//  SenseMailShare
//
//  Created by Sergey on 06.04.16.
//  Copyright © 2016 Sergey. All rights reserved.
//

#import "CertExchangePresenter.h"
#import "CertExchangeViewController.h"
#import "CommonProcs.h"
#import "UserInfoDataManager.h"
#import "GlobalRouter.h"
#import "AddressBookEntity.h"
#import "DataManager.h"
#import "Encryptor.h"

@implementation CertExchangePresenter

-(CertExchangeViewController*)getCertView:(AddressBookEntity*)addr
{
    if(viewController == nil)
    {
        viewController = [[CertExchangeViewController alloc] initWithNibName:@"CertExchangeViewController" bundle:nil];
    }
    
    // Get the cert, if any
    viewController.address = addr.address;
    viewController.presenter = self;
    viewController.addressBE = addr;
    
    if (addr.key) {
        // get the key
        [self askForPin];
    }else{
        [viewController setCert:nil keepOld:NO];//.certificate = nil;
        savedCert = nil;
    }
    
    return viewController;
}

-(void)askForPin
{
    NSString* mText = NSLocalizedString(@"Enter PIN for a message FROM this address",nil);
    //__weak __typeof__(self) weakSelf = self;
    
    // Dispatch it to the main thread although it's already on the main. Otherwise it won't show the view as it is already showing the pin request
    dispatch_async(dispatch_get_main_queue(), ^{
        //__strong __typeof__(self) strongSelf = weakSelf;
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:NSLocalizedString(@"Enter PIN",nil)
                                     message:mText
                                     preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"PIN-code";
            textField.textColor = [UIColor blueColor];
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
            textField.borderStyle = UITextBorderStyleRoundedRect;
            textField.secureTextEntry = YES;
        }];
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction * action)
                                 {
                                     [[GlobalRouter sharedManager] finishedWithDetailView:YES];
                                 }];
        [alert addAction:cancel];
        
        UIAlertAction* done = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"OK",nil)
                                 style:UIAlertActionStyleDefault
                                 handler:^(UIAlertAction * action)
        {
            NSArray * textfields = alert.textFields;
            UITextField * passw = textfields[0];
            NSMutableString* pin = [NSMutableString stringWithString: [passw text]];
            [CommonProcs showProgressWithTitle:1 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Processing...",nil) stopButton:NO];
            
            __weak __typeof__(self) weakSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                __strong __typeof__(self) strongSelf = weakSelf;
                DataManager* dataMan = [[DataManager alloc]init];
                NSString* cert = [dataMan getPinForAddress:strongSelf->viewController.address pin:pin pinTo:NO];
                if([cert isEqual:INVALID_CERT]){
                    // Wrong pwd?
                    [CommonProcs setMessageInProgress:@"Wrong password"];
                    sleep(1);
                    [CommonProcs hideProgress];
                    [[GlobalRouter sharedManager] finishedWithDetailView:YES];
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [strongSelf->viewController setCert:cert keepOld:NO];
                        strongSelf->savedCert = [strongSelf->viewController getCertString];
                        [CommonProcs hideProgress];
                    });
                }
            });
        }];
        [alert addAction:done];
        
        UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
        alert.popoverPresentationController.sourceView = pView;
        alert.popoverPresentationController.sourceRect = pView.frame;
        [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
    });
    /*
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter PIN",nil) message:mText delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Done",nil),nil];
    alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [alert setTag:100];
    [alert show];*/
}
/*
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100)
    {
        if (buttonIndex == 0){
            // Exit
            [[GlobalRouter sharedManager] finishedWithDetailView:YES];
        }else{
            [CommonProcs showProgressWithTitle:1 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Processing...",nil) stopButton:NO];
            NSMutableString* pin = [NSMutableString stringWithString: [[alertView textFieldAtIndex:0] text]];
            __weak __typeof__(self) weakSelf = self;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
                __strong __typeof__(self) strongSelf = weakSelf;
                DataManager* dataMan = [[DataManager alloc]init];
                NSString* cert = [dataMan getPinForAddress:strongSelf->viewController.address pin:pin pinTo:NO];
                if([cert isEqual:INVALID_CERT]){
                    // Wrong pwd?
                    [CommonProcs setMessageInProgress:@"Wrong password"];
                    sleep(1);
                    [CommonProcs hideProgress];
                    [[GlobalRouter sharedManager] finishedWithDetailView:YES];
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [strongSelf->viewController setCert:cert keepOld:NO];
                        strongSelf->savedCert = [strongSelf->viewController getCertString];
                        [CommonProcs hideProgress];
                    });
                }
            });
        }
    }
}*/

-(void)needSaveCert:(NSString *)certString pwd:(NSString*)pwd
{
    savedCert = certString;
    
    // 1. Convert cert from xxx-xxx-xxx-... to uint8_t*
    NSMutableData* ret = [[NSMutableData alloc] initWithCapacity:32];
    NSArray* bytes = [certString componentsSeparatedByString:@" "];
    for (NSString* byte in bytes) {
        int8_t i = (uint8_t)[byte intValue];
        [ret appendBytes:&i length:1];
    }
    
    //TODO: Decrypt cert with the shown password...
    //
    Encryptor* enc = [[Encryptor alloc] initWithSimpleKey:pwd];
    NSData* retM = [enc decryptAESData:ret];
    if (retM == nil) {
        [CommonProcs showMessage:NSLocalizedString(@"Error. Incorrect password?",nil) title:@""];
        /*
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error. Incorrect password?",nil) message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Close",nil) otherButtonTitles:nil,nil];
        [alert setTag:102];
        [alert show];*/
        return;
    }
    ret = [NSMutableData dataWithData:retM];
    
    NSString* retBase = [ret base64EncodedStringWithOptions:NSDataBase64Encoding76CharacterLineLength];
    
    NSLog(@"Cert %@", retBase);
    
    // 2. Save it!
    if(![NSThread isMainThread]){
        [CommonProcs saveCert:retBase forAddress:viewController.address];
        //if ([CommonProcs getSaveResult]) {
        //    viewController.addressBE.key = YES;
        //}
    }else{
        __weak __typeof__(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            __strong __typeof__(self) strongSelf = weakSelf;
            [CommonProcs saveCert:retBase forAddress:strongSelf->viewController.address];
            //if ([CommonProcs getSaveResult]) {
            //    viewController.addressBE.key = YES;
            //}
        });
    }
    
    // 3. Update
    [viewController setCert:retBase keepOld:NO];
    savedCert = [viewController getCertString];
    
    // Here is a bug... press cancel in a pin dialog and it will show that you've got a cert
    // untill you re-open the address book. Need some kind of a callback to indicate that the
    // save proc was successful
    viewController.addressBE.key = YES;
}

-(void)setSavedCertString:(NSString *)certString
{
    savedCert = certString;
}

-(void)wantCloseCert:(NSString*)cert
{
    if ([savedCert isEqualToString:cert] || (savedCert == nil && cert == nil)){
        [viewController setCert:nil keepOld:NO];
        [[GlobalRouter sharedManager] finishedWithDetailView:YES];
    }else{
        NSString* mText = NSLocalizedString(@"The certificate has been changed. Save before closing?",nil);
        __weak typeof(self) weakSelf = self;
        [CommonProcs askYesNoAndDoWithTitle:NSLocalizedString(@"Save changes?",nil) text:mText blockYes:^{
            __strong typeof(self) strongSelf = weakSelf;
            [self needSaveCert:[strongSelf->viewController getCertString] pwd:strongSelf->viewController.password.text];
            [strongSelf->viewController setCert:nil keepOld:NO];
            [[GlobalRouter sharedManager] finishedWithDetailView:YES];
        } blockNo:^{
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf->viewController setCert:nil keepOld:NO];
            [[GlobalRouter sharedManager] finishedWithDetailView:YES];
        }];
        
        /*
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Save changes?",nil) message:mText delegate:self cancelButtonTitle:NSLocalizedString(@"No",nil) otherButtonTitles:NSLocalizedString(@"Save",nil),nil];
        [alert setTag:101];
        [alert show];*/
    }
}

-(NSArray*)encryptCertForPresentation:(NSData *)cert
{
    NSString* pwd = [Encryptor generatePassword:3];
    Encryptor* enc = [[Encryptor alloc] initWithSimpleKey:pwd];
    NSData* ret = [enc encryptAESData:cert];
    return @[pwd, ret];
    
}

@end
