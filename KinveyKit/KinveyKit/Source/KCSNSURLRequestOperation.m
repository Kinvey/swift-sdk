//
//  KCSNSURLRequestOperation.m
//  KinveyKit
//
//  Created by Michael Katz on 8/20/13.
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


#import "KCSNSURLRequestOperation.h"

#import "KinveyCoreInternal.h"

@interface KCSNSURLRequestOperation () <NSURLConnectionDataDelegate, NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSMutableURLRequest* request;
@property (nonatomic, strong) NSMutableData* downloadedData;
@property (nonatomic, strong) NSURLConnection* connection;
@property (nonatomic) BOOL done;
@property (nonatomic, strong) KCSNetworkResponse* response;
@property (nonatomic, strong) NSError* error;
@end

@implementation KCSNSURLRequestOperation

- (instancetype) initWithRequest:(NSMutableURLRequest*) request
{
    self = [super init];
    if (self) {
        _request = request;
    }
    return self;
}

-(void)start {
    @autoreleasepool {
        [super start];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        
        self.downloadedData = [NSMutableData data];
        self.response = [[KCSNetworkResponse alloc] init];
        
        _connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self startImmediately:NO];
        // [connection setDelegateQueue:[NSOperationQueue currentQueue]];
        [_connection scheduleInRunLoop:runLoop forMode:NSRunLoopCommonModes];
        [_connection start];
        [runLoop run];
    }
}


- (void)setFinished:(BOOL)isFinished
{
    [self willChangeValueForKey:@"isFinished"];
    _done = isFinished;
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)isFinished
{
    return ([self isCancelled] ? YES : _done);
}


-(BOOL)isExecuting
{
    return YES;
}

- (BOOL)isReady
{
    return YES;
}

- (void) complete:(NSError*) error
{
    self.error = error;
    self.finished = YES;
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSHTTPURLResponse* hresponse = (NSHTTPURLResponse*) response;
    //TODO strip headers?
    KCSLogInfo(@"received response: %d %@", hresponse.statusCode, hresponse.allHeaderFields);

    self.response.code = hresponse.statusCode;
    self.response.headers = hresponse.allHeaderFields;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self complete:error];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.downloadedData appendData:data];
}

///TODO: put in response object
/*
 - (id) jsonResponseValue:(NSError**) anError
 {
 if (self.responseData == nil) {
 return nil;
 }
 if (self.responseData.length == 0) {
 return [NSData data];
 }
 //results are now wrapped by request in KCSRESTRequest, and need to unpack them here.
 KCS_SBJsonParser *parser = [[KCS_SBJsonParser alloc] init];
 NSDictionary *jsonResponse = [parser objectWithData:self.responseData];
 NSObject *jsonData = nil;
 if (parser.error) {
 KCSLogError(@"JSON Serialization failed: %@", parser.error);
 if ([parser.error isEqualToString:@"Broken Unicode encoding"]) {
 NSObject* reevaluatedObject = [self jsonResponseValue:anError format:NSASCIIStringEncoding];
 return reevaluatedObject;
 } else {
 if (anError != NULL) {
 *anError = [KCSErrorUtilities createError:@{NSURLErrorFailingURLStringErrorKey : _userData[NSURLErrorFailingURLStringErrorKey]}  description:parser.error errorCode:KCSInvalidJSONFormatError domain:KCSNetworkErrorDomain requestId:self.requestId];
 }
 }
 } else {
 jsonData = [jsonResponse valueForKey:@"result"];
 jsonData = jsonData ? jsonData : jsonResponse;
 }
 
 if (self.responseCode >= 400 && [jsonData isKindOfClass:[NSDictionary class]] && self.userData != nil && self.userData[NSURLErrorFailingURLStringErrorKey] != nil) {
 jsonData = [jsonData mutableCopy];
 ((NSMutableDictionary*)jsonData)[NSURLErrorFailingURLStringErrorKey] = self.userData[NSURLErrorFailingURLStringErrorKey];
 }
 
 return jsonData;
 }
 
 - (id) jsonResponseValue
 {
 NSString* cytpe = [_responseHeaders valueForKey:@"Content-Type"];
 
 if (cytpe == nil || [cytpe containsStringCaseInsensitive:@"json"]) {
 return [self jsonResponseValue:nil];
 } else {
 if (_responseData.length == 0) {
 return @{};
 } else {
 KCSLogWarning(@"not a json repsonse");
 return @{@"debug" : [self stringValue]};
 }
 }*/


- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    id obj = [[[KCS_SBJsonParser alloc] init] objectWithData:self.downloadedData];
    if (obj != nil) {
        self.response.jsonData = obj;
 
        [self complete:nil];
    } else {
        //TODO: is an error
        NSError* error = nil;
        [self complete:error];
    }
}

@end
