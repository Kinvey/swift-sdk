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
#import "SBJson.h"
#import "KinveyPing.h"
#import "KCSLogManager.h"
#import "KCSAuthCredential.h"
#import "KCSRESTRequest.h"
#import "KinveyCollection.h"

typedef BOOL(^KCSUserSuccessAction)(KCSUser *, KCSUserActionResult);
typedef BOOL(^KCSUserFailureAction)(KCSUser *, NSError *);
typedef BOOL(^KCSEntitySuccessAction)(id, NSObject *);
typedef BOOL(^KCSEntityFailureAction)(id, NSError *);


@interface KinveyKitUserTests ()
@property (nonatomic) BOOL testPassed;
@property (nonatomic, copy) KCSUserSuccessAction onSuccess;
@property (nonatomic, copy) KCSUserFailureAction onFailure;
@property (nonatomic, copy) KCSEntitySuccessAction onEntitySuccess;
@property (nonatomic, copy) KCSEntityFailureAction onEntityFailure;
@property (nonatomic, retain) KCS_SBJsonParser *parser;
@property (nonatomic, retain) KCS_SBJsonWriter *writer;

@end

@implementation KinveyKitUserTests
@synthesize testPassed = _testPassed;
@synthesize onFailure = _onFailure;
@synthesize onSuccess = _onSuccess;
@synthesize onEntityFailure = _onEntityFailure;
@synthesize onEntitySuccess = _onEntitySuccess;
@synthesize parser = _parser;
@synthesize writer = _writer;

- (void)setUp
{
    _testPassed = NO;
    _onSuccess = [^(KCSUser *u, KCSUserActionResult result){ return NO; } copy];
    _onFailure = [^(KCSUser *u, NSError *error){ return NO; } copy];
    _onEntitySuccess = [^(id u, NSObject *obj){ return NO; } copy];
    _onEntityFailure = [^(id u, NSError *error){ return NO; } copy];
    [KCSClient configureLoggingWithNetworkEnabled:YES debugEnabled:YES traceEnabled:YES warningEnabled:YES errorEnabled:YES];
    [[[KCSClient sharedClient] currentUser] logout];
    
    _parser = [[[KCS_SBJsonParser alloc] init] retain];
    _writer = [[[KCS_SBJsonWriter alloc] init] retain];
}


// These tests are ordered and must be run first, hence the AAAXX

- (void)testAAAAAInitializeCurrentUserInitializesCurrentUserNoNetwork{
    KCSUser *cUser = [[KCSClient sharedClient] currentUser];
    assertThat(cUser.username, is(nilValue()));
    assertThat(cUser.password, is(nilValue()));

    // initialize the user in the keychain (make a user that's "logged in")
    [KCSKeyChain setString:@"brian" forKey:@"username"];
    [KCSKeyChain setString:@"12345" forKey:@"password"];
    [KCSKeyChain setString:@"That's the combination for my luggage" forKey:@"_id"];
    
    [KCSUser initCurrentUser];

    cUser = [[KCSClient sharedClient] currentUser];
    KCSLogDebug(@"Blah: %@", cUser.password);
    
    assertThat(cUser.username, is(equalTo(@"brian")));
    assertThat(cUser.password, is(equalTo(@"12345")));
}

- (void)testAAABBLogoutLogsOutCurrentUser{
    KCSUser *cUser = [[KCSClient sharedClient] currentUser];
    [cUser logout];
    assertThat(cUser.username, is(nilValue()));
    assertThat(cUser.password, is(nilValue()));
    
}

- (void)testAAACCInitializeCurrentUserInitializesCurrentUserNetwork{
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
                                                                         responseData:[self.writer dataWithObject:dictionary]
                                                                           headerData:nil
                                                                             userData:nil];
    
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:connection];

    [KCSUser initCurrentUser];
    cUser = [[KCSClient sharedClient] currentUser];
    
    assertThat(cUser.username, is(notNilValue()));
    assertThat(cUser.password, is(notNilValue()));
    assertThat(cUser.username, is(equalTo(@"brian")));
    assertThat(cUser.password, is(equalTo(@"12345")));

    // Make sure we log-out
    [cUser logout];
    
    [[KCSConnectionPool sharedPool] drainPools];
}


- (void)testAAADDInitializeCurrentUserWithRequestPerformsRequest{

    // Ensure user is logged out
    [[[KCSClient sharedClient] currentUser] logout];

    // Create a mock object for the real request
    KCSMockConnection *realRequest = [[KCSMockConnection alloc] init];
    realRequest.connectionShouldFail = NO;
    realRequest.connectionShouldReturnNow = YES;
    realRequest.responseForSuccess = [KCSConnectionResponse connectionResponseWithCode:KCS_HTTP_STATUS_OK
                                                                          responseData:[self.writer dataWithObject:[NSDictionary dictionary]]
                                                                            headerData:nil
                                                                              userData:nil];
    
    // Create a Mock Object for the user request
    KCSMockConnection *connection = [[KCSMockConnection alloc] init];
    
    connection.connectionShouldReturnNow = YES;
    connection.connectionShouldFail = NO;
    
    // Success dictionary
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"brian", @"username",
                                @"12345", @"password",
                                @"hello", @"_id", nil];
    
    connection.responseForSuccess = [KCSConnectionResponse connectionResponseWithCode:KCS_HTTP_STATUS_CREATED
                                                                         responseData:[self.writer dataWithObject:dictionary]
                                                                           headerData:nil
                                                                             userData:nil];
    
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:connection];
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:realRequest];
    
    __block BOOL pingWorked = NO;
    __block NSString *description = nil;
    
    // Run the request
    [KCSPing pingKinveyWithBlock:^(KCSPingResult *res){ pingWorked = res.pingWasSuccessful; description = res.description;}];
    
    // This test CANNOT work with the existing KCS REST framework.  There's a built-in 0.05 second delay that we cannot compensate for here...
    // at the moment...
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


- (void)testCanCreateArbitraryUser
{
    NSString *testUsername = @"arbitrary";
    NSString *testPassword = @"54321";
    KCSMockConnection *connection = [[KCSMockConnection alloc] init];
    
    connection.connectionShouldReturnNow = YES;
    connection.connectionShouldFail = NO;
    
    // Success dictionary
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:testUsername, @"username",
                                testPassword, @"password",
                                @"hello", @"_id", nil];
    
    connection.responseForSuccess = [KCSConnectionResponse connectionResponseWithCode:KCS_HTTP_STATUS_CREATED
                                                                         responseData:[self.writer dataWithObject:dictionary]
                                                                           headerData:nil
                                                                             userData:nil];
    
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:connection];
    
    self.onSuccess = [^(KCSUser *user, KCSUserActionResult result){
        if ([user.username isEqualToString:testUsername] &&
            [user.password isEqualToString:testPassword] &&
            result == KCSUserCreated){
            return YES;
        } else {
            return NO;
        }
    } copy];
    
    [KCSUser userWithUsername:testUsername password:testPassword withDelegate:self];
    
    assertThat([NSNumber numberWithBool:self.testPassed], is(equalToBool(YES)));

}

- (void)testCanLoginExistingUser
{
    NSString *testUsername = @"existing";
    NSString *testPassword = @"56789";
    KCSMockConnection *connection = [[KCSMockConnection alloc] init];
    
    connection.connectionShouldReturnNow = YES;
    connection.connectionShouldFail = NO;
    
    // Success dictionary
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                testPassword, @"password",
                                testUsername, @"password",
                                @"28hjkshafkh982kjh", @"_id", nil];

    connection.responseForSuccess = [KCSConnectionResponse connectionResponseWithCode:KCS_HTTP_STATUS_OK
                                                                         responseData:[self.writer dataWithObject:dictionary]
                                                                           headerData:nil
                                                                             userData:nil];
    
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:connection];
    
    self.onSuccess = [^(KCSUser *user, KCSUserActionResult result){
        if ([user.username isEqualToString:testUsername] &&
            [user.password isEqualToString:testPassword] &&
            result == KCSUserFound){
            return YES;
        } else {
            return NO;
        }
    } copy];
    
    [KCSUser loginWithUsername:testUsername password:testPassword withDelegate:self];
    
    assertThat([NSNumber numberWithBool:self.testPassed], is(equalToBool(YES)));

    
    
}

- (void)testCanLogoutUser
{
    [KCSKeyChain setString:@"logout" forKey:@"username"];
    [KCSKeyChain setString:@"98765" forKey:@"password"];
    [KCSKeyChain setString:@"That's the combination for my luggage" forKey:@"_id"];
    [KCSUser initCurrentUser];
    [[[KCSClient sharedClient] currentUser] logout];
    
    
    // Check to make sure keychain is clean
    assertThat([KCSKeyChain getStringForKey:@"username"], is(nilValue()));
    assertThat([KCSKeyChain getStringForKey:@"password"], is(nilValue()));
    assertThat([KCSKeyChain getStringForKey:@"_id"], is(nilValue()));
    
    // Check to make sure we're not authd'
    assertThat([NSNumber numberWithBool:[[KCSClient sharedClient] userIsAuthenticated]], is(equalToBool(NO)));
    
    // Check to make sure user is nil
    assertThat([[KCSClient sharedClient] currentUser], is(nilValue()));
    

}

- (void)testAnonymousUserCreatedIfNoNamedUser
{
    NSString *testUsername = @"anon";
    NSString *testPassword = @"72727";
    KCSMockConnection *connection = [[KCSMockConnection alloc] init];
    
    connection.connectionShouldReturnNow = YES;
    connection.connectionShouldFail = NO;
    
    // Success dictionary
    // Success dictionary
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:testUsername, @"username",
                                testPassword, @"password",
                                @"hello", @"_id", nil];
    
    connection.responseForSuccess = [KCSConnectionResponse connectionResponseWithCode:KCS_HTTP_STATUS_CREATED
                                                                         responseData:[self.writer dataWithObject:dictionary]
                                                                           headerData:nil
                                                                             userData:nil];
    
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:connection];
    
    self.onSuccess = [^(KCSUser *user, KCSUserActionResult result){
        if ([user.username isEqualToString:testUsername] &&
            [user.password isEqualToString:testPassword] &&
            result == KCSUserCreated){
            return YES;
        } else {
            return NO;
        }
    } copy];
    
    KCSAuthCredential *cred = [KCSAuthCredential credentialForURL:[[KCSClient sharedClient] appdataBaseURL] usingMethod:kGetRESTMethod];

    KCSUser *preCurrentUser = [[KCSClient sharedClient] currentUser];    
   
    [cred HTTPBasicAuthString];
    
    KCSUser *postCurrentUser = [[KCSClient sharedClient] currentUser];

    assertThat(preCurrentUser, is(nilValue()));
    assertThat(postCurrentUser, is(notNilValue()));
    assertThat(postCurrentUser.username, is(testUsername));
    assertThat(postCurrentUser.password, is(testPassword));

}

- (void)testCanAddArbitraryDataToUser
{
    // Make sure we have a user
    if ([[KCSClient sharedClient] currentUser] == nil){
        [KCSKeyChain setString:@"brian" forKey:@"username"];
        [KCSKeyChain setString:@"12345" forKey:@"password"];
        [KCSKeyChain setString:@"That's the combination for my luggage" forKey:@"_id"];
        
        [KCSUser initCurrentUser];
    }
    
    KCSUser *currentUser = [[KCSClient sharedClient] currentUser];
    
//  Removed attributes... "attribute" from the class, this test is auto-fail now..., unless we comment out the
//  check here.
//    assertThat([currentUser attributes], is(empty()));
    
    [currentUser setValue:[NSNumber numberWithInt:32] forAttribute:@"age"];
    [currentUser setValue:@"Brooklyn, NY" forAttribute:@"birthplace"];
    [currentUser setValue:[NSNumber numberWithBool:YES] forAttribute:@"isAlive"];
     
    assertThat([currentUser getValueForAttribute:@"age"], is(equalToInt(32)));
    assertThat([currentUser getValueForAttribute:@"birthplace"], is(equalTo(@"Brooklyn, NY")));
    assertThat([currentUser getValueForAttribute:@"isAlive"], is(equalToBool(YES)));
    
    
}

- (void)testCanGetCurrentUser
{
    
    // Make sure we have a user
    if ([[KCSClient sharedClient] currentUser] == nil){
        [KCSKeyChain setString:@"brian" forKey:@"username"];
        [KCSKeyChain setString:@"12345" forKey:@"password"];
        [KCSKeyChain setString:@"That's the combination for my luggage" forKey:@"_id"];
        
        [KCSUser initCurrentUser];
    }
    
    KCSUser *currentUser = [[KCSClient sharedClient] currentUser];

    NSString *aKey = @"age";
    NSNumber *age = [NSNumber numberWithInt:32];
    NSNumber *age_ = [NSNumber numberWithInt:99];
    NSString *bKey = @"birthplace";
    NSString *bPlace = @"Brooklyn, NY";
    NSString *bPlace_ = @"Long Beach, CA";
    NSString *cKey = @"isAlive";
    NSNumber *alive = [NSNumber numberWithBool:YES];
    NSNumber *alive_ = [NSNumber numberWithBool:NO];

    [currentUser setValue:age forAttribute:aKey];
    [currentUser setValue:bPlace forAttribute:bKey];
    [currentUser setValue:alive forAttribute:cKey];

    // Check prior to fetch
    assertThat([currentUser getValueForAttribute:aKey], is(equalToInt([age intValue])));
    assertThat([currentUser getValueForAttribute:bKey], is(equalTo(bPlace)));
    assertThat([currentUser getValueForAttribute:cKey], is(equalToBool([alive boolValue])));
    
    // Prepare request
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"brian", @"username",
                                @"12345", @"password",
                                @"That's the combination for my luggage", @"_id",
                                age_, aKey,
                                bPlace_, bKey,
                                alive_, cKey, nil];
    
    KCSMockConnection *connection = [[KCSMockConnection alloc] init];
    
    connection.connectionShouldReturnNow = YES;
    connection.connectionShouldFail = NO;

    connection.responseForSuccess = [KCSConnectionResponse connectionResponseWithCode:KCS_HTTP_STATUS_OK
                                                                         responseData:[self.writer dataWithObject:dictionary]
                                                                           headerData:nil
                                                                             userData:nil];
    
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:connection];

    __block NSDictionary *dict;
    
    self.onEntitySuccess = [^(id e, NSObject *obj){
        dict = (NSDictionary *)obj;
        return YES;
    } copy];

    [[[KCSClient sharedClient] currentUser] loadWithDelegate:self];
    
    // Current user is primed
    assertThat([currentUser getValueForAttribute:aKey], is(equalToInt([age_ intValue])));
    assertThat([currentUser getValueForAttribute:bKey], is(equalTo(bPlace_)));
    assertThat([currentUser getValueForAttribute:cKey], is(equalToBool([alive_ boolValue])));

}

- (void)testCanTreatUsersAsCollection
{
    // Make sure we have a user
    if ([[KCSClient sharedClient] currentUser] == nil){
        [KCSKeyChain setString:@"brian" forKey:@"username"];
        [KCSKeyChain setString:@"12345" forKey:@"password"];
        [KCSKeyChain setString:@"That's the combination for my luggage" forKey:@"_id"];
        
        [KCSUser initCurrentUser];
    }
    assertThat([[[KCSClient sharedClient] currentUser] userCollection], is(instanceOf([KCSCollection class])));
}

- (void)user:(KCSUser *)user actionDidCompleteWithResult:(KCSUserActionResult)result
{
    self.testPassed = self.onSuccess(user, result);
}

- (void)user:(KCSUser *)user actionDidFailWithError:(NSError *)error
{
    self.testPassed = self.onFailure(user, error);
}

- (void)entity:(id<KCSPersistable>)entity fetchDidCompleteWithResult:(NSObject *)result
{
    self.testPassed = self.onEntitySuccess(entity, result);
}

- (void)entity:(id<KCSPersistable>)entity fetchDidFailWithError:(NSError *)error
{
    self.testPassed = self.onEntityFailure(entity, error);
}

- (void)entity:(id)entity operationDidCompleteWithResult:(NSObject *)result
{
    self.testPassed = self.onEntitySuccess(entity, result);
}

- (void)entity:(id)entity operationDidFailWithError:(NSError *)error
{
    self.testPassed = self.onEntityFailure(entity, error);
}


@end
