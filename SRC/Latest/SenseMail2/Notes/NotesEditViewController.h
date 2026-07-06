//
//  NotesEditViewController.h
//  SenseMail2
//
//  Created by Sergey on 08.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NoteEntity;
@class NotesPresenter;

@interface NotesEditViewController : UIViewController
{
    BOOL showingHTML;
}

@property (nonatomic, weak) NotesPresenter* presenter;
@property (nonatomic, strong) NoteEntity* item;
@property (nonatomic, strong) NoteEntity* originalItem;
@property (nonatomic, assign) BOOL isNew;

@property (nonatomic, weak) IBOutlet UITextField* dateField;
@property (nonatomic, weak) IBOutlet UITextField* titleField;
@property (nonatomic, weak) IBOutlet UITextView* bodyField;
@property (nonatomic) IBOutlet UIScrollView* scroll;
@property (nonatomic) IBOutlet NSLayoutConstraint* textHeightConstraint;
@property (nonatomic) IBOutlet UIView* contentView;

@property (strong, nonatomic) UIToolbar *inputAccessoryToolbar;

-(void)setCurrentItem:(NoteEntity *)item;
-(BOOL)checkIfChanged;
-(void)needSaveItem;

@end
