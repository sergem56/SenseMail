//
//  DetailViewController.h
//  SenseMailShare
//
//  Created by Sergey on 27.04.16.
//  Copyright © 2016 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (nonatomic, strong) IBOutlet UIBarButtonItem* masterButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* bookButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem* composeButton;
@property (nonatomic, weak)   IBOutlet UIToolbar* toolbar;

-(void)setMasterHidden:(BOOL)hidden;

-(IBAction)showMaster:(id)sender;
-(IBAction)exitApp:(id)sender;
-(IBAction)newMessage:(id)sender;
-(IBAction)showBook:(id)sender;

-(IBAction)showGallery:(id)sender;
-(IBAction)showNotes:(id)sender;
-(IBAction)gotoInbox:(id)sender;
-(IBAction)composeNew:(id)sender;
-(IBAction)showSettings:(id)sender;

-(void)hideMaster;
-(void)hideMasterAndRestore;

@end
