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
    
//TODO:
//    NSDictionary *deviceInfo = [self deviceInformation];
//    NSString *headerString = [NSString stringWithFormat:@"%@/%@ %@ %@ %@",
//                              [[deviceInfo objectForKey:@"model"] stringByReplacingOccurrencesOfString:@" " withString:@"_"],
//                              [[deviceInfo objectForKey:@"platform"] stringByReplacingOccurrencesOfString:@" " withString:@"_"],
//                              [[deviceInfo objectForKey:@"systemName"] stringByReplacingOccurrencesOfString:@" " withString:@"_"],
//                              [[deviceInfo objectForKey:@"systemVersion"] stringByReplacingOccurrencesOfString:@" " withString:@"_"],
//                              [self.UDID stringByReplacingOccurrencesOfString:@" " withString:@"_"]];
//    
//    return headerString;
    return @"";
}

@end
