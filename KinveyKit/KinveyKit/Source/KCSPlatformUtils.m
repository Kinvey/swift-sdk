//
//  KCSPlatformUtils.m
//  KinveyKit
//
//  Created by Michael Katz on 7/30/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "KCSPlatformUtils.h"

#import <UIKit/UIKit.h>

// For hardware platform information
#include <sys/types.h>
#include <sys/sysctl.h>

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

// From: http://www.cocos2d-iphone.org/forum/topic/21923
// NB: This is not 100% awesome and needs cleaned up
+ (NSString *) platform {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    return platform;
}


+ (NSString*) platformString
{
    UIDevice* device = [UIDevice currentDevice];
    return [NSString stringWithFormat:@"%@/%@ %@ %@", device.model, [self platform], device.systemName, device.systemVersion];
}

@end
