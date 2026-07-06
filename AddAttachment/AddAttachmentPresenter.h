//
//  AddAttachmentPresenter.h
//  SenseMail2
//
//  Created by Sergey on 06.03.15.
//  Copyright (c) 2015 Sergey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AddAttachmentViewController;

@interface AddAttachmentPresenter : NSObject{
    AddAttachmentViewController* viewController;
}

-(AddAttachmentViewController*)showView;

@end
