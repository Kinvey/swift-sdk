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

@interface KCSNSURLSessionOperationManager : NSObject  <NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@property (nonatomic, strong) NSMutableDictionary* tasks;

@property (nonatomic, strong) NSURLSessionConfiguration* sessionConfig;
@property (nonatomic, strong) NSURLSession* session;
@property (nonatomic, assign) dispatch_once_t sessionOnceToken;

+(instancetype)sharedInstance;

@end

@interface KCSNSURLSessionOperation () <NSURLSessionDelegate, NSURLSessionDataDelegate>
@property (nonatomic, strong) NSMutableURLRequest* request;
@property (nonatomic, strong) NSMutableData* downloadedData;
@property (nonatomic, strong) NSURLSessionDataTask* dataTask;
@property (nonatomic) long long expectedLength;
@property (nonatomic) BOOL done;
@property (nonatomic, strong) KCSNetworkResponse* response;
@property (nonatomic, strong) NSError* error;
@property (nonatomic, strong) KCSNSURLSessionOperationManager* manager;
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

-(void)start {
    @autoreleasepool {
        [super start];
        
        self.manager = [KCSNSURLSessionOperationManager sharedInstance];
        self.downloadedData = [NSMutableData data];
        self.response = [[KCSNetworkResponse alloc] init];
        self.dataTask = [self.manager.session dataTaskWithRequest:self.request];
        self.manager.tasks[@(self.dataTask.taskIdentifier)] = self;
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

-(BOOL)isAsynchronous
{
    return YES;
}

- (void) complete:(NSError*) error
{
    self.response.jsonData = self.downloadedData;
    self.error = error;
    self.finished = YES;
    [self.manager.tasks removeObjectForKey:@(self.dataTask.taskIdentifier)];
}

@end

@implementation KCSNSURLSessionOperationManager

static dispatch_once_t onceToken;

+(instancetype)sharedInstance
{
    static KCSNSURLSessionOperationManager* sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[KCSNSURLSessionOperationManager alloc] init];
    });
    return sharedInstance;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        self.tasks = [NSMutableDictionary dictionary];
    }
    return self;
}

-(NSURLSession*)session
{
    dispatch_once(&_sessionOnceToken, ^{
        self.sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.sessionConfig.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:0
                                                                    diskCapacity:0
                                                                        diskPath:nil];
        self.sessionConfig.HTTPShouldSetCookies = NO;
        self.sessionConfig.HTTPShouldUsePipelining = YES;
        self.session = [NSURLSession sessionWithConfiguration:self.sessionConfig
                                                     delegate:self
                                                delegateQueue:nil];
    });
    self.sessionConfig.protocolClasses = [KCSURLProtocol protocolClasses];
    return _session;
}

-(KCSNSURLSessionOperation*)operationForTask:(NSURLSessionTask*)task
{
    KCSNSURLSessionOperation* op = self.tasks[@(task.taskIdentifier)];
    NSParameterAssert(op);
    return op;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask
{
    
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    KCSNSURLSessionOperation* op = [self operationForTask:dataTask];
    [op.downloadedData appendData:data];
    if (op.progressBlock) {
        id partial = op.response.code <= 300 ? data : nil;
        op.progressBlock(partial, op.downloadedData.length / (double) op.expectedLength);
    }

}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    KCSNSURLSessionOperation* op = [self operationForTask:dataTask];
    NSHTTPURLResponse* hresponse = (NSHTTPURLResponse*) response;
    //TODO strip headers?
    KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"received response: %ld %@ (KinveyKit ID %@)", (long)hresponse.statusCode, hresponse.allHeaderFields, op.clientRequestId);
    
    op.response.code = hresponse.statusCode;
    op.response.headers = hresponse.allHeaderFields;
    
    op.expectedLength = response.expectedContentLength;
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *))completionHandler
{
    NSTHREAD_IS_NOT_MAIN_THREAD;
    completionHandler(NULL);
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    NSTHREAD_IS_NOT_MAIN_THREAD;
    KCSNSURLSessionOperation* op = nil;
    for (id key in self.tasks.allKeys) {
        op = self.tasks[key];
        op.error = error;
        [op complete:error];
    }
    onceToken = 0;
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
}

#pragma mark - NSURLSessionTaskDelegate

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSTHREAD_IS_NOT_MAIN_THREAD;
    KCSNSURLSessionOperation* op = [self operationForTask:task];
    [op complete:error];
}

@end
