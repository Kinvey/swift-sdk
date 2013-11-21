//
//  KinveyKitPingTests.m
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
#import "KCSHiddenMethods.h"

@interface KinveyKitPingTests()
@property (nonatomic, retain) KCS_SBJsonParser *parser;
@property (nonatomic, retain) KCS_SBJsonWriter *writer;
@end

@implementation KinveyKitPingTests

- (void)setUp
{
    KCSClient *client = [KCSClient sharedClient];
    [client.configuration setServiceHostname:@"baas"];
    (void)[client initializeKinveyServiceForAppKey:@"kid1234" withAppSecret:@"1234" usingOptions:nil];
    [KCSClient configureLoggingWithNetworkEnabled:YES debugEnabled:YES traceEnabled:YES warningEnabled:YES errorEnabled:YES];
    
    
    // Fake Auth
    [KCSKeyChain setString:@"kinvey" forKey:@"username"];
    [KCSKeyChain setString:@"12345" forKey:@"password"];
    
    // Needed, otherwise we burn a connection later...
    [KCSUser activeUser];
    
    _parser = [[KCS_SBJsonParser alloc] init];
    _writer = [[KCS_SBJsonWriter alloc] init];
}

- (void)tearDown
{
    [[KCSUser activeUser] logout];    
}


KK2(cleanup)
- (void)testPingSuccessOnGoodRequestNewStyle
{
//    __block NSString *description;
//    __block BOOL pingWasSuccessful;
//    
//    NSDictionary *pingResponse = wrapResponseDictionary(@{@"kinveyVersion" : @"0.6.6.", @"hello" :@"kinvey"});
//    KCSMockConnection *conn = [[KCSMockConnection alloc] init];
//    
//    KCSConnectionResponse *response = [KCSConnectionResponse connectionResponseWithCode:200
//                                                                           responseData:[self.writer dataWithObject:pingResponse]
//                                                                             headerData:nil
//                                                                               userData:nil];
//    
//    NSError *failure = [NSError errorWithDomain:KCSErrorDomain
//                                           code:KCSBadRequestError
//                                       userInfo:[KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Planned Testing Error"
//                                                                                          withFailureReason:@"Attempting to simulate failure"
//                                                                                     withRecoverySuggestion:@"Non offered, non expected."
//                                                                                        withRecoveryOptions:nil]];
//    
//    conn.responseForSuccess = response;
//    conn.errorForFailure = failure;
//    conn.connectionShouldReturnNow = YES;
//    
//    // Success
//    conn.connectionShouldFail = NO;
//    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
//    
//    [KCSPing pingKinveyWithBlock: ^(KCSPingResult *result){
//        description = result.description;
//        pingWasSuccessful = result.pingWasSuccessful;
//        self.done = YES;
//    }];
//    
//    [self poll];
//    
//    STAssertTrue(pingWasSuccessful, @"ping should be successful");
//    STAssertTrue([description hasPrefix:@"Kinvey Service is alive, version: "], @"");
//    STAssertTrue([description hasSuffix:@", response: hello"], @"");
}


- (void)testPingFailOnBadRequest
{
//    __block NSString *description;
//    __block BOOL pingWasSuccessful;
//    
//    KCSPingBlock pinger = ^(KCSPingResult *result){
//        description = result.description;
//        pingWasSuccessful = result.pingWasSuccessful;
//    };
//    
//    NSDictionary *pingResponse = wrapResponseDictionary([NSDictionary dictionaryWithObjectsAndKeys:@"0.6.6", @"version", @"hello", @"kinvey", nil]);
//    KCSMockConnection *conn = [[KCSMockConnection alloc] init];
//    
//    KCSConnectionResponse *response = [KCSConnectionResponse connectionResponseWithCode:200
//                                                                           responseData:[self.writer dataWithObject:pingResponse]
//                                                                             headerData:nil
//                                                                               userData:nil];
//    
//    NSError *failure = [NSError errorWithDomain:KCSErrorDomain
//                                           code:KCSBadRequestError
//                                       userInfo:[KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Planned Testing Error"
//                                                                                          withFailureReason:@"Attempting to simulate failure"
//                                                                                     withRecoverySuggestion:@"Non offered, non expected."
//                                                                                        withRecoveryOptions:nil]];
//    
//    conn.responseForSuccess = response;
//    conn.errorForFailure = failure;
//    conn.connectionShouldReturnNow = YES;
//    
//    // Failure
//    conn.connectionShouldFail = YES;
//    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
//    
//    [KCSPing pingKinveyWithBlock:pinger];
//    
//    STAssertFalse(pingWasSuccessful, @"ping should be successful");
//    STAssertTrue([description containsStringCaseInsensitive:@"Planned Testing Error"], @"");
}

@end
