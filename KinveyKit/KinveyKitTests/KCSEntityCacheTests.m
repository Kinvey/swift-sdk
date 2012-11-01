//
//  KCSEntityCacheTests.m
//  KinveyKit
//
//  Created by Michael Katz on 10/23/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSEntityCacheTests.h"

#import "KCSEntityCache.h"

#import "KCSQuery.h"
#import "ASTTestClass.h"
#import "TestUtils.h"

@implementation KCSEntityCacheTests


- (void) testRoundTripQuery
{
    KCSEntityCache* cache = [[KCSEntityCache alloc] init];
    
    KCSQuery* query = [KCSQuery queryOnField:@"foo" withExactMatchForValue:@"bar"];
    ASTTestClass* obj1 = [[ASTTestClass alloc] init];
    obj1.objId = @"1";
    ASTTestClass* obj2 = [[ASTTestClass alloc] init];
    obj2.objId = @"2";
    [cache setResults:@[obj1, obj2] forQuery:query];
    
    KCSQuery* query2 = [KCSQuery queryOnField:@"foo" withExactMatchForValue:@"bar"];
    NSArray* results = [cache resultsForQuery:query2];
    
    STAssertTrue(results.count == 2, @"should have both objects");
    STAssertTrue([results containsObject:obj1], @"should have item 1");
    STAssertTrue([results containsObject:obj2], @"should have item 2");
}

- (void) testRoundTripSingleId
{
    KCSEntityCache* cache = [[KCSEntityCache alloc] init];
    
    ASTTestClass* obj1 = [[ASTTestClass alloc] init];
    obj1.objId = @"1";
    [cache addResult:obj1];
    
    id result = [cache objectForId:@"1"];
    STAssertEqualObjects(result, obj1, @"should match");
}

- (void) testRoundTripArray
{
    KCSEntityCache* cache = [[KCSEntityCache alloc] init];
    
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
    KCSEntityCache* cache = [[KCSEntityCache alloc] init];
    
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
    KCSEntityCache* cache = [[KCSEntityCache alloc] init];
    
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


- (void) addBySave
{
    NSLog(@"---------- starting");
    
    ASTTestClass* obj = [[ASTTestClass alloc] init];
    obj.date = [NSDate date];
    obj.objCount = 79000;
    
//    KCSCollection* c = [TestUtils randomCollection:[ASTTestClass class]];
//    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:c options:@{KCSStoreKeyUniqueOfflineSaveIdentifier : @"x0"}];
//    
//    [store setReachable:NO];
    
    KCSEntityCache* cache = [[KCSEntityCache alloc] init];
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

//test save updates query
//test save new updates existing query
//save by id, load by query
//test persist
//test removal
@end
