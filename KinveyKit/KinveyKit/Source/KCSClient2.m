//
//  KCSClient2.m
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


#import "KCSClient2.h"

#import "KinveyCoreInternal.h"

KK2(remove import)
@interface KCSLogManager : NSObject
+ (KCSLogManager *)sharedLogManager;
- (BOOL) networkLogging;
@end

@implementation KCSClient2

+ (instancetype)sharedClient
{
    static KCSClient2 *sKCSClient;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sKCSClient = [[self alloc] init];
        NSAssert(sKCSClient != nil, @"Unable to instantiate KCSClient");
    });
    
    return sKCSClient;
}


- (instancetype) init
{
    self = [super init];
    if (self) {
        if ([[KCSLogManager sharedLogManager] networkLogging] == YES) {
            KK2(Use log sink)
            [DDLog addLogger:[DDASLLogger sharedInstance]];
            [DDLog addLogger:[DDTTYLogger sharedInstance]];
        }
    }
    return self;
}

- (KCSClientConfiguration *)configuration
{
    KK2(make our own);
    return [[KCSClient sharedClient] configuration];
}

@end
