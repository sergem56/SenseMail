//
//  AddressBookInteractor.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "AddressBookInteractor.h"
#import "UserInfoDataManager.h"
#import "AddressBookEntity.h"
#import "GlobalRouter.h"
#import "FullMessageEntity.h"
#import "DataManager.h"

@implementation AddressBookInteractor


-(NSMutableArray*)getBook:(NSString *)pin groupsOnly:(BOOL)gOnly
{
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    dataMan.receiver = [GlobalRouter sharedManager];
    
    NSMutableArray* temp = [NSMutableArray arrayWithArray: [dataMan getAddressBook:pin groupsOnly:gOnly]];
    
    NSMutableArray* toDel = [[NSMutableArray alloc] init];
    for (AddressBookEntity* i in temp) {
        if (([i.name  isEqual: @""] && [i.address  isEqual: @""] && [i.note  isEqual: @""]) || [i.address isEqualToString:MESSAGE_INVALID_PWD] || [i.name isEqualToString:MESSAGE_INVALID_PWD] || i.address == nil) {
            [toDel addObject:i];
        }
    }
    
    if (toDel.count > 0) {
        [temp removeObjectsInArray:toDel];
    }
    return temp;
}

-(void)userInfoFinishedTask:(BOOL)res
{
    
}

-(BOOL)saveBook:(NSArray*)book pin:(NSString*)pin
{
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    
    return [dataMan saveAddressBook:[[NSArray alloc] initWithArray:book copyItems:YES] pin:pin];
}

-(NSMutableArray*)addItemToBook:(AddressBookEntity *)item
{
    NSMutableArray* book = [self getBook :[GlobalRouter sharedManager].pin groupsOnly:NO];
    
    NSMutableArray* temp = [NSMutableArray arrayWithArray:book];
    BOOL needNew = YES;
    for (AddressBookEntity* ent in temp) {
        if([ent.uid isEqualToString: item.uid]){
            needNew = NO;
            [temp replaceObjectAtIndex:[temp indexOfObject:ent] withObject:item];
            break;
        }
    }
    if(needNew)
        [temp addObject:item];

    book = temp;
    
    // Save book encrypts the book and it's displayed encrypted after that :)
    // Used copyItems in saveBook
    [self saveBook:book pin:[GlobalRouter sharedManager].pin];
    
    //book = [self getBook :[GlobalRouter sharedManager].pin];
    
    return book;
}

-(void)sendCertificateForAddress:(NSString*)address existing:(BOOL)existing
{
    messageTo = [[FullMessageEntity alloc] init];
    messageTo.fromAddress = address;
    messageTo.encType = enTypePasswordForCert;
    if (existing) {
        // Ask for pin
        NSString* mText = NSLocalizedString(@"Enter PIN set to send a message TO the address",nil);
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Enter PIN",nil) message:mText delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel",nil) otherButtonTitles:NSLocalizedString(@"Done",nil),nil];
        alert.alertViewStyle = UIAlertViewStyleSecureTextInput;
        [alert setTag:100];
        [alert show];
        
    }else{
        messageTo.messageBody = @"";
        [[GlobalRouter sharedManager] needShowSendCertificate:messageTo];
    }
}

-(BOOL)deleteCertFor:(NSString *)address
{
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    return [dataMan deleteKeyFor:address];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100)
    {
        if (buttonIndex == 0)
        {
        }else{
            NSString* pin = [[alertView textFieldAtIndex:0] text];
            DataManager* dataMan = [[DataManager alloc]init];
            NSString* cert = [dataMan getPinForMessage:messageTo pin:pin pinTo:YES];
            messageTo.messageBody = cert;
            [[GlobalRouter sharedManager] needShowSendCertificate:messageTo];
        }
    }
}


-(void)sendMessageForAddress:(NSString*)address
{
    [[GlobalRouter sharedManager] finishedWithCurrentView];
    
    FullMessageEntity* message = [[FullMessageEntity alloc] init];
    message.fromAddress = address;
    [[GlobalRouter sharedManager] needShowComposeMessage:message includeAttachments:NO forward:NO];
}

@end
