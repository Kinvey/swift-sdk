//
//  KinveyKitUserTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KinveyKitUserTests.h"
#import "KinveyUser.h"
#import "KCSClient.h"
#import "KCSKeyChain.h"
#import "KCSConnectionPool.h"
#import "KCSMockConnection.h"
#import "KCSConnectionResponse.h"
#import "KinveyHTTPStatusCodes.h"
#import "JSONKit.h"
#import "KinveyPing.h"
#import "KCSLogManager.h"

@implementation KinveyKitUserTests

- (void)setUp
{
    [[[KCSClient sharedClient] currentUser] logout];
}

- (void)testAAInitializeCurrentUserInitializesCurrentUserNoNetwork{
    KCSUser *cUser = [[KCSClient sharedClient] currentUser];
    assertThat(cUser.username, is(nilValue()));
    assertThat(cUser.password, is(nilValue()));

    // initialize the user in the keychain (make a user that's "logged in")
    [KCSKeyChain setString:@"brian" forKey:@"username"];
    [KCSKeyChain setString:@"12345" forKey:@"password"];
    [KCSKeyChain setString:@"That's the combination for my luggage" forKey:@"_id"];
    
    [cUser initializeCurrentUser];
    
    KCSLogDebug(@"Blah: %@", cUser.password);
    
    assertThat(cUser.username, is(equalTo(@"brian")));
    assertThat(cUser.password, is(equalTo(@"12345")));
}

- (void)testBBLogoutLogsOutCurrentUser{
    KCSUser *cUser = [[KCSClient sharedClient] currentUser];
    [cUser logout];
    assertThat(cUser.username, is(nilValue()));
    assertThat(cUser.password, is(nilValue()));
    
}

- (void)testCCInitializeCurrentUserInitializesCurrentUserNetwork{
    KCSUser *cUser = [[KCSClient sharedClient] currentUser];
    assertThat(cUser.username, is(nilValue()));
    assertThat(cUser.password, is(nilValue()));
    
    // Create a Mock Object
    KCSMockConnection *connection = [[KCSMockConnection alloc] init];
    
    connection.connectionShouldReturnNow = YES;
    connection.delayInMSecs = 0.0;
    
    // Success dictionary
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"brian", @"username",
                                @"12345", @"password",
                                @"hello", @"_id", nil];
    
    connection.responseForSuccess = [KCSConnectionResponse connectionResponseWithCode:KCS_HTTP_STATUS_CREATED
                                                                         responseData:[dictionary JSONData]
                                                                           headerData:nil
                                                                             userData:nil];
    
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:connection];

    [cUser initializeCurrentUser];
    
    assertThat(cUser.username, is(notNilValue()));
    assertThat(cUser.password, is(notNilValue()));
    assertThat(cUser.username, is(equalTo(@"brian")));
    assertThat(cUser.password, is(equalTo(@"12345")));

    // Make sure we log-out
    [cUser logout];
    
    [[KCSConnectionPool sharedPool] drainPools];
}


- (void)testDDInitializeCurrentUserWithRequestPerformsRequest{

    // Ensure user is logged out
    [[[KCSClient sharedClient] currentUser] logout];

    // Create a mock object for the real request
    KCSMockConnection *realRequest = [[KCSMockConnection alloc] init];
    realRequest.connectionShouldFail = NO;
    realRequest.connectionShouldReturnNow = YES;
    realRequest.responseForSuccess = [KCSConnectionResponse connectionResponseWithCode:200
                                                                          responseData:[[NSDictionary dictionary] JSONData]
                                                                            headerData:nil
                                                                              userData:nil];
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:realRequest];
    
    // Create a Mock Object for the user request
    KCSMockConnection *connection = [[KCSMockConnection alloc] init];
    
    connection.connectionShouldReturnNow = YES;
    connection.connectionShouldFail = NO;
    
    // Success dictionary
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"brian", @"username",
                                @"12345", @"password",
                                @"hello", @"_id", nil];
    
    connection.responseForSuccess = [KCSConnectionResponse connectionResponseWithCode:KCS_HTTP_STATUS_CREATED
                                                                         responseData:[dictionary JSONData]
                                                                           headerData:nil
                                                                             userData:nil];
    
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:connection];

    __block BOOL pingWorked = NO;
    __block NSString *description;
    
    // Run the request
    [KCSPing pingKinveyWithBlock:^(KCSPingResult *res){ pingWorked = res.pingWasSuccessful; description = res.description;}];
    
    assertThat([NSNumber numberWithBool:pingWorked], is(equalToBool(YES)));
    assertThat(description, isNot(containsString(@"brian")));
    
    // Check to make sure the auth worked
    KCSUser *cUser = [[KCSClient sharedClient] currentUser];
    assertThat(cUser.username, is(notNilValue()));
    assertThat(cUser.password, is(notNilValue()));
    assertThat(cUser.username, is(equalTo(@"brian")));
    assertThat(cUser.password, is(equalTo(@"12345")));
    
    // Make sure we log-out
    [cUser logout];
    
    [[KCSConnectionPool sharedPool] drainPools];
}

@end
