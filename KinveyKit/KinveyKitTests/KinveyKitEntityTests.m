//
//  KinveyKitEntityTests.m
//  KinveyKit
//
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KinveyKitEntityTests.h"
#import "KinveyEntity.h"

#import "KCSObjectMapper.h"

@interface TestObject : NSObject <KCSPersistable>

@property (nonatomic, retain) NSString *testId;
@property (nonatomic, retain) NSString *testParam1;
@property (nonatomic, retain) NSNumber *testParam2;
@property (nonatomic, retain) NSDate* dateParam;
@property (nonatomic, retain) NSSet* setParam;
@property (nonatomic, retain) NSOrderedSet* oSetParam;
@property (nonatomic, retain) NSMutableAttributedString* asParam;

@end

@implementation TestObject
@synthesize asParam;
@synthesize testId = _testId;
@synthesize testParam1 = _testParam1;
@synthesize testParam2 = _testParam2;

- (NSDictionary *)hostToKinveyPropertyMapping
{
    return @{@"testId" : KCSEntityKeyId,
    @"testParam1" : @"testParam1i",
    @"testParam2" : @"testParam2i",
    @"setParam"   : @"setParam",
    @"dateParam" : @"dateParam",
    @"oSetParam" : @"oSetParam",
    @"asParam" : @"asParam"    };
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

- (void) testTypesSerialize
{
    TestObject* t = [[TestObject alloc] init];
    t.testId = @"idX";
    t.testParam1 = @"p1";
    t.testParam2 = @1.245;
    t.dateParam = [NSDate dateWithTimeIntervalSince1970:0];
    t.setParam = [NSSet setWithArray:@[@"2",@"1",@7]];
    t.oSetParam = [NSOrderedSet orderedSetWithArray:@[@"2",@"1",@7]];
    NSMutableAttributedString* s  = [[NSMutableAttributedString alloc] initWithString:@"abcdef"];
    [s setAttributes:@{@"myattr" : @"x"} range:NSMakeRange(1, 2)];
    t.asParam = s;
    
    KCSSerializedObject* so = [KCSObjectMapper makeKinveyDictionaryFromObject:t error:NULL];
    STAssertNotNil(so, @"should not have a nil object");
    
    NSDictionary* d = [so dataToSerialize];
    STAssertNotNil(d, @"should not have a nil dictionary");
    STAssertEquals([d count], (NSUInteger) 7, @"should have 6 params");
    
    STAssertEqualObjects([d objectForKey:KCSEntityKeyId], @"idX", @"should have set the id");
    STAssertEqualObjects([d objectForKey:@"testParam1i"],  @"p1", @"should have set the string");
    STAssertEqualObjects([d objectForKey:@"testParam2i"],  @1.245, @"should have set the number");
    STAssertEqualObjects([d objectForKey:@"dateParam"],   @"ISODate(\"1970-01-01T00:00:00.000Z\")", @"should have set the date");
    NSArray* a = @[@"2",@"1",@7];
    STAssertEqualObjects([d objectForKey:@"setParam"],    a, @"should have set the set");
    STAssertEqualObjects([d objectForKey:@"oSetParam"],   a, @"should have set the ordered set");
    STAssertEqualObjects([d objectForKey:@"asParam"],   @"abcdef", @"should have set the ordered set");
}

- (void) testTypesDeserialize
{
    NSDictionary* data = @{ KCSEntityKeyId : @"idX",
    @"testParam1i" : @"p1",
    @"testParam2i" : @1.245,
    @"dateParam"   : @"ISODate(\"1970-01-01T00:00:00.000Z\")",
    @"setParam"    : @[@"2",@"1",@7],
    @"oSetParam"   : @[@"2",@"1",@7],
    @"asParam"     : @"abcedf"};
    TestObject* out = [KCSObjectMapper makeObjectOfType:[TestObject class] withData:data];
    
    STAssertNotNil(out, @"Should not be nil");
    
    NSArray* a = @[@"2",@"1",@7];
    STAssertTrue([out.setParam isKindOfClass:[NSSet class]], @"should be a NSSet");
    STAssertEqualObjects(out.setParam,  [NSSet setWithArray:a], @"NSSets should be equal");
    STAssertTrue([out.oSetParam isKindOfClass:[NSOrderedSet class]], @"should be a NSOrderedSet");
    STAssertEqualObjects(out.oSetParam,  [NSOrderedSet orderedSetWithArray:a], @"NSOrderedSets should be equal");
    STAssertTrue([out.dateParam isKindOfClass:[NSDate class]], @"should be a NSOrderedSet");
    STAssertEqualObjects(out.dateParam,  [NSDate dateWithTimeIntervalSince1970:0], @"NSOrderedSets should be equal");
    STAssertTrue([out.asParam isKindOfClass:[NSMutableAttributedString class]], @"should be a NSOrderedSet");
}


@end
