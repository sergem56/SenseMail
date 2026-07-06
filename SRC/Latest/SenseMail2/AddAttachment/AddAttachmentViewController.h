//
//  AddAttachmentViewController.h
//  SenseMail2
//
//  Created by Sergey on 20.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "CommonStuff.h"
#import <Photos/Photos.h>

@class AddAttachmentPresenter;

@interface AddAttachmentViewController : UIViewController  <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate>
{
    UIBarButtonItem* photoButton;
    UIBarButtonItem* attCount;
    NSString* currentGroup;
}

@property (nonatomic, strong) NSMutableArray* selectedCells;
//@property (nonatomic, strong) UIPopoverController *popOver;

@property(nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property(nonatomic, strong) NSMutableArray *assets;
@property(nonatomic, strong) NSMutableDictionary *assetsGrouped;

@property (nonatomic, weak) id<AddAttachmentReceiver> caller;
@property (nonatomic, weak) AddAttachmentPresenter* presenter;

-(void)resetSelection;
+(PHPhotoLibrary*)defaultAssetsLibrary;

@end
