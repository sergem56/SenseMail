//
//  GalleryCollectionViewController.m
//  SenseMail2
//
//  Created by Sergey on 02.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "GalleryCollectionViewController.h"
#import "GalleryCollectionViewCell.h"
#import "GlobalRouter.h"
#import "GalleryPresenter.h"
#import "CommonProcs.h"

@interface GalleryCollectionViewController ()

@end

@implementation GalleryCollectionViewController

@synthesize caller, selectedCells;

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Register cell classes
    //[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    // Do any additional setup after loading the view.
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeGallery)];
    
    [self setToolbarItems:[NSArray arrayWithObjects: flexibleItem, button2, nil]];
    
    ///////// !!!!!!!!!!
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(deleteImage:)];
    longPress.delegate = self;
    [self.collectionView addGestureRecognizer:longPress];
}

-(void)deleteImage:(UILongPressGestureRecognizer *)lgr
{
    if (lgr.state == UIGestureRecognizerStateBegan) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to delete image?",nil) message:NSLocalizedString(@"Image will be permanently deleted",nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"NO",nil) otherButtonTitles:NSLocalizedString(@"YES",nil), nil];
        alert.tag = 100;
        alert.delegate = self;
        [alert show];
        loc = [lgr locationInView:self.collectionView];
    }
}

-(void)closeGallery
{
    if (caller != nil) {
        [self.caller setAttachments:selectedCells];
    }
    [[[GlobalRouter sharedManager] getBookRouter] finished];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    //return 1;
    
    if (self.items.count > 0) {
        // All these lines are here to fix the bg bug... you can't just remove the bg cuz it won't be removed...
        [self.collectionView.backgroundView removeFromSuperview];
        self.bgLabel.text = @"";
        self.bgLabel = nil;
        [self.collectionView setBackgroundView:self.bgLabel];// .backgroundView = nil;
        return 1;
        
    } else {
        // Display a message when the table is empty
        self.bgLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        self.bgLabel.text = NSLocalizedString(@"No images here", nil);
        self.bgLabel.textColor = [UIColor whiteColor];
        self.bgLabel.numberOfLines = 0;
        self.bgLabel.textAlignment = NSTextAlignmentCenter;
        [self.bgLabel sizeToFit];
        
        self.collectionView.backgroundView = self.bgLabel;
        //self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView2 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static BOOL nibMyCellloaded = NO;
    
    if(!nibMyCellloaded)
    {
        UINib *nib = [UINib nibWithNibName:@"GalleryCollectionViewCell" bundle: nil];
        [collectionView2 registerNib:nib forCellWithReuseIdentifier:reuseIdentifier];
        nibMyCellloaded = YES;
    }

    GalleryCollectionViewCell *cell = (GalleryCollectionViewCell*)[collectionView2 dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    NSString* key = [self.items.allKeys objectAtIndex:indexPath.row];
    UIImage* tmp =  self.items[key];
    cell.image.image = tmp;
    cell.asset = key;
    
    cell.backgroundColor = [UIColor whiteColor];
    cell.markLabel.hidden = YES;
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void) collectionView:(UICollectionView *)collectionView2 didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.caller != nil) {
        GalleryCollectionViewCell *datasetCell = (GalleryCollectionViewCell*)[collectionView2 cellForItemAtIndexPath:indexPath];
        datasetCell.markLabel.hidden = NO;
        [selectedCells addObject:datasetCell];
    }else{
        //[CommonProcs showProgressWithTitle:1 max:10 inView:[[GlobalRouter sharedManager] getCurrentView] title:NSLocalizedString(@"Loading...",nil) stopButton:NO];
        GalleryCollectionViewCell* cell = (GalleryCollectionViewCell*)[collectionView2 cellForItemAtIndexPath:indexPath];
        NSString* path = cell.asset;
        [CommonProcs spawnProcWithProgress:@selector(needShowImageAtPath:) object:self.presenter withParam:path];
        //[self.presenter needShowImageAtPath:path];
    }
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.caller != nil) {
        GalleryCollectionViewCell *datasetCell = (GalleryCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
        [selectedCells removeObject:datasetCell];
        datasetCell.markLabel.hidden = YES;
    }
}


/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100)
    {
        if (buttonIndex == 0)
        {
            //[self finished];
        }else{
            //CGPoint loc = [currentLong locationInView:self.collectionView];
            NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:loc];
            GalleryCollectionViewCell *cell = (GalleryCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
            NSString* path = cell.asset;
            [self.presenter wantToDeleteImage:path];
            loc = CGPointZero;
            
            [self.items removeObjectForKey:cell.asset];
            [self.collectionView reloadData];
        }
    }
}

@end
