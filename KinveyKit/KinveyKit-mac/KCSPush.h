//
//  KCSPush.h
//  KinveyKit
//
//  Created by Michael Katz on 8/13/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCSPush : NSObject

+ (instancetype) sharedPush;
- (void) registerDeviceToken:(void (^)(BOOL success, NSError* error))completionBlock;
@end
