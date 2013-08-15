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
    static BOOL supports;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
         supports = NSClassFromString(@"NSURLSession") != nil;
    });
    return supports;
}


@end
