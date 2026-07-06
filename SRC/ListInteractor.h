//
//  ListInteractor.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommonStuff.h"
#import "ShortMessageEntity.h"

@class DataManager;

@interface ListInteractor : NSObject <AsyncLoader>

//@property (nonatomic, retain) DataManager* dataManager;

-(NSArray*)getMessagesForBox:(int)boxType;

-(void)requestMessagesForBox:(boxTypes)boxType;
-(void)requestNextMessagesForBox:(boxTypes)boxType;

-(void)needDeleteMessage:(ShortMessageEntity*)message;
-(void)needStarForMessage:(ShortMessageEntity*)message;

-(void)requestMessagesForBoxWithFilter:(boxTypes)boxType filter:(NSString*)filterFrom;
-(void)requestNextMessagesForBoxWithFilter:(boxTypes)boxType filter:(NSString*)filterFrom;

@end
