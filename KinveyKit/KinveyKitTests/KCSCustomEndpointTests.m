//
//  KCSCustomEndpointTests.m
//  KinveyKit
//
//  Created by Michael Katz on 5/30/13.
//  Copyright (c) 2013-2014 Kinvey. All rights reserved.
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


#import "KCSCustomEndpointTests.h"

#import "TestUtils.h"
#import "KCSCustomEndpoints.h"

@implementation KCSCustomEndpointTests

- (void)setUp
{
    BOOL loaded = [TestUtils setUpKinveyUnittestBackend:self];
    XCTAssertTrue(loaded, @"should be loaded");
}

- (void) testCustomEndpoint
{
    XCTestExpectation* expectationCallEndpoint = [self expectationWithDescription:@"callEndpoint"];
    [KCSCustomEndpoints callEndpoint:@"bltest" params:nil completionBlock:^(id results, NSError *errorOrNil) {
        STAssertNoError;
        NSDictionary* expBody = @{@"a":@1,@"b":@2};
        XCTAssertEqualObjects(expBody, results, @"bodies should match");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationCallEndpoint fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testHS1468
{
    XCTestExpectation* expectationCallEndpoint = [self expectationWithDescription:@"callEndpoint"];
    [KCSCustomEndpoints callEndpoint:@"hs1468" params:@{@"email":@""} completionBlock:^(id results, NSError *error) {
        XCTAssertNil(error, @"error should be nil");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationCallEndpoint fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testHS1928_CallDoesNotInitCurrentUser
{
    [[KCSUser activeUser] logout];
    XCTAssertNil([KCSUser activeUser], @"user should be nil'd");
    dispatch_block_t call = ^{
        [KCSCustomEndpoints callEndpoint:@"bltest" params:nil completionBlock:^(id results, NSError *errorOrNil) {
            XCTAssertNotNil(errorOrNil, @"should have an error");
            KTAssertEqualsInt(errorOrNil.code, 401, @"no auth error");
            
            XCTAssertTrue([NSThread isMainThread]);
            
            self.done = YES;
        }];
    };
    XCTAssertThrowsSpecificNamed(call(), NSException, NSInternalInconsistencyException, @"should be an exception");
}

- (void) testCustomEndpointError
{
    XCTestExpectation* expectationCallEndpoint = [self expectationWithDescription:@"callEndpoint"];
    [KCSCustomEndpoints callEndpoint:@"bltest-notexist" params:nil completionBlock:^(id results, NSError *errorOrNil) {
        XCTAssertNotNil(errorOrNil, @"should have an error");
        //        STAssertEqualObjects(errorOrNil.domain, KCSBusinessLogicErrorDomain, @"Should be a bl error");
        NSString* url = errorOrNil.userInfo[NSURLErrorFailingURLErrorKey];
        XCTAssertNotNil(url, @"should list the URL");
        KTAssertEqualsInt(errorOrNil.code, 404, @"should be a 400 Not Found");
        
        XCTAssertTrue([NSThread isMainThread]);
        
        [expectationCallEndpoint fulfill];
    }];
    [self waitForExpectationsWithTimeout:30 handler:nil];
}

- (void) testChecksBadInputs
{
    dispatch_block_t block = ^{
        [KCSCustomEndpoints callEndpoint:@"foo" params:@{@"A":[NSObject new]} completionBlock:^(id results, NSError *error) {
            XCTFail(@"should not get here");
            XCTAssertTrue([NSThread isMainThread]);
        }];
    };
    
    XCTAssertThrowsSpecificNamed(block(), NSException, NSInvalidArgumentException, @"should be an exception");
}

@end
