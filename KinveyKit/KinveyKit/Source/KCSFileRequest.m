//
//  KCSFileRequest.m
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


#import "KCSFileRequest.h"

#import "KinveyCoreInternal.h"
#import "KinveyFileStoreInteral.h"

#import "KCSNSURLCxnFileOperation.h"
#import "KCSNSURLSessionFileOperation.h"
#import "KCSMockFileOperation.h"

@interface KCSFileRequest ()
@property (nonatomic, copy) StreamCompletionBlock completionBlock;
@property (nonatomic, copy) KCSProgressBlock2 progressBlock;

@property (nonatomic, retain) NSFileHandle* outputHandle;

@property (nonatomic) BOOL useMock;

@end

@implementation KCSFileRequest

static NSOperationQueue* queue;

+ (void)initialize
{
    queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 2;
    [queue setName:@"com.kinvey.KinveyKit.FileRequestQueue"];
}

- (NSFileHandle*) prepFile:(KCSFile*)intermediateFile error:(NSError **)error
{
    NSURL* file = [intermediateFile localURL];

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


- (id<KCSFileOperation>) downloadStream:(KCSFile*)intermediate
                        fromURL:(NSURL*)url
            alreadyWrittenBytes:(NSNumber*)alreadyWritten
                completionBlock:(StreamCompletionBlock)completionBlock
                  progressBlock:(KCSProgressBlock2)progressBlock
{
//    NSAssert(_route, @"should have route");
//    NSAssert(self.credentials, @"should have credentials");
//    DBAssert(self.options[KCSRequestOptionClientMethod], @"DB should set client method");
    
    self.completionBlock = completionBlock;
    self.progressBlock = progressBlock;

    NSError* error = nil;
    _outputHandle = [self prepFile:intermediate error:&error];
    if (_outputHandle == nil || error != nil) {
        completionBlock(NO, @{}, error);
        return nil;
    }
    
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:KCSRESTMethodGET];
    
    if (alreadyWritten != nil) {
        unsigned long long written = [_outputHandle seekToEndOfFile];
        if ([alreadyWritten unsignedLongLongValue] == written) {
            KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"Download was already in progress. Resuming from byte %llu.", written);
            [request addValue:[NSString stringWithFormat:@"bytes=%llu-", written] forHTTPHeaderField:@"Range"];
        } else {
            //if they don't match start from begining
            [_outputHandle seekToFileOffset:0];
        }
    }
    
    KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"%@ %@", request.HTTPMethod, request.URL);

    NSOperation<KCSFileOperation>* op = nil;


//    if (_useMock == YES) {
//        op = [[KCSMockFileOperation alloc] initWithRequest:request];
//    } else {
//        
//        if ([KCSPlatformUtils supportsNSURLSession]) {
//            op = [[KCSNSURLSessionFileOperation alloc] initWithRequest:request];
//        } else {
            op = [[KCSNSURLCxnFileOperation alloc] initWithRequest:request output:_outputHandle];
//        }
//    }

//    
    @weakify(op);
    op.completionBlock = ^() {
        @strongify(op);
        //TODO: remove ivar?
        [_outputHandle closeFile];
        completionBlock(YES, op.returnVals, op.error);
    };
    
    [queue addOperation:op];
    return op;
}

@end
