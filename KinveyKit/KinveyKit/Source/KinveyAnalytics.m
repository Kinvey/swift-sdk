//
//  KinveyAnalytics.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/9/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KinveyAnalytics.h"
#import "KCSKinveyUDID.h"

// For hardware platform information
#include <sys/types.h>
#include <sys/sysctl.h>


@implementation KCSAnalytics

@synthesize UUID=_UUID;
@synthesize UDID=_UDID;
@synthesize analyticsHeaderName = _analyticsHeaderName;

- (id)init
{
    self = [super init];
    if (self){
        _UDID = [[KCSKinveyUDID uniqueIdentifier] retain];//[[[UIDevice currentDevice] uniqueIdentifier] retain];
        _UUID = nil;
        _analyticsHeaderName = [[NSString stringWithString:@"X-Kinvey-Device-Information"] retain];
    }
    return self;
}

- (void)dealloc
{
    [_UDID release];
    [_UUID release];
    [_analyticsHeaderName release];
    [super dealloc];
}

- (NSString *)generateUUID
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uuidString = nil;
    
    if (uuid){
        uuidString = (NSString *)CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
    }
    // CreateString creates the string, so we own this string.
    // We must ensure it gets destroyed
    return [uuidString autorelease];
}

// Always return the same UUID for all users.
- (NSString *)UUID
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:KCS_UUID_USER_DEFAULTS_KEY] == nil) {
        [defaults setObject:[self generateUUID] forKey:KCS_UUID_USER_DEFAULTS_KEY];
        [defaults synchronize];
    }
    
    // Return the stored version
    return [defaults objectForKey:KCS_UUID_USER_DEFAULTS_KEY];

}

- (NSDictionary *)deviceInformation
{
    UIDevice *cd = [UIDevice currentDevice];
    NSMutableDictionary *d = [NSMutableDictionary dictionary];

    // Available Features
    [d setObject:[NSNumber numberWithBool:cd.multitaskingSupported] forKey:@"multitaskingSupported"];
    
    // Identifying Device / OS
    [d setObject:cd.name forKey:@"name"];
    [d setObject:cd.systemName forKey:@"systemName"];
    [d setObject:cd.systemVersion forKey:@"systemVersion"];
    [d setObject:cd.model forKey:@"model"];
    [d setObject:cd.localizedModel forKey:@"localizedModel"];
    [d setObject:[self platform] forKey:@"platform"];

    // Device Orientation
    [d setObject:[NSNumber numberWithInt:cd.orientation] forKey:@"orientation"];
    [d setObject:[NSNumber numberWithBool:cd.generatesDeviceOrientationNotifications]
          forKey:@"generatesDeviceOrientationNotifications"];
    
    
    // Battery
    [d setObject:[NSNumber numberWithFloat:cd.batteryLevel] forKey:@"batteryLevel"];
    [d setObject:[NSNumber numberWithBool:cd.batteryMonitoringEnabled] forKey:@"batteryMonitoringEnabled"];
    [d setObject:[NSNumber numberWithInt:cd.batteryState] forKey:@"batteryState"];
    
    
    // Proximity Sensor State
    [d setObject:[NSNumber numberWithBool:cd.proximityMonitoringEnabled] forKey:@"proximityMonitoringEnabled"];
    [d setObject:[NSNumber numberWithBool:cd.proximityState] forKey:@"proximityState"];
    
    // Record timestamp of when data was collected
    [d setObject:[NSNumber numberWithDouble:[NSDate timeIntervalSinceReferenceDate] + NSTimeIntervalSince1970]
          forKey:@"timestamp"];
    
    return d;
}


// From: http://www.cocos2d-iphone.org/forum/topic/21923
// NB: This is not 100% awesome and needs cleaned up
- (NSString *) platform{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    return platform;
}


- (NSString *)headerString
{
    /*
     * Model: The hardware model that's making the request
     * Name: The name of the device making the request
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
                              [[deviceInfo objectForKey:@"systemVersion"] stringByReplacingOccurrencesOfString:@" " withString:@"_"],
                              [self.UDID stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
    
    return headerString;
}

@end
