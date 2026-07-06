//
//  AddAttachmentViewController.m
//  SenseMail2
//
//  Created by Sergey on 20.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "AddAttachmentViewController.h"
#import "AttCollectionViewCell.h"
#import "GlobalRouter.h"
#import "AddAttachmentRouter.h"
#import "CommonProcs.h"

@interface AddAttachmentViewController ()

@end

@implementation AddAttachmentViewController


@synthesize selectedCells;


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager]getCurrentView] title:NSLocalizedString(@"Loading...", nil) stopButton:NO];
    _assets = [@[] mutableCopy];
    __block NSMutableArray *tmpAssets = [@[] mutableCopy];
    // 1
    ALAssetsLibrary *assetsLibrary = [AddAttachmentViewController defaultAssetsLibrary];

    // 2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        int num = (int)group.numberOfAssets;
        __block int i = 0;
        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [CommonProcs setMessageInProgress:[NSString stringWithFormat:@"%@ %d/%d",NSLocalizedString(@"Loading...", nil), i++, num]];
            });
            if(result)
            {
                // 3
                [tmpAssets addObject:result];
            }
        }];
        
        // 4
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
        self.assets = [NSMutableArray arrayWithArray: [tmpAssets sortedArrayUsingDescriptors:@[sort]]];
        //self.assets = tmpAssets;
        
        // 5
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
        });
        [CommonProcs hideProgress];
    } failureBlock:^(NSError *error) {
        NSLog(@"Error loading images %@", error);
    }];
    });
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationController.toolbarHidden = NO;
    //UIBarButtonItem* button0
    photoButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(takePhotoButtonTapped)];
    UIBarButtonItem *fixedItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedItem.width = 5.0f;
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(albumsButtonTapped)];
    attCount = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
    UIBarButtonItem *flexItem2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeView)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:photoButton, fixedItem, button1, flexItem2, attCount, flexibleItem, button2, nil]];

    if (selectedCells == nil) {
        selectedCells = [[NSMutableArray alloc] init];
    }
    [selectedCells removeAllObjects];
    
    self.collectionView.allowsMultipleSelection = YES;
}

-(void)resetSelection
{
    if (selectedCells != nil) {
        for (AttCollectionViewCell* cell in selectedCells) {
            cell.markLabel.hidden = YES;
        }
        [selectedCells removeAllObjects];
    }
}

-(void)showSelectedCount
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* titleC = [NSString stringWithFormat:NSLocalizedString(@"Images: %i", nil), selectedCells.count];
        [attCount setTitle:titleC];
    });
}

#pragma mark - collection view data source

- (NSInteger) collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assets.count;
}

- (UICollectionViewCell *) collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"AddCell";
    
    static BOOL nibMyCellloaded = NO;
    
    if(!nibMyCellloaded)
    {
        UINib *nib = [UINib nibWithNibName:@"AddCell" bundle: nil];
        [collectionView registerNib:nib forCellWithReuseIdentifier:identifier];
        nibMyCellloaded = YES;
    }
    
    AttCollectionViewCell *cell = (AttCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    ALAsset *asset = self.assets[indexPath.row];
    cell.asset = asset;
    cell.backgroundColor = [UIColor redColor];
    cell.markLabel.hidden = YES;
    
    return cell;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 4;
}

- (CGFloat) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 1;
}

#pragma mark - collection view delegate

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    //ALAsset *asset = self.assets[indexPath.row];
    //ALAssetRepresentation *defaultRep = [asset defaultRepresentation];
    //UIImage *image = [UIImage imageWithCGImage:[defaultRep fullScreenImage] scale:[defaultRep scale] orientation:0];
    // Do something with the image
    
    AttCollectionViewCell *datasetCell = (AttCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    
    datasetCell.markLabel.hidden = NO;//!datasetCell.markLabel.hidden;
    [selectedCells addObject:datasetCell];
    [self showSelectedCount];
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    AttCollectionViewCell *datasetCell = (AttCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    [selectedCells removeObject:datasetCell];
    datasetCell.markLabel.hidden = YES;
}


#pragma mark - assets

+ (ALAssetsLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static ALAssetsLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [[ALAssetsLibrary alloc] init];
    });
    return library;
}

#pragma mark - Actions

- (void)takePhotoButtonTapped
{
    if (([UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeCamera] == NO))
        return;
    
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    mediaUI.allowsEditing = NO;
    mediaUI.delegate = self;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:mediaUI];
        [popover presentPopoverFromBarButtonItem:photoButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        self.popOver = popover;
    } else {
        [self presentViewController:mediaUI animated:YES completion:nil];
    }
    
}

- (void)albumsButtonTapped
{
    if (([UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypePhotoLibrary] == NO))
        return;
    
    [CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager]getCurrentView] title:NSLocalizedString(@"Loading...", nil) stopButton:NO];
    
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    mediaUI.allowsEditing = NO;
    mediaUI.delegate = self;
    [self presentViewController:mediaUI animated:YES completion:^{
        [CommonProcs hideProgress];
    }];
    
}

-(void)closeView
{
    [self.caller setAttachments:selectedCells];
    [[[GlobalRouter sharedManager] getAddAttRouter] finished];
}

#pragma mark - image picker delegate

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = (UIImage *) [info objectForKey:
                                  UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:^{
        // Do something with the image - save to camera roll
        if(picker.sourceType == UIImagePickerControllerSourceTypeCamera){
            //UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
        
            ALAssetsLibrary *library = [AddAttachmentViewController defaultAssetsLibrary]; //[[ALAssetsLibrary alloc] init];
            // Request to save the image to camera roll
            [library writeImageToSavedPhotosAlbum:[image CGImage] orientation:(ALAssetOrientation)[image imageOrientation] completionBlock:^(NSURL *assetURL, NSError *error){
                if (error) {
                    //NSLog(@"error");
                } else {
                    //NSLog(@"url %@", assetURL);
                    [library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                        if(asset){
                            [self.assets insertObject:asset atIndex:0];
                            [self.collectionView reloadData];
                        }
                    } failureBlock:^(NSError *error) {
                        
                    }];
                }  
            }];
        }else{
            ALAssetsLibrary *library = [AddAttachmentViewController defaultAssetsLibrary];
            NSURL* assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
            [library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                if(asset){
                    //[self.assets insertObject:asset atIndex:0];
                    BOOL found = NO;
                    for (int i=0;i<self.assets.count; i++) {
                        ALAsset* ta = [self.assets objectAtIndex:i];
                        if ([[ta valueForProperty:ALAssetPropertyAssetURL] isEqual: [asset valueForProperty:ALAssetPropertyAssetURL]]) {
                            AttCollectionViewCell *datasetCell = (AttCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                            if (datasetCell == nil) {
                                datasetCell = [[AttCollectionViewCell alloc] init];
                                datasetCell.asset = asset;
                            }else
                                datasetCell.markLabel.hidden = NO;
                            [selectedCells addObject:datasetCell];
                            [self showSelectedCount];
                            found = YES;
                            break;
                        }
                    }
                    if (!found) {
                        AttCollectionViewCell* datasetCell = [[AttCollectionViewCell alloc] init];
                        datasetCell.asset = asset;
                        [selectedCells addObject:datasetCell];
                        [self showSelectedCount];
                    }
                    //[self.collectionView reloadData];
                }
            } failureBlock:^(NSError *error) {
                
            }];
        }
    }];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self.popOver dismissPopoverAnimated:YES];
    }
    //[selectedCells addObject:image];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{
    }];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self.popOver dismissPopoverAnimated:YES];
    }
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

@end
