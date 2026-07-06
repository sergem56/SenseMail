//
//  AddAttachmentPresenter.m
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "AddAttachmentPresenter.h"
#import "AddAttachmentViewController.h"
#import "GlobalRouter.h"
#import "DataManager.h"
#import "CommonProcs.h"
#import "GroupSelectTableViewController.h"

@implementation AddAttachmentPresenter

@synthesize assets, assetsGrouped, groupPosters;

-(AddAttachmentViewController*)showView
{
    if(viewController == nil)
    {
        viewController = [[AddAttachmentViewController alloc] initWithNibName:@"AddAttachmentViewController" bundle:nil];
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
            [self readGallery];
        //});
    }else{
        //[self needShowGroups];
    }
    
    /*
    [CommonProcs showProgress:1 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
    //dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
    dispatch_async([[GlobalRouter sharedManager] getQ], ^{
        
        [[GlobalRouter sharedManager] setAssets: [DataManager defaultAssetsLibrary]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [CommonProcs showProgress:10 max:10 inView:[[GlobalRouter sharedManager] getCurrentView]];
        });
        
    });
     */
    
    viewController.presenter = self;
    self.currentGroup = nil;
    
    /*if (self.currentGroup == nil) {
        viewController.assets = assets;
    }else{
        viewController.assets = [assetsGrouped valueForKey:self.currentGroup];
    }*/
    viewController.assets = assets;
    [viewController resetSelection];

    return viewController;

}

-(void)showGroup:(NSString *)group
{
    self.currentGroup = group;
    
    if (self.currentGroup == nil) {
        viewController.assets = assets;
    }else{
        PHFetchResult* res = [self fetchImagesFromGroup:self.currentGroup];
        viewController.assets = res;
        //viewController.assets = [self fetchImagesFromGroup:self.currentGroup]; //[assetsGrouped valueForKey:self.currentGroup];
    }
    [viewController resetSelection];

}

-(void)needShowGroups
{
    [self needShowGroups:NO];
}

-(void)needShowGroups:(BOOL)updateOnly
{
    // Show the list of groups
    NSMutableArray* tmpItems = [[NSMutableArray alloc] initWithCapacity:assetsGrouped.count];
    NSArray* allKeysArray = assetsGrouped.allKeys;
    
    NSArray *sortedKeys = [allKeysArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        /* NSOrderedAscending, NSOrderedSame, NSOrderedDescending */
        BOOL isDigit1 = [[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[(NSString*)obj1 characterAtIndex:0]];
        BOOL isDigit2 = [[NSCharacterSet decimalDigitCharacterSet] characterIsMember:[(NSString*)obj2 characterAtIndex:0]];
        if (isDigit1 && !isDigit2) {
            return NSOrderedDescending;
        } else if (!isDigit1 && isDigit2) {
            return NSOrderedAscending;
        }
        return [(NSString*)obj1 compare:obj2 options:NSDiacriticInsensitiveSearch|NSCaseInsensitiveSearch];
    }];
    //NSArray* sortedKeys = [[[assetsGrouped.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] reverseObjectEnumerator] allObjects];
    for (NSString* grp in sortedKeys){//} assetsGrouped.allKeys) {
        //NSArray* tmpp = [assetsGrouped valueForKey:grp];
        PHAssetCollection* tmpp = [assetsGrouped valueForKey:grp];
        //NSInteger cnt = tmpp.estimatedAssetCount;
        NSArray* arr = [[NSArray alloc] initWithObjects:grp,[groupPosters valueForKey:grp],[NSNumber numberWithLong:tmpp.estimatedAssetCount], nil];
        [tmpItems addObject:arr];
    }
    
    if (updateOnly) {
        if(groups){
            groups.items = tmpItems;
            [groups.tableView reloadData];
        }
    }else{
        groups = [[GroupSelectTableViewController alloc] init];
        groups.items = tmpItems;
        groups.caller = self;
        groups.gsType = gsAlbums;
        [[[GlobalRouter sharedManager] getAddAttRouter] showViewInCurrentNavController:groups];
        self.groupsShown = YES;
    }
}

// Show docs - need to show list, then tapped show the preview and attach from there
-(void)needShowDocs
{
    //[[GlobalRouter sharedManager] finishedWithCurrentView:NO];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsPath = [paths objectAtIndex:0];
    
    NSError * error;
    NSArray * directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsPath error:&error];
    // Filter out database files
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"NOT (self CONTAINS '.sqlite' OR self MATCHES 'Gallery')"];
    NSArray *filtered = [directoryContents filteredArrayUsingPredicate:fltr];
    
    groups = [[GroupSelectTableViewController alloc] init];
    groups.items = filtered;
    groups.attReceiver = [[GlobalRouter sharedManager] getAddAttRouter].caller;
    [groups.tableView setEditing:YES]; // Show checkboxes
    groups.gsType = gsiTunesDocs;
    [[[GlobalRouter sharedManager] getAddAttRouter] showViewInCurrentNavController:groups];
}

-(void)needShowAllDocs
{
    UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.content"] inMode:UIDocumentPickerModeImport];
    documentPicker.delegate = viewController;
    documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
    [viewController presentViewController:documentPicker animated:YES completion:^{
        NSLog(@"Presentation done");
    }];
}

-(void)needShowSecureDocs
{
    // Dismiss the image list first?
    
    [[GlobalRouter sharedManager] needAddSecureAttachmentWithCaller:[[GlobalRouter sharedManager] getAddAttRouter].caller];
}

-(void)readGallery
{
    //[CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager]getCurrentView] title:NSLocalizedString(@"Loading...", nil) stopButton:NO];
    assets = [@[] mutableCopy];
    
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {
        //self.showAlert(cancelTitle: nil, buttonTitles:["OK"], title: "Oops", message:"Access to PHPhoto library is denied.")
        return;
    }else{
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if(status == PHAuthorizationStatusAuthorized){
                PHFetchOptions *allPhotosOptions = [PHFetchOptions new];
                allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
                PHFetchResult* res = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:allPhotosOptions];
                int counter = 0;
                for(PHAsset* imAs in res){
                    if(!imAs)continue;
                    [self.assets addObject:imAs];
                    counter++;
                    if(counter == 50){ // update the view to shorten wait time
                        //counter = 0;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self->viewController.collectionView reloadData];
                        });
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->viewController.collectionView reloadData];
                });
            }
        }];
        
        // Get groups
        [self readGroups];
    }
}

-(void)readGroups
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0), ^{
        self->assetsGrouped = [[NSMutableDictionary alloc] init];
        self->groupPosters  = [[NSMutableDictionary alloc] init];
        
        PHFetchOptions *userAlbumsOptions = [PHFetchOptions new];
        userAlbumsOptions.predicate = [NSPredicate predicateWithFormat:@"estimatedAssetCount > 0"];
        
        PHFetchResult *userAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAny options:userAlbumsOptions];
        
        [userAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
            //PHFetchOptions *allPhotosOptions = [PHFetchOptions new];
            //allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
            //PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:collection options:allPhotosOptions];
            [self->assetsGrouped setObject:collection/*result*/ forKey:collection.localizedTitle];
            [self->groupPosters setObject:[UIImage imageNamed:@"calendar"] forKey:collection.localizedTitle];
            //NSLog(@"album title %@, type %ld", collection.localizedTitle, (long)collection.assetCollectionSubtype);
        }];
        
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
            [smartAlbums enumerateObjectsUsingBlock:^(PHAssetCollection *collection, NSUInteger idx, BOOL *stop) {
                //PHFetchOptions *allPhotosOptions = [PHFetchOptions new];
                //allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
                //PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:collection options:allPhotosOptions];
                [self->assetsGrouped setObject:collection forKey:collection.localizedTitle];
                [self->groupPosters setObject:[UIImage imageNamed:@"search"] forKey:collection.localizedTitle];
                //NSLog(@"album title %@", collection.localizedTitle);
            }
        ];
        
        if (self.groupsShown) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self needShowGroups:YES];
            });
        }
    });
}

-(PHFetchResult*)fetchImagesFromGroup:(NSString*)groupName //(PHAssetCollection*)collection
{
    PHAssetCollection* collection = [assetsGrouped valueForKey:groupName];
    PHFetchOptions *allPhotosOptions = [PHFetchOptions new];
    allPhotosOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:collection options:allPhotosOptions];
    
    return result;
}

/*
-(void)readGalleryOld
{
    [CommonProcs showProgressWithTitle:0 max:10 inView:[[GlobalRouter sharedManager]getCurrentView] title:NSLocalizedString(@"Loading...", nil) stopButton:NO];
    assets = [@[] mutableCopy];
    
    // 1
    ALAssetsLibrary *assetsLibrary = [AddAttachmentViewController defaultAssetsLibrary];
    
    assetsGrouped = [[NSMutableDictionary alloc] init];
    groupPosters  = [[NSMutableDictionary alloc] init];
    // 2
    // TODO: Need show camera roll first
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [assetsLibrary enumerateGroupsWithTypes:/-*ALAssetsGroupSavedPhotos*/ /*ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            if (group == nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [CommonProcs setMessageInProgress:NSLocalizedString(@"Sorting...", nil)];
                });
                //NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
                //assets = [NSMutableArray arrayWithArray:[assets sortedArrayUsingDescriptors:@[sort]]];
                
                //dispatch_async(dispatch_get_main_queue(), ^{
                //    [self.collectionView reloadData];
                //});
                
                [CommonProcs hideProgress];
                //[self needShowGroups];
                
            }else{
                int grpType = [[group valueForProperty:ALAssetsGroupPropertyType] intValue];
                if (grpType == ALAssetsGroupEvent || grpType == ALAssetsGroupFaces) {
                    // ignore events and faces
                }else{
                    int num = (int)group.numberOfAssets;
                    __block int i = 0;
                    
                    NSString* groupName = [group valueForProperty:ALAssetsGroupPropertyName];
                    NSMutableArray* tmpAssets = [[NSMutableArray alloc] init];
                    
                    UIImage* image = [UIImage imageWithCGImage:[group posterImage]];
                    
                    [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [CommonProcs setMessageInProgress:[NSString stringWithFormat:@"%@ %@ %d/%d",NSLocalizedString(@"Loading...", nil), [group valueForProperty:ALAssetsGroupPropertyName],  i++, num]];
                        });
                        if(result)
                        {
                            // 3
                            /////[assets addObject:result];
                            [tmpAssets addObject:result];
                        }
                    }];
                    
    //#warning Folders - need select groups!!!
                    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
                    tmpAssets = [NSMutableArray arrayWithArray:[tmpAssets sortedArrayUsingDescriptors:@[sort]]];
                    //[tmpAssets insertObject:image atIndex:0]; // First item is a group poster image
                    [self->groupPosters setObject:image forKey:groupName];
                    [self->assetsGrouped setObject:tmpAssets forKey:groupName];
                    image = nil;
                    // 4
                    //NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
                    if(grpType == ALAssetsGroupSavedPhotos){
                        [self.assets insertObjects:tmpAssets atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, tmpAssets.count)]];
                    }else
                        [self.assets addObjectsFromArray:tmpAssets];//] [NSMutableArray arrayWithArray: [tmpAssets sortedArrayUsingDescriptors:@[sort]]]];
                    //self.assets = tmpAssets;
                    
                    // 5
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self->viewController.collectionView reloadData];
                        //
                    });
                }
            }
        } failureBlock:^(NSError *error) {
            NSLog(@"Error loading images %@", error);
        }];
    });

}
*/
-(void)dismissViewController
{
//#warning why assets are not dismissed?
    viewController.assets = nil;
    viewController.assetsGrouped = nil;
    /// !!!
    //viewController = nil;
    //self.assets = nil;
    //self.assetsGrouped = nil;
    
}

@end
