//
//  KCSMICRequest2.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-26.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"

#import "KCSMICRequest2.h"
#import "KCSHttpRequest+Private.h"
#import "KCSUser2+KinveyUserService+Private.h"
#import "KCSClient2.h"
#import "NSDictionary+KinveyAdditions.h"
#import "KCSClient.h"
#import "KCSClientConfiguration.h"

@interface KCSMICRequest2 ()

@property (strong) NSString* redirectURI;

@end

@implementation KCSMICRequest2

+(instancetype)requestWithRedirectURI:(NSString *)redirectURI
                           completion:(KCSRequestCompletionBlock)completion
{
    return [self requestWithRedirectURI:redirectURI
                                 client:[KNVClient sharedClient]
                             completion:completion];
}

+(instancetype)requestWithRedirectURI:(NSString *)redirectURI
                               client:(KNVClient*)client
                           completion:(KCSRequestCompletionBlock)completion
{
    KCSMICRequest2* request = [[KCSMICRequest2 alloc] initWithClient:client];
    request.redirectURI = redirectURI;
    request.completionBlock = completion;
    
    request.route = KCSRESTRouteUser;
    request.options = @{KCSRequestLogMethod};
    request.credentials = (id) [KCSClient2 sharedClient];
    return request;
}

-(NSMutableURLRequest *)urlRequest
{
    return [self urlRequestWithClient:[KNVClient sharedClient]];
}

-(NSMutableURLRequest *)urlRequestWithClient:(KNVClient*)client
{
    NSURL* url = [KCSUser2 URLforLoginWithMICRedirectURI:self.redirectURI
                                             isLoginPage:NO
                                                  client:client];
    NSMutableURLRequest* request = [KCSHttpRequest requestForURL:url
                                                          client:client];
    request.HTTPMethod = @"POST";
    KCSClientConfiguration* config = [KCSClient2 sharedClient].configuration;
    if (!config) {
        config = [KCSClient sharedClient].configuration;
    }
    request.HTTPBody = [@{
        @"client_id" : config.appKey,
        kKCSMICRedirectURIKey : self.redirectURI,
        @"response_type" : @"code"
    }.queryString dataUsingEncoding:NSUTF8StringEncoding];
    
    [request setValue:@(request.HTTPBody.length).stringValue
   forHTTPHeaderField:@"Content-Length"];
    
    [request setValue:@"application/x-www-form-urlencoded"
   forHTTPHeaderField:@"Content-Type"];
    return request;
}

@end

#pragma clang diagnostic pop
