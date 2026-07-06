//
//  MessageListRouter.h
//  SenseMail2
//
//  Created by Sergey on 23.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CommonStuff.h"

@class ListPresenter;
@class ListInteractor;
@class DataManager;
@class DataStorage;
@class ShortMessageEntity;

@interface MessageListRouter : NSObject{
    //ListPresenter* presenter;
    UINavigationController* nav;
    
    //ListInteractor* interactor;
    //DataManager* manager;
    //DataStorage* dataStore;
    
    BOOL gettingNewCount;
}

@property (nonatomic, strong) ListPresenter* presenter;
@property (nonatomic, strong) ListInteractor* interactor;
@property (nonatomic, strong) DataManager* manager;
@property (nonatomic, strong) DataStorage* dataStore;
@property (nonatomic, assign) BOOL largeFont;
@property (nonatomic, assign) BOOL sortByDate;
@property (nonatomic, assign) listSortOrder sortOrder;

-(void)showListInNavController:(UINavigationController*)navController forBox:(boxTypes)boxType;

-(void)listReceivedCallback:(NSArray*) list error:(NSString*)error;

-(void)noNeedForMore :(BOOL)value;

-(void)needUpdateList;
-(void)updateItemsFlags:(ShortMessageEntity*)item;
-(void)removeItemFromList:(ShortMessageEntity*)item;

-(void)clearList;
-(void)clearFilter;

-(void)needHideRefreshControl;

-(void)needSearch;
-(void)needSearchWithString:(NSString*)searchStr;

-(ShortMessageEntity*)getNextShortMessageFor:(ShortMessageEntity*)item;
-(ShortMessageEntity*)getPrevShortMessageFor:(ShortMessageEntity*)item;

-(BOOL)isFetching;
-(void)cleanUp;

-(BOOL)isActive;

-(BOOL)isShowingMenu;
-(void)dismissMenu;
-(BOOL)isFullyLoaded;

-(void)showShortcutBar;

@end
