//
//  KCSEntityCacheTests.m
//  KinveyKit
//
//  Created by Michael Katz on 10/23/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "KCSEntityCacheTests.h"

#import "KCSEntityCache.h"
#import "KCSEntityCache2.h"

#import "KCSQuery.h"
#import "ASTTestClass.h"
#import "TestUtils.h"

@implementation KCSEntityCacheTests

- (void) setUp
{
    [KCSClient configureLoggingWithNetworkEnabled:YES debugEnabled:YES traceEnabled:YES warningEnabled:YES errorEnabled:YES];
}

- (id<KCSEntityCache>) cache:(NSString*)pid
{
    id<KCSEntityCache> c;
    if (pid) {
        c =  [[KCSEntityCache2 alloc] initWithPersistenceId:pid];
        [c setPersistenceId:pid];
    } else {
        c =  [[KCSEntityCache2 alloc] init];
    }
    return c;
}

- (void) testRoundTripQuery
{
    id<KCSEntityCache> cache = [self cache:nil];
    
    KCSQuery* query = [KCSQuery queryOnField:@"foo" withExactMatchForValue:@"bar"];
    [query addSortModifier:[[KCSQuerySortModifier alloc] initWithField:@"sortOrder" inDirection:kKCSAscending]];
    ASTTestClass* obj1 = [[ASTTestClass alloc] init];
    obj1.objId = @"1";
    ASTTestClass* obj2 = [[ASTTestClass alloc] init];
    obj2.objId = @"2";
    [cache setResults:@[obj1, obj2] forQuery:query];
    
    KCSQuery* query2 = [KCSQuery queryOnField:@"foo" withExactMatchForValue:@"bar"];
    [query2 addSortModifier:[[KCSQuerySortModifier alloc] initWithField:@"sortOrder" inDirection:kKCSAscending]];
    NSArray* results = [cache resultsForQuery:query2];
    
    STAssertTrue(results.count == 2, @"should have both objects");
    STAssertTrue([results containsObject:obj1], @"should have item 1");
    STAssertTrue([results containsObject:obj2], @"should have item 2");
    
}

- (void) testRoundTripSingleId
{
    id<KCSEntityCache> cache = [self cache:nil];
    
    ASTTestClass* obj1 = [[ASTTestClass alloc] init];
    obj1.objId = @"1";
    [cache addResult:obj1];
    
    id result = [cache objectForId:@"1"];
    STAssertEqualObjects(result, obj1, @"should match");
}

- (void) testRoundTripArray
{
    id<KCSEntityCache> cache = [self cache:nil];
    
    ASTTestClass* obj1 = [[ASTTestClass alloc] init];
    obj1.objId = @"1";
    ASTTestClass* obj2 = [[ASTTestClass alloc] init];
    obj2.objId = @"2";
    [cache addResults:@[obj1, obj2]];
    
    NSArray* results = [cache resultsForIds:@[@"1",@"2",@"3"]];
    STAssertTrue(results.count == 2, @"should have both objects");
    STAssertTrue([results containsObject:obj1], @"should have item 1");
    STAssertTrue([results containsObject:obj2], @"should have item 2");
}

- (void) testUpdate
{
    id<KCSEntityCache> cache = [self cache:nil];
    
    KCSQuery* query = [KCSQuery queryOnField:@"foo" withExactMatchForValue:@"bar"];
    ASTTestClass* obj1 = [[ASTTestClass alloc] init];
    obj1.objId = @"1";
    obj1.objCount = 10;
    ASTTestClass* obj2 = [[ASTTestClass alloc] init];
    obj2.objId = @"2";
    
    [cache setResults:@[obj1, obj2] forQuery:query];

    ASTTestClass* result = [cache objectForId:@"1"];
    STAssertEquals(result.objCount, 10, @"should get back obj1");
    
    ASTTestClass* obj1Prime = [[ASTTestClass alloc] init];
    obj1Prime.objId = @"1";
    obj1Prime.objCount = 100;
    [cache addResult:obj1Prime];
    
    NSArray* primeResults = [cache resultsForQuery:query];
    STAssertTrue(primeResults.count == 2, @"should have both objects");
    __block BOOL found = NO;
    [primeResults enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ASTTestClass* o = obj;
        if ([o.objId isEqualToString:@"1"]) {
            found = YES;
            STAssertEquals(o.objCount, 100, @"should have been updated");
        }
    }];
    STAssertTrue(found, @"Expecting obj1 to be in the results");
}

- (void) testById
{
    id<KCSEntityCache> cache = [self cache:nil];
    
    ASTTestClass* obj1 = [[ASTTestClass alloc] init];
    obj1.objId = @"1";
    ASTTestClass* obj2 = [[ASTTestClass alloc] init];
    obj2.objId = @"2";
    [cache addResults:@[obj1,obj2]];
    
    NSArray* results = [cache resultsForIds:@[@"1",@"2"]];
    STAssertTrue(results.count == 2, @"should have both objects");
    STAssertTrue([results containsObject:obj1], @"should have item 1");
    STAssertTrue([results containsObject:obj2], @"should have item 2");
}


- (void) testAddBySave
{
    NSLog(@"---------- starting");
    
    ASTTestClass* obj = [[ASTTestClass alloc] init];
    obj.date = [NSDate date];
    obj.objCount = 79000;
    
//    KCSCollection* c = [TestUtils randomCollection:[ASTTestClass class]];
//    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:c options:@{KCSStoreKeyUniqueOfflineSaveIdentifier : @"x0"}];
//    
//    [store setReachable:NO];
    
    id<KCSEntityCache> cache = [self cache:nil];
    [cache addUnsavedObject:obj];

    NSString* objId = obj.objId;
    STAssertNotNil(objId, @"Should have objid assigned");
    
    id ret = [cache objectForId:objId];
    STAssertEqualObjects(obj, ret, @"should get our object back");
}
    
//    self.done = NO;
//    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//        STAssertError(errorOrNil, KCSKinveyUnreachableError);
//        NSArray* objs = [[errorOrNil userInfo] objectForKey:KCS_ERROR_UNSAVED_OBJECT_IDS_KEY];
//        STAssertEquals((NSUInteger)1, (NSUInteger) objs.count, @"should have one unsaved obj, from above");
//        self.done = YES;
//    } withProgressBlock:^(NSArray *objects, double percentComplete) {
//        NSLog(@"%f", percentComplete);
//    }];
//    
//    [self poll];
//}

- (NSURL*) urlForDB:(NSString*)pid
{
    NSURL* url = nil;
    url = [NSURL fileURLWithPath: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"com.kinvey.%@_cache.plist", pid]]];
    url = [NSURL fileURLWithPath: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"com.kinvey.%@_cache.sqllite", pid]]];
    return url;
}

- (void) testClearCaches
{
    //setup peristence
    id<KCSEntityCache> cache = [self cache:@"persistenceId"];
    
    KCSQuery* query = [KCSQuery queryOnField:@"foo" withExactMatchForValue:@"bar"];
    ASTTestClass* obj1 = [[ASTTestClass alloc] init];
    obj1.objId = @"1";
    ASTTestClass* obj2 = [[ASTTestClass alloc] init];
    obj2.objId = @"2";
    [cache setResults:@[obj1, obj2] forQuery:query];
    
    NSURL* url = [self urlForDB:@"persistenceId"];
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[url path]], @"should have cache at %@", [url path]);

    [cache clearCaches];
    
    STAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[url path]], @"should not have cache at %@", [url path]);
    
    KCSQuery* query2 = [KCSQuery queryOnField:@"foo" withExactMatchForValue:@"bar"];
    NSArray* results = [cache resultsForQuery:query2];
    
    STAssertEquals((int)results.count, (int)0, @"should not have any results after clearing cache");
}

- (void) testCacheClearasOnUserChange
{
    
    id<KCSEntityCache> cache = [self cache:@"persistenceId"];
    
    KCSQuery* query = [KCSQuery queryOnField:@"foo" withExactMatchForValue:@"bar"];
    ASTTestClass* obj1 = [[ASTTestClass alloc] init];
    obj1.objId = @"1";
    ASTTestClass* obj2 = [[ASTTestClass alloc] init];
    obj2.objId = @"2";
    [cache setResults:@[obj1, obj2] forQuery:query];
    
    NSURL* url = [self urlForDB:@"persistenceId"];
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[url path]], @"should have cache at %@", [url path]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    [KCSClient sharedClient].currentUser = [[KCSUser alloc] init];
#pragma clang diagnostic pop
    
    STAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[url path]], @"should not have cache at %@", [url path]);
}

//test save updates query
//test save new updates existing query
//save by id, load by query
//test persist
//test removal

@end
