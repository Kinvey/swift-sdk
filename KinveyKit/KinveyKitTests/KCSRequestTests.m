//
//  KCSRequestTests.m
//  KinveyKit
//
//  Created by Michael Katz on 5/30/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "KCSRequestTests.h"
#import "TestUtils.h"

#import "KCSRequest.h"
#import "KCSClient.h"

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
    NSString* expectedURL = [NSString stringWithFormat:@"https://%@.kinvey.com/rpc/%@/custom/endpoint", client.serviceHostname, client.appKey];
    
    STAssertEqualObjects(expectedURL, url.absoluteString, @"should have a url match");
    
    NSData* bodyData = urlRequest.HTTPBody;
    NSDictionary* undidBody = [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:NULL];
    NSDictionary* expBody = @{@"foo":@"bar",@"baz":@[@1,@2,@3]};
    STAssertEqualObjects(expBody, undidBody, @"bodies should match");
}
@end
