//
//  NotesViewController.h
//  SenseMail2
//
//  Created by Sergey on 08.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NotesPresenter;

@interface NotesViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray* notes;
@property (nonatomic, weak) NotesPresenter* presenter;

-(void)reloadNotes;
-(void)showMessage:(NSString*)message title:(NSString*)title;

@end
