//
//  KinveyKitConnectionPoolTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "KinveyKitConnectionPoolTests.h"
#import "KCSConnectionPool.h"
#import "KCSMockConnection.h"
#import "KCSConnection.h"
#import "KCSAsyncConnection.h"

@implementation KinveyKitConnectionPoolTests

// All code under test must be linked into the Unit Test bundle


- (void)testSingletonReturnsValue
{
    KCSConnectionPool *pool = [KCSConnectionPool sharedPool];
    STAssertNotNil(pool, @"pool should not be nil");
    STAssertTrue([pool isKindOfClass:[KCSConnectionPool class]], @"should be of the pool class");
}

- (void)testSingletonIsSingleton
{
    KCSConnectionPool *poolOne = [KCSConnectionPool sharedPool];
    KCSConnectionPool *poolTwo = [KCSConnectionPool sharedPool];

    STAssertEquals(poolOne, poolTwo, @"pools should be the same");
}

- (void)testFillPoolsWithArbitraryConnectionReturnsCorrectConnection
{
    // Fill async and sync pools with mock types
    [[KCSConnectionPool sharedPool] fillAsyncPoolWithConnections:[KCSMockConnection class]];
    
    // Test correct types returned
    KCSConnection *connection = [KCSConnectionPool asyncConnection];
    STAssertTrue([connection isKindOfClass:[KCSMockConnection class]], @"class should match");

    // Reset connections
    [[KCSConnectionPool sharedPool] fillPools];

    // Test correct types returned
    connection = [KCSConnectionPool asyncConnection];
    STAssertTrue([connection isKindOfClass:[KCSAsyncConnection class]], @"class should match");
}

- (void)testFillPoolsFillsToDefaultValues
{
    // Reset connections
    [[KCSConnectionPool sharedPool] fillPools];
    
    // Test correct types returned
    KCSConnection *connection = [KCSConnectionPool asyncConnection];
    STAssertTrue([connection isKindOfClass:[KCSAsyncConnection class]], @"class should match");
}

- (void)testArbitraryConnectionType
{
    KCSConnection *connection = [KCSConnectionPool connectionWithConnectionType:[KCSMockConnection class]];
    
    STAssertTrue([connection isKindOfClass:[KCSMockConnection class]], @"class should match");
}

- (void)testThatNonConnectionObjectCausesException
{
    KCSConnectionPool *pool = [KCSConnectionPool sharedPool];
    
    STAssertThrows([pool fillAsyncPoolWithConnections:[NSString class]],
                   @"Fill Async pool allowed invalid connection type");
    
    STAssertThrows([KCSConnectionPool connectionWithConnectionType:[NSString class]],
                   @"Pool returned is notvalid connection");
}

@end
