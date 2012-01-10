//
//  KinveyKitConnectionPoolTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KinveyKitConnectionPoolTests.h"
#import "KCSConnectionPool.h"
#import "KCSMockConnection.h"
#import "KCSConnection.h"
#import "KCSAsyncConnection.h"
#import "KCSSyncConnection.h"

@implementation KinveyKitConnectionPoolTests

// All code under test must be linked into the Unit Test bundle


- (void)testSingletonReturnsValue{
    KCSConnectionPool *pool = [KCSConnectionPool sharedPool];
    assertThat(pool, is(notNilValue()));
    assertThat(pool, is(instanceOf([KCSConnectionPool class])));
}

- (void)testSingletonIsSingleton{
    
    KCSConnectionPool *poolOne = [KCSConnectionPool sharedPool];
    KCSConnectionPool *poolTwo = [KCSConnectionPool sharedPool];
    
    assertThat(poolOne, is(sameInstance(poolTwo)));
}

- (void)testFillPoolsWithArbitraryConnectionReturnsCorrectConnection{
    
    // Fill async and sync pools with mock types
    [[KCSConnectionPool sharedPool] fillAsyncPoolWithConnections:[KCSMockConnection class]];
    [[KCSConnectionPool sharedPool] fillSyncPoolWithConnections:[KCSMockConnection class]];
    
    // Test correct types returned
    KCSConnection *connection = [KCSConnectionPool asyncConnection];
    assertThat(connection, is(instanceOf([KCSMockConnection class])));

    connection = [KCSConnectionPool syncConnection];
    assertThat(connection, is(instanceOf([KCSMockConnection class])));    
    
    // Reset connections
    [[KCSConnectionPool sharedPool] fillPools];

    // Test correct types returned
    connection = [KCSConnectionPool asyncConnection];
    assertThat(connection, is(instanceOf([KCSAsyncConnection class])));
    
    connection = [KCSConnectionPool syncConnection];
    assertThat(connection, is(instanceOf([KCSSyncConnection class])));    

}

- (void)testFillPoolsFillsToDefaultValues{
    // Reset connections
    [[KCSConnectionPool sharedPool] fillPools];
    
    // Test correct types returned
    KCSConnection *connection = [KCSConnectionPool asyncConnection];
    assertThat(connection, is(instanceOf([KCSAsyncConnection class])));
    
    connection = [KCSConnectionPool syncConnection];
    assertThat(connection, is(instanceOf([KCSSyncConnection class])));    

}

- (void)testArbitraryConnectionType{
    KCSConnection *connection = [KCSConnectionPool connectionWithConnectionType:[KCSMockConnection class]];
    
    assertThat(connection, is(instanceOf([KCSMockConnection class])));
}

- (void)testThatNonConnectionObjectCausesException{
    KCSConnectionPool *pool = [KCSConnectionPool sharedPool];
    
    STAssertThrows([pool fillAsyncPoolWithConnections:[NSString class]],
                   @"Fill Async pool allowed invalid connection type");
    
    STAssertThrows([pool fillSyncPoolWithConnections:[NSString class]],
                   @"Fill Sync pool allowed invalid connection type");
    
    STAssertThrows([KCSConnectionPool connectionWithConnectionType:[NSString class]],
                   @"Pool returned is notvalid connection");

}

@end
