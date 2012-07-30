//
//  KinveyKitClientTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/15/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
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
    assertThat(client.userAgent,
               allOf(startsWith(@"ios-kinvey-http/"),
                     endsWith([NSString stringWithFormat:@"kcs/%@", MINIMUM_KCS_VERSION_SUPPORTED]),
                     nil));
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
    
    assertThat([[KCSClient sharedClient] appdataBaseURL],
               is(urlString));
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
    
    assertThat([[KCSClient sharedClient] resourceBaseURL],
               is(urlString));
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
    
    assertThat([[KCSClient sharedClient] userBaseURL],
               is(urlString));
}

- (void)testBaseURLIsValid
{
    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid6969"
                                                 withAppSecret:@"secret"
                                                  usingOptions:nil];
    
    NSURL *baseURL = [NSURL URLWithString:[[KCSClient sharedClient] appdataBaseURL]];
    assertThat(baseURL, isNot(nilValue()));
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
    assertThat([[KCSClient sharedClient] userBaseURL],
               is(urlString));
    
    [[KCSClient sharedClient] setServiceHostname:newHost];

    assertThat([[KCSClient sharedClient] appdataBaseURL],
               is([NSString stringWithFormat:@"https://%@.kinvey.com/appdata/%@/", newHost, kidID]));

    assertThat([[KCSClient sharedClient] resourceBaseURL],
               is([NSString stringWithFormat:@"https://%@.kinvey.com/blob/%@/", newHost, kidID]));

    assertThat([[KCSClient sharedClient] userBaseURL],
               is([NSString stringWithFormat:@"https://%@.kinvey.com/user/%@/", newHost, kidID]));

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
    
    assertThat(coll1, is(equalTo(coll2)));
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
    
    assertThat([[KCSClient sharedClient] authCredentials], is(equalTo(cred)));
}

- (void)testSingletonIsSingleton
{
    KCSClient *client1 = [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid6969"
                                                                      withAppSecret:@"secret"
                                                                       usingOptions:nil];
    KCSClient *client2 = [KCSClient sharedClient];
    
    assertThat(client1, is(sameInstance(client2)));
}

// Still need tests for push and initializing via plist

@end
