//
//  TestUtils2.m
//  KinveyKit
//
//  Created by Michael Katz on 8/15/13.
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


#import "TestUtils2.h"
#import <objc/runtime.h>
#import "KinveyCoreInternal.h"

#import "KCSClient.h"

#define POLL_INTERVAL 0.05
#define MAX_POLL_COUNT 30 / POLL_INTERVAL

#define STAGING_ALPHA @"alpha"
#define STAGING_V3YK1N @"v3yk1n"

#define STAGING_API STAGING_V3YK1N


@interface MockCredentials : NSObject <KCSCredentials>

@end
@implementation MockCredentials

- (NSString *)authString
{
    return @"";
}

@end

id<KCSCredentials> mockCredentails()
{
    return [[MockCredentials alloc] init];
}

@implementation SenTestCase (TestUtils2)
@dynamic done;

- (BOOL) poll
{
    int pollCount = 0;
    while (self.done == NO && pollCount < MAX_POLL_COUNT) {
        NSLog(@"polling... %4.2fs", pollCount * POLL_INTERVAL);
        NSRunLoop* loop = [NSRunLoop mainRunLoop];
        NSDate* until = [NSDate dateWithTimeIntervalSinceNow:POLL_INTERVAL];
        [loop runUntilDate:until];
        pollCount++;
    }
    return pollCount == MAX_POLL_COUNT;
}

- (BOOL)done {
    return [objc_getAssociatedObject(self, @"doneval") boolValue];
}

- (void)setDone:(BOOL)newDone {
    objc_setAssociatedObject(self, @"doneval", [NSNumber numberWithBool:newDone], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Kinvey

- (void) setupStaging
{
    (void)[[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid10005"
                                                       withAppSecret:@"8cce9613ecb7431ab580d20863a91e20"
                                                        usingOptions:@{KCS_LOG_LEVEL              : @255,
                                                                       KCS_LOG_ADDITIONAL_LOGGERS : @[[LogTester sharedInstance]]}];
    [[KCSClient sharedClient].configuration setServiceHostname:STAGING_API];
    
}
- (void) setupProduction
{
    (void)[[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid1880"
                                                       withAppSecret:@"6414992408f04132bd467746f7ecbdcf"
                                                        usingOptions:@{KCS_LOG_LEVEL              : @255,
                                                                       KCS_LOG_ADDITIONAL_LOGGERS : @[[LogTester sharedInstance]]}];
    
}

- (void)setupKCS
{
    [self setupStaging];
}

- (void) useMockUser
{
    KCSUser* mockUser = [[KCSUser alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    [KCSClient sharedClient].currentUser = mockUser;
#pragma clang diagnostic pop
}

@end

@implementation TestUtils2

@end
