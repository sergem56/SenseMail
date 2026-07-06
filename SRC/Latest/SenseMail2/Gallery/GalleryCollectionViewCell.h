//
//  GalleryCollectionViewCell.h
//  SenseMail2
//
//  Created by Sergey on 02.06.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GalleryCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UIImageView* image;
@property (nonatomic, strong) NSString *asset;
//@property (nonatomic, strong) NSString* imageKey; // imageKey = asset - renamed it to conform to protocol
@property (nonatomic, weak) IBOutlet UILabel *markLabel;

@end
