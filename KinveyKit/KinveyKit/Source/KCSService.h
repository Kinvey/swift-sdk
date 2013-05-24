//
//  KCSService.h
//  KinveyKit
//
//  Created by Michael Katz on 5/23/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KCSRequest.h"

@protocol KCSService <NSObject>

- (void) startRequest:(KCSNetworkRequest*)request;

@end

