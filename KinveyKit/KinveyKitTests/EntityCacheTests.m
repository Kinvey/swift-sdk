//
//  EntityCache.m
//  KinveyKit
//
//  Created by Michael Katz on 10/25/13.
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

#import "KinveyDataStoreInternal.h"

@interface EntityCacheTests : SenTestCase

@end

@implementation EntityCacheTests

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

- (void)testRW
{
    KCSEntityPersistence* cache = [[KCSEntityPersistence alloc] initWithPersistenceId:@"x"];
    NSDictionary* o = @{@"_id":@"1",@"foo":@"bar"};
    BOOL u = [cache updateWithEntity:o route:@"r" collection:@"c"];
    STAssertTrue(u, @"should pass");
    NSDictionary* d = [cache entityForId:@"1" route:@"r" collection:@"c"];
    STAssertNotNil(d, @"should get back value");
    
    STAssertEqualObjects(o, d, @"should be restored");
}

- (void) testRemove
{
    KCSEntityPersistence* cache = [[KCSEntityPersistence alloc] initWithPersistenceId:@"x"];
    NSDictionary* o = @{@"_id":@"1",@"foo":@"bar"};
    [cache updateWithEntity:o route:@"r" collection:@"c"];
    NSDictionary* d = [cache entityForId:@"1" route:@"r" collection:@"c"];
    STAssertNotNil(d, @"should get back value");
    
    BOOL u = [cache removeEntity:@"1" route:@"r" collection:@"c"];
    STAssertTrue(u, @"should pass");

    d = [cache entityForId:@"1" route:@"r" collection:@"c"];
    STAssertNil(d, @"should get back no value");
}

- (void) testQueryRW
{
    KCSEntityPersistence* cache = [[KCSEntityPersistence alloc] initWithPersistenceId:@"x"];
    
}

@end
