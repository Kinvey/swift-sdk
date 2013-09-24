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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    dispatch_queue_t startQ = dispatch_get_current_queue();
    KCSRequest2* request = [KCSRequest2 requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        
        dispatch_queue_t endQ = dispatch_get_current_queue();
#pragma clang diagnostic pop
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
        STAssertEqualObjects(method, @"KCSRequest2Tests testMethodAnayltics", @"should be this method");
        
        KTPollDone
    } route:KCSRestRouteTestReflection options:@{KCSRequestOptionUseMock: @(YES), KCSRequestLogMethod} credentials:mockCredentails()];
    [request start];
    KTPollStart
}

- (void) testPath
{
    NSArray* path =  @[@"1",@"2"];
    KCSRequest2* request = [KCSRequest2 requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        STAssertNotNil(response, @"need response");
        NSURL* url = response.originalURL;
        STAssertNotNil(url, @"needed url");

        NSArray* components = [url pathComponents];
        NSArray* lastComponents = [components subarrayWithRange:NSMakeRange(components.count - 2, 2)];
        KTAssertCount(2, lastComponents);
        STAssertEqualObjects(lastComponents, path, @"should match");
        
        KTPollDone
    } route:KCSRestRouteTestReflection options:@{KCSRequestOptionUseMock: @(YES), KCSRequestLogMethod} credentials:mockCredentails()];
    request.path = path;
    [request start];
    KTPollStart
}

- (void) testRetryKCS
{
    KCSNetworkResponse* retryResponse = createMockErrorResponse(@"KinveyInternalErrorRetry", nil, nil, 500);
    [[KCSMockServer sharedServer] setResponse:retryResponse forRoute:@"appdata/:kid/foo"];

    LogTester* tester = [LogTester sharedInstance];
    [tester clearLogs];
    
    NSArray* path =  @[@"foo"];
    KCSRequest2* request = [KCSRequest2 requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        NSArray* logs = tester.logs;
        NSArray* retries = [logs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
            return [evaluatedObject hasPrefix:@"Retrying"];
        }]];
        KTAssertCount(5, retries);
        KTPollDone
    } route:KCSRESTRouteAppdata options:@{KCSRequestOptionUseMock: @(YES), KCSRequestLogMethod} credentials:mockCredentails()];
    request.path = path;
    [request start];
    KTPollNoAssert
}

- (void) testRetryCFNetwork
{
    KTNIY
}


@end
