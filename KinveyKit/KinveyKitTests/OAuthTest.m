//
//  OAuthTest.m
//  KinveyKit
//
//  Created by Michael Katz on 12/4/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "OAuthTest.h"
#import "KCSGenericRESTRequest.h"
#import "NSString+KinveyAdditions.h"
#import "KCS_OAuthCore.h"

#import "TestUtils.h"
#import "KCSHiddenMethods.h"
#import "KCSConnectionResponse.h"

@implementation OAuthTest


- (void) notestOAuth1Step1a
{
    
//    NSURL* url = [NSURL URLWithString:@"https://api.linkedin.com/uas/oauth/requestToken"];
    
    NSString* urlString = @"https://api.linkedin.com/uas/oauth/requestToken";
    urlString = [urlString stringByAppendingQueryString:@"scope=r_basicprofile"];
    
//    KCSGenericRESTRequest* request = [[KCSGenericRESTRequest alloc] initWithResource:urlString usingMethod:kPostRESTMethod];
    
//    OAMutableURLRequest *request =
//    [[[OAMutableURLRequest alloc] initWithURL:requestTokenURL
//                                     consumer:self.consumer
//                                        token:nil
//                                     callback:linkedInCallbackURL
//                            signatureProvider:nil] autorelease];
    
  //  [request setHTTPMethod:@"POST"];
    
//    OARequestParameter *nameParam = [[OARequestParameter alloc] initWithName:@"scope"
//                                                                       value:@"r_basicprofile+rw_nus"];
//    NSArray *params = [NSArray arrayWithObjects:nameParam, nil];
//    [request setParameters:params];
//    OARequestParameter * scopeParameter=[OARequestParameter requestParameter:@"scope" value:@"r_fullprofile rw_nus"];
//    
//    [request setParameters:[NSArray arrayWithObject:scopeParameter]];
    

    
//    OADataFetcher *fetcher = [[[OADataFetcher alloc] init] autorelease];
//    [fetcher fetchDataWithRequest:request
//                         delegate:self
//                didFinishSelector:@selector(requestTokenResult:didFinish:)
//                  didFailSelector:@selector(requestTokenResult:didFail:)];
    

    self.done = NO;
    
    NSString *method = [KCSGenericRESTRequest getHTTPMethodForConstant:kPostRESTMethod];
    NSString* auth = KCS_OAuthorizationHeader([NSURL URLWithString:urlString], method, nil, @"u1kcjwo0qa5d", @"XpqT72RXPQICPWrQ", nil, nil, nil);
    
    
    __block NSString* results = nil;
    
    KCSGenericRESTRequest* request = [KCSGenericRESTRequest requestForResource:urlString usingMethod:kPostRESTMethod withCompletionAction:^(KCSConnectionResponse *response) {
        NSLog(@"%@", [response stringValue]);
        results = [response stringValue];
        self.done = YES;
    } failureAction:^(NSError *errorOrNil) {
        STAssertNoError
        self.done = YES;
    } progressAction:nil];
    [request.headers setValue:auth forKey:@"Authorization"];
    
    [request start];
    
    [self poll];
    
    STAssertNotNil(results, @"results - 1a");
    
    NSString* oauthToken = nil;
    
    NSArray* pairs = [results componentsSeparatedByString:@"&"];
    for (NSString* pair in pairs) {
        NSArray* keyval = [results componentsSeparatedByString:@"="];
        NSString* key = keyval[0];
        NSString* value = keyval[1];
        if ([key isEqualToString:@"oauth_token"]) {
            oauthToken = value;
        }
    }
    
//    NSString* webUrlString = [@"https://www.linkedin.com/uas/oauth/authorize" stringByAppendingQueryString:[NSString stringWithFormat:@"oauth_token=%@", oauthToken]];
}

@end
