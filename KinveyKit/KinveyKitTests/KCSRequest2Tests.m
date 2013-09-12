//
//  KCSRequest2Tests.m
//  KinveyKit
//
//  Created by Michael Katz on 8/23/13.
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
#import "TestUtils2.h"

@interface KCSRequest2Tests : SenTestCase

@end

@implementation KCSRequest2Tests

- (void)setUp
{
    [super setUp];
    [self setupKCS];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testQueuesAreSame
{
    dispatch_queue_t startQ = dispatch_get_current_queue();
    
    KCSRequest2* request = [KCSRequest2 requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        
        dispatch_queue_t endQ = dispatch_get_current_queue();
        STAssertEquals(startQ, endQ, @"queues should match");
        
        KTPollDone
    } route:KCSRESTRouteAppdata options:@{KCSRequestOptionUseMock: @(YES), KCSRequestLogMethod} credentials:mockCredentails()];
    [request start];
    KTPollStart
}

- (void) testMethodAnayltics
{
    KCSRequest2* request = [KCSRequest2 requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        STAssertNotNil(response, @"need response");
        NSDictionary* headers = response.headers;
        NSString* method = headers[@"X-Kinvey-Client-Method"];
        STAssertNotNil(method, @"should have the method");
        STAssertEqualObjects(method, NSStringFromSelector(_cmd), @"should be this method");
        
        KTPollDone
    } route:KCSRestRouteTestReflection options:@{KCSRequestOptionUseMock: @(YES), KCSRequestLogMethod} credentials:mockCredentails()];
    [request start];
    KTPollStart
}

@end
