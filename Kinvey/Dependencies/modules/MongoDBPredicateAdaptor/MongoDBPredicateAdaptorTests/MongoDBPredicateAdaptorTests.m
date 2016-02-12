//
//  MongoDBPredicateAdaptorTests.m
//  MongoDBPredicateAdaptorTests
//
//  Created by Victor Barros on 2016-02-11.
//  Copyright © 2016 tjboneman. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MongoDBPredicateAdaptorKit/MongoDBPredicateAdaptorKit.h>

@interface MongoDBPredicateAdaptorTests : XCTestCase

@end

@implementation MongoDBPredicateAdaptorTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    [Test hello];
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"name == %@", @"Victor"];
    NSError* error = nil;
    NSDictionary* result = [MongoDBPredicateAdaptor queryDictFromPredicate:predicate
                                                                   orError:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(result);
    XCTAssertEqualObjects(result, @{@"name" : @"Victor"});
}

@end
