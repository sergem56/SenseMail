//
//  ComposeMessageRouter.h
//  SenseMail2
//
//  Created by Sergey on 15.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class FullMessageEntity;
@class ComposeMessagePresenter;
@class DataStorage;
@class DataManager;

@interface ComposeMessageRouter : NSObject{
    ComposeMessagePresenter* presenter;
    UINavigationController* nav;
}

@property (nonatomic) FullMessageEntity* currentMessage;

@property (nonatomic, strong) DataManager* manager;
@property (nonatomic, strong) DataStorage* dataStore;

-(void)showComposerInNavController:(UINavigationController*)navController message:(FullMessageEntity*)message includeAttachments:(BOOL)includeAttachments forward:(BOOL)forward;
-(void)showCertComposerInNavController:(UINavigationController*)navController message:(FullMessageEntity*)message;
-(void)needAddressBook;
-(void)needAttachment;

-(void)sendingResult:(NSString*)result;

@end
