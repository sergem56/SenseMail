//
//  OTCTableViewCell.h
//  SenseMailShare
//
//  Created by Sergey on 16/01/2019.
//  Copyright © 2019 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OTCTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel* textLabelC;
@property (nonatomic, strong) IBOutlet UILabel* detailTextLabelC;
@property (nonatomic, strong) IBOutlet UIImageView* imageViewC;

@end

NS_ASSUME_NONNULL_END
