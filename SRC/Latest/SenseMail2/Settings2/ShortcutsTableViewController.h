//
//  ShortcutsTableViewController.h
//  SenseMailShare
//
//  Created by Sergey on 29.01.2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class Settings2Interactor;
@class SettingsEntity;
@class ShortcutEntity;

@interface ShortcutsTableViewController : UITableViewController <UIGestureRecognizerDelegate>
{
    UISwitch* enableBarSwitch;
    BOOL barEnabled;
    UIBarButtonItem* buttonR;
    UIBarButtonItem* button1;
    UIBarButtonItem* button2;
    NSMutableArray* toDelete;
}
@property (nonatomic, strong) NSMutableArray* items;

@property (nonatomic, strong) SettingsEntity* settings;
@property (nonatomic, weak) Settings2Interactor* interactor;

//@property (nonatomic, weak) IBOutlet UISwitch* enableBarSwitch;

-(void)setUp;

-(void)itemChanged:(ShortcutEntity*)item;

@end

NS_ASSUME_NONNULL_END
