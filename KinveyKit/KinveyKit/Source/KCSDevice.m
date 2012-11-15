//
//  KCSDevice.m
//  KinveyKit
//
//  Created by Michael Katz on 11/2/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSDevice.h"

@implementation KCSDevice

+ (KCSDevice*) currentDevice
{
    static KCSDevice* device;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        device = [[KCSDevice alloc] init];
    });
    return device;
}


- (NSString *)deviceTokenString
{
    NSString *deviceToken = [[self.deviceToken description] stringByReplacingOccurrencesOfString: @"<" withString: @""];
    deviceToken = [deviceToken stringByReplacingOccurrencesOfString: @">" withString: @""] ;
    deviceToken = [deviceToken stringByReplacingOccurrencesOfString: @" " withString: @""];
    return deviceToken;
}


@end
