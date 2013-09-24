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

@interface KCSNSURLCxnFileOperation ()
@property (nonatomic, copy) StreamCompletionBlock completionBlock;
@property (nonatomic, copy) KCSProgressBlock2 progressBlock;
@property (nonatomic, retain) NSFileHandle* outputHandle;
@property (nonatomic) NSUInteger maxLength;
@property (nonatomic, retain) KCSFile* intermediateFile;
@property (nonatomic, retain) NSString* serverContentType;
@property (nonatomic, retain) NSURLConnection* connection;
@property (nonatomic, retain) NSHTTPURLResponse* response;
@property (nonatomic, retain) NSMutableData* responseData;
@property (nonatomic) unsigned long long bytesWritten;
@end

@implementation KCSNSURLCxnFileOperation

- (void) downloadStream:(KCSFile*)intermediate
                fromURL:(NSURL*)url
    alreadyWrittenBytes:(NSNumber*)alreadyWritten
        completionBlock:(StreamCompletionBlock)completionBlock
          progressBlock:(KCSProgressBlock2)progressBlock
{
    self.completionBlock = completionBlock;
    self.progressBlock = progressBlock;
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    
    NSURL* file = [intermediate localURL];
    NSError* error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[file path]] == NO) {
        [[NSFileManager defaultManager] createFileAtPath:[file path] contents:nil attributes:nil];
    }
    if (error != nil) {
        KK2(error domain)
        error = [error updateWithMessage:@"Unable to write to intermediate file" domain:KCSFileStoreErrorDomain];
        completionBlock(NO, @{}, error);
        return;
    }
    _outputHandle = [NSFileHandle fileHandleForWritingToURL:file error:&error];
    if (error != nil) {
        error = [error updateWithMessage:@"Unable to write to intermediate file" domain:KCSFileStoreErrorDomain];
        completionBlock(NO, @{}, error);
        return;
    }
    if (alreadyWritten != nil) {
        unsigned long long written = [_outputHandle seekToEndOfFile];
        if ([alreadyWritten unsignedLongLongValue] == written) {
            KCSLogInfo(KCS_LOG_CONTEXT_NETWORK, @"Download was already in progress. Resuming from byte %llu.", written);
            [request addValue:[NSString stringWithFormat:@"bytes=%llu-", written] forHTTPHeaderField:@"Range"];
        }
    }
    
    _intermediateFile = intermediate;
    _bytesWritten = 0;
    
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [_connection start];
    
    
//#if BUILD_FOR_UNIT_TEST
//    lastRequest = self;
//#endif
}

@end
