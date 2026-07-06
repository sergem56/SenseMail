//
//  Settings2GeneralCell.m
//  SenseMailShare
//
//  Created by Sergey on 06.12.2019.
//  Copyright © 2019 Sergey. All rights reserved.
//

#import "Settings2GeneralCell.h"

@implementation Settings2GeneralCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    // Make the spacing a bit more, since the rows are too tight in the menu
    [self.contentView setFrame:CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height+8)];
}

@end
