//
//  DataModelTests.m
//  KinveyKit
//
//  Created by Michael Katz on 1/29/14.
//  Copyright (c) 2014 Kinvey. All rights reserved.
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

#import "KinveyKit.h"
#import "KinveyDataStoreInternal.h"

#import "TestUtils2.h"

@interface TC : NSObject <KCSPersistable>
@property (nonatomic, retain) id<KCSPersistable> p1;
@property (nonatomic, retain) TC* enemy;
@property (nonatomic, retain) NSMutableArray* friends;
@end

@implementation TC

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return @{@"p1":@"f1",@"enemy":@"enemyF",@"friends":@"friendsF"};
}

+ (NSDictionary *)kinveyPropertyToCollectionMapping
{
    return @{@"f1":@"p1",@"enemyF":@"c",@"friendsF":@"c"};
}

@end

@interface DataModelTests : SenTestCase

@end

@implementation DataModelTests

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

KK2(update tests with KCSPersistable2 objects)

- (void)testRefs
{
    TC* obj = [[TC alloc] init];
    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:obj collection:@"c"];
    STAssertNotNil(descr, @"Should have a description");
    
    NSArray* refs = descr.references;
    STAssertNotNil(refs, @"refs");
    KTAssertCount(3, refs);
}

- (void) testObjectGraphEmpty
{
    TC* obj = [[TC alloc] init];
    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:obj collection:@"c"];
    NSDictionary* graph = [descr objectListFromObjects:@[]];
    
    KTAssertCount(0, graph);
}

- (void) testGraphOneObj
{
    TC* obj = [[TC alloc] init];
    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:obj collection:@"c"];
    NSDictionary* graph = [descr objectListFromObjects:@[obj]];
    
    KTAssertCount(1, graph);
    id recoveredObj = [graph[@"c"] anyObject];
    STAssertEqualObjects(recoveredObj, obj, @"should get back original");
}

- (void) testGraphMultipleObj
{
    TC* obj1 = [[TC alloc] init];
    TC* obj2 = [[TC alloc] init];
    TC* obj3 = [[TC alloc] init];

    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:obj1 collection:@"c"];
    NSDictionary* graph = [descr objectListFromObjects:@[obj1,obj2,obj3]];
    
    KTAssertCount(1, graph);
    NSSet* recoverdObjs = graph[@"c"];
    KTAssertCount(3, recoverdObjs);
    
    STAssertTrue([recoverdObjs containsObject:obj1], @"should get back original");
    STAssertTrue([recoverdObjs containsObject:obj2], @"should get back original");
    STAssertTrue([recoverdObjs containsObject:obj3], @"should get back original");
}

- (void) testGraphMultipleObjOneToOneSameCollection
{
    TC* obj1 = [[TC alloc] init];
    TC* obj2 = [[TC alloc] init];
    TC* obj3 = [[TC alloc] init];
    
    obj1.enemy = obj3;
    obj2.enemy = obj3;
    obj3.enemy = obj1;
    
    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:obj1 collection:@"c"];
    NSDictionary* graph = [descr objectListFromObjects:@[obj1,obj2,obj3]];
    
    KTAssertCount(1, graph);
    NSSet* recoverdObjs = graph[@"c"];
    KTAssertCount(3, recoverdObjs);
    
    STAssertTrue([recoverdObjs containsObject:obj1], @"should get back original");
    STAssertTrue([recoverdObjs containsObject:obj2], @"should get back original");
    STAssertTrue([recoverdObjs containsObject:obj3], @"should get back original");
}

- (void) testGraphMultipleObjOneToManySameCollection
{
    TC* obj1 = [[TC alloc] init];
    TC* obj2 = [[TC alloc] init];
    TC* obj3 = [[TC alloc] init];
    
    obj1.enemy = obj3;
    obj2.enemy = obj3;
    obj3.enemy = obj1;
    
    obj1.friends = [@[obj2,obj3] mutableCopy];
    obj2.friends = [@[obj1] mutableCopy];
    obj3.friends = [@[obj1,obj2] mutableCopy];
    
    KCSPersistableDescription* descr = [[KCSPersistableDescription alloc] initWithKinveyKit1Object:obj1 collection:@"c"];
    NSDictionary* graph = [descr objectListFromObjects:@[obj1,obj2,obj3]];
    
    KTAssertCount(1, graph);
    NSSet* recoverdObjs = graph[@"c"];
    KTAssertCount(3, recoverdObjs);
    
    STAssertTrue([recoverdObjs containsObject:obj1], @"should get back original");
    STAssertTrue([recoverdObjs containsObject:obj2], @"should get back original");
    STAssertTrue([recoverdObjs containsObject:obj3], @"should get back original");

}

- (void) testGraphMultipleObjSelfRef
{
    
}

- (void) testRefInDictionary
{
    
}

#define WA(a)     NSLog(@"cfc: %@",[a classForCoder]); NSLog(@"cfka: %@", [a classForKeyedArchiver]); NSLog(@"cfku: %@", [[a class] classForKeyedUnarchiver]); NSLog(@"ro: %@", [[a replacementObjectForKeyedArchiver:ka] class]);


- (void) testRefInArrayInDictionary
{
 
    NSArray* a = [[NSMutableArray alloc] init];
    NSDictionary* d = [[NSMutableDictionary alloc] init];
    NSSet* s = [[NSMutableSet alloc] init];
    NSOrderedSet* os = [[NSMutableOrderedSet alloc] init];
    
    NSKeyedArchiver* ka = [[NSKeyedArchiver alloc] initForWritingWithMutableData:[NSMutableData data]];
    
    //    NSLog(@"cfc: %@",[a classForCoder]); NSLog(@"cfka: %@", [a classForKeyedArchiver]); NSLog(@"cfku: %@", [[a class] classForKeyedUnarchiver]);
    WA(a)
    WA(d)
    WA(s)
    WA(os)
}

@end
