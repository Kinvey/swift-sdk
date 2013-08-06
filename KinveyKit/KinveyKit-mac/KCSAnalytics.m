//
//  KCSAnalytics.m
//  KinveyKit
//
//  Created by Michael Katz on 1/30/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "KCSAnalytics.h"

@implementation KCSAnalytics

- (instancetype)init
{
    self = [super init];
    if (self){
        _analyticsHeaderName = @"X-Kinvey-Device-Information";
    }
    return self;
}

- (BOOL)supportsUDID
{
    return NO;
}

- (NSDictionary *)deviceInformation
{
    UIDevice *cd = [UIDevice currentDevice];
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    
    // Available Features
    [d setObject:@(cd.multitaskingSupported) forKey:@"multitaskingSupported"];
    
    // Identifying Device / OS
    [d setObject:cd.name forKey:@"name"];
    [d setObject:cd.systemName forKey:@"systemName"];
    [d setObject:cd.systemVersion forKey:@"systemVersion"];
    [d setObject:cd.model forKey:@"model"];
    [d setObject:cd.localizedModel forKey:@"localizedModel"];
    [d setObject:[self platform] forKey:@"platform"];
    
    // Device Orientation
    [d setObject:@(cd.orientation) forKey:@"orientation"];
    [d setObject:@(cd.generatesDeviceOrientationNotifications) forKey:@"generatesDeviceOrientationNotifications"];
    
    
    // Battery
    [d setObject:@(cd.batteryLevel) forKey:@"batteryLevel"];
    [d setObject:@(cd.batteryMonitoringEnabled) forKey:@"batteryMonitoringEnabled"];
    [d setObject:@(cd.batteryState) forKey:@"batteryState"];
    
    
    // Proximity Sensor State
    [d setObject:@(cd.proximityMonitoringEnabled) forKey:@"proximityMonitoringEnabled"];
    [d setObject:@(cd.proximityState) forKey:@"proximityState"];
    
    // Record timestamp of when data was collected
    [d setObject:@([NSDate timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970) forKey:@"timestamp"];
    
    return d;
}

- (NSString *)headerString
{
    /*
     * Model: The hardware model that's making the request
     * Platform: The platform of the device making the request
     * SystemName: The name of the system making the request
     * SystemVersion: The version of the system making the request
     * UDID: The unique device ID making the request
     */
    // Switch spaces to '_', space separate them in the following order
    // model name SystemName SystemVersion
    
    NSDictionary *deviceInfo = [self deviceInformation];
    NSString *headerString = [NSString stringWithFormat:@"%@/%@ %@ %@ %@",
                              [[deviceInfo objectForKey:@"model"] stringByReplacingOccurrencesOfString:@" " withString:@"_"],
                              [[deviceInfo objectForKey:@"platform"] stringByReplacingOccurrencesOfString:@" " withString:@"_"],
                              [[deviceInfo objectForKey:@"systemName"] stringByReplacingOccurrencesOfString:@" " withString:@"_"],
                              [[deviceInfo objectForKey:@"systemVersion"] stringByReplacingOccurrencesOfString:@" " thString:@"_"],
                              [self.UDID stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
    
    return headerString;
}

@end
