//
//  GroupSelectTableViewController.h
//  SenseMailShare
//
//  Created by Sergey on 18.11.15.
//  Copyright © 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>
#import <Photos/Photos.h>
#import "CommonStuff.h"

@class AddAttachmentPresenter;

typedef NS_ENUM(NSInteger, gsDialogType){
    gsAlbums,
    gsiTunesDocs
};

@interface GroupSelectTableViewController : UITableViewController <QLPreviewControllerDataSource,QLPreviewControllerDelegate>

@property (nonatomic, weak) AddAttachmentPresenter* caller;
@property (nonatomic, weak) id<AddAttachmentReceiver> attReceiver;
@property (nonatomic, strong) NSArray* items; // item = array -> name+image
@property (nonatomic, assign) gsDialogType gsType;

@end
