//
//  KCSMockServerTest.m
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


#import <SenTestingKit/SenTestingKit.h>

#import "KCSMockServer.h"
#import "KinveyCoreInternal.h"
#import "TestUtils2.h"

@interface KCSMockServer (TEST)
- (KCSNetworkResponse*) responseForURL:(NSString*)urlStr;
@end
@implementation KCSMockServer (TEST)

- (KCSNetworkResponse *)responseForURL:(NSString *)urlStr
{
    NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    return [self responseForRequest:req];
}

@end

@interface KCSMockServerTest : SenTestCase
@property (nonatomic, strong) KCSMockServer* server;
@end

@implementation KCSMockServerTest

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
    _server = [[KCSMockServer alloc] init];
    _server.appKey = @"kid_test";
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}


- (void) testNoURL
{
    KCSNetworkResponse* x = [_server responseForURL:@"http://v3yk1n.kinvey.com/foo/kid_test/a/b/c"];
    KTAssertNotNil(x);
    KTAssertEqualsInt(x.code, 404);
}

- (void) testAppdataBasic
{
    NSDictionary* data = @{@"_id":@1, @"key":@"value"};
    KCSNetworkResponse* response = [KCSNetworkResponse MockResponseWith:200 data:data];
    [_server setResponse:response forRoute:@"/appdata/kid_test/collection/1"];
    KCSNetworkResponse* r1 = [_server responseForURL:@"http://foo.bar.com/appdata/kid_test/collection/1"];
    KTAssertNotNil(r1);
    KTAssertEqualsInt(r1.code, 200);
    STAssertEqualObjects(r1.jsonData, data, @"data should match previous");
}

- (void) testPing
{
    KCSNetworkResponse* x = [_server responseForURL:@"http://v3yk1n.kinvey.com/appdata/kid_test"];
    KTAssertNotNil(x);
    KTAssertEqualsInt(x.code, 200);
}

- (void) testBadCreds
{
    
    KCSNetworkResponse* x = [_server responseForURL:@"http://v3yk1n.kinvey.com/appdata/kid_fail"];
    KTAssertNotNil(x);
    KTAssertEqualsInt(x.code, 401);
    STAssertEqualObjects(x.jsonData[@"error"], @"InvalidCredentials", @"should be an invalid creds error");
}

- (void) testReflection
{
    NSMutableURLRequest* req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://v3yk1n.kinvey.com/!reflection/kid_test"]];
    NSDictionary* headers = @{@"A":@"B"};
    req.allHTTPHeaderFields = headers;
    id body = @[@"A",@{@"K":@1}];
    req.HTTPBody = [[[KCS_SBJsonWriter alloc] init] dataWithObject:body];
    
    KCSNetworkResponse* x = [_server responseForRequest:req];
    KTAssertNotNil(x);
    KTAssertEqualsInt(x.code, 200);
    STAssertEqualObjects(x.jsonData, body, @"body must match");
    STAssertEqualObjects(x.headers, headers, @"headers must match");
}

@end
