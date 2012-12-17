//
//    KCS_TWSignedRequest.m
//
//    Copyright (c) 2012 Sean Cook
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to
//    deal in the Software without restriction, including without limitation the
//    rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//    sell copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in
//    all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//    IN THE SOFTWARE.
//
//  Modified by Kinvey 2012

#import "KCS_TWSignedRequest.h"

#import "KCSHiddenMethods.h"
#import "KCSClient.h"
#import "KCS_OAuthCore.h"

@interface KCS_TWSignedRequest()
{
    NSURL *_url;
    NSDictionary *_parameters;
    KCSRESTMethod _signedRequestMethod;
}

- (NSURLRequest *)_buildRequest;

@end

@implementation KCS_TWSignedRequest
@synthesize authToken = _authToken;
@synthesize authTokenSecret = _authTokenSecret;

- (id)initWithURL:(NSURL *)url parameters:(NSDictionary *)parameters requestMethod:(KCSRESTMethod)requestMethod;
{
    self = [super init];
    if (self) {
        _url = [url copy];
        _parameters = [parameters copy];
        _signedRequestMethod = requestMethod;
    }
    return self;
}

- (NSURLRequest *)_buildRequest
{
    NSAssert(_url, @"You can't build a request without an URL");

    NSString *method = [KCSGenericRESTRequest getHTTPMethodForConstant:_signedRequestMethod];

    //  Build our parameter string
    NSMutableString *paramsAsString = [[NSMutableString alloc] init];
    [_parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [paramsAsString appendFormat:@"%@=%@&", key, obj];
    }];

    //  Create the authorization header and attach to our request
    NSData *bodyData = [paramsAsString dataUsingEncoding:NSUTF8StringEncoding];
    NSString* twitterKey = [[KCSClient sharedClient].options objectForKey:KCS_TWITTER_CLIENT_KEY];
    NSString* twitterSecret = [[KCSClient sharedClient].options objectForKey:KCS_TWITTER_CLIENT_SECRET];

    
    NSString *authorizationHeader = KCS_OAuthorizationHeader(_url, method, bodyData, twitterKey, twitterSecret, _authToken, _authTokenSecret, nil);

    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:_url];
    [request setHTTPMethod:method];
    [request setValue:authorizationHeader forHTTPHeaderField:@"Authorization"];
    [request setHTTPBody:bodyData];

    return request;
}

- (void)performRequestWithHandler:(KCS_TWSignedRequestHandler)handler
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURLResponse *response;
        NSError *error;
        NSData *data = [NSURLConnection sendSynchronousRequest:[self _buildRequest] returningResponse:&response error:&error];
        handler(data, response, error);
    });
}
@end
