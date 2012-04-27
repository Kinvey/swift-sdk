//
//  KinveyKitEntityDictTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KinveyKitEntityDictTests.h"
#import "KCSEntityDict.h"

@implementation KinveyKitEntityDictTests

- (void)testSet
{
    KCSEntityDict *d = [[KCSEntityDict alloc] init];
    [d setValue:@"test" forProperty:@"test"];
    // CHEAT
    NSString *str = [[d entityProperties] objectForKey:@"test"];
    assertThat(str, is(equalTo(@"test")));
    
    
    // Verify that we're acting like a dictionary
    STAssertThrows([d setValue:nil forProperty:@"nilTest"], @"Expected throw for nil in dictionary, did not get");
    
    [d setValue:[NSNull null] forProperty:@"nilTest"];
    // CHEAT
    NSNull *n = [[d entityProperties] objectForKey:@"nilTest"];
    assertThat(n, is(equalTo([NSNull null])));
    
    // Number
    NSNumber *tn = [NSNumber numberWithDouble:3.14159];
    [d setValue:tn forProperty:@"test"];
    // CHEAT
    NSNumber *nmb = [[d entityProperties] objectForKey:@"test"];
    assertThat(nmb, is(equalTo(tn)));
    
    // Bool
    tn = [NSNumber numberWithBool:YES];
    [d setValue:tn forProperty:@"test"];
    // CHEAT
    nmb = [[d entityProperties] objectForKey:@"test"];
    assertThat(nmb, is(equalTo(tn)));

    // Array
    NSArray *t = [NSArray arrayWithObjects:@"one", @"two", @"three", nil];
    [d setValue:t forProperty:@"test"];
    // CHEAT
    NSArray *array = [[d entityProperties] objectForKey:@"test"];
    assertThat(array, is(equalTo(t)));

    // Dict
    NSDictionary *td = [NSDictionary dictionaryWithObjectsAndKeys:@"1", @"one", @"2", @"two", nil];
    [d setValue:td forProperty:@"test"];
    // CHEAT
    NSDictionary *dict = [[d entityProperties] objectForKey:@"test"];
    assertThat(dict, is(equalTo(td)));
    
}

- (void)testGet
{
    KCSEntityDict *d = [[KCSEntityDict alloc] init];
    [d setValue:@"test" forProperty:@"test"];
    NSString *str = [d getValueForProperty:@"test"];
    assertThat(str, is(equalTo(@"test")));
    
    
    // Verify that we're acting like a dictionary
    STAssertThrows([d setValue:nil forProperty:@"nilTest"], @"Expected throw for nil in dictionary, did not get");
    
    [d setValue:[NSNull null] forProperty:@"nilTest"];
    NSNull *n = [d getValueForProperty:@"nilTest"];
    assertThat(n, is(equalTo([NSNull null])));
    
    // Number
    NSNumber *tn = [NSNumber numberWithDouble:3.14159];
    [d setValue:tn forProperty:@"test"];
    NSNumber *nmb = [d getValueForProperty:@"test"];
    assertThat(nmb, is(equalTo(tn)));
    
    // Bool
    tn = [NSNumber numberWithBool:YES];
    [d setValue:tn forProperty:@"test"];
    nmb = [d getValueForProperty:@"test"];
    assertThat(nmb, is(equalTo(tn)));
    
    // Array
    NSArray *t = [NSArray arrayWithObjects:@"one", @"two", @"three", nil];
    [d setValue:t forProperty:@"test"];
    NSArray *array = [d getValueForProperty:@"test"];
    assertThat(array, is(equalTo(t)));
    
    // Dict
    NSDictionary *td = [NSDictionary dictionaryWithObjectsAndKeys:@"1", @"one", @"2", @"two", nil];
    [d setValue:td forProperty:@"test"];
    NSDictionary *dict = [d getValueForProperty:@"test"];
    assertThat(dict, is(equalTo(td)));
    
   
}

- (void)testSerialize
{
    
}

- (void)testCRUD
{
    
}

// All code under test must be linked into the Unit Test bundle
- (void)testEntityDictUnimplemented{
    STFail(@"Entity Dicts are not yet implemented");
}

@end
