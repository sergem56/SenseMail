//
//  EditShortcutTableViewController.h
//  SenseMailShare
//
//  Created by Sergey on 30.01.2020.
//  Copyright © 2020 Sergey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CommonStuff.h"

@class ShortcutsTableViewController;
@class ShortcutEntity;

NS_ASSUME_NONNULL_BEGIN

@interface EditShortcutTableViewController : UITableViewController <selectedFolderReceiver>
{
    UITextField* nameField;
    NSMutableArray* commandItems;
    int selectedCommand;
    NSMutableDictionary* alteredText;
    NSString* customFolder;
    
    UIToolbar* inputTB;
}

@property (nonatomic, weak) ShortcutsTableViewController* parentVC;
@property (nonatomic, strong, nullable) ShortcutEntity* item; 
  
+(NSArray*)getCommandDescription:(NSString*)command;

@end

NS_ASSUME_NONNULL_END
