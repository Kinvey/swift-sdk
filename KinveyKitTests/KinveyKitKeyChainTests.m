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
    assertThat(value, is(nilValue()));
}

- (void)testNilKeyReturnsNil{
    NSString *value = [KCSKeyChain getStringForKey:nil];
    assertThat(value, is(nilValue()));
}

- (void)testRemoveNonExistentValueReturnsFalse{
    NSNumber *retVal =
    [NSNumber numberWithBool:[KCSKeyChain removeStringForKey:@"DoesNotExist"]];

    assertThat(retVal, is(equalToBool(NO)));
}

- (void)testSetValueWithNilKeyReturnsFalse{
    NSNumber *retVal = [NSNumber numberWithBool:
                        [KCSKeyChain setString:@"testSetValueWithNilKeyReturnsFalse"
                                        forKey:nil]];
    
    assertThat(retVal, is(equalToBool(NO)));

}

- (void)testGetValue{
    NSString *retVal = [KCSKeyChain getStringForKey:@"getTest"];
    assertThat(retVal, is(equalTo(@"Test String")));
}

- (void)testRemoveValue{
    NSString *retVal = [KCSKeyChain getStringForKey:@"rmTest"];
    assertThat(retVal, is(equalTo(@"Delete Test")));
    NSNumber *rmRetVal = [NSNumber numberWithBool:[KCSKeyChain removeStringForKey:@"rmTest"]];
    assertThat(rmRetVal, is(equalToBool(YES)));
    retVal = [KCSKeyChain getStringForKey:@"rmTest"];
    assertThat(retVal, is(nilValue()));
}


- (void)testSetValueSetsValue{

    NSString *testKey = @"testKey";
    NSString *testValue = @"testSetValueSetsValue";
    
    // Set value, make sure response is YES
    NSNumber *setRetVal = [NSNumber numberWithBool:
                           [KCSKeyChain setString:testValue
                                           forKey:testKey]];
    
    assertThat(setRetVal, is(equalToBool(YES)));
    
    // Check value
    NSString *key = [KCSKeyChain getStringForKey:testKey];
    assertThat(key, is(equalTo(testValue)));
    
    // Remove value
    setRetVal = [NSNumber numberWithBool:
                 [KCSKeyChain removeStringForKey:testKey]];
    assertThat(setRetVal, is(equalToBool(YES)));
    
    
}



@end
