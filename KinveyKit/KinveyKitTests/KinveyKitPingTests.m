//
//  KinveyKitPingTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KinveyKitPingTests.h"
#import "KCSClient.h"
#import "KCSKeyChain.h"
#import "KCSConnectionPool.h"
#import "KCSConnectionResponse.h"
#import "KCS_SBJson.h"
#import "KCSMockConnection.h"
#import "KinveyUser.h"
#import "KinveyPing.h"
#import "KinveyErrorCodes.h"
#import "KCSErrorUtilities.h"
#import "TestUtils.h"
#import "NSString+KinveyAdditions.h"

@interface KinveyKitPingTests()
@property (nonatomic, retain) KCS_SBJsonParser *parser;
@property (nonatomic, retain) KCS_SBJsonWriter *writer;
@end

@implementation KinveyKitPingTests

- (void)setUp
{
    KCSClient *client = [KCSClient sharedClient];
    [client setServiceHostname:@"baas"];
    (void)[client initializeKinveyServiceForAppKey:@"kid1234" withAppSecret:@"1234" usingOptions:nil];
    [KCSClient configureLoggingWithNetworkEnabled:YES debugEnabled:YES traceEnabled:YES warningEnabled:YES errorEnabled:YES];
    
    
    // Fake Auth
    [KCSKeyChain setString:@"kinvey" forKey:@"username"];
    [KCSKeyChain setString:@"12345" forKey:@"password"];
    
    // Needed, otherwise we burn a connection later...
    [KCSUser initCurrentUser];
    
    _parser = [[KCS_SBJsonParser alloc] init];
    _writer = [[KCS_SBJsonWriter alloc] init];

}

- (void)tearDown
{
    [[KCSUser activeUser] logout];    
}


- (void)testPingSuccessOnGoodRequestOldStyle
{
    // Set-up client
    (void)[[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid1234"
                                                 withAppSecret:@"1234"
                                                  usingOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                                                                           forKey:KCS_USE_OLD_PING_STYLE_KEY]];
    __block NSString *description;
    __block BOOL pingWasSuccessful;
    
    KCSPingBlock pinger = ^(KCSPingResult *result){
        description = result.description;
        pingWasSuccessful = result.pingWasSuccessful;
    };
    
    NSDictionary *pingResponse = wrapResponseDictionary([NSDictionary dictionaryWithObjectsAndKeys:@"0.6.6", @"version", @"hello", @"kinvey", nil]);
    KCSMockConnection *conn = [[KCSMockConnection alloc] init];

    KCSConnectionResponse *response = [KCSConnectionResponse connectionResponseWithCode:200
                                                                           responseData:[self.writer dataWithObject:pingResponse]
                                                                             headerData:nil
                                                                               userData:nil];

    NSError *failure = [NSError errorWithDomain:KCSErrorDomain
                                           code:KCSBadRequestError
                                       userInfo:[KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Planned Testing Error"
                                                                                          withFailureReason:@"Attempting to simulate failure"
                                                                                     withRecoverySuggestion:@"Non offered, non expected."
                                                                                        withRecoveryOptions:nil]];
    
    conn.responseForSuccess = response;
    conn.errorForFailure = failure;
    conn.connectionShouldReturnNow = YES;
    
    // Success
    conn.connectionShouldFail = NO;
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
    
    [KCSPing pingKinveyWithBlock:pinger];
    
    STAssertTrue(pingWasSuccessful, @"ping should be successful");
    STAssertTrue([description containsStringCaseInsensitive:@"kinvey = hello"], @"");
    STAssertTrue([description containsStringCaseInsensitive:@"version = \"0.6.6\""], @"");
    
    // Reset client
    (void)[[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid1234"
                                                 withAppSecret:@"1234"
                                                  usingOptions:nil];
}

- (void)testPingSuccessOnGoodRequestNewStyle
{
    __block NSString *description;
    __block BOOL pingWasSuccessful;
    
    KCSPingBlock pinger = ^(KCSPingResult *result){
        description = result.description;
        pingWasSuccessful = result.pingWasSuccessful;
    };
    
    NSDictionary *pingResponse = wrapResponseDictionary([NSDictionary dictionaryWithObjectsAndKeys:@"0.6.6", @"version", @"hello", @"kinvey", nil]);
    KCSMockConnection *conn = [[KCSMockConnection alloc] init];
    
    KCSConnectionResponse *response = [KCSConnectionResponse connectionResponseWithCode:200
                                                                           responseData:[self.writer dataWithObject:pingResponse]
                                                                             headerData:nil
                                                                               userData:nil];
    
    NSError *failure = [NSError errorWithDomain:KCSErrorDomain
                                           code:KCSBadRequestError
                                       userInfo:[KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Planned Testing Error"
                                                                                          withFailureReason:@"Attempting to simulate failure"
                                                                                     withRecoverySuggestion:@"Non offered, non expected."
                                                                                        withRecoveryOptions:nil]];
    
    conn.responseForSuccess = response;
    conn.errorForFailure = failure;
    conn.connectionShouldReturnNow = YES;
    
    // Success
    conn.connectionShouldFail = NO;
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
    
    [KCSPing pingKinveyWithBlock:pinger];
    
    STAssertTrue(pingWasSuccessful, @"ping should be successful");
    STAssertTrue([description hasPrefix:@"Kinvey Service is alive, version: "], @"");
    STAssertTrue([description hasSuffix:@", response: hello"], @"");
}


- (void)testPingFailOnBadRequest
{
    __block NSString *description;
    __block BOOL pingWasSuccessful;
    
    KCSPingBlock pinger = ^(KCSPingResult *result){
        description = result.description;
        pingWasSuccessful = result.pingWasSuccessful;
    };
    
    NSDictionary *pingResponse = wrapResponseDictionary([NSDictionary dictionaryWithObjectsAndKeys:@"0.6.6", @"version", @"hello", @"kinvey", nil]);
    KCSMockConnection *conn = [[KCSMockConnection alloc] init];
    
    KCSConnectionResponse *response = [KCSConnectionResponse connectionResponseWithCode:200
                                                                           responseData:[self.writer dataWithObject:pingResponse]
                                                                             headerData:nil
                                                                               userData:nil];
    
    NSError *failure = [NSError errorWithDomain:KCSErrorDomain
                                           code:KCSBadRequestError
                                       userInfo:[KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Planned Testing Error"
                                                                                          withFailureReason:@"Attempting to simulate failure"
                                                                                     withRecoverySuggestion:@"Non offered, non expected."
                                                                                        withRecoveryOptions:nil]];
    
    conn.responseForSuccess = response;
    conn.errorForFailure = failure;
    conn.connectionShouldReturnNow = YES;
    
    // Failure
    conn.connectionShouldFail = YES;
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
    
    [KCSPing pingKinveyWithBlock:pinger];
    
    STAssertFalse(pingWasSuccessful, @"ping should be successful");
    STAssertTrue([description containsStringCaseInsensitive:@"Planned Testing Error"], @"");
}

@end
