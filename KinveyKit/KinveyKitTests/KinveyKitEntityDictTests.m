//
//  KinveyKitEntityDictTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, understand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
//


#import "KinveyKitEntityDictTests.h"
#import "KinveyKit.h"
#import "KCSObjectMapper.h"

#import "TestUtils.h"
#import "KCSHiddenMethods.h"

@interface KinveyKitEntityDictTests ()

@end


@implementation KinveyKitEntityDictTests

- (void)setUp
{
}

- (void)tearDown
{
}


- (void) testSerialize
{
    NSDictionary* myDict = @{@"_id" : @"12345", @"keyA" : @"valA", @"keyB" : @10};
    KCSSerializedObject* so = [KCSObjectMapper makeKinveyDictionaryFromObject:myDict error:NULL];
    NSDictionary* outDict = [so dataToSerialize];
    STAssertFalse(so.isPostRequest, @"Should not be a post because _id is specified");
    STAssertEqualObjects(myDict, outDict, @"dicts should be the same");
    
    myDict = @{@"keyA" : @"valA", @"keyB" : @10};
    so = [KCSObjectMapper makeKinveyDictionaryFromObject:myDict error:NULL];
    outDict = [so dataToSerialize];
    STAssertTrue(so.isPostRequest, @"Should be true, no _id is specified");
    STAssertEqualObjects(myDict, outDict, @"dicts should be the same");
}

- (void) testRoundtrip
{
    BOOL setup = [TestUtils setUpKinveyUnittestBackend];
    STAssertTrue(setup, @"should be set up");
    
    KCSCollection* testCollection = [TestUtils randomCollection:[NSDictionary class]];
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:testCollection options:nil];
    
    NSDictionary* obj = @{@"test" : @"testRoundtrip", @"timestamp" : [NSDate date]};
    
    __block NSDictionary* retDict = nil;
    
    self.done = NO;
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        retDict = [objectsOrNil objectAtIndex:0];
        STAssertEqualObjects(obj, retDict, @"dicts should match");
        self.done = YES;
    } withProgressBlock:nil];;
    [self poll];
    
    self.done = NO;
    [store queryWithQuery:[KCSQuery queryOnField:@"test" withExactMatchForValue:@"testRoundtrip"] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        retDict = [objectsOrNil objectAtIndex:0];
        STAssertEqualObjects([obj objectForKey:@"test"], [retDict objectForKey:@"test"], @"dicts should match");
        NSDate* oDate = [obj objectForKey:@"timestamp"];
        NSDate* nDate = [retDict objectForKey:@"timestamp"];
        STAssertTrue([oDate timeIntervalSinceDate:nDate] < 1000, @"dicts should match");
        STAssertNotNil([retDict objectForKey:@"_id"], @"should have id specified");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
}

- (void) testRoundTripMutable
{
    BOOL setup = [TestUtils setUpKinveyUnittestBackend];
    STAssertTrue(setup, @"should be set up");
    
    KCSCollection* testCollection = [TestUtils randomCollection:[NSMutableDictionary class]];
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:testCollection options:nil];
    
    NSDictionary* obj = [@{@"test" : @"testRoundtrip", @"timestamp" : [NSDate date]}  mutableCopy];
    
    __block NSDictionary* retDict = nil;
    
    self.done = NO;
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        retDict = [objectsOrNil objectAtIndex:0];
        STAssertEqualObjects([obj objectForKey:@"test"], [retDict objectForKey:@"test"], @"dicts should match");
        NSDate* oDate = [obj objectForKey:@"timestamp"];
        NSDate* nDate = [retDict objectForKey:@"timestamp"];
        STAssertTrue([oDate timeIntervalSinceDate:nDate] < 1000, @"dicts should match");
        STAssertNotNil([retDict objectForKey:@"_id"], @"should have id specified");
        self.done = YES;
    } withProgressBlock:nil];;
    [self poll];
    
    self.done = NO;
    [store loadObjectWithID:[retDict objectForKey:@"_id"] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError;
        retDict = [objectsOrNil objectAtIndex:0];
        STAssertEqualObjects([obj objectForKey:@"test"], [retDict objectForKey:@"test"], @"dicts should match");
        NSDate* oDate = [obj objectForKey:@"timestamp"];
        NSDate* nDate = [retDict objectForKey:@"timestamp"];
        STAssertTrue([oDate timeIntervalSinceDate:nDate] < 1000, @"dicts should match");
        STAssertNotNil([retDict objectForKey:@"_id"], @"should have id specified");
        self.done = YES;
    } withProgressBlock:nil];
    [self poll];
}

@end
