//
//  KCSAsyncConnection2.h
//  KinveyKit
//
//  Created by Michael Katz on 5/23/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

//TODO - remove
#import "KCSConnection.h"

@interface KCSAsyncConnection2 : NSObject <NSURLConnectionDataDelegate>

/* The (HTTP) response from the server.  We only store the final responding server in a redirect chain */
@property (strong) NSURLResponse *lastResponse;

/* How long to wait for a response before timing out */
@property (readonly) double connectionTimeout;

@property (nonatomic, copy) NSURLRequest *request;

@property (nonatomic, readonly) NSInteger contentLength;
@property (nonatomic, readonly) double percentComplete;
@property (nonatomic) double percentNotificationThreshold;

- (void)performRequest:(NSURLRequest *)theRequest
         progressBlock:(KCSConnectionProgressBlock)onProgress
       completionBlock:(KCSConnectionCompletionBlock)onCompletion
          failureBlock:(KCSConnectionFailureBlock)onFailure;

@end
