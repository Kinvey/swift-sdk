//
//  KCSCachedStoreTests.m
//  KinveyKit
//
//  Created by Michael Katz on 5/10/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
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


#import "KCSCachedStoreTests.h"
#import "KCSCachedStore.h"
#import "KCSEntityDict.h"

#import "KinveyKit.h"

#import "KCSConnectionResponse.h"
#import "KCSMockConnection.h"
#import "KCSConnectionPool.h"
#import "KCS_SBJson.h"
#import "TestUtils.h"
#import "KCSHiddenMethods.h"

@interface TestEntity : NSObject
@property (nonatomic, retain) NSString* key;
@property (nonatomic, retain) NSString* objId;

@end
@implementation TestEntity
@synthesize key;

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return @{@"key" : @"key" , @"objId" : KCSEntityKeyId};
}
@end

@implementation KCSCachedStoreTests

static float pollTime;

- (BOOL) queryServer:(id<KCSStore>) store
{
    if (store == nil) {
        return false;
    }
    NSDictionary *dict = wrapResponseDictionary(@{@"key" : @"val", KCSEntityKeyId : @"foo - id"});
    
    KCS_SBJsonWriter* jsonwriter = [[KCS_SBJsonWriter alloc] init];
    NSData* data = [jsonwriter dataWithObject:dict];
    KCSConnectionResponse *response = [KCSConnectionResponse connectionResponseWithCode:200
                                                                           responseData:data
                                                                             headerData:nil
                                                                               userData:nil];
    
    _conn = [[KCSMockConnection alloc] init];
    _conn.responseForSuccess = response;
    _conn.connectionShouldFail = NO;
    _conn.connectionShouldReturnNow = YES;
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:_conn];
    
    __block BOOL wasCalled = NO;
    __block BOOL firstCall = YES;
    id query = [KCSQuery query];
 
    self.done = NO;
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        NSLog(@"completion block: %@,%i", query, _conn.wasCalled);
        if (firstCall) {
            wasCalled = _conn.wasCalled;
            firstCall = NO;
        }
        _callbackCount++;
        self.done = YES;
    } withProgressBlock:^(NSArray *objects, double percentComplete) {
        NSLog(@"progress block");
        //DO nothing on progress
    }];
    [self poll];
    NSLog(@"done");
    return wasCalled;
}

id<KCSStore> createStore(KCSCachePolicy cachePolicy)
{
    KCSCollection* collection = [[KCSCollection alloc] init];
    collection.collectionName = [NSString stringWithFormat:@"lists%@",[NSDate date]];
    collection.objectTemplate = [TestEntity class];
    KCSCachedStore* store = [KCSCachedStore storeWithOptions:@{KCSStoreKeyResource : collection, KCSStoreKeyCachePolicy: @(cachePolicy)}];
    return store;
}


- (void) setUp
{
    pollTime = 0.1;
    _callbackCount = 0;
    [TestUtils justInitServer];
    KCSUser* mockUser = [[KCSUser alloc] init];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    [KCSClient sharedClient].currentUser = mockUser;
#pragma clang diagnostic pop

}

- (void) tearDown
{
    [[KCSConnectionPool sharedPool] drainPools];
}

- (void) testCachedStoreNoCache
{
    pollTime = 2.;
    
    id<KCSStore> store = createStore(KCSCachePolicyNone);
    STAssertNotNil(store, @"must make a store");
    
    STAssertTrue([self queryServer:store], @"expecting to call server");
    STAssertTrue([self queryServer:store], @"expecting to call server");
    STAssertTrue([self queryServer:store], @"expecting to call server");    
}

- (void) testCachedStoreLocalCache
{
    id<KCSStore> store = createStore(KCSCachePolicyLocalOnly);
    STAssertNotNil(store, @"must make a store");
    
    STAssertFalse([self queryServer:store], @"expecting to use cache, not server");
    STAssertFalse([self queryServer:store], @"expecting to use cache, not server");
    STAssertFalse([self queryServer:store], @"expecting to use cache, call server");    
}

- (void) testCachedStoreLocalFirst
{
    id<KCSStore> store = createStore(KCSCachePolicyLocalFirst);
    STAssertNotNil(store, @"must make a store");
    
    STAssertTrue([self queryServer:store], @"expecting to call server for first time");

    _callbackCount = 0;
    STAssertFalse([self queryServer:store], @"expecting to use cache, not server on repeat call");
    STAssertTrue(_conn.wasCalled, @"expecting to call server after cache");
    STAssertTrue(1 == _callbackCount, @"expecting callback to be called only once");    
}

#if BUILD_FOR_UNIT_TEST
- (void) testCachedStoreNetworkFirst
{
    pollTime = 2.;
    
    id<KCSStore> store = createStore(KCSCachePolicyNetworkFirst);
    STAssertNotNil(store, @"must make a store");
    
    STAssertTrue([self queryServer:store], @"expecting to call server");
    STAssertTrue([self queryServer:store], @"expecting to call server");

    _callbackCount = 0;
    STAssertTrue([self queryServer:store], @"expecting to call server");
    STAssertTrue(1 == _callbackCount, @"expecting callback to be called only once");
    
    [(KCSCachedStore*)store setReachable:NO];

    STAssertFalse([self queryServer:store], @"expecting to use cache, not server on repeat call");

}
#endif

- (void) testCachedStoreBoth
{
    id<KCSStore> store = createStore(KCSCachePolicyBoth);
    STAssertNotNil(store, @"must make a store");
    
    BOOL useServer = [self queryServer:store];
    STAssertTrue(useServer, @"expecting to call server for first time");
    
    NSLog(@"0");
    _callbackCount = 0;
    
    useServer = [self queryServer:store];
    STAssertFalse(useServer, @"expecting to use cache, not server on repeat call");
    STAssertTrue(_conn.wasCalled, @"expecting to call server after cache");
    STAssertTrue(2 == _callbackCount, @"expecting callback to be called twice");
}

- (void) testTwoCollectionsNotSameCache
{
    KCSCollection* collection1 = [[KCSCollection alloc] init];
    collection1.collectionName = @"lists";
    collection1.objectTemplate = [TestEntity class];
    KCSCachedStore* store1 = [KCSCachedStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:collection1, KCSStoreKeyResource, [NSNumber numberWithInt:KCSCachePolicyLocalFirst],KCSStoreKeyCachePolicy, nil]];
    
    KCSCollection* collection2 = [[KCSCollection alloc] init];
    collection2.collectionName = @"fists";
    collection2.objectTemplate = [TestEntity class];
    KCSCachedStore* store2 = [KCSCachedStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:collection2, KCSStoreKeyResource, [NSNumber numberWithInt:KCSCachePolicyLocalFirst], KCSStoreKeyCachePolicy, nil]];
    
    STAssertTrue([self queryServer:store1], @"expecting to call server for first time");    
    STAssertFalse([self queryServer:store1], @"expecting to use cache, not server on repeat call");
    STAssertTrue([self queryServer:store2], @"expecting to call server for first time");    
    STAssertFalse([self queryServer:store2], @"expecting to use cache, not server on repeat call");
}

- (void) testTwoCollectionsReuseCache
{
    KCSCollection* collection1 = [[KCSCollection alloc] init];
    collection1.collectionName = @"reusecachelists";
    collection1.objectTemplate = [TestEntity class];
    KCSCachedStore* store1 = [KCSCachedStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:collection1, KCSStoreKeyResource, [NSNumber numberWithInt:KCSCachePolicyLocalFirst],KCSStoreKeyCachePolicy, nil]];
    
    KCSCollection* collection2 = [[KCSCollection alloc] init];
    collection2.collectionName = @"reusecachelists";
    collection2.objectTemplate = [TestEntity class];
    KCSCachedStore* store2 = [KCSCachedStore storeWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:collection2, KCSStoreKeyResource, [NSNumber numberWithInt:KCSCachePolicyLocalFirst], KCSStoreKeyCachePolicy, nil]];
    
    STAssertTrue([self queryServer:store1], @"expecting to call server for first time");    
    STAssertFalse([self queryServer:store1], @"expecting to use cache, not server on repeat call");
    STAssertFalse([self queryServer:store2], @"expecting to use cache, even with new store because of shared cache");
    STAssertFalse([self queryServer:store2], @"expecting to use cache, not server on repeat call");
}

#pragma mark - Import/Export

- (NSArray*) jsonArray
{
    NSString* cdata = @"[{\"date\":\"ISODate(\\\"2013-06-21T12:51:38.969Z\\\")\",\"objCount\":10,\"objDescription\":\"one\",\"_acl\":{\"creator\":\"51c44c5982cd0ade36000012\"},\"_kmd\":{\"lmt\":\"2013-06-21T12:51:37.817Z\",\"ect\":\"2013-06-21T12:51:37.817Z\"},\"_id\":\"51c44c5982cd0ade36000013\"},{\"date\":\"ISODate(\\\"2013-06-21T12:51:38.969Z\\\")\",\"objCount\":10,\"objDescription\":\"two\",\"_acl\":{\"creator\":\"51c44c5982cd0ade36000012\"},\"_kmd\":{\"lmt\":\"2013-06-21T12:51:37.818Z\",\"ect\":\"2013-06-21T12:51:37.818Z\"},\"_id\":\"51c44c5982cd0ade36000014\"},{\"date\":\"ISODate(\\\"2013-06-21T12:51:38.969Z\\\")\",\"objCount\":10,\"objDescription\":\"two\",\"_acl\":{\"creator\":\"51c44c5982cd0ade36000012\"},\"_kmd\":{\"lmt\":\"2013-06-21T12:51:37.819Z\",\"ect\":\"2013-06-21T12:51:37.819Z\"},\"_id\":\"51c44c5982cd0ade36000015\"},{\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-08-07T02:22:50.154Z\",\"ect\":\"2013-08-07T02:22:50.154Z\"},\"_id\":\"5201af7a3bb9501365000025\"},{\"_acl\":{\"creator\":\"506f3c35aa9734091d0000ee\"},\"_kmd\":{\"lmt\":\"2013-08-07T02:23:02.122Z\",\"ect\":\"2013-08-07T02:23:02.122Z\"},\"_id\":\"5201af863bb9501365000026\"},{\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-09-24T19:14:55.984Z\",\"ect\":\"2013-09-24T19:14:55.984Z\"},\"_id\":\"5241e4af8daed3725400009c\"},{\"abc\":\"1\",\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-09-24T19:15:02.536Z\",\"ect\":\"2013-09-24T19:15:02.536Z\"},\"_id\":\"5241e4b68daed3725400009d\"},{\"abc\":\"true\",\"_acl\":{\"creator\":\"kid10005\"},\"_kmd\":{\"lmt\":\"2013-09-24T19:15:11.263Z\",\"ect\":\"2013-09-24T19:15:11.263Z\"},\"_id\":\"5241e4bf8daed3725400009e\"}]";
    KCS_SBJsonParser* p = [[KCS_SBJsonParser alloc] init];
    NSArray* entities = [p objectWithString:cdata];
    STAssertNotNil(entities, @"Should have data to import: %@", p.error);
    
    return entities;
}

- (void) testImport
{
    KCSCachedStore* store = [KCSCachedStore storeWithCollection:[TestUtils randomCollection:[NSMutableDictionary class]] options:@{KCSStoreKeyCachePolicy : @(KCSCachePolicyLocalOnly)}];
    
    //1. import data
    NSArray* array = [self jsonArray];
    [store import:array];
    
    //2. do a query all and get the objs back
    self.done = NO;
    [store queryWithQuery:[KCSQuery query] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        KTAssertCount(8, objectsOrNil);
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    //3. do an export and check the data
    NSArray* out = [store exportCache];
    KTAssertCount(8, out);
    STAssertEqualObjects(out, array, @"should match");
    
}

@end
