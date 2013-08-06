//
//  KCSCachedStoreTests.m
//  KinveyKit
//
//  Created by Michael Katz on 5/10/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSCachedStoreTests.h"
#import "KCSCachedStore.h"
#import "KCSEntityDict.h"

#import "KinveyKit.h"

#import "KCSConnectionResponse.h"
#import "KCSMockConnection.h"
#import "KCSConnectionPool.h"
#import "KCS_SBJsonWriter.h"
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

@end
