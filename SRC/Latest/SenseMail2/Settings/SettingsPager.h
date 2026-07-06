//
//  SettingsPager.h
//  SenseMailShare
//
//  Created by Sergey on 08.07.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PageViewController.h"

@interface SettingsPager : PageViewController{
    dispatch_block_t pageLeaved;
}

@property (nonatomic, retain) UIBarButtonItem* buttonDel;

@property (nonatomic, assign) BOOL needAddAccount;

@property (nonatomic, strong) NSString* email;
@property (nonatomic, strong) NSString* password;

@end
