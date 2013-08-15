//
//  KCSPush.m
//  KinveyKit
//
//  Created by Michael Katz on 8/13/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "KCSPush.h"

@implementation KCSPush

+ (instancetype)sharedPush
{
    return nil;
}

- (void) registerDeviceToken:(void (^)(BOOL success, NSError* error))completionBlock
{
    completionBlock(NO, nil);
}
@end
