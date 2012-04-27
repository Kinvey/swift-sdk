//
//  KinveyKitCollectionTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/19/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KinveyKitCollectionTests.h"
#import "KinveyCollection.h"
#import "KCSClient.h"
#import "KCSConnectionResponse.h"
#import "KCSKeyChain.h"
#import "KinveyUser.h"
#import "SBJson.h"
#import "KCSMockConnection.h"
#import "KinveyPersistable.h"
#import "KinveyEntity.h"
#import "KCSConnectionPool.h"


typedef BOOL(^SuccessAction)(NSArray *);
typedef BOOL(^FailureAction)(NSError *);
typedef BOOL(^InfoSuccessAction)(int);

@interface SimpleClass : NSObject <KCSPersistable>
@property (nonatomic, retain) NSArray *items;
@property (nonatomic, retain) NSString *kinveyID;
@end

@implementation SimpleClass
@synthesize items = _items;
@synthesize kinveyID = _kinveyID;
- (NSDictionary *)hostToKinveyPropertyMapping
{
    return [NSDictionary dictionaryWithObjectsAndKeys:@"_id", @"kinveyID",
            @"items", @"items", nil];
}

@end


@interface KinveyKitCollectionTests ()
@property (nonatomic) BOOL testPassed;
@property (retain, nonatomic) NSString *testID;
@property (retain, nonatomic) SuccessAction onSuccess;
@property (retain, nonatomic) FailureAction onFailure;
@property (retain, nonatomic) InfoSuccessAction onInfoSuccess;
@property (retain, nonatomic) NSString *message;

@property (retain, nonatomic) NSArray *completeDataSet;
@property (retain, nonatomic) NSDictionary *allTypes;
@property (retain, nonatomic) NSDictionary *nesting;

@property (retain, nonatomic) KCS_SBJsonParser *parser;
@property (retain, nonatomic) KCS_SBJsonWriter *writer;

@end

@implementation KinveyKitCollectionTests
@synthesize testID = _testID;
@synthesize onFailure = _onFailure;
@synthesize onSuccess = _onSuccess;
@synthesize onInfoSuccess = _onInfoSuccess;
@synthesize testPassed = _testPassed;
@synthesize message = _message;
@synthesize completeDataSet = _completeDataSet;
@synthesize allTypes = _allTypes;
@synthesize nesting = _nesting;
@synthesize parser = _parser;
@synthesize writer = _writer;

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
    [client setServiceHostname:@"baas"];
    [client initializeKinveyServiceForAppKey:@"kid1234" withAppSecret:@"1234" usingOptions:nil];
    
    
    // Fake Auth
    [KCSKeyChain setString:@"kinvey" forKey:@"username"];
    [KCSKeyChain setString:@"12345" forKey:@"password"];
    
    // Needed, otherwise we burn a connection later...
    [KCSUser initCurrentUser];

    
    // Seed data types
    _allTypes = [NSDictionary dictionaryWithObjectsAndKeys:
                 [NSNumber numberWithInt:1], @"int",
                 [NSNumber numberWithFloat:2.0], @"float",
//                 [NSNumber numberWithFloat:2.0E-11], @"float",                 
                 [NSNumber numberWithDouble:3.14159], @"double",
                 [NSNumber numberWithBool:NO], @"boolNo",
                 [NSNumber numberWithBool:YES], @"boolYes",
                 [NSDate dateWithTimeIntervalSince1970:0], @"date1970",
                 @"This is my string, it's OK!", @"string",
                 nil, @"nil",
                 nil];

    _nesting = [NSDictionary dictionaryWithObjectsAndKeys:
                [NSArray arrayWithObjects:@"one", @"two",[NSArray arrayWithObjects:@"three", _allTypes, nil],nil],@"array",
                [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:@"five", @"six", @"7", nil],@"array",_allTypes,@"dict",nil],@"dict",
                nil];
    
    _completeDataSet = [NSArray arrayWithObjects:_allTypes, _nesting, nil];
                 
    _writer = [[[KCS_SBJsonWriter alloc] init] retain];
    _parser = [[[KCS_SBJsonParser alloc] init] retain];
}

- (void)tearDown
{
    [[[KCSClient sharedClient] currentUser] logout];    
}

- (void)collection:(KCSCollection *)collection didCompleteWithResult:(NSArray *)result
{
    self.testPassed = self.onSuccess(result);
}

- (void)collection:(KCSCollection *)collection didFailWithError:(NSError *)error
{
    self.testPassed = self.onFailure(error);
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
    NSDictionary *dict = [NSDictionary dictionaryWithObject:self.completeDataSet forKey:@"items"];
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
    
    [[[KCSClient sharedClient] collectionFromString:@"testCollection" withClass:[SimpleClass class]] fetchAllWithDelegate:self];

    STAssertTrue(self.testPassed, self.message);
    [conn release];
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
        
        self.message = [NSString stringWithFormat:@"Expected array with 0 count, got array with %d count (%@)", results.count, results];
        if (results.count == 0){
            return YES;
        } else {
            return NO;
        }
    };
    
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
    
    [[[KCSClient sharedClient] collectionFromString:@"testCollection" withClass:[SimpleClass class]] fetchAllWithDelegate:self];
    
    
    STAssertTrue(self.testPassed, self.message);
    [conn release];

}

- (void)testCountFunction
{
    NSDictionary *zero = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:@"count"];
    NSDictionary *one  = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1] forKey:@"count"];
    NSDictionary *bigNum = [NSDictionary dictionaryWithObject:[NSNumber numberWithLongLong:0x7fffffffffffffffLL] forKey:@"count"];
    NSDictionary *negative = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:-1] forKey:@"count"];
    NSDictionary *fraction = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:3.14156] forKey:@"count"];

    KCSClient *client = [KCSClient sharedClient];
    KCSCollection *collection = [client collectionFromString:@"test" withClass:[SimpleClass class]];
    
    KCSConnectionResponse *response = nil;
    __block long long expectedResult = 0;
    
    self.onInfoSuccess = ^(int res){
        self.message = [NSString stringWithFormat:@"Value mismatch, got %d, expected %d", res, expectedResult];
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
    self.testID = [NSString stringWithString:@"Count: 0"];
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
    self.testID = [NSString stringWithString:@"Count: 1"];
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
    self.testID = [NSString stringWithString:@"Count: HUGE"];
    response = [KCSConnectionResponse connectionResponseWithCode:200
                                                    responseData:[self.writer dataWithObject:bigNum]
                                                      headerData:nil
                                                        userData:nil];
    // This test is a little strange, the idea was to fill a 32-bit register
    // with 1's, then, have the library convert that to JSON and send back to
    // the library.  The idea being that we want to test the maximal value for
    // count.  What ends up happening is that the value overflows (to 0?)
    // but still registers as a negative int..., so we end up with:
    // 0x80000000 => -2147483648.
    expectedResult = -2147483648;
    conn.responseForSuccess = response;
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
    [collection entityCountWithDelegate:self];
    STAssertTrue(self.testPassed, self.message);
    self.testPassed = NO;
    // END BIGNUM
    
    // NEGATIVE
    self.testID = [NSString stringWithString:@"Count: -1"];
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
    self.testID = [NSString stringWithString:@"Count: 1/2"];
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

    [conn release];
}



@end
