//
//  KCSNSURLSessionFileOperation.m
//  KinveyKit
//
//  Created by Michael Katz on 9/24/13.
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

#import "KCSNSURLSessionFileOperation.h"

#import "KinveyCoreInternal.h"
#import "KinveyDataStoreInternal.h"

@interface KCSNSURLSessionFileOperation () <NSURLSessionDelegate, NSURLSessionDownloadDelegate>
//TODO: cleanup outputhandle from thing - this should probably be the fname!
//@property (nonatomic, retain) NSFileHandle* outputHandle;
//@property (nonatomic) long long maxLength;
@property (nonatomic, retain) NSURL* localFile;
@property (nonatomic, retain) NSURLSession* session;
@property (nonatomic, retain) NSURLSessionDownloadTask* task;
@property (nonatomic, strong) NSURLRequest* request;
//@property (nonatomic, retain) NSHTTPURLResponse* response;
//@property (nonatomic, retain) NSMutableData* responseData;
@property (nonatomic) unsigned long long bytesWritten;
@property (nonatomic, strong) NSError* error;
@property (nonatomic, strong) NSDictionary* returnVals;
@property (nonatomic) BOOL done;
@end

@implementation KCSNSURLSessionFileOperation

- (instancetype) initWithRequest:(NSURLRequest*)request output:(NSURL*)fileHandle
{
    self = [super init];
    if (self) {
        _request = request;
        _localFile = fileHandle;
        _bytesWritten = 0;
        
        //#if BUILD_FOR_UNIT_TEST
        //    lastRequest = self;
        //#endif
    }
    return self;
}


-(void)start {
    @autoreleasepool {
        [super start];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue currentQueue]];
        _task = [_session downloadTaskWithRequest:_request];
        [_task resume];
        
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


//- (void) cancel
//{
//    [_connection cancel];
//    [_outputHandle closeFile];
//    NSError* error = [NSError errorWithDomain:@"UNIT TEST" code:700 userInfo:nil];
//
//    NSMutableDictionary* returnVals = [NSMutableDictionary dictionary];
//    setIfValNotNil(returnVals[KCSFileMimeType], _serverContentType);
//    _completionBlock(NO, returnVals, error);
//}

- (void) complete:(NSError*)error
{
    //TODO: figure this out vvv
//    if (_response && _response.statusCode >= 400) {
//        //is an error just get the data locally
//        //TODO: handle this!!  [_responseData appendData:data];
//    }
    
    NSMutableDictionary* results = [NSMutableDictionary dictionary];
    setIfValNotNil(results[KCSFileMimeType], [self contentType]);
    setIfValNotNil(results[kBytesWritten], @(_bytesWritten));
    self.returnVals = [results copy];
    //SET finished _completionBlock(NO, returnVals, error);
    
    self.finished = YES;
}

#pragma mark - info

- (NSString*) contentType
{
    return self.request.allHTTPHeaderFields[kHeaderContentType];
}

#pragma mark - delegate methods

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    [self complete:error];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    [self complete:error];
}

//- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
//{
//    KCSLogDebug(KCS_LOG_CONTEXT_NETWORK, @"GCS download response code: %d",[(NSHTTPURLResponse*)response statusCode]);
//    
//    _response = (NSHTTPURLResponse*)response;
//    NSDictionary* headers =  [_response allHeaderFields];
//    NSString* length = headers[kHeaderContentLength];
//    _maxLength = [length longLongValue];
//}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    NSInteger responseCode = 200;//self.response.statusCode; TODO?
    NSError* error = nil;
    
    if (responseCode >= 400) {
        NSString* errorStr = [NSString stringWithContentsOfURL:location encoding:NSUTF8StringEncoding error:&error];
        ifNil(errorStr, @"");
        NSDictionary* userInfo = @{NSLocalizedDescriptionKey : @"Download from GCS Failed",
                                   NSLocalizedFailureReasonErrorKey : errorStr,
                                   NSURLErrorFailingURLErrorKey : self.request.URL};
        if (error) {
            userInfo = [userInfo dictionaryByAddingDictionary:@{NSUnderlyingErrorKey : error}];
        }
        error = [NSError createKCSError:KCSFileStoreErrorDomain
                                   code:responseCode
                               userInfo:userInfo];
    } else {
        [[NSFileManager defaultManager] moveItemAtURL:location toURL:self.localFile error:&error];
        //TODO: handle error
    }
    
    [self complete:error];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    KCSLogDebug(KCS_LOG_CONTEXT_NETWORK, @"downloaded %lld bytes from file service", bytesWritten);
    
    _bytesWritten = totalBytesWritten;
                if (self.progressBlock) {
                    //            NSUInteger downloadedAmount = [_outputHandle offsetInFile];
//                    _intermediateFile.length = downloadedAmount;
        //
                    double progress = (double)totalBytesWritten / (double) totalBytesExpectedToWrite;
        //#warning fix this, please
                    self.progressBlock(@[], progress, @{});
                }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    //TODO: do something here
}

@end
