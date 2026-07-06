//
//  AttCollectionViewCell.h
//  SenseMail2
//
//  Created by Sergey on 20.04.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface AttCollectionViewCell : UICollectionViewCell

@property(nonatomic, strong) ALAsset *asset;
@property(nonatomic, weak) IBOutlet UIImageView *photoImageView;
@property(nonatomic, weak) IBOutlet UILabel *markLabel;

-(IBAction)viewImage:(id)sender;

@end
