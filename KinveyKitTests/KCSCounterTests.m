//
//  KCSCounterTests.m
//  KinveyKit
//
//  Created by Michael Katz on 9/13/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSCounterTests.h"
#import "TestUtils.h"
#import "KinveyKit.h"
#import "ASTTestClass.h"

@implementation KCSCounterTests

- (void) setUp
{
    [TestUtils setUpKinveyUnittestBackend];
}

- (void) testGet
{
    KCSCollection* collection = [[KCSCollection alloc] init];
    collection.collectionName = [NSString stringWithFormat:@"testObjects%i", arc4random()];
    collection.objectTemplate = [ASTTestClass class];
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:collection options:nil];
    
    self.done = NO;
    [store loadObjectWithID:KCSSequenceId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertNotNil(objectsOrNil, @"should get objects back");
        STAssertTrue(objectsOrNil.count == 1, @"Should have one object back");
        KCSUniqueNumber* counter = [objectsOrNil objectAtIndex:0];
        STAssertTrue([counter isKindOfClass:[KCSUniqueNumber class]], @"should be a counter entity");
        STAssertEquals((int)1, (int)counter.value, @"should be 1");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
}

- (void) testSet
{
    KCSCollection* collection = [[KCSCollection alloc] init];
    collection.collectionName = [NSString stringWithFormat:@"testObjects%i", arc4random()];
    collection.objectTemplate = [ASTTestClass class];
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:collection options:nil];
    
    KCSUniqueNumber* counter = [KCSUniqueNumber defaultSequence];
    counter.value = 300;
    
    self.done = NO;
    [store saveObject:counter withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertNotNil(objectsOrNil, @"should get objects back");
        STAssertTrue(objectsOrNil.count == 1, @"Should have one object back");
        KCSUniqueNumber* counter = [objectsOrNil objectAtIndex:0];
        STAssertTrue([counter isKindOfClass:[KCSUniqueNumber class]], @"should be a counter entity");
        STAssertEquals((int)300, (int)counter.value, @"should not be changed");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    self.done = NO;
    [store loadObjectWithID:KCSSequenceId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertNotNil(objectsOrNil, @"should get objects back");
        STAssertTrue(objectsOrNil.count == 1, @"Should have one object back");
        KCSUniqueNumber* counter = [objectsOrNil objectAtIndex:0];
        STAssertTrue([counter isKindOfClass:[KCSUniqueNumber class]], @"should be a counter entity");
        STAssertEquals((int)counter.value, (int)300, @"should be 300");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    self.done = NO;
    [store loadObjectWithID:KCSSequenceId withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertNotNil(objectsOrNil, @"should get objects back");
        STAssertTrue(objectsOrNil.count == 1, @"Should have one object back");
        KCSUniqueNumber* counter = [objectsOrNil objectAtIndex:0];
        STAssertTrue([counter isKindOfClass:[KCSUniqueNumber class]], @"should be a counter entity");
        STAssertEquals((int)counter.value, (int)301, @"subsequent get should be 301");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
}

- (void) testCounterCollection
{
    KCSCollection* collection = [[KCSCollection alloc] init];
    collection.collectionName = [NSString stringWithFormat:@"testObjects%i", arc4random()];
    collection.objectTemplate = [ASTTestClass class];
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:collection options:nil];
    
    KCSUniqueNumber* counter1 = [[[KCSUniqueNumber alloc] init] autorelease];
    counter1.sequenceId = @"A";
    
    KCSUniqueNumber* counter2 = [[[KCSUniqueNumber alloc] init] autorelease];
    counter2.sequenceId = @"B";
    counter2.value = 100;
    
    self.done = NO;
    [store saveObject:@[counter1, counter2] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertNotNil(objectsOrNil, @"should get objects back");
        STAssertTrue(objectsOrNil.count == 2, @"Should have one object back");
        KCSUniqueNumber* counter = [objectsOrNil objectAtIndex:0];
        STAssertTrue([counter isKindOfClass:[KCSUniqueNumber class]], @"should be a counter entity");
        STAssertTrue(counter.value == 0 || counter.value == 100, @"should not be changed");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    self.done = NO;
    [store loadObjectWithID:@[@"A",@"B"] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertNotNil(objectsOrNil, @"should get objects back");
        STAssertTrue(objectsOrNil.count == 2, @"Should have one object back");
        KCSUniqueNumber* counter = [objectsOrNil objectAtIndex:0];
        STAssertTrue([counter isKindOfClass:[KCSUniqueNumber class]], @"should be a counter entity");
        STAssertTrue(counter.value == 0 || counter.value == 100, @"should not be changed on first get");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
    
    self.done = NO;
    [store loadObjectWithID:@[@"A",@"B"] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertNotNil(objectsOrNil, @"should get objects back");
        STAssertTrue(objectsOrNil.count == 2, @"Should have one object back");
        KCSUniqueNumber* counter = [objectsOrNil objectAtIndex:0];
        STAssertTrue([counter isKindOfClass:[KCSUniqueNumber class]], @"should be a counter entity");
        STAssertTrue(counter.value == 1 || counter.value == 101, @"should be incremented");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
}

@end
