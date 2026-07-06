//
//  MessageInfoInteractor.h
//  SenseMailShare
//
//  Created by Sergey on 02.02.2018.
//  Copyright © 2018 Sergey. All rights reserved.
//


// New concept - see OneTimeCertInteractor for more details

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class MessageInfoViewController;

@interface MessageInfoInteractor : NSObject
{
    MessageInfoViewController* viewController;
}

@property (nonatomic, weak) NSString* messageToShow;

-(int)presentViewInNavController:(UINavigationController*)nav messageInfo:(NSString*)info;

@end
