//
//  NotesEditViewController.m
//  SenseMail2
//
//  Created by Sergey on 08.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "NotesEditViewController.h"
#import "NoteEntity.h"
#import "GlobalRouter.h"
#import "NotesPresenter.h"

@interface NotesEditViewController ()

@end

@implementation NotesEditViewController

@synthesize dateField, titleField, bodyField, item, originalItem, isNew;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self setCurrentItem:self.item];
    
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(needSaveItem)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeBook)];
    [self setToolbarItems:[NSArray arrayWithObjects: button1, flexibleItem, button2, nil]];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    // prevents the scroll view from swallowing up the touch event of child buttons
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
    
    [[bodyField layer] setCornerRadius:8.0f];
    [[bodyField layer] setMasksToBounds:YES];
    [[bodyField layer] setBorderWidth:0.5f];
    [[bodyField layer] setBorderColor:[UIColor grayColor].CGColor];
}

-(void)hideKeyboard
{
    [self.view endEditing:YES];
}

-(void)needSaveItem
{
    isNew = NO;
    if(item == nil){
        item = [[NoteEntity alloc] init];
        item.uid = [[NSUUID UUID] UUIDString];
        isNew = YES;
    }
    
    item.title = titleField.text;
    item.body = bodyField.text;
    
    NSString* dateString =  dateField.text;

    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd.MM.yy HH:mm"];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    
    item.date = [formatter dateFromString:dateString];
    
    if([item.uid isEqualToString:@""])
        item.uid = [[NSUUID UUID] UUIDString];
    
    [self.presenter needAddItem:item];
    
    originalItem = item;
}

-(BOOL)checkIfChanged
{
    if ([originalItem.title isEqualToString:titleField.text] && [originalItem.body isEqualToString:bodyField.text] ){
        return NO;
    }else{
        return YES;
    }
}

-(void)closeBook
{
    [self closeBook:YES];
}

-(void)closeBook:(BOOL)needCheck
{
    if (needCheck && [self checkIfChanged]) {
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Item changed",nil) message:NSLocalizedString(@"Save changes?",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"No",nil) otherButtonTitles:NSLocalizedString(@"Yes",nil),nil];
        [alert setTag:100];
        [alert show];
    }else
        [[[GlobalRouter sharedManager] getNotesRouter] finished];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setCurrentItem:(NoteEntity *)cItem
{
    item = cItem;
    originalItem = cItem;
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd.MM.yy HH:mm"];
    [formatter setTimeZone:[NSTimeZone systemTimeZone]];
    
    if (item == nil) {
        dateField.text = [formatter stringFromDate:[NSDate date]];
        titleField.text = @"";
        bodyField.text = @"";
    }else{
        dateField.text = [formatter stringFromDate:item.date];
        titleField.text = item.title;
        bodyField.text = item.body;
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100)
    {
        if (buttonIndex == 0)
        {
            [self closeBook:NO];
            
        }else{
            [self needSaveItem];
            [self closeBook:NO];
        }
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
