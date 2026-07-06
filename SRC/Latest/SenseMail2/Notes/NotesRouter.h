//
//  NotesRouter.h
//  SenseMail2
//
//  Created by Sergey on 08.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class NotesPresenter;
@class NoteEntity;

@interface NotesRouter : NSObject{
    NotesPresenter* presenter;
    UINavigationController* nav;
}

-(void)showNotesInNavController:(UINavigationController*)navigationController;
-(void)finished;

-(void)showAddItem:(NoteEntity*)item;

-(void)appWillGoToBG;

@end
