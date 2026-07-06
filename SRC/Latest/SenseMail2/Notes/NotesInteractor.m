//
//  NotesInteractor.m
//  SenseMail2
//
//  Created by Sergey on 08.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "NotesInteractor.h"
#import "UserInfoDataManager.h"
#import "NoteEntity.h"
#import "GlobalRouter.h"

@implementation NotesInteractor

-(NSMutableArray*)getNotes:(NSMutableString *)pin
{
    NSMutableArray* ret = nil;//[[NSMutableArray alloc] init];
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    ret = [dataMan getNotes:pin];
    if(!ret)return [[NSMutableArray alloc] init];
    NSMutableArray* toDel = [[NSMutableArray alloc] init];
    for (NoteEntity* i in ret) {
        if (([i.title  isEqual: @""] && [i.body  isEqual: @""]) || (i.title == nil && i.body == nil) || [i.body isEqualToString:MESSAGE_INVALID_PWD] || [i.title isEqualToString:MESSAGE_INVALID_PWD] ) {
            [toDel addObject:i];
        }
    }
    
    if (toDel.count > 0) {
        [ret removeObjectsInArray:toDel];
    }

    return ret;
}

-(BOOL)addNote:(NoteEntity *)note
{
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    return [dataMan addNote:note pin:[GlobalRouter sharedManager].pin];
}

-(BOOL)deleteNote:(NoteEntity *)note
{
    UserInfoDataManager* dataMan = [[UserInfoDataManager alloc] init];
    return [dataMan deleteNote:note pin:[GlobalRouter sharedManager].pin];
}

@end
