//
//  SecurityTableViewController.h
//  SenseMailShare
//
//  Created by Sergey on 10.12.2019.
//  Copyright © 2019 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class Settings2Interactor;
@class SettingsEntity;

@interface SecurityTableViewController : UITableViewController
{
    BOOL bioSet;
    BOOL bgCheck;
    BOOL clearBG;
    BOOL doNotHide;
    UITextField* erasePin;
}

@property (nonatomic, strong) SettingsEntity* settings;
@property (nonatomic, weak) Settings2Interactor* interactor;

-(void)setUp;

@end

NS_ASSUME_NONNULL_END
