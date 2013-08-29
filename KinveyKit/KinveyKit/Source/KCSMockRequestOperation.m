//
//  KCSMockRequestOperation.m
//  KinveyKit
//
//  Created by Michael Katz on 8/23/13.
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

#import "KCSMockRequestOperation.h"

@interface KCSMockRequestOperation ()
@property (nonatomic, strong) NSMutableURLRequest* request;
@property (nonatomic) BOOL done;
@end

@implementation KCSMockRequestOperation

- (instancetype)initWithRequest:(NSMutableURLRequest *)request
{
    self = [super init];
    if (self) {
        _request = request;
    }
    return self;
}

- (void)main {
    @autoreleasepool {
        
        //        [[NSThread currentThread] setName:@"KinveyKit"];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        
        NSLog(@"started");
//        self.downloadedData = [NSMutableData data];
//        
//        _connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self startImmediately:NO];
//        // [connection setDelegateQueue:[NSOperationQueue currentQueue]];
//        [_connection scheduleInRunLoop:runLoop forMode:NSRunLoopCommonModes];
//        [_connection start];
        dispatch_async(dispatch_get_current_queue(), ^{
            [self resolveRequest];
        });
        [runLoop run];
    }
}

- (void) resolveRequest
{
    self.done = YES;
}

- (BOOL)isFinished
{
    return _done;
}

-(BOOL)isExecuting
{
    return YES;
}

- (BOOL)isReady
{
    return YES;
}


@end
