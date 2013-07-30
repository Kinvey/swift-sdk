//
//  KCSPlatformUtils.m
//  KinveyKit
//
//  Created by Michael Katz on 7/30/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "KCSPlatformUtils.h"

@implementation KCSPlatformUtils


+ (BOOL) supportsNSURLSession
{
    return NSClassFromString(@"NSURLSession") != nil;
}


@end
