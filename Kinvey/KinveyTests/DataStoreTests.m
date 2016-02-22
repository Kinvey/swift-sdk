//
//  DataStoreTests.m
//  Kinvey
//
//  Created by Victor Barros on 2016-02-22.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KNVDataStore.h"
#import "Person.h"

@interface DataStoreTests : XCTestCase

@end

@implementation DataStoreTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    KNVDataStore<Person*>* store = [[KNVDataStore alloc] init];
    [store find:^(Person * _Nullable person, NSError * _Nullable error) {
    }];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
