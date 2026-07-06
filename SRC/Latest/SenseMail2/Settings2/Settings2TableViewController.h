//
//  Settings2TableViewController.h
//  SenseMailShare
//
//  Created by Sergey on 06.12.2019.
//  Copyright © 2019 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Settings2Interactor;
@class SettingsEntity;

NS_ASSUME_NONNULL_BEGIN

@interface Settings2TableViewController : UITableViewController
@property (nonatomic, strong) Settings2Interactor* interactor;
@property (nonatomic, strong, nullable) SettingsEntity* generalSettings;

@property (nonatomic, strong) NSArray* generalItems;
@property (nonatomic, strong) NSArray* generalItemsDetails;
@property (nonatomic, strong) NSArray* generalItemsImages;
@property (nonatomic, strong) NSMutableArray* accountItems; // of SettingEntity

@end

NS_ASSUME_NONNULL_END
