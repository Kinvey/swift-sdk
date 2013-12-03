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
@property (nonatomic, strong) NSMutableURLRequest* request;
@property (nonatomic, retain) NSHTTPURLResponse* response;
@property (nonatomic, retain) NSMutableData* responseData;
@property (nonatomic) unsigned long long bytesWritten;
@property (nonatomic, strong) NSError* error;
@property (nonatomic, strong) NSDictionary* returnVals;
@property (nonatomic) BOOL done;
@property (nonatomic, strong) id context;
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


- (instancetype) initWithRequest:(NSMutableURLRequest*)request output:(NSURL*)fileURL context:(id)context
{
    self = [super init];
    if (self) {
        _request = request;
        _localURL = fileURL;
        _bytesWritten = 0;
        _context = context;
        
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

        
        NSNumber* alreadyWritten = (NSNumber*)self.context;
        if (alreadyWritten != nil) {
            //TODO: figure this one out
            unsigned long long written = [_outputHandle seekToEndOfFile];
            //unsigned long long written = [alreadyWritten unsignedLongLongValue];
            if ([alreadyWritten unsignedLongLongValue] == written) {
                KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"Download was already in progress. Resuming from byte %@.", alreadyWritten);
                [self.request addValue:[NSString stringWithFormat:@"bytes=%llu-", written] forHTTPHeaderField:@"Range"];
            } else {
                //if they don't match start from begining
                [_outputHandle seekToFileOffset:0];
            }
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


- (void) cancel
{
    [_connection cancel];
    [_outputHandle closeFile];
    NSError* error = [NSError errorWithDomain:@"UNIT TEST" code:700 userInfo:nil];
    
    self.error = error;

    [super cancel];
    self.finished = YES;
}

- (void) complete:(NSError*)error
{
    NSMutableDictionary* results = [NSMutableDictionary dictionary];
    setIfValNotNil(results[KCSFileMimeType], [self contentType]);
    setIfValNotNil(results[kBytesWritten], @(_bytesWritten));
    self.returnVals = [results copy];

    [_outputHandle closeFile];
    self.error = error;


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
    KCSLogDebug(KCS_LOG_CONTEXT_NETWORK, @"GCS download response code: %ld",(long)[(NSHTTPURLResponse*)response statusCode]);
    
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
    KCSLogDebug(KCS_LOG_CONTEXT_NETWORK, @"downloaded %lu bytes from file service", (long)[data length]);
    
    if (_response && _response.statusCode >= 400) {
        //is an error just get the data locally
        [_responseData appendData:data];
    } else {
        //response is good, collect data
        [_outputHandle writeData:data];
        _bytesWritten += data.length;
        if (self.progressBlock) {
            NSUInteger downloadedAmount = [_outputHandle offsetInFile];
            //TODO: fix  or not?          _intermediateFile.length = downloadedAmount;
            
            double progress = (double)downloadedAmount / (double) _maxLength;
            _progressBlock(@[], progress, @{});
        }
    }
}

@end
