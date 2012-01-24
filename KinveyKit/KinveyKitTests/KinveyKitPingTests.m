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
#import "SBJson.h"
#import "KCSMockConnection.h"
#import "KinveyUser.h"
#import "KinveyPing.h"
#import "KinveyErrorCodes.h"
#import "KCSErrorUtilities.h"

@interface KinveyKitPingTests()
@property (nonatomic, retain) KCS_SBJsonParser *parser;
@property (nonatomic, retain) KCS_SBJsonWriter *writer;
@end

@implementation KinveyKitPingTests
@synthesize parser = _parser;
@synthesize writer = _writer;


- (void)setUp
{
    KCSClient *client = [KCSClient sharedClient];
    [client setServiceHostname:@"baas"];
    [client initializeKinveyServiceForAppKey:@"kid1234" withAppSecret:@"1234" usingOptions:nil];
    
    
    // Fake Auth
    [KCSKeyChain setString:@"kinvey" forKey:@"username"];
    [KCSKeyChain setString:@"12345" forKey:@"password"];
    
    // Needed, otherwise we burn a connection later...
    [KCSUser initCurrentUser];
    
    _parser = [[[KCS_SBJsonParser alloc] init]retain];
    _writer = [[[KCS_SBJsonWriter alloc] init]retain];

}

- (void)tearDown
{
    [[[KCSClient sharedClient] currentUser] logout];    
}


- (void)testPingSuccessOnGoodRequestOldStyle
{
    // Set-up client
    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid1234" 
                                                 withAppSecret:@"1234"
                                                  usingOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                                                                           forKey:KCS_USE_OLD_PING_STYLE_KEY]];
    __block NSString *description;
    __block BOOL pingWasSuccessful;
    
    KCSPingBlock pinger = ^(KCSPingResult *result){
        description = result.description;
        pingWasSuccessful = result.pingWasSuccessful;
    };
    
    NSDictionary *pingResponse = [NSDictionary dictionaryWithObjectsAndKeys:@"0.6.6", @"version", @"hello", @"kinvey", nil];
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
    
    assertThat([NSNumber numberWithBool:pingWasSuccessful], is(equalToBool(YES)));
    assertThat(description, containsString(@"kinvey = hello"));
    assertThat(description, containsString(@"version = \"0.6.6\""));
    
    [conn release];
    
    // Reset client
    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid1234" 
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
    
    NSDictionary *pingResponse = [NSDictionary dictionaryWithObjectsAndKeys:@"0.6.6", @"version", @"hello", @"kinvey", nil];
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
    
    assertThat([NSNumber numberWithBool:pingWasSuccessful], is(equalToBool(YES)));
    assertThat(description, startsWith(@"Kinvey Service is alive, version: "));
    assertThat(description, endsWith(@", response: hello"));
    
    [conn release];
}


- (void)testPingFailOnBadRequest
{
    __block NSString *description;
    __block BOOL pingWasSuccessful;
    
    KCSPingBlock pinger = ^(KCSPingResult *result){
        description = result.description;
        pingWasSuccessful = result.pingWasSuccessful;
    };
    
    NSDictionary *pingResponse = [NSDictionary dictionaryWithObjectsAndKeys:@"0.6.6", @"version", @"hello", @"kinvey", nil];
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
    
    assertThat([NSNumber numberWithBool:pingWasSuccessful], is(equalToBool(NO)));
    assertThat(description, containsString(@"Planned Testing Error"));
    
    [conn release];
}





@end
