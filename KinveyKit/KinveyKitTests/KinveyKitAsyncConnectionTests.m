//
//  KinveyKitAsyncConnectionTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/12/11.
//  Copyright (c) 2011-2012 Kinvey. All rights reserved.
//

#import "KinveyKitAsyncConnectionTests.h"
#import "KCSConnection.h"
#import "KCSAsyncConnection.h"
#import "KCSMockURLConnection.h"
#import "KCSClient.h"

@implementation KinveyKitAsyncConnectionTests

- (void)setUp
{
    KCSClient* client = [KCSClient sharedClient];
    _oldHostname = [client.serviceHostname retain];
    [client setServiceHostname:@"kinvey.com"];
}

- (void) tearDown
{
    KCSClient* client = [KCSClient sharedClient];
    [client setServiceHostname:_oldHostname];    
}

- (void) dealloc
{
    [_oldHostname release];
    [super dealloc];
}

- (void)testMockInit
{
    KCSMockURLConnection *urlConnection = [[KCSMockURLConnection alloc] init];
    KCSConnection *connection = [[KCSAsyncConnection alloc] initWithConnection:urlConnection];
    
    STAssertNoThrow([connection performRequest:nil progressBlock:NULL completionBlock:NULL failureBlock:NULL usingCredentials:nil],
                    @"Nil connection test");
    
}

- (void) testDoesHTTPHeadersPreservedForNonRedirect
{
    KCSMockURLConnection *urlConnection = [[KCSMockURLConnection alloc] init];
    KCSAsyncConnection *connection = [[KCSAsyncConnection alloc] initWithConnection:urlConnection];
    
    NSURL* testURL = [NSURL URLWithString:@"test://test.com/test.html?test=test"];
    NSMutableURLRequest* testRequest = [[NSMutableURLRequest alloc] initWithURL:testURL];
    [testRequest setValue:@"value1" forHTTPHeaderField:@"header1"];
    [testRequest setValue:@"value2" forHTTPHeaderField:@"header2"];
    
    NSURLRequest* newrequest = [connection connection:urlConnection willSendRequest:testRequest redirectResponse:nil];
    
    STAssertEqualObjects(newrequest.URL, testRequest.URL, @"For no redirect, expecting back the same request headers");
    STAssertEqualObjects([newrequest allHTTPHeaderFields], [testRequest allHTTPHeaderFields], @"For no redirect, expecting back the same request headers");
}

- (void) testDoesNotTransferHTTPHeadersForRedirect
{
    KCSMockURLConnection *urlConnection = [[KCSMockURLConnection alloc] init];
    KCSAsyncConnection *connection = [[KCSAsyncConnection alloc] initWithConnection:urlConnection];
    
    NSURL* redirectURL = [NSURL URLWithString:@"redirect://redirect.com/index.html"];
    NSMutableURLRequest* redirectRequest = [[NSMutableURLRequest alloc] initWithURL:redirectURL];
    [redirectRequest setValue:@"value1" forHTTPHeaderField:@"header1"];
    [redirectRequest setValue:@"value2" forHTTPHeaderField:@"header2"];

    
    NSHTTPURLResponse* redirect = [[[NSHTTPURLResponse alloc] init] autorelease];
    NSURLRequest* newrequest = [connection connection:urlConnection willSendRequest:redirectRequest redirectResponse:redirect];
    
    STAssertEqualObjects(newrequest.URL, redirectURL, @"new request should have the redirect url");
    STAssertNil([[newrequest allHTTPHeaderFields] objectForKey:@"header1"], @"should not have old headers set");
}

@end
