//
//  KinveyKitEntityTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KinveyKitEntityTests.h"
#import "KinveyEntity.h"

@interface TestObject : NSObject <KCSPersistable>

@property (nonatomic, retain) NSString *testId;
@property (nonatomic, retain) NSString *testParam1;
@property (nonatomic, retain) NSNumber *testParam2;

@end

@implementation TestObject

@synthesize testId = _testId;
@synthesize testParam1 = _testParam1;
@synthesize testParam2 = _testParam2;

- (NSDictionary *)hostToKinveyPropertyMapping
{
    static NSDictionary *map = nil;
    
    if (map == nil){
        map = [NSDictionary dictionaryWithObjectsAndKeys:@"_id", @"testId",
               @"testParam1", @"testParam1",
               @"testParam2", @"testParam2", nil];
    }
    
    return map;
}


@end

@implementation KinveyKitEntityTests

// All code under test must be linked into the Unit Test bundle

- (void)testSaveEntityNormal
{
    STFail(@"Not implemented yet");
}

- (void)testSaveEntityBadEntity
{
    STFail(@"Not implemented yet");
}

- (void)testDeleteEntityNormal
{
    STFail(@"Not implemented yet");
}

- (void)testDeleteEntityBadEntity
{
    STFail(@"Not implemented yet");
}


- (void)testLoadNormalEntity
{
    STFail(@"Not implemented yet");
}

- (void)testLoadMalformedEntity
{
    STFail(@"Not implemented yet");
}

- (void)testValueForPropertyDeserialization
{
    STFail(@"Not implemented yet");
}


- (void)testFindEntityWithPropertyRoutines
{
    STFail(@"Not implemented yet");
}


- (void)testFetchOneFromCollection
{
    STFail(@"Not implemented yet");
}

- (void)testObjectIDConvienience
{
    STFail(@"Not implemented yet");
}


- (void)testSetValueForObject
{
    STFail(@"Not implemented yet");
}

- (void)testHostToKinveyPropertyMappingRaisesException
{
    STFail(@"Not implemented yet");
}


@end
