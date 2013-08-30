//
//  KCSCustomEndpointTests.m
//  KinveyKit
//
//  Created by Michael Katz on 5/30/13.
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


#import "KCSCustomEndpointTests.h"

#import "TestUtils.h"
#import "KCSCustomEndpoints.h"

@implementation KCSCustomEndpointTests

- (void)setUp
{
    BOOL loaded = [TestUtils setUpKinveyUnittestBackend];
    STAssertTrue(loaded, @"should be loaded");
}

- (void) testCustomEndpoint
{
    self.done = NO;
    [KCSCustomEndpoints callEndpoint:@"bltest" params:nil completionBlock:^(id results, NSError *errorOrNil) {
        STAssertNoError;
        NSDictionary* expBody = @{@"a":@1,@"b":@2};
        STAssertEqualObjects(expBody, results, @"bodies should match");
        self.done = YES;
    }];
    [self poll];
}

- (void) testHS1468
{
    self.done = NO;
    [KCSCustomEndpoints callEndpoint:@"hs1468" params:@{@"email":@""} completionBlock:^(id results, NSError *error) {
        STAssertNil(error, @"error should be nil");
        self.done= YES;
    }];
    [self poll];
}

- (void) testHS1928_CallDoesNotInitCurrentUser
{
    [[KCSUser activeUser] logout];
    STAssertNil([KCSUser activeUser], @"user should be nil'd");
    self.done = NO;
    [KCSCustomEndpoints callEndpoint:@"bltest" params:nil completionBlock:^(id results, NSError *errorOrNil) {
        STAssertNotNil(errorOrNil, @"should have an error");
        KTAssertEqualsInt(errorOrNil.code, 401, @"no auth error");
        self.done = YES;
    }];
    [self poll];

}

- (void) testCustomEndpointError
{
    self.done = NO;
    [KCSCustomEndpoints callEndpoint:@"bltest-error" params:nil completionBlock:^(id results, NSError *errorOrNil) {
        STAssertNotNil(errorOrNil, @"should have an error");
        STAssertEqualObjects(errorOrNil.domain, KCSBusinessLogicErrorDomain, @"Should be a bl error");
        STAssertNotNil(errorOrNil.userInfo[NSURLErrorFailingURLStringErrorKey], @"should list the URL");
        KTAssertEqualsInt(errorOrNil.code, 400, @"should be a 400");
        self.done = YES;
    }];
    [self poll];
}
@end
