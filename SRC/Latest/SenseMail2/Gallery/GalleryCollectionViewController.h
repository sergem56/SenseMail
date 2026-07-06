//
//  GalleryCollectionViewController.h
//  SenseMail2
//
//  Created by Sergey on 02.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonStuff.h"

@class GalleryPresenter;

@interface GalleryCollectionViewController : UICollectionViewController <UIGestureRecognizerDelegate, UIAlertViewDelegate>{
    CGPoint loc;
}

// This feature is a bit complicated to implement, maybe I'll do it later on...
// Protocol AddAttachmentReceiver expects array of ALAssets but here i've got
// an array of paths to encrypted files.
// However, all the stuff with this class is done. Now it's a ComposeMessage's turn...
@property (nonatomic) NSMutableArray* selectedCells;
@property (nonatomic) NSMutableDictionary* selectedCellsPaths;
@property (nonatomic, weak) id<AddAttachmentReceiver> caller;

@property (nonatomic, weak) GalleryPresenter* presenter;
@property (nonatomic, strong) NSMutableDictionary* items;
@property (nonatomic, strong) NSMutableArray* sortedKeys;

@property (nonatomic, retain) UILabel* bgLabel;

@end
