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
    
    self.selectedCells = [[NSMutableArray alloc] init];
    self.selectedCellsPaths = [[NSMutableDictionary alloc] init];
}

-(void)deleteImage:(UILongPressGestureRecognizer *)lgr
{
    if (lgr.state == UIGestureRecognizerStateBegan) {
        loc = [lgr locationInView:self.collectionView];
        
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:loc];
        if (!indexPath) {
            return;
        }
        //GalleryCollectionViewCell *cell = (GalleryCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
        
        NSString* title = NSLocalizedString(@"Are you sure you want to delete image?",nil);
        UIAlertController * alert = [UIAlertController
                                     alertControllerWithTitle:title
                                     message:NSLocalizedString(@"Image will be permanently deleted",nil)
                                     preferredStyle:UIAlertControllerStyleAlert];
        __weak __typeof__(self) weakSelf = self;
        UIAlertAction* deleteIt = [UIAlertAction
                                actionWithTitle:NSLocalizedString(@"Yes",nil)
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action)
                                {
                                    __strong __typeof__(self) strongSelf = weakSelf;
                                    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:strongSelf->loc];
                                    if (!indexPath) {
                                        return;
                                    }
                                    GalleryCollectionViewCell *cell = (GalleryCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:indexPath];
                                    NSString* path = cell.asset;
                                    [self.presenter wantToDeleteImage:path];
                                    strongSelf->loc = CGPointZero;
                                    if(cell && cell.asset){
                                        [self.items removeObjectForKey:cell.asset];
                                        [self.collectionView reloadData];
                                    }
                                }];
        [alert addAction:deleteIt];
        
        UIAlertAction* cancel = [UIAlertAction
                                 actionWithTitle:NSLocalizedString(@"No",nil)
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction * action)
                                 {
                                     
                                 }];
        [alert addAction:cancel];
        
        UIView* pView = [[GlobalRouter sharedManager] getCurrentView];
        alert.popoverPresentationController.sourceView = pView;
        alert.popoverPresentationController.sourceRect = pView.frame;
        [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:alert animated:YES completion:nil];
    }
}

-(void)closeGallery
{
    if (caller != nil) {
        [self.caller setAttachments:[selectedCells copy]];
        self.caller = nil;
    }
    [[[GlobalRouter sharedManager] getGalleryRouter] finished];
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
    
    if (self.items.count > 1) {
        // All these lines are here to fix the bg bug... you can't just remove the bg cuz it won't be removed...
        [self.collectionView.backgroundView removeFromSuperview];
        self.bgLabel.text = @"";
        self.bgLabel = nil;
        [self.collectionView setBackgroundView:self.bgLabel];// .backgroundView = nil;
        return 1;
        
    } else {
        // Display a message when the table is empty
        float height = self.view.bounds.size.height;
        self.bgLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, height/2-20, self.view.bounds.size.width, self.view.bounds.size.height)];
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
    return self.items.count-1; // one for the sorted keys
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView2 cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static BOOL nibMyCellloaded = NO;
    
    if(!nibMyCellloaded || YES) // Error when clearing for BG
    {
        UINib *nib = [UINib nibWithNibName:@"GalleryCollectionViewCell" bundle: nil];
        [collectionView2 registerNib:nib forCellWithReuseIdentifier:reuseIdentifier];
        nibMyCellloaded = YES;
    }

    GalleryCollectionViewCell *cell = (GalleryCollectionViewCell*)[collectionView2 dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    //NSString* key = [self.items.allKeys objectAtIndex:indexPath.row];
    NSString* key = [self.sortedKeys objectAtIndex:indexPath.row];
    UIImage* tmp =  self.items[key];
    cell.image.image = tmp;
    cell.asset = key;
    
    if (@available(iOS 13.0, *)) {
        cell.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        // Fallback on earlier versions
        cell.backgroundColor = [UIColor whiteColor];
    }
    cell.markLabel.hidden = YES;
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void) collectionView:(UICollectionView *)collectionView2 didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.caller != nil) {
        GalleryCollectionViewCell *datasetCell = (GalleryCollectionViewCell*)[collectionView2 cellForItemAtIndexPath:indexPath];
        if(datasetCell){
            datasetCell.markLabel.hidden = NO;
            
            NSString* pth;
            UserInfoDataManager* man = [[UserInfoDataManager alloc] init];
            //man.receiver = self;
            UIImage* image = [man getFullImage:datasetCell.asset pin:[GlobalRouter sharedManager].pin];
            if(image){
                pth = [CommonProcs getTempPathForDoc:datasetCell.asset.pathExtension];
                [UIImageJPEGRepresentation(image, 0.7) writeToFile:pth atomically:NO];
            }else{
                NSData* dt = [man getFullData:datasetCell.asset pin:[GlobalRouter sharedManager].pin]; // Here is double decryption that was already done above...
                pth = [CommonProcs getTempPathForDoc:datasetCell.asset.pathExtension];
                [dt writeToFile:pth atomically:NO];
            }
            
            [selectedCells addObject:pth];
            [self.selectedCellsPaths setValue:pth forKey:datasetCell.asset];
        }
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
        [selectedCells removeObject:[self.selectedCellsPaths objectForKey:datasetCell.asset]];
        [self.selectedCellsPaths removeObjectForKey:datasetCell.asset];
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

@end
