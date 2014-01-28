//
//  KCSClientShimTests.m
//  KinveyKit
//
//  Created by Michael Katz on 9/12/13.
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

#import <SenTestingKit/SenTestingKit.h>

#import "KinveyCoreInternal.h"

@interface KCSClientShimTests : SenTestCase

@end

@implementation KCSClientShimTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testConfig
{
    KCSClientConfiguration* config = [KCSClientConfiguration configurationWithAppKey:@"TEST_KEY" secret:@"TEST_SECRET"];
    [[KCSClient sharedClient] initializeWithConfiguration:config];
    
    KCSClient2* c2 = [KCSClient2 sharedClient];
    STAssertEqualObjects(c2.configuration.appKey, @"TEST_KEY", @"match");
    STAssertEqualObjects(c2.configuration.appSecret, @"TEST_SECRET", @"match");
    STAssertEqualObjects(c2.configuration.serviceHostname, @"baas", @"should be a baas");
    
    config.serviceHostname = @"ch";
    [KCSClient sharedClient].configuration = config;
    
    STAssertEqualObjects(c2.configuration.serviceHostname, @"ch", @"match");
}

@end
