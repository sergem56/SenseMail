//
//  AttCollectionViewCell.m
//  SenseMail2
//
//  Created by Sergey on 20.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import "AttCollectionViewCell.h"
#import "GlobalRouter.h"

@implementation AttCollectionViewCell

- (void) setAsset:(PHAsset *)asset
{
    _asset = asset;
    //self.photoImageView.image = [UIImage imageWithCGImage:[asset thumbnail]];
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.resizeMode = PHImageRequestOptionsResizeModeExact;
    
    NSInteger retinaMultiplier = [UIScreen mainScreen].scale;
    CGSize retinaSquare = CGSizeMake(self.photoImageView.bounds.size.width * retinaMultiplier, self.photoImageView.bounds.size.height * retinaMultiplier);
    
    [[PHImageManager defaultManager]
     requestImageForAsset:(PHAsset *)_asset
     targetSize:retinaSquare
     contentMode:PHImageContentModeAspectFill
     options:options
     resultHandler:^(UIImage *result, NSDictionary *info) {
         self.photoImageView.image =[UIImage imageWithCGImage:result.CGImage scale:retinaMultiplier orientation:result.imageOrientation];
         
     }];
}

-(IBAction)viewImage:(id)sender
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[GlobalRouter sharedManager] needShowAttachment:self.asset atIndex:0 showSaveButton:YES];
    });
}

@end
