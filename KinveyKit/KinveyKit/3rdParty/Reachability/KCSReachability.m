// KCSReachability.m
// KinveyKit
//
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


#import "KCSReachability.h"
#import "KCS_KSReachability.h"

NSString* const KCSReachabilityChangedNotification = kDefaultNetworkReachabilityChangedNotification;

@interface KCSReachability ()
@property (strong) KCS_KSReachability* reachability;
@end

@interface KCSUnreachable : KCSReachability
@end
@implementation KCSUnreachable

- (BOOL)isReachable
{
    return NO;
}

- (BOOL)isReachableViaWiFi
{
    return NO;
}

- (BOOL)isReachableViaWWAN
{
    return NO;
}
@end

@implementation KCSReachability

+ (instancetype) reachabilityForInternetConnection
{
    return [[KCSReachability alloc] initWithReachability:[KCS_KSReachability reachabilityToLocalNetwork]];
}

+ (instancetype) reachabilityWithHostName:(NSString *)hostName
{
    KCS_KSReachability* reachability = [KCS_KSReachability reachabilityToHost:hostName];
    reachability.notificationName = KCSReachabilityChangedNotification;
    return [[KCSReachability alloc] initWithReachability:reachability];
}

+ (instancetype) unreachableReachability
{
    return [[KCSUnreachable alloc] init];
}

- (instancetype) initWithReachability:(KCS_KSReachability*)reachability
{
    self = [super init];
    if (self) {
        _reachability = reachability;
    }
    return self;
}

- (BOOL)isReachable
{
    return !_reachability.initialized || _reachability.reachable;
}

- (BOOL)isReachableViaWWAN
{
    return !_reachability.initialized || _reachability.WWANOnly;
}

- (BOOL) isReachableViaWiFi
{
    return !_reachability.initialized || (_reachability && !_reachability.WWANOnly);
}

@end
