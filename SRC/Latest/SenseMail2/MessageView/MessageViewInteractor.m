//
//  MessageViewInteractor.m
//  SenseMail2
//
//  Created by Sergey on 30.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "MessageViewInteractor.h"
#import <UIKit/UIKit.h>
#import "DataManager.h"
#import "CommonProcs.h"
#import "GlobalRouter.h"
#import "AddressBookEntity.h"
#import "UserInfoDataManager.h"
#import "MessageViewPresenter.h"
#import "ComposeMessagePresenter.h"
#import "ComposeMessageInteractor.h"
#if !LITE
#import "OneTimeCertInteractor.h"
#import "OneTimeCert.h"
#endif


@implementation MessageViewInteractor

-(void)markMessageAsRead:(ShortMessageEntity*)item
{
    item.flags &= ~mfNew;
    [GlobalRouter sharedManager].newMessages--;
    [GlobalRouter sharedManager].newMessagesTotal--;
    [[[GlobalRouter sharedManager] getListRouter].manager markAsRead:item];
}

-(FullMessageEntity*)getFullMessageFor:(ShortMessageEntity*)item PIN:(NSMutableString *)pin
{
    //DataManager* dataMan = [[DataManager alloc] init];
    //return [dataMan getFullMessageFor:item PIN:pin];
    
    [[GlobalRouter sharedManager]restartQ];
    [CommonProcs showProgress:1 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
    dispatch_async([[GlobalRouter sharedManager] getQ], ^{
        
        DataManager* dataMan = [[DataManager alloc] init];
        NSString* error = @"";
        FullMessageEntity* ret = [dataMan getFullMessageFor:item PIN:pin forBox:[GlobalRouter sharedManager].currentBox];
        if(!ret)
        {
            error = NSLocalizedString(@"Error loading message", nil);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(![[GlobalRouter sharedManager] isCancelled]){
                [[[GlobalRouter sharedManager] getMessageRouter] messageReceivedCallback:ret error:error];
                //[CommonProcs showProgress:10 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
                [CommonProcs hideProgress];
            }else{
                [[GlobalRouter sharedManager]restartQ];
                [[GlobalRouter sharedManager]finishedWithCurrentView];
            }
        });
        
    });
    
    return nil;

}

-(void)requestFullMessageFor:(ShortMessageEntity*)item PIN:(NSMutableString*)pin
{
    //DataManager* dataMan = [[DataManager alloc] init];
    
    [[GlobalRouter sharedManager] restartQ];
    [[[GlobalRouter sharedManager] getListRouter].manager getFullMessageFor:item PIN:pin forBox:[GlobalRouter sharedManager].currentBox];
}

-(BOOL)saveAllAttachments:(FullMessageEntity *)item caller:(MessageViewPresenter*)caller
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    for (NSObject* im in item.attachments) {
        UIImageWriteToSavedPhotosAlbum([CommonProcs getFullImage:im], caller, @selector(itemSaved:didFinishSavingWithError:contextInfo:),nil);
    }
    });
    return YES;
}

// AsyncLoader protocol
-(void)setProgress:(int)progress max:(int)max
{
    //[CommonProcs showProgress:progress max:max inView:[[GlobalRouter sharedManager] getCurrentView]];
    [CommonProcs setProgress:progress max:max title:NSLocalizedString(@"Loading...", nil)];
}

-(void)dataReady:(NSArray*)data error:(NSString*)error
{
    //[CommonProcs showProgress:10 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    [CommonProcs hideProgress];
    
    if(![[GlobalRouter sharedManager] isCancelled]){
        FullMessageEntity* tmpm;
        if(data == nil){
            tmpm = nil;
        }else if([data count] == 0){
            tmpm = nil;
        }else{
            tmpm = [data objectAtIndex:0];
        }
        [[[GlobalRouter sharedManager] getMessageRouter] messageReceivedCallback:tmpm error:error];
    }else{
        //[[GlobalRouter sharedManager] finishedWithDetailView:YES];
        [[[GlobalRouter sharedManager] getMessageRouter] messageReceivedCallback:nil error:error];
    }
    
}

-(void)addContactFor:(NSString *)name address:(NSString *)address
{
    UserInfoDataManager* userMan = [[UserInfoDataManager alloc] init];
    AddressBookEntity* item = [userMan findInAddressBook:name address:address pin:[GlobalRouter sharedManager].pin];
    if (item == nil) {
        item = [[AddressBookEntity alloc] init];
        item.name = name;
        item.address = address;
    }
    [[[GlobalRouter sharedManager] getBookRouter] showAddItem:item];
}

-(void)checkReadReceipt:(ShortMessageEntity *)message
{
    if (message.readReceiptTo && [[[GlobalRouter sharedManager] getMessageRouter] getPresenter].needToSendRR) {
#if DEBUG
        NSLog(@"Read receipt to %@", message.readReceiptTo);
#endif
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:NSLocalizedString(@"Warning",nil)
                                     message:NSLocalizedString(@"The sender has requested a read receipt. Would you like to send it?",nil)
                                     preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* canSend = [UIAlertAction
                                  actionWithTitle:NSLocalizedString(@"Send it", nil)
                                  style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction * action)
                                  {
                                      //NSLog(@"Allowed to send");
                                      FullMessageEntity* receipt = [[FullMessageEntity alloc] init];
                                      receipt.fromAddress = message.toAddress;
                                      receipt.toAddress = message.readReceiptTo;
                                      receipt.subject = @"Read receipt";
                                      receipt.flags = mfNone;
                                      receipt.messageBody = [NSString stringWithFormat:@"Your message has been read.\nMessage details:\nMessage to: %@\nSent on: %@\nSubject: %@",message.toAddress, message.date, [NSString stringWithFormat:@"%@[hidden...]", [message.subject substringToIndex:4]]];
                                      [CommonProcs spawnProcWithProgress:@selector(needSendMessage:pin:) object:[[ComposeMessagePresenter alloc] init] withParam1:receipt withParam2:NSLocalizedString(@"no",nil)];
                                  }];
        [alert addAction:canSend];
        
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"No",nil)
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction * action)
                                 {
                                     
                                 }];
        [alert addAction:cancel];
        
        UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
        alert.popoverPresentationController.sourceView = pView;
        alert.popoverPresentationController.sourceRect = pView.frame;
        [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
    }
}

-(void)reEncryptMessage:(FullMessageEntity *)message
{
    message.encType = enTypePassword;
#if !LITE
    // Check OTC
    ComposeMessageInteractor* inter = [[ComposeMessageInteractor alloc] init];
    __block OneTimeCert* cert = [inter checkForOTC:message];
    if (cert) {
        // Cert found, ask to use it. If no, remove certID and encType from the message
        // After use, set expiration date and used mark
        //__weak __typeof__(self) weakSelf = self;
        OneTimeCertInteractor* otcint = [[OneTimeCertInteractor alloc] init];
        [otcint showUseOTCDialog:cert completion:^{
            [[GlobalRouter sharedManager] finishedWithDetailView:YES];
            //__strong __typeof__(self) strongSelf = weakSelf;
            if (cert.yourEmail == nil) {
                // ask for a PIN
                message.encType = enTypePassword;
                cert = nil;
                [self usePin:message];
            }else{
                message.encType = enTypeOTC;
                message.keyID = cert.certID;
                NSMutableString* pinCode = [cert getCertString];
                message.expireOTCon = cert.expirationDate;
                // Append
                DataManager* dataMan = [[DataManager alloc] init];
                [dataMan encryptExistingMessage:message pin:pinCode];
                // Set used cert in sendingResult
                if(cert){
                    cert.dateUsed = [OneTimeCert getStringForDate:[NSDate date]];
                    [otcint setExpirationTimeForCert:cert.certID expiration:[cert getExpirationDate] dateUsed:[NSDate date] from:message.fromAddress];
                }
            }
        }];
    }
    if(!cert){
        [self usePin:message];
    }
#else
    [self usePin:message];
#endif
}

-(void)usePin:(FullMessageEntity*)message
{
    // Ask for a pin and encrypt
    controller = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter PIN",nil)
                                                     message:NSLocalizedString(@"Set a new PIN-code for the message",nil)
                                              preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *button2 = [UIAlertAction actionWithTitle:NSLocalizedString(@"Save",nil) style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                                                        [self useMutablePIN:message];
                                                    }];
    
    //UIAlertActionStyleDestructive gives you a red colored button
    UIAlertAction *buttonCancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil) style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * _Nonnull action) {
                                                             
                                                         }];
    //__weak __typeof__(self) weakSelf = self;
    [controller addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        //__strong __typeof__(self) strongSelf = weakSelf;
        textField.placeholder = @"PIN-code for a message";
        textField.textColor = [UIColor blueColor];
        textField.keyboardType = UIKeyboardTypeDefault;
        textField.secureTextEntry = YES;
    }];
    
    [controller addAction:buttonCancel];
    [controller addAction:button2];
    
    [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:controller animated:YES completion:nil];
}

-(void)useMutablePIN:(FullMessageEntity*)message
{
    NSMutableString* pinCode = [NSMutableString stringWithString: [[controller textFields][0] text]];
    
    uint8_t buf[4];
    int cpRet = SecRandomCopyBytes(kSecRandomDefault, 4, buf);
    if (cpRet != errSecSuccess) {
        arc4random_buf(buf, sizeof(buf));
    }
    uint32_t* i = (uint32_t*)(&buf);
    message.mutationNumber = *i%(mutationBase-1)+1;
    
    if(![pinCode isEqualToString:@""]){
        // Append
        //DataManager* dataMan = [[DataManager alloc] init];
        //[dataMan encryptExistingMessage:message pin:pinCode];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[[GlobalRouter sharedManager] getListRouter].manager encryptExistingMessage:message pin:pinCode];
        });
    }else{
        [CommonProcs showMessage:NSLocalizedString(@"PIN code cannot be empty", nil) title:@""];
    }
}

-(NSString*)prepareMessageForPrinting:(FullMessageEntity*)message
{
    NSString* str;
    if([message.fromName isEqualToString:@""] || [message.fromName isEqualToString:message.fromAddress]){
        str = [NSString stringWithFormat:@"<h3>%@</h3>From: %@<br>To: %@<br>Date: %@<br><p>%@</p>", message.subject, message.fromAddress, message.toAddress, message.date, message.messageBody];
    }else{
        str = [NSString stringWithFormat:@"<h3>%@</h3>From: %@ (%@)<br>To: %@<br>Date: %@<br><p>%@</p>", message.subject, message.fromName, message.fromAddress, message.toAddress, message.date, message.messageBody];
    }
    
    return str;
}

-(void)printHTMLContent:(FullMessageEntity*)message fromRect:(CGRect)rect inView:(UIView*)inView
{
    NSString* htmlString = [self prepareMessageForPrinting:message];
    
    UIPrintInteractionController *pic = [UIPrintInteractionController sharedPrintController];
    pic.delegate = self;
 
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputGeneral;
    printInfo.jobName = message.subject;
    pic.printInfo = printInfo;
 
    UIMarkupTextPrintFormatter *htmlFormatter = [[UIMarkupTextPrintFormatter alloc]
        initWithMarkupText:htmlString];
    htmlFormatter.startPage = 0;
    htmlFormatter.contentInsets = UIEdgeInsetsMake(36.0, 72.0, 36.0, 36.0); // 1/2-1 inch margins
    pic.printFormatter = htmlFormatter;
    pic.showsPageRange = YES;
 
    void (^completionHandler)(UIPrintInteractionController *, BOOL, NSError *) =
         ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
             if (!completed && error) {
                 NSLog(@"Printing could not complete because of error: %@", error);
             }
         };
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [pic presentFromRect:rect inView:inView animated:YES completionHandler:completionHandler];
    } else {
        [pic presentAnimated:YES completionHandler:completionHandler];
    }
}

@end
