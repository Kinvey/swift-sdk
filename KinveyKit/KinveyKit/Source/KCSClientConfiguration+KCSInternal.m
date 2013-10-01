//
//  KCSClientConfiguration+KCSInternal.m
//  KinveyKit
//
//  Created by Michael Katz on 9/11/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, understand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
//


#import "KCSClientConfiguration+KCSInternal.h"
#import "KinveyCoreInternal.h"

@implementation KCSClientConfiguration (KCSInternal)

- (NSString*) baseURL
{
    NSString* protocol = self.options[@"KCS_HOST_PROTOCOL"];
    NSString* hostname = self.serviceHostname;
    NSString* hostdomain = self.options[@"KCS_HOST_DOMAIN"];
    NSString* port = self.options[@"KCS_HOST_PORT"];
    return [NSString stringWithFormat:@"%@://%@.%@%@/", protocol, hostname, hostdomain, port];
}

- (int)loglevel
{
    int baselevel = [self.options[KCS_LOG_LEVEL] intValue];
    int level = LOG_LEVEL_FATAL;
    switch (baselevel) {
        case 0:
            level = LOG_LEVEL_FATAL;
            break;
        case 1:
            level = LOG_LEVEL_ERROR;
            break;
        case 2:
            level = LOG_LEVEL_WARN;
            break;
        case 3:
            level = LOG_LEVEL_NOTICE;
            break;
        case 4:
            level = LOG_LEVEL_INFO;
            break;
        case 5:
            level = LOG_LEVEL_DEBUG;
            break;
        default:
            level = LOG_LEVEL_DEBUG;
            break;
    }
    return level;
}

- (void) setLoglevel:(int)level
{
    NSMutableDictionary* d = [NSMutableDictionary dictionaryWithDictionary:self.options];
    d[KCS_LOG_LEVEL] = @(level);
    self.options = d;
}

@end
