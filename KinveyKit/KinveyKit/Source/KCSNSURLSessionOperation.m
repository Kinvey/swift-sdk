//
//  KCSNSURLSessionOperation.m
//  KinveyKit
//
//  Created by Michael Katz on 9/11/13.
//  Copyright (c) 2013-2014 Kinvey. All rights reserved.
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


#import "KCSNSURLSessionOperation.h"

#import "KinveyCoreInternal.h"
#import "KCSURLProtocol.h"

@interface KCSNSURLSessionOperation () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSMutableURLRequest* request;
@property (nonatomic, strong) NSMutableData* downloadedData;
@property (nonatomic) long long expectedLength;
@property (nonatomic, strong) KCSNetworkResponse* response;
@property (nonatomic, strong) NSError* error;
@property (nonatomic, strong) NSURLConnection* connection;
@end

@implementation KCSNSURLSessionOperation

- (instancetype) initWithRequest:(NSMutableURLRequest*) request
{
    self = [super init];
    if (self) {
        _request = request;
        _progressBlock = nil;
    }
    return self;
}

-(void)main
{
    self.connection = [NSURLConnection connectionWithRequest:self.request
                                                    delegate:self];
    
    CFRunLoopRun();
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.error = error;
    CFRunLoopStop(CFRunLoopGetCurrent());
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (response && [response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*) response;
        self.response = [[KCSNetworkResponse alloc] init];
        self.response.code = httpResponse.statusCode;
        self.response.headers = httpResponse.allHeaderFields;
        
        self.expectedLength = httpResponse.expectedContentLength;
        self.downloadedData = [NSMutableData dataWithCapacity:MAX(0, (NSUInteger) httpResponse.expectedContentLength)];
    }
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.downloadedData appendData:data];
    if (self.progressBlock) {
        id partial = self.response.code <= 300 ? data : nil;
        self.progressBlock(partial, self.downloadedData.length / (double) self.expectedLength);
    }
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.response.jsonData = self.downloadedData;
    CFRunLoopStop(CFRunLoopGetCurrent());
}

@end
