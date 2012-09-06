//
//  KinveyKitQueryTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/26/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KinveyKitQueryTests.h"
#import "NSString+KinveyAdditions.h"
#import "KinveyKit.h"
#import "TestUtils.h"
#import "ASTTestClass.h"

@compatibility_alias TestClass ASTTestClass;

@implementation KinveyKitQueryTests

// All code under test must be linked into the Unit Test bundle
- (void)testSomeQueries
{
    NSString *expectedJSON = @"{\"$or\":[{\"age\":{\"$gt\":30}},{\"jobs\":{\"$gt\":1,\"$lt\":5}}],\"children\":{\"$not\":{\"$lt\":3}}}";
    
    KCSQuery *query  = [KCSQuery queryOnField:@"age" usingConditional:kKCSGreaterThan forValue:[NSNumber numberWithInt:30]];
    KCSQuery *query2 = [KCSQuery queryOnField:@"jobs" usingConditionalsForValues:
                        kKCSGreaterThan, [NSNumber numberWithInt:1],
                        kKCSLessThan, [NSNumber numberWithInt:5], nil];
    KCSQuery *orQuery = [KCSQuery queryForJoiningOperator:kKCSOr onQueries:query, query2, nil];
    
    [orQuery addQueryNegatingQuery:[KCSQuery queryOnField:@"children" usingConditional:kKCSLessThan forValue:[NSNumber numberWithInt:3]]];
    
    NSString *computedJSON = [orQuery JSONStringRepresentation];
    
    assertThat(computedJSON, is(equalTo(expectedJSON)));
    
    
    KCSQuery *geoQuery = [KCSQuery queryOnField:@"location" usingConditional:kKCSNearSphere forValue:[NSArray arrayWithObjects:[NSNumber numberWithFloat:50.0], [NSNumber numberWithFloat:50.0], nil]];
    
    NSLog(@"%@\n%@", [geoQuery JSONStringRepresentation], [NSString stringByPercentEncodingString:[geoQuery JSONStringRepresentation]]);
}

- (void)testCombo
{
    KCSQuery *q1 = [KCSQuery query];
    [q1 addQueryOnField:@"testField" usingConditional:kKCSGreaterThan forValue:[NSNumber numberWithInt:23]];
    
    KCSQuery *q2 = [KCSQuery queryOnField:@"testField" usingConditional:kKCSGreaterThan forValue:[NSNumber numberWithInt:23]];

    NSString *a = [q1 JSONStringRepresentation];
    NSString *b = [q2 JSONStringRepresentation];
    assertThat(a, is(equalTo(b)));
}

- (void)testMongoOps
{
    KCSQuery *q = [KCSQuery query];
    
    // Ex1 {"age": {"$gte": 18, "$lte": 40}}
    
    [q clear];
    
    // Ex2  {"username": {"$ne": "joe"}}
    // Ex3  {"ticket_no": {"$in": [725, 542, 390]}}
    // Ex4  {"user_id": {"$in": [12345, "joe"]}}
    // Ex5  {"ticket_no": {"$nin": [725, 542, 390]}}
    // Ex6  {"$or": [{"ticket_no": 725}, {"winner": true}]}
    // Ex7  {"$or": [{"ticket_no": {"$in": [725, 542, 390]}, {"winner": true}]}
    // Ex8a {"id_num": {"$mod": [5, 1]}}
    // Ex8b {"id_num": {"$not": {"$mod": [5, 1]}}}
    // Ex9  {"y": null}
    
}


- (void)testBlog
{
    NSString *r1 = @"{\"_geoloc\":{\"$nearSphere\":[-71,41]}}";
    KCSQuery *q1 = [KCSQuery queryOnField:@"coordinates"
                         usingConditional:kKCSNearSphere
                                 forValue: [NSArray arrayWithObjects:
                                            [NSNumber numberWithInt:-71],
                                            [NSNumber numberWithInt:41], nil]];

    assertThat([q1 JSONStringRepresentation], is(equalTo(r1)));

    NSString *r2 = @"{\"_geoloc\":{\"$nearSphere\":[-71,42],\"$maxDistance\":0.5}}";
    KCSQuery *q2 = [KCSQuery queryOnField:@"coordinates"
               usingConditionalsForValues:
                    kKCSNearSphere,
                    [NSArray arrayWithObjects:
                     [NSNumber numberWithInt:-71],
                     [NSNumber numberWithInt:42], nil],
                    kKCSMaxDistance,
                    [NSNumber numberWithFloat:0.5], nil]; // Does this need to be a string?
    
    assertThat([q2 JSONStringRepresentation], is(equalTo(r2)));
    
    NSString *r3 = @"{\"_geoloc\":{\"$within\":{\"$box\":[[-70,44],[-72,42]]}}}";
    NSArray *point1 = [NSArray arrayWithObjects:[NSNumber numberWithInt:-70],
                       [NSNumber numberWithInt:44], nil];
    
    NSArray *point2 = [NSArray arrayWithObjects:[NSNumber numberWithInt:-72],
                       [NSNumber numberWithInt:42], nil];

    NSArray *box = [NSArray arrayWithObjects:point1, point2, nil];
    KCSQuery *q3 = [KCSQuery queryOnField:@"coordinates"
                         usingConditional:kKCSWithinBox
                                 forValue:box];

    assertThat([q3 JSONStringRepresentation], is(equalTo(r3)));

}

- (void) testAscendingDecending
{
    BOOL setup = [TestUtils setUpKinveyUnittestBackend];
    STAssertTrue(setup, @"Backend should be good to go");
    
    KCSCollection* collection = [TestUtils randomCollection:[TestClass class]];
    
    NSMutableArray* arr = [NSMutableArray arrayWithCapacity:20];
    for (int i=0; i < 20; i++) {
        TestClass* a = [[[TestClass alloc] init] autorelease];
        a.objCount = i;
        [arr addObject:a];
    }
    
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:collection options:nil];
    self.done = NO;
    [store saveObject:arr withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"not expecting error: %@");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    KCSQuery* query = [KCSQuery query];
    query.limitModifer = [[KCSQueryLimitModifier alloc] initWithLimit:10];
    
    [query addSortModifier:[[KCSQuerySortModifier alloc] initWithField:@"objCount" inDirection:kKCSAscending]];
    
    self.done = NO;
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"not expecting error: %@");
        STAssertEquals((int)[objectsOrNil count], (int) 10, @"should have 10 objects");
        int count = 0;
        for (TestClass* a in objectsOrNil) {
            count += a.objCount;
        }
        STAssertEquals(count, (int) 45, @"count should match");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    query = [KCSQuery query];
    query.limitModifer = [[KCSQueryLimitModifier alloc] initWithLimit:10];
    
    [query addSortModifier:[[KCSQuerySortModifier alloc] initWithField:@"objCount" inDirection:kKCSDescending]];
    
    self.done = NO;
    [store queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNil(errorOrNil, @"not expecting error: %@");
        STAssertEquals((int)[objectsOrNil count], (int) 10, @"should have 10 objects");
        int count = 0;
        for (TestClass* a in objectsOrNil) {
            count += a.objCount;
        }
        STAssertEquals(count, (int) 145, @"count should match");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
}


#define AssertQuery STAssertEqualObjects([query JSONStringRepresentation], expectedJSON, @"should match");
- (void) testRegex
{
    NSString* expectedJSON = @"{\"field\":{\"$regex\":\"abcdef\"}}";
    KCSQuery* query  = [KCSQuery queryOnField:@"field" withRegex:@"abcdef"];
    AssertQuery
    
    query = [KCSQuery queryOnField:@"field" withRegex:@"abcdef" options:kKCSRegexepDefault];
    AssertQuery
    
    expectedJSON = @"{\"field\":{\"$regex\":\"abcdef\",\"$options\":\"i\"}}";
    query  = [KCSQuery queryOnField:@"field" withRegex:@"abcdef" options:kKCSRegexpCaseInsensitive];
    AssertQuery
    
    expectedJSON = @"{\"field\":{\"$regex\":\"abcdef\",\"$options\":\"x\"}}";
    query  = [KCSQuery queryOnField:@"field" withRegex:@"abcdef" options:kKCSRegexpAllowCommentsAndWhitespace];
    AssertQuery
    
    expectedJSON = @"{\"field\":{\"$regex\":\"abcdef\",\"$options\":\"s\"}}";
    query  = [KCSQuery queryOnField:@"field" withRegex:@"abcdef" options:kKCSRegexpDotMatchesAll];
    AssertQuery
    
    expectedJSON = @"{\"field\":{\"$regex\":\"abcdef\",\"$options\":\"m\"}}";
    query  = [KCSQuery queryOnField:@"field" withRegex:@"abcdef" options:kKCSRegexpAnchorsMatchLines];
    AssertQuery

    expectedJSON = @"{\"field\":{\"$regex\":\"abcdef\",\"$options\":\"ix\"}}";
    query  = [KCSQuery queryOnField:@"field" withRegex:@"abcdef" options:kKCSRegexpCaseInsensitive | kKCSRegexpAllowCommentsAndWhitespace];
    AssertQuery
    
    expectedJSON = @"{\"field\":{\"$regex\":\"abcdef\",\"$options\":\"ixsm\"}}";
    query  = [KCSQuery queryOnField:@"field" withRegex:@"abcdef" options:kKCSRegexpCaseInsensitive | kKCSRegexpAllowCommentsAndWhitespace | kKCSRegexpDotMatchesAll | kKCSRegexpAnchorsMatchLines];
    AssertQuery
    
    expectedJSON = @"{\"field\":{\"$not\":{\"$regex\":\"abcdef\",\"$options\":\"ixsm\"}}}";
    [query negateQuery];
    AssertQuery
    
    expectedJSON = @"{\"age\":{\"$lt\":10},\"field\":{\"$not\":{\"$regex\":\"abcdef\",\"$options\":\"ixsm\"}}}";
    [query addQuery:[KCSQuery queryOnField:@"age" usingConditionalsForValues:kKCSLessThan, @(10), nil]];
    AssertQuery
}

@end
