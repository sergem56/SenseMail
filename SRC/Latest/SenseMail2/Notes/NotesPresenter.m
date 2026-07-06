//
//  NotesPresenter.m
//  SenseMail2
//
//  Created by Sergey on 08.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "NotesPresenter.h"
#import "NotesViewController.h"
#import "NotesInteractor.h"
#import "NoteEntity.h"
#import "NotesEditViewController.h"
#import "GlobalRouter.h"

@implementation NotesPresenter

#ifdef DEMO
-(NotesViewController*)showNotes:(NSString *)pin
{
    return nil;
}
#else
-(NotesViewController*)showNotes:(NSMutableString *)pin
{
    NotesInteractor* notesIn = [[NotesInteractor alloc] init];
    NSMutableArray* notes = [notesIn getNotes :pin];
    
    if(viewController == nil)
    {
        viewController = [[NotesViewController alloc] initWithNibName:@"NotesViewController" bundle:nil];
    }
    
    viewController.presenter = self;
    viewController.notes = notes;
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [strongSelf->viewController reloadNotes];
    });
    
    return viewController;

}
#endif

-(void)needShowAddItem
{
    [[[GlobalRouter sharedManager] getNotesRouter] showAddItem:nil];
}

-(void)needEditItem:(NoteEntity*)item
{
    [[[GlobalRouter sharedManager] getNotesRouter] showAddItem:item];
}

-(void)needDeleteItem:(NoteEntity *)item
{
    [viewController.notes removeObject:item];
    NotesInteractor* notesIn = [[NotesInteractor alloc] init];
    [notesIn deleteNote:item];
}

-(NotesEditViewController*)showAddItem:(NoteEntity*)item
{
    if(addViewController == nil)
    {
        addViewController = [[NotesEditViewController alloc] initWithNibName:@"NotesEditViewController" bundle:nil];
        addViewController.item = item;
        addViewController.presenter = self;
    }else{
        addViewController.presenter = self;
        [addViewController setCurrentItem:item];
    }
    
    return addViewController;
}

-(BOOL)needAddItem:(NoteEntity*)item
{
    BOOL ret;
    self.needUpdateList = YES;
    NotesInteractor* notesIn = [[NotesInteractor alloc] init];
    if (addViewController.isNew) {
        [viewController.notes insertObject:item atIndex:0];
    }
    ret = [notesIn addNote:[item copy]];
    if(ret){
        [viewController showMessage:@"" title:NSLocalizedString(@"Note saved",nil)];
    }else{
        [viewController showMessage:@"" title:NSLocalizedString(@"Error saving note",nil)];
    }

    return ret;
}

-(void)updateList
{
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof__(self) strongSelf = weakSelf;
        [strongSelf->viewController reloadNotes];
    });
}

-(void)saveCurrentItem
{
    if(addViewController){
        if([addViewController checkIfChanged]){
            [addViewController needSaveItem];
        }
    }
}

-(void)clearVC
{
    addViewController = nil;
}

@end
