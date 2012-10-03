//
//  KinveyKitClientTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/15/11.
//  Copyright (c) 2011-2012 Kinvey. All rights reserved.
//

#import "KinveyKitClientTests.h"
#import "KCSClient.h"
#import "KinveyCollection.h"

@implementation KinveyKitClientTests

- (void) testNilAppKeyRaisesException
{
    STAssertThrows([[KCSClient sharedClient] initializeKinveyServiceForAppKey:nil withAppSecret:@"text" usingOptions:nil],
                   @"nil AppKey Did Not raise exception!");
}

- (void) testNilAppSecretRaisesException
{
    STAssertThrows([[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid6969" withAppSecret:nil usingOptions:nil],
                   @"nil AppSecret did not raise exception!");
}


- (void)testUserAgentStringIsMeaningful
{
    KCSClient *client = [KCSClient sharedClient];
    STAssertTrue([client.userAgent hasPrefix:@"ios-kinvey-http/"], @"should be meaningful string: %@", client.userAgent);
    NSString* suffix = [NSString stringWithFormat:@"kcs/%@", MINIMUM_KCS_VERSION_SUPPORTED];
    STAssertTrue([client.userAgent hasSuffix:suffix], @"should be meaningful string: %@", client.userAgent);
}

- (void)testAppdataBaseURL
{
    NSString *kidID = @"kid6969";
    NSString *urlString = [NSString stringWithFormat:
                           @"https://baas.kinvey.com/appdata/%@/",
                           kidID];
    
    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:kidID
                                                 withAppSecret:@"secret"
                                                  usingOptions:nil];
    
    STAssertEqualObjects([[KCSClient sharedClient] appdataBaseURL], urlString, @"should match");
}

- (void)testResourceBaseURL
{
    NSString *kidID = @"kid6969";
    NSString *urlString = [NSString stringWithFormat:
                           @"https://baas.kinvey.com/blob/%@/",
                           kidID];
    
    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:kidID
                                                 withAppSecret:@"secret"
                                                  usingOptions:nil];
    
    STAssertEqualObjects([[KCSClient sharedClient] resourceBaseURL], urlString, @"should match");
}

- (void)testUserBaseURL
{
    NSString *kidID = @"kid6969";
    NSString *urlString = [NSString stringWithFormat:
                           @"https://baas.kinvey.com/user/%@/",
                           kidID];
    
    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:kidID
                                                 withAppSecret:@"secret"
                                                  usingOptions:nil];
    
    
    STAssertEqualObjects([[KCSClient sharedClient] userBaseURL], urlString, @"should match");
}

- (void)testBaseURLIsValid
{
    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid6969"
                                                 withAppSecret:@"secret"
                                                  usingOptions:nil];
    
    NSURL *baseURL = [NSURL URLWithString:[[KCSClient sharedClient] appdataBaseURL]];
    STAssertNotNil(baseURL, @"url should not be nil");
}

- (void)testURLOverrideWorks
{
    NSString *newHost = @"latestbeta";
    
    NSString *kidID = @"kid6969";
    NSString *urlString = [NSString stringWithFormat:
                           @"https://baas.kinvey.com/user/%@/",
                           kidID];
    
    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:kidID
                                                 withAppSecret:@"secret"
                                                  usingOptions:nil];

    // Make sure starting value is good
    STAssertEqualObjects([[KCSClient sharedClient] userBaseURL], urlString, @"should match");
    
    [[KCSClient sharedClient] setServiceHostname:newHost];

    NSString* testStr = [NSString stringWithFormat:@"https://%@.kinvey.com/appdata/%@/", newHost, kidID];
    STAssertEqualObjects([[KCSClient sharedClient] appdataBaseURL], testStr, @"should match");
    testStr = [NSString stringWithFormat:@"https://%@.kinvey.com/blob/%@/", newHost, kidID];
    STAssertEqualObjects([[KCSClient sharedClient] resourceBaseURL], testStr, @"should match");
    testStr = [NSString stringWithFormat:@"https://%@.kinvey.com/user/%@/", newHost, kidID];
    STAssertEqualObjects([[KCSClient sharedClient] userBaseURL], testStr, @"should match");
}

- (void)testThatInitializeWithKeyAndSecretRejectsInvalidInput
{
    STAssertThrows([[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"<app key>"
                                                 withAppSecret:@"secret"
                                                  usingOptions:nil],
                   @"Malformed input DID NOT raise exception!");
}

// Check that asking for a collection is a lightweight wrapper
// Semantics of the collections will be tested there


- (void)testCollectionIsReallyCollection
{
    KCSCollection *coll1 = [[KCSClient sharedClient] collectionFromString:@"test"
                                                                withClass:[NSObject class]];
    KCSCollection *coll2 = [KCSCollection collectionFromString:@"test"
                                                       ofClass:[NSObject class]];
    STAssertEqualObjects(coll1, coll2, @"should be equal");
}

- (void)testAuthCredentials
{
    NSString *appKey = @"name";
    NSString *appSecret = @"secret";
    
    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:appKey
                                                 withAppSecret:appSecret
                                                  usingOptions:nil];
    
    NSURLCredential *cred = [NSURLCredential credentialWithUser:appKey
                                                       password:appSecret
                                                    persistence:NSURLCredentialPersistenceNone];
    STAssertEqualObjects([[KCSClient sharedClient] authCredentials], cred, @"should be equal");
}

- (void)testSingletonIsSingleton
{
    KCSClient *client1 = [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid6969"
                                                                      withAppSecret:@"secret"
                                                                       usingOptions:nil];
    KCSClient *client2 = [KCSClient sharedClient];
    STAssertEquals(client1, client2, @"should be same instance");
}

// Still need tests for push and initializing via plist

@end
