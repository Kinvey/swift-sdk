//
//  KinveyKitEntityDictTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "KinveyKitEntityDictTests.h"
#import "KinveyKit.h"
#import "KCSObjectMapper.h"

#import "TestUtils.h"
#import "KCSKeyChain.h"
#import "KCSHiddenMethods.h"

#import "KCS_SBJson.h"

typedef BOOL(^SuccessAction)(NSArray *);
typedef BOOL(^FailureAction)(NSError *);
typedef BOOL(^InfoSuccessAction)(int);

@interface KCSEntityDict ()
@property (nonatomic, strong) NSMutableDictionary *entityProperties;
@end

@interface KinveyKitEntityDictTests ()
@property (nonatomic) BOOL testPassed;
@property (retain, nonatomic) NSString *testID;
@property (copy, nonatomic) SuccessAction onSuccess;
@property (copy, nonatomic) FailureAction onFailure;
@property (copy, nonatomic) InfoSuccessAction onInfoSuccess;
@property (retain, nonatomic) NSString *message;

@property (retain, nonatomic) KCS_SBJsonParser *parser;
@property (retain, nonatomic) KCS_SBJsonWriter *writer;

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation KinveyKitEntityDictTests

- (void)setUp
{
    _testID = nil;
    
    // Provide default FALSE implementations
    _onFailure = ^(NSError *err){return NO;};
    _onSuccess = ^(NSArray *res){return NO;};
    _onInfoSuccess = ^(int res){return NO;};
    
    _testPassed = NO;
    _message = nil;
    
    // Ensure that KCSClient is alive
    KCSClient *client = [KCSClient sharedClient];
    [client.configuration setServiceHostname:@"baas"];
    (void)[client initializeKinveyServiceForAppKey:@"kid1234" withAppSecret:@"1234" usingOptions:nil];
    
    
    // Fake Auth
    [KCSKeyChain setString:@"kinvey" forKey:@"username"];
    [KCSKeyChain setString:@"12345" forKey:@"password"];
    
    // Needed, otherwise we burn a connection later...
    [KCSUser activeUser];
    
    
    _writer = [[KCS_SBJsonWriter alloc] init];
    _parser = [[KCS_SBJsonParser alloc] init];
}

- (void)tearDown
{
    [[[KCSClient sharedClient] currentUser] logout];
}


- (void)testSet
{
    KCSEntityDict *d = [[KCSEntityDict alloc] init];
    [d setValue:@"test" forProperty:@"test"];
    // CHEAT
    NSString *str = [[d performSelector:@selector(entityProperties)] objectForKey:@"test"];
    STAssertEqualObjects(str, @"test", @"property should match");
    
    // Verify that we're acting like a dictionary
    STAssertThrows([d setValue:nil forProperty:@"nilTest"], @"Expected throw for nil in dictionary, did not get");
    
    [d setValue:[NSNull null] forProperty:@"nilTest"];
    // CHEAT
    NSNull *n = [[d performSelector:@selector(entityProperties)] objectForKey:@"nilTest"];
    STAssertEqualObjects(n,[NSNull null], @"property should match");
    
    // Number
    NSNumber *tn = @3.14159;
    [d setValue:tn forProperty:@"test"];
    // CHEAT
    NSNumber *nmb = [[d performSelector:@selector(entityProperties)] objectForKey:@"test"];
    STAssertEqualObjects(nmb, tn, @"property should match");
    
    // Bool
    tn = @(YES);
    [d setValue:tn forProperty:@"test"];
    // CHEAT
    nmb = [[d performSelector:@selector(entityProperties)] objectForKey:@"test"];
    STAssertEqualObjects(nmb, tn, @"property should match");

    // Array
    NSArray *t = [NSArray arrayWithObjects:@"one", @"two", @"three", nil];
    [d setValue:t forProperty:@"test"];
    // CHEAT
    NSArray *array = [[d performSelector:@selector(entityProperties)] objectForKey:@"test"];
    STAssertEqualObjects(array, t, @"property should match");

    // Dict
    NSDictionary *td = [NSDictionary dictionaryWithObjectsAndKeys:@"1", @"one", @"2", @"two", nil];
    [d setValue:td forProperty:@"test"];
    // CHEAT
    NSDictionary *dict = [[d performSelector:@selector(entityProperties)] objectForKey:@"test"];
    STAssertEqualObjects(dict, td, @"property should match");

}

- (void)testGet
{
    KCSEntityDict *d = [[KCSEntityDict alloc] init];
    [d setValue:@"test" forProperty:@"test"];
    NSString *str = [d getValueForProperty:@"test"];
    STAssertEqualObjects(str, @"test", @"property should match");
    
    // Verify that we're acting like a dictionary
    STAssertThrows([d setValue:nil forProperty:@"nilTest"], @"Expected throw for nil in dictionary, did not get");
    
    [d setValue:[NSNull null] forProperty:@"nilTest"];
    NSNull *n = [d getValueForProperty:@"nilTest"];
    STAssertEqualObjects(n, [NSNull null], @"property should match");
    
    // Number
    NSNumber *tn = [NSNumber numberWithDouble:3.14159];
    [d setValue:tn forProperty:@"test"];
    NSNumber *nmb = [d getValueForProperty:@"test"];
    STAssertEqualObjects(nmb, tn, @"property should match");
    
    // Bool
    tn = [NSNumber numberWithBool:YES];
    [d setValue:tn forProperty:@"test"];
    nmb = [d getValueForProperty:@"test"];
    STAssertEqualObjects(nmb, tn, @"property should match");

    
    // Array
    NSArray *t = [NSArray arrayWithObjects:@"one", @"two", @"three", nil];
    [d setValue:t forProperty:@"test"];
    NSArray *array = [d getValueForProperty:@"test"];
    STAssertEqualObjects(array, t, @"property should match");

    // Dict
    NSDictionary *td = [NSDictionary dictionaryWithObjectsAndKeys:@"1", @"one", @"2", @"two", nil];
    [d setValue:td forProperty:@"test"];
    NSDictionary *dict = [d getValueForProperty:@"test"];
    STAssertEqualObjects(dict, td, @"property should match");

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
#pragma clang diagnostic pop
