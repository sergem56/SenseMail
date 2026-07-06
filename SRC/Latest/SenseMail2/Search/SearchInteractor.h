//
//  searchInteractor.h
//  SenseMailShare
//
//  Created by Sergey on 21.09.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//

// http://libmailcore.com/api/objc/Classes/MCOIMAPSearchExpression.html#//api/name/searchAll
// Search ideas:
// In a top text field search for:
//  - from and mail body (doesn't matter if it's encrypted, there might be some plain-text messages
//  - date received - suggest date received, date before, date after
//  -
//
// In a table view show search for:
//  - unread
//  - messages with attachments
//  - flagged
//  - answered
//  - large messages
//  -


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "CommonStuff.h"

@class SearchViewController;

NS_ASSUME_NONNULL_BEGIN

@interface SearchInteractor : NSObject

@property (nonatomic, strong, nullable) SearchViewController* vc;


-(void)showSearchInVC:(UINavigationController *)nav;
-(void)cancelSearch;
-(void)doSearch;
-(void)searchWithType:(searchTypes)type text:(NSString*)text;

-(void)searchStringChanged:(NSString*)searchStr;

@end

NS_ASSUME_NONNULL_END
