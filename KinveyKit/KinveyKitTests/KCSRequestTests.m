//
//  KCSRequestTests.m
//  KinveyKit
//
//  Created by Michael Katz on 5/30/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
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


#import "KCSRequestTests.h"
#import "TestUtils.h"

#import "KCSRequest.h"
#import "KCSClient.h"
#import "KCSHiddenMethods.h"

@implementation KCSRequestTests

- (void)setUp
{
    BOOL loaded = [TestUtils setUpKinveyUnittestBackend];
    STAssertTrue(loaded, @"should be loaded");
}

- (void) testCreateCustomURLRquest
{
    KCSNetworkRequest* request = [[KCSNetworkRequest alloc] init];
    request.httpMethod = kKCSRESTMethodPOST;
    request.contextRoot = kKCSContextRPC;
    request.pathComponents = @[@"custom",@"endpoint"];
    request.body = @{@"foo":@"bar",@"baz":@[@1,@2,@3]};
    
    NSURLRequest* urlRequest = [request nsurlRequest];
    NSURL* url = urlRequest.URL;
    
    KCSClient* client = [KCSClient sharedClient];
    NSString* expectedURL = [NSString stringWithFormat:@"https://%@.kinvey.com/rpc/%@/custom/endpoint", client.configuration.serviceHostname, client.appKey];
    
    STAssertEqualObjects(expectedURL, url.absoluteString, @"should have a url match");
    
    NSData* bodyData = urlRequest.HTTPBody;
    NSDictionary* undidBody = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:NULL];
    NSDictionary* expBody = @{@"foo":@"bar",@"baz":@[@1,@2,@3]};
    STAssertEqualObjects(expBody, undidBody, @"bodies should match");
}


@end
