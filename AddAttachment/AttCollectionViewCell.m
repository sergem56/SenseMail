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

- (void) setAsset:(ALAsset *)asset
{
    _asset = asset;
    self.photoImageView.image = [UIImage imageWithCGImage:[asset thumbnail]];
}

-(IBAction)viewImage:(id)sender
{
    [[GlobalRouter sharedManager] needShowAttachment:self.asset];
}

@end
