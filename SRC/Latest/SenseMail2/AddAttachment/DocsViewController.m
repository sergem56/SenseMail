//
//  DocsViewController.m
//  SenseMailShare
//
//  Created by Sergey on 27.12.16.
//  Copyright © 2016 Sergey. All rights reserved.
//

#import "DocsViewController.h"
#import "UserInfoDataManager.h"
#import "GlobalRouter.h"

@implementation DocsViewController

#pragma mark - QLPreviewControllerDataSource

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    //UIBarButtonItem* button0 = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save secure",nil) style:UIBarButtonItemStylePlain target:self action:@selector(needSaveDocSecure)];
    
    if(self.showSaveButton){
        UIBarButtonItem* button0 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"saveSec"] style:UIBarButtonItemStylePlain target:self action:@selector(needSaveDocSecure)];
        [[self navigationItem] setRightBarButtonItem:button0];
    }
    /*
    NSLayoutConstraint *heightConstraint = [NSLayoutConstraint constraintWithItem:button0 attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:32];
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:button0 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:32];
    [heightConstraint setActive:TRUE];
    [widthConstraint setActive:TRUE];
     */
    /*
    NSMutableArray* buttons = [[NSMutableArray alloc] initWithCapacity:4];
    
    
    UIToolbar* toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 180, 44.01)];
    [toolbar setTranslucent:YES];
    // Create button 1
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(button1Pressed)];
    [buttons addObject:button1];
    
    // Create button 2
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(button2Pressed)];
    [buttons addObject:button2];
    
    // Create button 3
    UIBarButtonItem* button3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(button3Pressed)];
    [buttons addObject:button3];
    
    // Create a action button
    UIBarButtonItem* openButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(openWith)];
    [buttons addObject:openButton];
    
    // insert the buttons in the toolbar
    [toolbar setItems:buttons animated:NO];
    
    // and put the toolbar in the navigation bar
    [[self navigationItem] setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:toolbar]];
     */
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES];
}

-(NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller
{
    return self.items.count;
}

- (id <QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    if (self.items.count == 1 && [self.items[0] isKindOfClass:[NSURL class]]) {
        return self.items[0];
    }
    if (self.items.count >= index && [self.items[index] isKindOfClass:[NSURL class]]) {
        return self.items[index];
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    //NSLog(documentsPath);
    
    NSString* path = [NSString stringWithFormat:@"%@/%@", documentsPath, self.items[index]];
    return [NSURL fileURLWithPath:path];
}

-(void)needSaveDocSecure
{
    //UserInfoDataManager* man = [[UserInfoDataManager alloc] init];
    //man.receiver = self;
    [CommonProcs getThumbnailFromURL:self.items[self.currentPreviewItemIndex] delegate:self];//:self.view];
    
    //[man writeURLPathData:self.items[self.currentPreviewItemIndex] pin:[GlobalRouter sharedManager].pin thumb:thumb];
}

-(void)thumbReady:(UIImage*)thumb
{
    UserInfoDataManager* man = [[UserInfoDataManager alloc] init];
    man.receiver = self;
    [man writeURLPathData:self.items[self.currentPreviewItemIndex] pin:[GlobalRouter sharedManager].pin thumb:thumb];
    // Need update gallery
    [[[GlobalRouter sharedManager] getGalleryRouter] reloadGallery];
}

-(void)userInfoFinishedTask:(BOOL)res
{
    //[CommonProcs showProgress:10 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    [CommonProcs hideProgress];
    
    if(res)
    {
        [CommonProcs showMessage:@"" title:NSLocalizedString(@"File saved to secure storage",nil)];
    }else{
        [CommonProcs showMessage:@"" title:NSLocalizedString(@"Error saving file",nil)];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.deleteOnExit) {
        for (NSURL* path in self.items) {
            NSError* error;
            [[NSFileManager defaultManager] removeItemAtURL:path error:&error];
            if (error) {
                NSLog(@"Error removing %@ %@", path.path, error.localizedDescription);
            }
        }
    }
}

@end
