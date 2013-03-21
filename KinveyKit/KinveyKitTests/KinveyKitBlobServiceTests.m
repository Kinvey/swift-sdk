//
//  KinveyKitBlobServiceTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/5/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "KinveyKitBlobServiceTests.h"
#import "KCSMockConnection.h"
#import "KCSConnectionResponse.h"
#import "KCS_SBJson.h"
#import "KinveyHTTPStatusCodes.h"
#import "KCSConnectionPool.h"
#import "KCSKeyChain.h"
#import "KCSClient.h"
#import "KinveyUser.h"
#import "KinveyErrorCodes.h"
#import "KCSErrorUtilities.h"
#import "KCSLogManager.h"
#import "TestUtils.h"

typedef BOOL(^SuccessAction)(KCSResourceResponse *);
typedef BOOL(^FailureAction)(NSError *);

@interface KinveyKitBlobServiceTests ()

@property (retain, nonatomic) NSString *testID;
@property (copy, nonatomic) SuccessAction onSuccess;
@property (copy, nonatomic) FailureAction onFailure;
@property (nonatomic) BOOL testPassed;
@property (retain, nonatomic) NSString *message;
@property (retain, nonatomic) KCS_SBJsonWriter *writer;
@property (retain, nonatomic) KCS_SBJsonParser *parser;

- (KCSMockConnection *)buildDefaultMockConnection;

@end

@implementation KinveyKitBlobServiceTests

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"

- (void)setUp
{
    _testID = nil;

    // Provide default FALSE implementations
    _onFailure = ^(NSError *err){return NO;};
    _onSuccess = ^(KCSResourceResponse *response){return NO;};

    _testPassed = NO;
    _message = nil;
    
    // Ensure that KCSClient is alive
    KCSClient *client = [KCSClient sharedClient];
    [client setServiceHostname:@"baas"];
    (void)[client initializeKinveyServiceForAppKey:@"kid1234" withAppSecret:@"1234" usingOptions:nil];
    
    
    // Fake Auth
    [KCSKeyChain setString:@"kinvey" forKey:@"username"];
    [KCSKeyChain setString:@"12345" forKey:@"password"];

    // Needed, otherwise we burn a connection later...
//    [[client currentUser] initializeCurrentUser];
    [KCSUser initCurrentUser];
    
    _writer = [[KCS_SBJsonWriter alloc] init];
    _parser = [[KCS_SBJsonParser alloc] init];
    
    STAssertTrue([TestUtils setUpKinveyUnittestBackend], @"should be set up");
}

- (void)tearDown
{
    [[[KCSClient sharedClient] currentUser] logout];
}

- (void)resourceServiceDidCompleteWithResult:(KCSResourceResponse *)result
{
    KCSLogDebug(@"Success delegate called for test: %@", [self.testID copy]);
    self.testPassed = _onSuccess(result);
}

- (void)resourceServiceDidFailWithError:(NSError *)error
{
    KCSLogDebug(@"Failure delegate called for test: %@", self.testID);
    self.testPassed = _onFailure(error);
}

// All code under test must be linked into the Unit Test bundle
- (void)testTestFramework
{
    self.onFailure = ^(NSError *err){
        self.message = @"Yes, the test passed";
        self.done = YES;
        return YES;
    };
    
    self.onSuccess = ^(KCSResourceResponse *response){
        self.message = @"Yes, the test passed";
        self.done = YES;
        return YES;
    };
    
    self.testID = @"Test the tests";
    
    KCSMockConnection *conn = [[KCSMockConnection alloc] init];
    conn.connectionShouldFail = NO;
    conn.connectionShouldReturnNow = YES;
    NSError *err = [NSError errorWithDomain:KCSErrorDomain
                                       code:KCSBadRequestError
                                   userInfo:[KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Planned Testing Error"
                                                                                      withFailureReason:@"Attempting to simulate failure"
                                                                                 withRecoverySuggestion:@"Non offered, non expected."
                                                                                    withRecoveryOptions:nil]];
    
    KCSConnectionResponse *cr = [KCSConnectionResponse connectionResponseWithCode:KCS_HTTP_STATUS_OK
                                                                     responseData:[self.writer dataWithObject:[NSDictionary dictionary]]
                                                                       headerData:nil userData:nil];
    conn.responseForSuccess = cr;
    conn.errorForFailure = err;
    
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
    
    self.done = NO;
    [KCSResourceService downloadResource:@"blah" withResourceDelegate:self];
    [self poll];
    STAssertTrue(self.testPassed, self.message);

    conn.connectionShouldFail = YES;
    
    [[KCSConnectionPool sharedPool] drainPools];
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
    
    [KCSResourceService getStreamingURLForResource:@"blah" withResourceDelegate:self];
    STAssertTrue(self.testPassed, self.message);
    
    [[KCSConnectionPool sharedPool] drainPools];
}

- (KCSMockConnection *)buildDefaultMockConnection
{
    KCSMockConnection *conn = [[KCSMockConnection alloc] init];
    conn.connectionShouldFail = NO;
    conn.connectionShouldReturnNow = YES;
    NSError *err = [NSError errorWithDomain:KCSErrorDomain
                                       code:KCSBadRequestError
                                   userInfo:[KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Planned Testing Error"
                                                                                      withFailureReason:@"Attempting to simulate failure"
                                                                                 withRecoverySuggestion:@"Non offered, non expected."
                                                                                    withRecoveryOptions:nil]];
    KCSConnectionResponse *cr = [KCSConnectionResponse connectionResponseWithCode:KCS_HTTP_STATUS_OK
                                                                     responseData:[self.writer dataWithObject:[NSDictionary dictionary]]
                                                                       headerData:nil userData:nil];
    conn.responseForSuccess = cr;
    conn.errorForFailure = err;
    return conn;    
}

- (void)testDownloadResource
{
    self.testID = @"Test download resources";

    KCSMockConnection *conn = [self buildDefaultMockConnection];

    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
    [KCSResourceService downloadResource:@"blah" withResourceDelegate:self];

    KCSLogDebug(@"Conn: %@", conn.providedRequest);
    KCSClient *client = [KCSClient sharedClient];
    NSString *expectedString = [NSString stringWithFormat:@"%@download-loc/blah",
                                client.resourceBaseURL];
    
    STAssertTrue([[conn.providedRequest.URL absoluteString] hasSuffix:expectedString], @"did not have expected response");
    
    [[KCSConnectionPool sharedPool] drainPools];
}

- (void)testDownloadResourceToFile
{
    self.testID = @"Test download resource to file";
    
    KCSMockConnection *conn = [self buildDefaultMockConnection];
    
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
    [KCSResourceService downloadResource:@"blah" withResourceDelegate:self];
    
    KCSLogDebug(@"Conn: %@", conn.providedRequest);
    KCSClient *client = [KCSClient sharedClient];
    NSString *expectedString = [NSString stringWithFormat:@"%@download-loc/blah",
                                client.resourceBaseURL];
    
    
    STAssertTrue([[conn.providedRequest.URL absoluteString] hasSuffix:expectedString], @"did not have expected response");
    
    [[KCSConnectionPool sharedPool] drainPools];
}


- (void)testGetStreamingURLForResource
{
    //note station.mp4 must be pre-uploaded for thist test
    self.done = NO;
    [KCSResourceService getStreamingURLForResource:@"station.mp4" completionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        STAssertNoError
        STAssertObjects(1)
        KCSResourceResponse* response = objectsOrNil[0];
        NSString* s = [response streamingURL];
        STAssertNotNil(s, @"expeting a streaming URL");
        STAssertTrue([s rangeOfString:@"station.mp4"].location != NSNotFound, @"expecting to get back our resource (%@)", s);
        self.done = YES;
    } progressBlock:nil];
    [self poll];
}

- (void)testSaveLocalResource
{
    
    self.testID = @"SaveLocalResource";

    // This is the SECOND! connection, this one will be used to simulate
    // the actual RESOURCE service
    KCSMockConnection *resource = [self buildDefaultMockConnection];
    KCSConnectionResponse *resResponse = [KCSConnectionResponse connectionResponseWithCode:KCS_HTTP_STATUS_CREATED
                                                                              responseData:nil 
                                                                                headerData:nil
                                                                                  userData:nil];
    resource.responseForSuccess = resResponse;
   
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:resource];
    
    
    // This is the FIRST! connection and will be used to simulate Kinvey
    KCSMockConnection *kinvey = [self buildDefaultMockConnection];
    
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObject:@"http://www.google.com" forKey:@"URI"];
    
    KCSConnectionResponse *kinveyResponse = [KCSConnectionResponse connectionResponseWithCode:KCS_HTTP_STATUS_OK
                                                                                 responseData:[self.writer dataWithObject:jsonDict]
                                                                                   headerData:nil
                                                                                     userData:nil];
    kinvey.responseForSuccess = kinveyResponse;
    
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:kinvey];
    NSString *filePath = [[NSBundle bundleForClass:[self class]]   pathForResource:@"1px" ofType:@"png"];
    [KCSResourceService saveLocalResource:filePath withDelegate:self];
    
    KCSLogDebug(@"Conn: %@", kinvey.providedRequest);
    KCSClient *client = [KCSClient sharedClient];
    NSString *expectedString = [NSString stringWithFormat:@"%@upload-loc/1px.png",
                                client.resourceBaseURL];
    
    STAssertTrue([[kinvey.providedRequest.URL absoluteString] hasSuffix:expectedString], @"did not have expected response");
    
    [[KCSConnectionPool sharedPool] drainPools];
    
    KCSLogDebug(@"Made it out of the woods...");
}

- (void)testSaveData
{
    
    self.testID = @"TestSaveData";
    
    // This is the SECOND! connection, this one will be used to simulate
    // the actual RESOURCE service
    KCSMockConnection *resource = [self buildDefaultMockConnection];
    KCSConnectionResponse *resResponse = [KCSConnectionResponse connectionResponseWithCode:KCS_HTTP_STATUS_CREATED
                                                                              responseData:nil 
                                                                                headerData:nil
                                                                                  userData:nil];
    resource.responseForSuccess = resResponse;
    
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:resource];
    
    
    // This is the FIRST! connection and will be used to simulate Kinvey
    KCSMockConnection *kinvey = [self buildDefaultMockConnection];
    
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObject:@"http://www.google.com" forKey:@"URI"];
    
    KCSConnectionResponse *kinveyResponse = [KCSConnectionResponse connectionResponseWithCode:KCS_HTTP_STATUS_OK
                                                                                 responseData:[self.writer dataWithObject:jsonDict]
                                                                                   headerData:nil
                                                                                     userData:nil];
    kinvey.responseForSuccess = kinveyResponse;
    
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:kinvey];
    
    [KCSResourceService saveData:[NSData data] toResource:@"blob" withDelegate:self];
    
    
    KCSLogDebug(@"Conn: %@", kinvey.providedRequest);
    KCSClient *client = [KCSClient sharedClient];
    NSString *expectedString = [NSString stringWithFormat:@"%@upload-loc/blob",
                                client.resourceBaseURL];
    
    STAssertTrue([[kinvey.providedRequest.URL absoluteString] hasSuffix:expectedString], @"did not have expected response");
    
    [[KCSConnectionPool sharedPool] drainPools];
}

- (void)testDeleteResource
{
    self.testID = @"Delete Resource";
    
    // This is the SECOND! connection, this one will be used to simulate
    // the actual RESOURCE service
    KCSMockConnection *resource = [self buildDefaultMockConnection];
    KCSConnectionResponse *resResponse = [KCSConnectionResponse connectionResponseWithCode:KCS_HTTP_STATUS_OK
                                                                              responseData:nil 
                                                                                headerData:nil
                                                                                  userData:nil];
    resource.responseForSuccess = resResponse;
    
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:resource];
    
    
    // This is the FIRST! connection and will be used to simulate Kinvey
    KCSMockConnection *kinvey = [self buildDefaultMockConnection];
    
    NSDictionary *jsonDict = [NSDictionary dictionaryWithObject:@"http://www.google.com" forKey:@"URI"];
    
    KCSConnectionResponse *kinveyResponse = [KCSConnectionResponse connectionResponseWithCode:KCS_HTTP_STATUS_OK
                                                                                 responseData:[self.writer dataWithObject:jsonDict]
                                                                                   headerData:nil
                                                                                     userData:nil];
    kinvey.responseForSuccess = kinveyResponse;
    
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:kinvey];
    [KCSResourceService deleteResource:@"blah" withDelegate:self];
    
    KCSLogDebug(@"Conn: %@", kinvey.providedRequest);
    KCSClient *client = [KCSClient sharedClient];
    NSString *expectedString = [NSString stringWithFormat:@"%@remove-loc/blah",
                                client.resourceBaseURL];
    
    STAssertTrue([[kinvey.providedRequest.URL absoluteString] hasSuffix:expectedString], @"did not have expected response");
    
    [[KCSConnectionPool sharedPool] drainPools];
}

- (void)testNonexistingResrouceFailsCorrectly
{
    self.testID = @"Test non-existent file upload";

    self.onFailure = ^(NSError *err){
        if (err){
            NSLog(@"Got Error: %@", err);
            self.message = @"Yes, We did actually handle the error";
            return YES;
        } else {
            self.message = @"Nope, epic fail trying to handle error";
            return NO;
        }
    };
    
    KCSMockConnection *conn = [self buildDefaultMockConnection];
    
    conn.errorForFailure = nil;
    
    [[KCSConnectionPool sharedPool] drainPools];
    [[KCSConnectionPool sharedPool] topPoolsWithConnection:conn];
    
    // Make sure we're not false positve.
    self.testPassed = NO;
    
    [KCSResourceService saveLocalResource:@"ImNotHere.png" toResource:@"WhoCares.png" withDelegate:self];
    
    STAssertTrue(self.testPassed, self.message);
    
    [[KCSConnectionPool sharedPool] drainPools];

}

@end
#pragma clang diagnostic pop
