//
//  KCSAsyncConnection.h
//  KinveyKit
//
//  Copyright (c) 2008-2013, Kinvey, Inc. All rights reserved.
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

#import "KCSConnection.h"

typedef void (^RunBlock_t)();

@interface KCSAsyncConnection : KCSConnection <NSURLConnectionDataDelegate>

/* The (HTTP) response from the server.  We only store the final responding server in a redirect chain */
@property (strong) NSURLResponse *lastResponse;

/* Stored credentials for Kinvey access */
@property (strong) NSURLCredential *basicAuthCred;

/* How long to wait for a response before timing out */
@property (readonly) double connectionTimeout;

@property (nonatomic, copy) NSURLRequest *request;

@property (nonatomic, readonly) NSInteger contentLength;
@property (nonatomic, readonly) double percentComplete;
@property (nonatomic) double percentNotificationThreshold;

@end
