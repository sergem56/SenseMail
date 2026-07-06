//
//  NotesPresenter.h
//  SenseMail2
//
//  Created by Sergey on 08.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NotesViewController;
@class NoteEntity;
@class NotesEditViewController;

//static BOOL needUpdateList;

@interface NotesPresenter : NSObject{
    NotesViewController* viewController;
    NotesEditViewController* addViewController;
}

@property (nonatomic, assign) BOOL needUpdateList;

-(NotesViewController*)showNotes:(NSMutableString*)pin;

-(void)needShowAddItem;
-(NotesEditViewController*)showAddItem:(NoteEntity*)item;

-(BOOL)needAddItem:(NoteEntity*)item;
-(void)needEditItem:(NoteEntity*)item;
-(void)needDeleteItem:(NoteEntity*)item;

-(void)updateList;
-(void)saveCurrentItem;

-(void)clearVC;

@end
