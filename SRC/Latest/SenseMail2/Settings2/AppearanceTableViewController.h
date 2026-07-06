//
//  AppearanceTableViewController.h
//  SenseMailShare
//
//  Created by Sergey on 10.12.2019.
//  Copyright © 2019 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonStuff.h"

NS_ASSUME_NONNULL_BEGIN

@class Settings2Interactor;
@class SettingsEntity;

@interface AppearanceTableViewController : UITableViewController <UIGestureRecognizerDelegate>
{
    int nToLoad;
    BOOL largeFont;
    float JPEGCompression;
    listSortOrder sorting;
    UITextField* nToLoadTF;
    UISwitch* largeFontSwitch;
    UISlider* compressionSlider;
    UILabel* compressionValue;
    UITextField* silentFrom;
    UITextField* silentTo;
    UIDatePicker* pickerFrom;
    UIDatePicker* pickerTo;
    NSDate* dFrom;
    NSDate* dTo;
}

@property (nonatomic, strong) SettingsEntity* settings;
@property (nonatomic, weak) Settings2Interactor* interactor;

-(void)setUp;

@end

NS_ASSUME_NONNULL_END
