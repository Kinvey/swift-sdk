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

#import "TestUtils2.h"

#import "KinveyCoreInternal.h"
#import "KinveyDataStoreInternal.h"

#undef ddLogLevel
#define ddLogLevel LOG_FLAG_DEBUG

#define KTAssertU STAssertTrue(u, @"pass");

@interface EntityCacheTests : SenTestCase

@end

@implementation EntityCacheTests

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
    KCSClientConfiguration* cfg = [KCSClientConfiguration configurationWithAppKey:@"Fake" secret:@"Fake"];
    [[KCSClient sharedClient] initializeWithConfiguration:cfg];
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

#pragma mark - Persistence

- (void)testRW
{
    KCSEntityPersistence* cache = [[KCSEntityPersistence alloc] initWithPersistenceId:@"x"];
    NSDictionary* o = @{@"_id":@"1",@"foo":@"bar"};
    BOOL u = [cache updateWithEntity:o route:@"r" collection:@"c"];
    KTAssertU
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
    KTAssertU

    d = [cache entityForId:@"1" route:@"r" collection:@"c"];
    STAssertNil(d, @"should get back no value");
}

- (void) testQueryRW
{
    KCSEntityPersistence* cache = [[KCSEntityPersistence alloc] initWithPersistenceId:@"x"];
    NSArray* ids = @[@"1",@"2",@"3"];
    NSString* query = @"abcdefg";
    NSString* route = @"r";
    NSString* cln = @"c";
    BOOL u = [cache setIds:ids forQuery:query route:route collection:cln];
    KTAssertU
    
    NSArray* loadedIds = [cache idsForQuery:query route:route collection:cln];
    STAssertNotNil(loadedIds, @"should have ids");
    STAssertEqualObjects(loadedIds, ids, @"should match");
}

- (void) testQueryReplacesOld
{
    KCSEntityPersistence* cache = [[KCSEntityPersistence alloc] initWithPersistenceId:@"x"];
    NSArray* ids = @[@"1",@"2",@"3"];
    NSString* query = @"abcdefg";
    NSString* route = @"r";
    NSString* cln = @"c";
    BOOL u = [cache setIds:ids forQuery:query route:route collection:cln];
    KTAssertU
    
    NSArray* secondSet = @[@"2",@"3",@"4"];
    u = [cache setIds:secondSet forQuery:query route:route collection:cln];
    KTAssertU

    NSArray* loadedIds = [cache idsForQuery:query route:route collection:cln];
    STAssertNotNil(loadedIds, @"should have ids");
    STAssertEqualObjects(loadedIds, secondSet, @"should match");
}
- (void) testImport
{
    NSString* cdata = @"[{\"date\":\"ISODate(\\\"2013-06-21T12:51:38.969Z\\\")\",\"objCount\":10,\"objDescription\":\"one\",\"_acl\":{\"creator\":\"51c44c5982cd0ade36000012\"},\"_kmd\":{\"lmt\":\"2013-06-21T12:51:37.817Z\",\"ect\":\"2013-06-21T12:51:37.817Z\"},\"_id\":\"51c44c5982cd0ade36000013\"},{\"date\":\"ISODate(\\\"2013-06-21T12:51:38.969Z\\\")\",\"objCount\":10,\"objDescription\":\"two\",\"_acl\":{\"creator\":\"51c44c5982cd0ade36000012\"},\"_kmd\":{\"lmt\":\"2013-06-21T12:51:37.818Z\",\"ect\":\"2013-06-21T12:51:37.818Z\"},\"_id\":\"51c44c5982cd0ade36000014\"},{\"date\":\"ISODate(\\\"2013-06-21T12:51:38.969Z\\\")\",\"objCount\":10,\"objDescription\":\"two\",\"_acl\":{\"creator\":\"51c44c5982cd0ade36000012\"},\"_kmd\":{\"lmt\":\"2013-06-21T12:51:37.819Z\",\"ect\":\"2013-06-21T12:51:37.819Z\"},\"_id\":\"51c44c5982cd0ade36000015\"},{\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-08-07T02:22:50.154Z\",\"ect\":\"2013-08-07T02:22:50.154Z\"},\"_id\":\"5201af7a3bb9501365000025\"},{\"_acl\":{\"creator\":\"506f3c35aa9734091d0000ee\"},\"_kmd\":{\"lmt\":\"2013-08-07T02:23:02.122Z\",\"ect\":\"2013-08-07T02:23:02.122Z\"},\"_id\":\"5201af863bb9501365000026\"},{\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-09-24T19:14:55.984Z\",\"ect\":\"2013-09-24T19:14:55.984Z\"},\"_id\":\"5241e4af8daed3725400009c\"},{\"abc\":\"1\",\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-09-24T19:15:02.536Z\",\"ect\":\"2013-09-24T19:15:02.536Z\"},\"_id\":\"5241e4b68daed3725400009d\"},{\"abc\":\"true\",\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-09-24T19:15:11.263Z\",\"ect\":\"2013-09-24T19:15:11.263Z\"},\"_id\":\"5241e4bf8daed3725400009e\"}]";
    KCS_SBJsonParser* p = [[KCS_SBJsonParser alloc] init];
    NSArray* entities = [p objectWithString:cdata];
    STAssertNotNil(entities, @"Should have data to import: %@", p.error);
    
    KCSEntityPersistence* cache = [[KCSEntityPersistence alloc] initWithPersistenceId:@"x"];
    NSString* route = @"r";
    NSString* cln = @"c";
    
    BOOL u = [cache import:entities route:route collection:cln];
    KTAssertU
    
    NSDictionary* entity = [cache entityForId:@"51c44c5982cd0ade36000013" route:route collection:cln];
    STAssertNotNil(entity, @"should get back an entity");
}


#pragma mark - Cache
- (void) testPullQuery
{
    NSString* cdata = @"[{\"date\":\"ISODate(\\\"2013-06-21T12:51:38.969Z\\\")\",\"objCount\":10,\"objDescription\":\"one\",\"_acl\":{\"creator\":\"51c44c5982cd0ade36000012\"},\"_kmd\":{\"lmt\":\"2013-06-21T12:51:37.817Z\",\"ect\":\"2013-06-21T12:51:37.817Z\"},\"_id\":\"51c44c5982cd0ade36000013\"},{\"date\":\"ISODate(\\\"2013-06-21T12:51:38.969Z\\\")\",\"objCount\":10,\"objDescription\":\"two\",\"_acl\":{\"creator\":\"51c44c5982cd0ade36000012\"},\"_kmd\":{\"lmt\":\"2013-06-21T12:51:37.818Z\",\"ect\":\"2013-06-21T12:51:37.818Z\"},\"_id\":\"51c44c5982cd0ade36000014\"},{\"date\":\"ISODate(\\\"2013-06-21T12:51:38.969Z\\\")\",\"objCount\":10,\"objDescription\":\"two\",\"_acl\":{\"creator\":\"51c44c5982cd0ade36000012\"},\"_kmd\":{\"lmt\":\"2013-06-21T12:51:37.819Z\",\"ect\":\"2013-06-21T12:51:37.819Z\"},\"_id\":\"51c44c5982cd0ade36000015\"},{\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-08-07T02:22:50.154Z\",\"ect\":\"2013-08-07T02:22:50.154Z\"},\"_id\":\"5201af7a3bb9501365000025\"},{\"_acl\":{\"creator\":\"506f3c35aa9734091d0000ee\"},\"_kmd\":{\"lmt\":\"2013-08-07T02:23:02.122Z\",\"ect\":\"2013-08-07T02:23:02.122Z\"},\"_id\":\"5201af863bb9501365000026\"},{\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-09-24T19:14:55.984Z\",\"ect\":\"2013-09-24T19:14:55.984Z\"},\"_id\":\"5241e4af8daed3725400009c\"},{\"abc\":\"1\",\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-09-24T19:15:02.536Z\",\"ect\":\"2013-09-24T19:15:02.536Z\"},\"_id\":\"5241e4b68daed3725400009d\"},{\"abc\":\"true\",\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-09-24T19:15:11.263Z\",\"ect\":\"2013-09-24T19:15:11.263Z\"},\"_id\":\"5241e4bf8daed3725400009e\"}]";
    KCS_SBJsonParser* p = [[KCS_SBJsonParser alloc] init];
    NSArray* entities = [p objectWithString:cdata];
    STAssertNotNil(entities, @"Should have data to import: %@", p.error);
    
    KCSEntityPersistence* cache = [[KCSEntityPersistence alloc] initWithPersistenceId:@"x"];
    NSString* route = @"r";
    NSString* cln = @"c";
    
    BOOL u = [cache import:entities route:route collection:cln];
    KTAssertU

    NSString* _id = @"51c44c5982cd0ade36000013";
    KCSQuery* q = [KCSQuery queryOnField:KCSEntityKeyId withExactMatchForValue:_id];
    u = [cache setIds:@[_id] forQuery:[q parameterStringRepresentation] route:route collection:cln];
    KTAssertU
    
    
    KCSObjectCache* ocache = [[KCSObjectCache alloc] init];
    NSArray* results = [ocache pullQuery:q route:route collection:cln];
    STAssertNotNil(results, @"should have results");
    KTAssertCount(1, results);
    
    id obj = results[0];
    STAssertTrue([obj isKindOfClass:[NSMutableDictionary class]], @"default should be nsmutable dictionary");
}
@end
