//
//  KCSServerService.m
//  KinveyKit
//
//  Created by Michael Katz on 5/23/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "KCSServerService.h"

#import "KCSAsyncConnection2.h"

@implementation KCSServerService

- (void)performRequest:(NSURLRequest *)theRequest progressBlock:(KCSConnectionProgressBlock)onProgress completionBlock:(KCSConnectionCompletionBlock)onCompletion failureBlock:(KCSConnectionFailureBlock)onFailure
{
    KCSAsyncConnection2* cxn = [[KCSAsyncConnection2 alloc] init];
    [cxn performRequest:theRequest progressBlock:onProgress completionBlock:onCompletion failureBlock:onFailure];
}

@end
