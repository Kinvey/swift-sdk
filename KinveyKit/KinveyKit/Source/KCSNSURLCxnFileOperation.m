//
//  KCSNSURLCxnFileOperation.m
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


#import "KCSNSURLCxnFileOperation.h"

#import "KinveyCoreInternal.h"
#import "KinveyDataStoreInternal.h"

#define kBytesWritten @"bytesWritten"

@interface KCSNSURLCxnFileOperation ()
@property (nonatomic, retain) NSFileHandle* outputHandle;
@property (nonatomic, retain) NSURL* localURL;
@property (nonatomic) long long maxLength;
@property (nonatomic, retain) NSURLConnection* connection;
@property (nonatomic, strong) NSURLRequest* request;
@property (nonatomic, retain) NSHTTPURLResponse* response;
@property (nonatomic, retain) NSMutableData* responseData;
@property (nonatomic) unsigned long long bytesWritten;
@property (nonatomic, strong) NSError* error;
@property (nonatomic, strong) NSDictionary* returnVals;
@property (nonatomic) BOOL done;
@end

@implementation KCSNSURLCxnFileOperation

- (NSFileHandle*) prepFile:(NSURL*)file error:(NSError **)error
{
    NSFileHandle* handle = nil;
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[file path]] == NO) {
        [[NSFileManager defaultManager] createFileAtPath:[file path] contents:nil attributes:nil];
    }
    
    NSError* tempError = nil;
    handle = [NSFileHandle fileHandleForWritingToURL:file error:&tempError];
    if (tempError != nil) {
        handle = nil;
        if (error != NULL) {
            *error = [tempError updateWithMessage:@"Unable to write to intermediate file." domain:KCSFileStoreErrorDomain];
        }
    }
    return handle;
}


- (instancetype) initWithRequest:(NSURLRequest*)request output:(NSURL*)fileURL
{
    self = [super init];
    if (self) {
        _request = request;
        _localURL = fileURL;
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
        
        NSError* error = nil;
        _outputHandle = [self prepFile:self.localURL error:&error];
        if (_outputHandle == nil || error != nil) {
            [self complete:error];
            return;
        }




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
    NSMutableDictionary* results = [NSMutableDictionary dictionary];
    setIfValNotNil(results[KCSFileMimeType], [self contentType]);
    setIfValNotNil(results[kBytesWritten], @(_bytesWritten));
    self.returnVals = [results copy];

    [_outputHandle closeFile];

    //SET finished _completionBlock(NO, returnVals, error);
    
    self.finished = YES;
}

#pragma mark - info

- (NSString*) contentType
{
    return self.request.allHTTPHeaderFields[kHeaderContentType];
}

#pragma mark - delegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self complete:error];
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    KCSLogDebug(KCS_LOG_CONTEXT_NETWORK, @"GCS download response code: %d",[(NSHTTPURLResponse*)response statusCode]);
    
    _response = (NSHTTPURLResponse*)response;
    NSDictionary* headers =  [_response allHeaderFields];
    NSString* length = headers[kHeaderContentLength];
    _maxLength = [length longLongValue];
    
    if (_response.statusCode >= 400) {
        _responseData = [NSMutableData data];
    }
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
    
    NSInteger responseCode = self.response.statusCode;
    NSError* error = nil;
    if (responseCode >= 400) {
        NSString* errorStr = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
        ifNil(errorStr, @"");
        error = [NSError createKCSError:KCSFileStoreErrorDomain
                                   code:responseCode
                               userInfo:@{NSLocalizedDescriptionKey : @"Download from GCS Failed",
                                          NSLocalizedFailureReasonErrorKey : errorStr,
                                          NSURLErrorFailingURLErrorKey : self.request.URL}];
    }
    
    [self complete:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    KCSLogDebug(KCS_LOG_CONTEXT_NETWORK, @"downloaded %u bytes from file service", [data length]);
    
    if (_response && _response.statusCode >= 400) {
        //is an error just get the data locally
        [_responseData appendData:data];
    } else {
        //response is good, collect data
        [_outputHandle writeData:data];
        _bytesWritten += data.length;
//        if (_progressBlock) {
//            NSUInteger downloadedAmount = [_outputHandle offsetInFile];
//            _intermediateFile.length = downloadedAmount;
//            
//            double progress = (double)downloadedAmount / (double) _maxLength;
//#warning fix this, please
//            _progressBlock(@[_intermediateFile], progress, @{});
//        }
    }
}

@end
