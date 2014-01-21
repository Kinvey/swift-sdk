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

@interface KCSNSURLSessionOperation () <NSURLSessionDelegate, NSURLSessionDataDelegate>
@property (nonatomic, strong) NSMutableURLRequest* request;
@property (nonatomic, strong) NSMutableData* downloadedData;
@property (nonatomic, strong) NSURLSessionDataTask* dataTask;
@property (nonatomic) long long expectedLength;
@property (nonatomic) BOOL done;
@property (nonatomic, strong) KCSNetworkResponse* response;
@property (nonatomic, strong) NSError* error;
@end

@implementation KCSNSURLSessionOperation

- (NSURLSession*) session
{
    //    static NSURLSession* session;
    //    static dispatch_once_t onceToken;
    //    dispatch_once(&onceToken, ^{
    NSURLSession* session;
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    //    });
    return session;
}


- (instancetype) initWithRequest:(NSMutableURLRequest*) request
{
    self = [super init];
    if (self) {
        _request = request;
        _progressBlock = nil;
    }
    return self;
}

-(void)start {
    @autoreleasepool {
        [super start];
        
        self.downloadedData = [NSMutableData data];
        self.response = [[KCSNetworkResponse alloc] init];
        self.dataTask = [[self session] dataTaskWithRequest:self.request];
        [self.dataTask setTaskDescription:self.clientRequestId];
        [self.dataTask resume];
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
    self.response.jsonData = self.downloadedData;
    self.error = error;
    self.finished = YES;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    [self.downloadedData appendData:data];
    if (self.progressBlock) {
        id partial = self.response.code <= 300 ? self.downloadedData : nil;
        self.progressBlock(partial, self.downloadedData.length / (double) _expectedLength);
    }

}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NSHTTPURLResponse* hresponse = (NSHTTPURLResponse*) response;
    //TODO strip headers?
    KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"received response: %ld %@ (KinveyKit ID %@)", (long)hresponse.statusCode, hresponse.allHeaderFields, self.clientRequestId);
    
    self.response.code = hresponse.statusCode;
    self.response.headers = hresponse.allHeaderFields;
    
    _expectedLength = response.expectedContentLength;
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *))completionHandler
{
    completionHandler(NULL);
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    self.error = error;
    [self complete:error];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    [self complete:error];
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
}

#pragma mark - completion

- (void)dealloc
{
    NSAssert(NO,@"No way, man");
}
@end
