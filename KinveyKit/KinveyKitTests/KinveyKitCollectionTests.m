//
//  KinveyKitCollectionTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/19/11.
//  Copyright (c) 2011-2013 Kinvey. All rights reserved.
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


#import "KinveyKitCollectionTests.h"
#import "KinveyCollection.h"
#import "KCSClient.h"
#import "KCSConnectionResponse.h"
#import "KCSKeyChain.h"
#import "KinveyUser.h"
#import "KCS_SBJson.h"
#import "KCSMockConnection.h"
#import "KinveyPersistable.h"
#import "KinveyEntity.h"
#import "KCSConnectionPool.h"
#import "KCSQuery.h"
#import "TestUtils.h"
#import "KCSHiddenMethods.h"


typedef BOOL(^SuccessAction)(NSArray *);
typedef BOOL(^FailureAction)(NSError *);
typedef BOOL(^InfoSuccessAction)(int);

@interface SimpleClass : NSObject <KCSPersistable>
@property (nonatomic, retain) NSArray *items;
@property (nonatomic, retain) NSString *kinveyID;
@end

@implementation SimpleClass
- (NSDictionary *)hostToKinveyPropertyMapping
{
    return [NSDictionary dictionaryWithObjectsAndKeys:@"_id", @"kinveyID",
            @"items", @"items", nil];
}

@end


@interface KinveyKitCollectionTests ()
@property (nonatomic) BOOL testPassed;
@property (retain, nonatomic) NSString *testID;
@property (copy, nonatomic) SuccessAction onSuccess;
@property (copy, nonatomic) FailureAction onFailure;
@property (copy, nonatomic) InfoSuccessAction onInfoSuccess;
@property (retain, nonatomic) NSString *message;

@property (retain, nonatomic) NSArray *completeDataSet;
@property (retain, nonatomic) NSDictionary *allTypes;
@property (retain, nonatomic) NSDictionary *nesting;

@property (retain, nonatomic) KCS_SBJsonParser *parser;
@property (retain, nonatomic) KCS_SBJsonWriter *writer;

@end

@implementation KinveyKitCollectionTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"

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

    
    // Seed data types
    _allTypes = [NSDictionary dictionaryWithObjectsAndKeys:
                 @1, @"int",
                 @2.0, @"float",
                 @3.14159, @"double",
                 @NO, @"boolNo",
                 @YES, @"boolYes",
                 [NSDate dateWithTimeIntervalSince1970:0], @"date1970",
                 @"This is my string, it's OK!", @"string",
                 nil, @"nil",
                 nil];

    _nesting = [NSDictionary dictionaryWithObjectsAndKeys:
                @[@"one", @"two", @[@"three", _allTypes]],@"array",
                [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"five", @"six", @"7", nil],@"array",_allTypes,@"dict",nil],@"dict",
                nil];
    
    self.completeDataSet = @[_allTypes, _nesting];
                 
    _writer = [[KCS_SBJsonWriter alloc] init];
    _parser = [[KCS_SBJsonParser alloc] init];
}

- (void)tearDown
{
    [[KCSUser activeUser] logout];
}

- (void)collection:(KCSCollection *)collection didCompleteWithResult:(NSArray *)result
{
    self.testPassed = self.onSuccess(result);
    self.done = YES;
}

- (void)collection:(KCSCollection *)collection didFailWithError:(NSError *)error
{
    self.testPassed = self.onFailure(error);
    self.done = YES;
}

- (void)collection:(KCSCollection *)collection informationOperationDidCompleteWithResult:(int)result
{
    self.testPassed = self.onInfoSuccess(result);
}

- (void)collection:(KCSCollection *)collection informationOperationFailedWithError:(NSError *)error
{
    self.testPassed = self.onFailure(error);
}

- (void)testFetchAll
{
    NSDictionary *dict = wrapResponseDictionary(@{@"items" : self.completeDataSet});
    NSData* data = [self.writer dataWithObject:dict];
    KCSConnectionResponse *response = [KCSConnectionResponse connectionResponseWithCode:200
                                                                           responseData:data
                                                                             headerData:nil
                                                                               userData:nil];
    
    KCSMockConnection *conn = [[KCSMockConnection alloc] init];
    conn.responseForSuccess = response;
    
    conn.connectionShouldFail = NO;
    conn.connectionShouldReturnNow = YES;
    
    self.onSuccess = ^(NSArray *results){

        NSArray *expected = self.completeDataSet;
        SimpleClass *data = [results objectAtIndex:0];
        NSArray *actual = [data items];
        self.message = [NSString stringWithFormat:@"Received: %@\n\n\nExpected: %@", actual, expected];

        BOOL areTheyEqual = [actual isEqualToArray:expected];
        return areTheyEqual;
    };
    
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
    
    KCSCollection* collection = [KCSCollection collectionFromString:@"testCollection" ofClass:[SimpleClass class]];
    [collection fetchAllWithDelegate:self];

    STAssertTrue(self.testPassed, self.message);
}

- (void) testQueryWithDelegate
{
    NSDictionary *dict = wrapResponseDictionary([NSDictionary dictionaryWithObject:self.completeDataSet forKey:@"items"]);
    KCSConnectionResponse *response = [KCSConnectionResponse connectionResponseWithCode:200
                                                                           responseData:[self.writer dataWithObject:dict]
                                                                             headerData:nil
                                                                               userData:nil];
    
    KCSMockConnection *conn = [[KCSMockConnection alloc] init];
    conn.responseForSuccess = response;
    
    conn.connectionShouldFail = NO;
    conn.connectionShouldReturnNow = YES;
    
    self.onSuccess = ^(NSArray *results){
        
        NSArray *expected = self.completeDataSet;
        SimpleClass *data = [results objectAtIndex:0];
        NSArray *actual = [data items];
        self.message = [NSString stringWithFormat:@"Received: %@\n\n\nExpected: %@", actual, expected];
        
        BOOL areTheyEqual = [actual isEqualToArray:expected];
        return areTheyEqual;
    };
    
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
    
    KCSCollection* collection = [KCSCollection collectionFromString:@"testCollection" ofClass:[SimpleClass class]];
    [collection fetchWithQuery:[KCSQuery query] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        self.testPassed = self.onSuccess(objectsOrNil);
    } withProgressBlock:nil];
    
    STAssertTrue(self.testPassed, self.message);
}

- (void)testFetchEmptyCollectionReturns0SizedArray
{
    NSDictionary *dict = [NSDictionary dictionary];
    KCSConnectionResponse *response = [KCSConnectionResponse connectionResponseWithCode:200
                                                                           responseData:[self.writer dataWithObject:dict]
                                                                             headerData:nil
                                                                               userData:nil];
    
    KCSMockConnection *conn = [[KCSMockConnection alloc] init];
    conn.responseForSuccess = response;
    
    conn.connectionShouldFail = NO;
    conn.connectionShouldReturnNow = YES;
    
    self.onSuccess = ^(NSArray *results){
        
        self.message = [NSString stringWithFormat:@"Expected array with 0 count, got array with %lu count (%@)", (unsigned long)results.count, results];
        if (results.count == 0){
            return YES;
        } else {
            return NO;
        }
    };
    
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
    
    [[KCSCollection collectionFromString:@"testCollection" ofClass:[SimpleClass class]] fetchAllWithDelegate:self];
    
    
    STAssertTrue(self.testPassed, self.message);
}

- (void)testCountFunction
{
    NSDictionary *zero = wrapResponseDictionary([NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:@"count"]);
    NSDictionary *one  =  wrapResponseDictionary([NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"count"]);
    NSDictionary *bigNum =  wrapResponseDictionary([NSDictionary dictionaryWithObject:[NSNumber numberWithLongLong:0x7fffffffffffffffLL] forKey:@"count"]);
    NSDictionary *negative =  wrapResponseDictionary([NSDictionary dictionaryWithObject:[NSNumber numberWithInt:-1] forKey:@"count"]);
    NSDictionary *fraction =  wrapResponseDictionary([NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:3.14156] forKey:@"count"]);

    KCSCollection *collection = [KCSCollection collectionFromString:@"test" ofClass:[SimpleClass class]];
    
    KCSConnectionResponse *response = nil;
    __block long long expectedResult = 0;
    
    self.onInfoSuccess = ^(int res){
        self.message = [NSString stringWithFormat:@"Value mismatch, got %d, expected %lld", res, expectedResult];
        if (res != expectedResult){
            return NO;
        } else {
            return YES;
        }
    };

    // Same for all
    KCSMockConnection *conn = [[KCSMockConnection alloc] init];
    conn.connectionShouldFail = NO;
    conn.connectionShouldReturnNow = YES;

    // ZERO
    self.testID = @"Count: 0";
    response = [KCSConnectionResponse connectionResponseWithCode:200
                                                    responseData:[self.writer dataWithObject:zero]
                                                      headerData:nil
                                                        userData:nil];
    expectedResult = 0;
    conn.responseForSuccess = response;
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
    [collection entityCountWithDelegate:self];
    STAssertTrue(self.testPassed, self.message);
    self.testPassed = NO;
    // END ZERO
    
    // ONE
    self.testID = @"Count: 1";
    response = [KCSConnectionResponse connectionResponseWithCode:200
                                                    responseData:[self.writer dataWithObject:one]
                                                      headerData:nil
                                                        userData:nil];
    expectedResult = 1;
    conn.responseForSuccess = response;
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
    [collection entityCountWithDelegate:self];
    STAssertTrue(self.testPassed, self.message);
    self.testPassed = NO;
    // END ONE
    
    // BIGNUM
    self.testID = @"Count: HUGE";
    NSData* data = [self.writer dataWithObject:bigNum];
    response = [KCSConnectionResponse connectionResponseWithCode:200
                                                    responseData:data
                                                      headerData:nil
                                                        userData:nil];
    // This test is a little strange, the idea was to fill a 32-bit register
    // with 1's, then, have the library convert that to JSON and send back to
    // the library.  The idea being that we want to test the maximal value for
    // count.  What ends up happening is that the value overflows (to 0?)
    // but still registers as a negative int..., so we end up with:
    // 0x80000000 => -2147483648.
    expectedResult = -1;
    conn.responseForSuccess = response;
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
    [collection entityCountWithDelegate:self];
    STAssertTrue(self.testPassed, self.message);
    self.testPassed = NO;
    // END BIGNUM
    
    // NEGATIVE
    self.testID = @"Count: -1";
    response = [KCSConnectionResponse connectionResponseWithCode:200
                                                    responseData:[self.writer dataWithObject:negative]
                                                      headerData:nil
                                                        userData:nil];
    expectedResult = -1;
    conn.responseForSuccess = response;
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
    [collection entityCountWithDelegate:self];
    STAssertTrue(self.testPassed, self.message);
    self.testPassed = NO;
    // END NEGATIVE

    // FRACTION
    self.testID = @"Count: 1/2";
    response = [KCSConnectionResponse connectionResponseWithCode:200
                                                    responseData:[self.writer dataWithObject:fraction]
                                                      headerData:nil
                                                        userData:nil];
    expectedResult = 3;
    conn.responseForSuccess = response;
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
    [collection entityCountWithDelegate:self];
    STAssertTrue(self.testPassed, self.message);
    self.testPassed = NO;
    // END FRACTION
}

- (void) testQuery
{
    KCSQuery* aq = [KCSQuery query];
    KCSCollection* collection = [KCSCollection collectionFromString:@"abc" ofClass:[NSMutableDictionary class]];
    [collection fetchWithQuery:aq withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        self.done = YES;
    } withProgressBlock:nil];
    
    [self poll];
}


- (void) testQueryQlio
{
    [TestUtils setUpKinveyUnittestBackend];
    KCSQuery *q = [KCSQuery queryOnField:@"location"
                  withExactMatchForValue:@"N"];
    KCSCollection *fuelStations = [KCSCollection 
                                   collectionFromString:@"qlio-errors"
                                   ofClass:[NSMutableDictionary class]];
    fuelStations.query=q;
    [fuelStations fetchWithDelegate:self];
    
    [self poll];
    
    
//    For example this is iOS app code:
//    KCSQuery *q = [KCSQuery queryOnField:@"location" withExactMatchForValue:[NSString stringWithFormat:@"%f,%f", newLocation.coordinate.latitude, newLocation.coordinate.longitude]];
//    KCSCollection *fuelStations = [[KCSClient sharedClient]
//                                   collectionFromString:@"FuelStations"
//                                   withClass:[NSMutableDictionary class]];
//    KCSAppdataStore* fuelStationStore = [KCSAppdataStore storeWithCollection:fuelStations options:nil];
//    [fuelStationStore queryWithQuery:q withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//        //handle response
//    } withProgressBlock:nil];
    
//    [KCSUser initCurrentUser]; //loads the activeUser from keychain
//    
//    
//    NSArray* usernames = @[@"12345", @"username2", @"basfsadsaXE2"]; //whatever usernames you have
//    KCSQuery* query = [KCSQuery queryOnField:KCSUserAttributeUsername usingConditional:kKCSIn forValue:usernames]; //find users with username in 'usernames' array
//    
//    //optional, sort return by last names
//    KCSQuerySortModifier* sort = [[KCSQuerySortModifier alloc] initWithField:KCSUserAttributeSurname inDirection:kKCSAscending];
//    [query addSortModifier:sort];
//    
//    KCSCachedStore* userStore = [KCSCachedStore storeWithCollection:[KCSCollection userCollection] options:@{KCSStoreKeyCachePolicy : @(KCSCachePolicyLocalFirst)}]; //store that caches and reads from the cache and updates in the background
//    [userStore queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//        //handle response
//    } withProgressBlock:nil];
}
#pragma clang diagnostic pop
@end
