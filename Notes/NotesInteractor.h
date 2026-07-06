//
//  NotesInteractor.h
//  SenseMail2
//
//  Created by Sergey on 08.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NoteEntity;

@interface NotesInteractor : NSObject

-(NSMutableArray*)getNotes:(NSString*)pin;

-(BOOL)addNote:(NoteEntity*)note;
-(BOOL)deleteNote:(NoteEntity*)note;

@end
