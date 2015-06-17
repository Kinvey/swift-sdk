//
//  KCSMICViewController.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-06-16.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KinveyUser.h"

@interface KCSMICViewController : UIViewController

-(instancetype)initWithRedirectURI:(NSString*)redirectURI
               withCompletionBlock:(KCSUserCompletionBlock)completionBlock;

@end
