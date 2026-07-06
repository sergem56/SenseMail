//
//  AddAttachmentPresenter.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class AddAttachmentViewController;
@class GroupSelectTableViewController;

@interface AddAttachmentPresenter : NSObject{
    AddAttachmentViewController* viewController;
    GroupSelectTableViewController* groups;
}

@property(nonatomic, strong) NSMutableArray *assets;
@property(nonatomic, strong) NSMutableDictionary *assetsGrouped; // group name + assets array
@property(nonatomic, strong) NSMutableDictionary *groupPosters;
@property (nonatomic, strong) NSString* currentGroup;
@property (nonatomic, assign) BOOL groupsShown;

-(AddAttachmentViewController*)showView;
-(void)showGroup:(NSString*)group;
-(void)needShowGroups;
-(void)needShowDocs;
-(void)needShowAllDocs;
-(void)needShowSecureDocs;

-(void)dismissViewController;
-(void)setGroupsShown:(BOOL)groupsShown;

@end
