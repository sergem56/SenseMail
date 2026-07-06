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
    UIBarButtonItem* button0 = [[UIBarButtonItem alloc] initWithTitle:@"HTML/Txt" style:UIBarButtonItemStylePlain target:self action:@selector(changeView)];
    
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(needSaveItem)];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeBook)];
    [self setToolbarItems:[NSArray arrayWithObjects:button0, button1, flexibleItem, button2, nil]];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
    // prevents the scroll view from swallowing up the touch event of child buttons
    tapGesture.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGesture];
    
    [[bodyField layer] setCornerRadius:8.0f];
    [[bodyField layer] setMasksToBounds:YES];
    [[bodyField layer] setBorderWidth:0.5f];
    [[bodyField layer] setBorderColor:[UIColor grayColor].CGColor];
    
    [self registerForKeyboardNotifications];
    
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                      attribute:NSLayoutAttributeLeading
                                                                      relatedBy:0
                                                                         toItem:self.view
                                                                      attribute:NSLayoutAttributeLeading
                                                                     multiplier:1.0
                                                                       constant:0];
    [self.view addConstraint:leftConstraint];
    
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:self.contentView
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:0
                                                                          toItem:self.view
                                                                       attribute:NSLayoutAttributeTrailing
                                                                      multiplier:1.0
                                                                        constant:0];
    [self.view addConstraint:rightConstraint];
 
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat newHeight = screenRect.size.height - self.bodyField.frame.origin.y - self.navigationController.toolbar.frame.size.height-24;
    self.textHeightConstraint.constant = newHeight;
    
    // AccessoryView toolbar
    UIBarButtonItem* button01 = [[UIBarButtonItem alloc] initWithTitle:@"HTML/Txt" style:UIBarButtonItemStylePlain target:self action:@selector(changeView)];
    UIBarButtonItem* button11 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(needSaveItem)];
    UIBarButtonItem *flexibleItem1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button21 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeBook)];
    self.inputAccessoryToolbar = [[UIToolbar alloc] init];
    self.inputAccessoryToolbar.frame = CGRectMake(0,0,250,44);
    self.inputAccessoryToolbar.items = [NSArray arrayWithObjects:button01, button11, flexibleItem1, button21, nil];
    self.titleField.inputAccessoryView = self.inputAccessoryToolbar;
    self.dateField.inputAccessoryView = self.inputAccessoryToolbar;
    self.bodyField.inputAccessoryView = self.inputAccessoryToolbar;
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
    if (item.date == nil) {
        item.date = [NSDate date];
    }
    
    if([item.uid isEqualToString:@""])
        item.uid = [[NSUUID UUID] UUIDString];
    
    [self.presenter needAddItem:item];
    
    originalItem = item;
}

-(BOOL)checkIfChanged
{
    if ([originalItem.title isEqualToString:titleField.text] && ([originalItem.body isEqualToString:bodyField.text] || showingHTML)){
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
        /*
        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Item changed",nil) message:NSLocalizedString(@"Save changes?",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"No",nil) otherButtonTitles:NSLocalizedString(@"Yes",nil),nil];
        [alert setTag:100];
        [alert show];
        */
        [CommonProcs askYesNoAndDoWithTitle:NSLocalizedString(@"Item changed",nil) text:NSLocalizedString(@"Save changes?",nil) blockYes:^{
            [self needSaveItem];
            [self closeBook:NO];
        } blockNo:^{
            [self closeBook:NO];
        }];
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
    showingHTML = NO;
    
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

-(void)changeView
{
    if (showingHTML) {
        showingHTML = NO;
        bodyField.attributedText = nil; // if not nil it, there's a strange bug with a width of text
        bodyField.font = [UIFont systemFontOfSize:14]; // get my font back!
        if (@available(iOS 13.0, *)) {
            [bodyField setTextColor:[UIColor labelColor]];
        } else {
            // Fallback on earlier versions
            [bodyField setTextColor:[UIColor blackColor]];
        }
        bodyField.editable = YES;
        if (item == nil) {
            bodyField.text = @"";
        }else{
            bodyField.text = item.body;
        }
        //bodyField.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
    }else{
        showingHTML = YES;
        NSString *htmlString = item.body;
        NSError* error;
        NSAttributedString *attributedString = [[NSAttributedString alloc]
                                                initWithData: [htmlString dataUsingEncoding:NSUnicodeStringEncoding]
                                                options: @{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                                                documentAttributes: nil
                                                error: &error
                                                ];
        if(!error){
            bodyField.attributedText = attributedString;
            bodyField.editable = NO; // don't want to edit html view
            bodyField.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
        }else{
            // Show plain text
            showingHTML = NO;
            bodyField.editable = YES;
            if (item == nil) {
                bodyField.text = @"";
            }else{
                bodyField.text = item.body;
            }
        }
        //bodyField.editable = NO;
    }
}

/*
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
*/
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Keyboard and size

/*
- (void)viewDidLayoutSubviews
{
    //[super viewDidLayoutSubviews];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat fixedWidth = self.bodyField.frame.size.width;
        CGSize newSize = [self.bodyField sizeThatFits:CGSizeMake(fixedWidth, CGFLOAT_MAX)];
        if (newSize.height<300) {
            CGRect screenRect = [[UIScreen mainScreen] bounds];
            CGFloat newHeight = screenRect.size.height - self.bodyField.frame.origin.y - self.navigationController.toolbar.frame.size.height-24;
            self.textHeightConstraint.constant = newHeight;
        }else{
            self.textHeightConstraint.constant = newSize.height;
        }
        //NSLog(@"--------");
        //[super viewWillLayoutSubviews];
    });
    
    [self.view layoutIfNeeded];
}
*/

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWasShown:(NSNotification*)aNotification {
    
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scroll.contentInset.top, self.scroll.contentInset.left, kbSize.height+32, 0.0);
    self.scroll.contentInset = contentInsets;
    self.scroll.scrollIndicatorInsets = contentInsets;
    
    if([self.bodyField isFirstResponder] && self.bodyField.selectedTextRange != nil)
    {
        CGRect cursorPosition = [self.bodyField caretRectForPosition:self.bodyField.selectedTextRange.start];
        cursorPosition.origin.y += self.bodyField.frame.origin.y;
        [self.scroll scrollRectToVisible:cursorPosition animated:YES];
    }
    
     // If active text field is hidden by keyboard, scroll it so it's visible
     // Your app might not need or want this behavior.
     CGRect aRect = self.view.frame;
     aRect.size.height -= kbSize.height;
     if (!CGRectContainsPoint(aRect, self.bodyField.frame.origin) ) {
         [self.scroll scrollRectToVisible:self.bodyField.frame animated:YES];
     }
    
    
    
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    //UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.scroll.contentInset.top, 0.0, 32, 0.0);
    self.scroll.contentInset = contentInsets;
    self.scroll.scrollIndicatorInsets = contentInsets;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    // unregister for keyboard notifications while not visible.
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidShowNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}


@end
