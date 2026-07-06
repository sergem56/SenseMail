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
#import "AddAttachmentPresenter.h"
#import "DocsViewController.h"

@interface AddAttachmentViewController ()

@end

@implementation AddAttachmentViewController

static BOOL nibMyCellloaded = NO;

@synthesize selectedCells, assetsGrouped;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    /*
    [CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager]getCurrentView] title:NSLocalizedString(@"Loading...", nil) stopButton:NO];
    _assets = [@[] mutableCopy];
    //__block NSMutableArray *tmpAssets = [@[] mutableCopy];
    // 1
    ALAssetsLibrary *assetsLibrary = [AddAttachmentViewController defaultAssetsLibrary];

    assetsGrouped = [[NSMutableDictionary alloc] init];
    // 2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [assetsLibrary enumerateGroupsWithTypes: ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        if (group == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [CommonProcs setMessageInProgress:NSLocalizedString(@"Sorting...", nil)];
            });
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
            self.assets = [NSMutableArray arrayWithArray:[self.assets sortedArrayUsingDescriptors:@[sort]]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.collectionView reloadData];
            });
            
            [CommonProcs hideProgress];
        }else{
            int num = (int)group.numberOfAssets;
            __block int i = 0;
            
            NSString* groupName = [group valueForProperty:ALAssetsGroupPropertyName];
            NSMutableArray* tmpAssets = [[NSMutableArray alloc] init];
            
            [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [CommonProcs setMessageInProgress:[NSString stringWithFormat:@"%@ %@ %d/%d",NSLocalizedString(@"Loading...", nil), [group valueForProperty:ALAssetsGroupPropertyName],  i++, num]];
                });
                if(result)
                {
                    // 3
                    //[tmpAssets addObject:result];
                    [self.assets addObject:result];
                    [tmpAssets addObject:result];
                }
            }];
            
#warning Folders - need select groups!!!
            NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
            tmpAssets = [NSMutableArray arrayWithArray:[tmpAssets sortedArrayUsingDescriptors:@[sort]]];
            [assetsGrouped setObject:tmpAssets forKey:groupName];
            
            // 4
            //NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
            //[self.assets addObjectsFromArray:tmpAssets];//] [NSMutableArray arrayWithArray: [tmpAssets sortedArrayUsingDescriptors:@[sort]]]];
            //self.assets = tmpAssets;
            
            // 5
            dispatch_async(dispatch_get_main_queue(), ^{
                //[self.collectionView reloadData];
            });
        }
    } failureBlock:^(NSError *error) {
        NSLog(@"Error loading images %@", error);
    }];
    });
     
     */
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.navigationController.toolbarHidden = NO;
    self.navigationItem.hidesBackButton = YES;
    //UIBarButtonItem* button0
    photoButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(takePhotoButtonTapped)];
    UIBarButtonItem *fixedItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedItem.width = 5.0f;
    UIBarButtonItem* button1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(albumsButtonTapped)];
    
    // DOCS button
    UIBarButtonItem* button11 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(docsButtonTapped)];
    // End DOCS
    
    // DOCS-2 button
    UIImage *image = [UIImage imageNamed:@"iCloud"]; //imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    UIBarButtonItem *button12 = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(allDocsButtonTapped)];
    //UIBarButtonItem* button12 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks target:self action:@selector(allDocsButtonTapped)];
    // End DOCS
    
    // SECURE DOCS button
    UIBarButtonItem* button13 = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"galleryCircle"] style:UIBarButtonItemStylePlain target:self action:@selector(secureDocsButtonTapped)];
    // End SECURE DOCS
    
    attCount = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
    UIBarButtonItem *flexItem3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *flexItem2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *flexibleItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* button2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(closeView)];
    
    [self setToolbarItems:[NSArray arrayWithObjects:photoButton, flexibleItem/*fixedItem*/, button1,flexibleItem/*fixedItem*/, button11,flexibleItem,button12,flexItem3, button13, flexItem2, attCount, flexibleItem, button2, nil]];
    
    [photoButton setEnabled:[UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]];
    
    if (selectedCells == nil) {
        selectedCells = [[NSMutableArray alloc] init];
    }
    [selectedCells removeAllObjects];
    
    self.collectionView.allowsMultipleSelection = YES;
}

-(void)viewDidDisappear:(BOOL)animated
{
    //self.assets = nil;
    //self.assetsGrouped = nil;
    //self.popOver = nil;
    [super viewDidDisappear:animated];
}

-(void)resetSelection
{
    if (selectedCells != nil) {
        //for (AttCollectionViewCell* cell in selectedCells) {
            //cell.markLabel.hidden = YES;
        //}
        [selectedCells removeAllObjects];
    }
    
    [self showSelectedCount];
    
    // Reset the selection in collection view itself otherwise you need to click twice
    // although there's no selection mark
    for (NSIndexPath *indexPath in [self.collectionView indexPathsForSelectedItems]) {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
    [self.collectionView reloadData];
}

-(void)showSelectedCount
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* titleC = [NSString stringWithFormat:NSLocalizedString(@"Images: %i", nil), self->selectedCells.count];
        [self->attCount setTitle:titleC];
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
    
    //static BOOL nibMyCellloaded = NO;
    
    if(!nibMyCellloaded)
    {
        UINib *nib = [UINib nibWithNibName:@"AddCell" bundle: nil];
        [collectionView registerNib:nib forCellWithReuseIdentifier:identifier];
        nibMyCellloaded = YES;
    }
    
    AttCollectionViewCell *cell = (AttCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    
    PHAsset *asset = self.assets[indexPath.row];
    cell.asset = asset;
    //cell.backgroundColor = [UIColor redColor];
    cell.markLabel.hidden = YES;
    if ([selectedCells containsObject:indexPath]) {
        cell.markLabel.hidden = NO;
    }
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
    //[selectedCells addObject:datasetCell];
    if (selectedCells == nil) {
        selectedCells = [[NSMutableArray alloc] init];
    }
    [selectedCells addObject:indexPath];
    [self showSelectedCount];
}

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    AttCollectionViewCell *datasetCell = (AttCollectionViewCell*)[collectionView cellForItemAtIndexPath:indexPath];
    //[selectedCells removeObject:datasetCell];
    [selectedCells removeObject:indexPath];
    datasetCell.markLabel.hidden = YES;
    [self showSelectedCount];
}


#pragma mark - assets

+ (PHPhotoLibrary *)defaultAssetsLibrary
{
    static dispatch_once_t pred = 0;
    static PHPhotoLibrary *library = nil;
    dispatch_once(&pred, ^{
        library = [PHPhotoLibrary sharedPhotoLibrary];// [[PHPhotoLibrary alloc] init];
    });
    return library;
}

#pragma mark - Actions

- (void)takePhotoButtonTapped
{
    if (([UIImagePickerController isSourceTypeAvailable:
          UIImagePickerControllerSourceTypeCamera] == NO))
        return;
    // There's a bug causing a "Snapshotting a view that has not been rendered results in an empty snapshot.
    // Ensure your view has been rendered at least once before snapshotting or snapshot after screen updates."
    // to appear. Was trying to get rid of it, but to no avail...
    [self performSelector:@selector(showcamera) withObject:nil afterDelay:0.0f];
}

-(void) showcamera
{
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypeCamera;
    mediaUI.allowsEditing = NO;//YES;
    mediaUI.delegate = self;
    //mediaUI.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    mediaUI.modalPresentationStyle = UIModalPresentationPopover;
    //mediaUI.popoverPresentationController.sourceView = self.view;
    //mediaUI.popoverPresentationController.sourceRect = self.view.frame;
    mediaUI.popoverPresentationController.barButtonItem = photoButton;
    [self presentViewController:mediaUI animated:YES completion:nil];
    
    /*
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:mediaUI];
        [popover presentPopoverFromBarButtonItem:photoButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        self.popOver = popover;
    } else {
        [self presentViewController:mediaUI animated:YES completion:nil];
    }
    */
}

- (void)albumsButtonTapped
{
    // Show dialog with groups. Groups are in the presenter
    [self.presenter needShowGroups];
}

-(void) docsButtonTapped
{
    [self.presenter needShowDocs];
}

-(void) allDocsButtonTapped
{
    [self.presenter needShowAllDocs];
}

-(void)secureDocsButtonTapped
{
    [self.presenter needShowSecureDocs];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
    if (controller.documentPickerMode == UIDocumentPickerModeImport) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs showWheelinView:[[GlobalRouter sharedManager] getCurrentView] message:NSLocalizedString(@"Loading...", nil) stopButtonVisible:NO];
            /*BOOL ret = */[url startAccessingSecurityScopedResource];
            
            /*
             // Do not check, it fails on the device
             if(!ret){
                [CommonProcs showMessage:NSLocalizedString(@"Cannot open file", nil) title:NSLocalizedString(@"Error", nil)];
                [self closeView];
                [CommonProcs hideProgress];
                [url stopAccessingSecurityScopedResource];
                return;
            }
            */
            // Do I need to show a preview? There's no use - you cannot cancel the doc, anyway it's going to be
            // added to a mail, so there's no need to show a preview. You can preview it from the mail.
            //
            //add doc to sel cells
            
            if (self->selectedCells == nil) {
                self->selectedCells = [[NSMutableArray alloc]init];
            }
            NSString* tmppth = [CommonProcs copyFileToTemp:[url path]];
            if(tmppth)[self->selectedCells addObject:tmppth];
            // Need to show that the doc was selected
            [url stopAccessingSecurityScopedResource];
            [self closeView];
            [CommonProcs hideProgress];
            
            /*
            if(![QLPreviewController canPreviewItem:url]){
                NSLog(@"Cannot preview this item");
                if (self->selectedCells == nil) {
                    self->selectedCells = [[NSMutableArray alloc]init];
                }
                [self->selectedCells addObject:[CommonProcs copyFileToTemp:[url path]]];
                // Need to show that the doc was selected
                
                [url stopAccessingSecurityScopedResource];
                [self closeView];
                [CommonProcs hideProgress];
            }else{
                DocsViewController *previewController=[[DocsViewController alloc]init];
                previewController.items = @[url];
                previewController.delegate=previewController;
                previewController.dataSource=previewController;
                [previewController setCurrentPreviewItemIndex:0];
                [[[GlobalRouter sharedManager] getDetailNavController] presentViewController:previewController animated:YES completion:^{
    #warning iCloud TODO here
                    //add doc to sel cells
                    //int i = self.items.count;
                    if (self->selectedCells == nil) {
                        self->selectedCells = [[NSMutableArray alloc]init];
                    }
                    [self->selectedCells addObject:[CommonProcs copyFileToTemp:[url path]]];
                    // Need to show that the doc was selected
                    [url stopAccessingSecurityScopedResource];
                    [self closeView];
                    [CommonProcs hideProgress];
                }];
            }
             */
        });
    }
}


-(void)closeView
{
    // stop scrolling first as it crashed if you close it while it is srolling
    [self.collectionView setContentOffset:self.collectionView.contentOffset animated:NO];
    
    if(self.selectedCells.count > 0){
        NSMutableArray* selCells = [[NSMutableArray alloc] initWithCapacity:self.selectedCells.count];
        for (id/*NSIndexPath* */ ip in self.selectedCells) {
            if ([ip isKindOfClass:[NSString class] ]) {
                [selCells addObject:ip];
            }else{
                [selCells addObject:self.assets[((NSIndexPath*)ip).row]];
            }
        }
        //[self.caller setAttachments:selectedCells];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.caller setAttachments:selCells];
        });
    }
    
    [[[GlobalRouter sharedManager] getAddAttRouter] finished];
    nibMyCellloaded = NO;
    self.selectedCells = nil;
}

#pragma mark - image picker delegate

- (void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //UIImage *image = (UIImage *) [info objectForKey: UIImagePickerControllerOriginalImage];
    //__weak id weakSelf = self;
    
    [picker dismissViewControllerAnimated:YES completion:^{
        // Do something with the image - save to camera roll
        if(picker.sourceType == UIImagePickerControllerSourceTypeCamera){
            
            [CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager]getCurrentView] title:NSLocalizedString(@"Writing image...", nil) stopButton:NO];
        
            // Request to save the image to camera roll
            __block PHAssetChangeRequest *changeRequest;
            __block PHFetchResult* res;
            __block PHObjectPlaceholder *assetPlaceholder;
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                changeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:[info valueForKey:UIImagePickerControllerOriginalImage]];
                assetPlaceholder = changeRequest.placeholderForCreatedAsset;
                
            } completionHandler:^(BOOL success, NSError *error) {
                [CommonProcs hideProgress];
                if (success) {
                    //NSLog(@"Success");
                    res = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetPlaceholder.localIdentifier] options:nil];
                    if ([res.firstObject isKindOfClass:[PHAsset class]]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self.assets insertObject:res.firstObject atIndex:0];
                            [self.collectionView reloadData];
                            [self collectionView:self.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
                        });
                    }
                }
                else {
                    //NSLog(@"write error : %@",error);
                    [CommonProcs showMessage:error.localizedDescription title:NSLocalizedString(@"Error",nil)];
                }
            }];
        }else{
            
            // WTF? How can we get here???
            NSLog(@"Something strange has happened, source type is not a camera...");
            
            /*
            ALAssetsLibrary *library = [AddAttachmentViewController defaultAssetsLibrary];
            NSURL* assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
            [library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
                AddAttachmentViewController* strongSelf = weakSelf;
                if(asset){
                    //[self.assets insertObject:asset atIndex:0];
                    BOOL found = NO;
                    for (int i=0;i<strongSelf.assets.count; i++) {
                        ALAsset* ta = [strongSelf.assets objectAtIndex:i];
                        if ([[ta valueForProperty:ALAssetPropertyAssetURL] isEqual: [asset valueForProperty:ALAssetPropertyAssetURL]]) {
                            AttCollectionViewCell *datasetCell = (AttCollectionViewCell*)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
                            if (datasetCell == nil) {
                                datasetCell = [[AttCollectionViewCell alloc] init];
                                datasetCell.asset = asset;
                            }else
                                datasetCell.markLabel.hidden = NO;
                            [self->selectedCells addObject:datasetCell];
                            [strongSelf showSelectedCount];
                            found = YES;
                            break;
                        }
                    }
                    if (!found) {
                        AttCollectionViewCell* datasetCell = [[AttCollectionViewCell alloc] init];
                        datasetCell.asset = asset;
                        [self->selectedCells addObject:datasetCell];
                        [strongSelf showSelectedCount];
                    }
                    //[self.collectionView reloadData];
                }
            } failureBlock:^(NSError *error) {
                
            }];
             */
        }
    }];
    
    /*
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self.popOver dismissPopoverAnimated:YES];
    }*/
    //[selectedCells addObject:image];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{
    }];
    /*
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self.popOver dismissPopoverAnimated:YES];
    }*/
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
