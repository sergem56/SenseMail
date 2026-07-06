//
//  ListPresenter.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIViewController.h>
#import "MessageListViewController.h"
//#import "MessageList.h"
#import "CommonStuff.h"
#import "ShortMessageEntity.h"

@interface ListPresenter : NSObject{
    MessageListViewController* messageListViewController;
    //boxTypes currentBox;
}

//@property (nonatomic) MessageListViewController* messageViewController;

@property (nonatomic, assign) BOOL noNeedForMore;

-(MessageListViewController*)showListOfType:(boxTypes)type;

-(void)setList:(NSArray*)list error:(NSString*)error;
-(void)updateList;
-(void)updateItemsFlags:(ShortMessageEntity*)item;

-(BOOL)deleteItem:(ShortMessageEntity*)item;
-(void)deleteItemFromList:(ShortMessageEntity*)item;
-(void)showMessageItem:(ShortMessageEntity*)item;

-(void)exitPressed;
-(void)markMessageFavourite:(ShortMessageEntity*)item;
-(void)checkMail;
-(void)newMessage;
-(void)showSettings;
-(void)search;
-(void)showHelp;
-(void)showPP;

-(void)needShowInbox;
-(void)needShowSent;
-(void)needShowFavs;
-(void)needShowSpam;
-(void)sos;

-(void)needShowOtherBox;

-(void)needMoreMessages;
//-(void)tellUpNoMoreButton;

-(void)clearList;

@end
