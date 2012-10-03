//
//  KinveyKitKeyChainTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KinveyKitKeyChainTests.h"
#import "KCSKeyChain.h"


@implementation KinveyKitKeyChainTests

- (void)setUp{
    [KCSKeyChain setString:@"Test String" forKey:@"getTest"];
    [KCSKeyChain setString:@"Delete Test" forKey:@"rmTest"];
}

- (void)tearDown{
    [KCSKeyChain removeStringForKey:@"getTest"];
    [KCSKeyChain removeStringForKey:@"rmTest"];
}

- (void)testGetNonExistentKeyReturnsNil{
    NSString *value = [KCSKeyChain getStringForKey:@"DoesNotExist"];
    STAssertNil(value, @"should be nil");
}

- (void)testNilKeyReturnsNil{
    NSString *value = [KCSKeyChain getStringForKey:nil];
    STAssertNil(value, @"should be nil");
}

- (void)testRemoveNonExistentValueReturnsFalse{
    BOOL retVal = [KCSKeyChain removeStringForKey:@"DoesNotExist"];

    STAssertFalse(retVal, @"should be false");
}

- (void)testSetValueWithNilKeyReturnsFalse{
    BOOL retVal = [KCSKeyChain setString:@"testSetValueWithNilKeyReturnsFalse" forKey:nil];
    STAssertFalse(retVal, @"should be false");
}

- (void)testGetValue{
    NSString *retVal = [KCSKeyChain getStringForKey:@"getTest"];
    STAssertEqualObjects(retVal, @"Test String", @"strings should match");
}

- (void)testRemoveValue{
    NSString *retVal = [KCSKeyChain getStringForKey:@"rmTest"];
    STAssertEqualObjects(retVal, @"Delete Test", @"strings should match");
   
    BOOL rmRetVal = [KCSKeyChain removeStringForKey:@"rmTest"];
    STAssertTrue(rmRetVal, @"Should be true");

    retVal = [KCSKeyChain getStringForKey:@"rmTest"];
    STAssertNil(retVal, @"string should be nil after removal");
}


- (void)testSetValueSetsValue{

    NSString *testKey = @"testKey";
    NSString *testValue = @"testSetValueSetsValue";
    
    // Set value, make sure response is YES
    BOOL setRetVal = [KCSKeyChain setString:testValue forKey:testKey];
    STAssertTrue(setRetVal, @"set should be YES");
    
    // Check value
    NSString *key = [KCSKeyChain getStringForKey:testKey];
    STAssertEqualObjects(key, testValue, @"keys should match");
    
    // Remove value
    setRetVal = [KCSKeyChain removeStringForKey:testKey];
    STAssertTrue(setRetVal, @"remove should be YES");
}

@end
