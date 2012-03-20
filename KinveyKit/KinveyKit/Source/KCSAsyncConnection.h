//
//  KCSAsyncConnection.h
//  KinveyKit
//
//  Copyright (c) 2008-2011, Kinvey, Inc. All rights reserved.
//
//  This software contains valuable confidential and proprietary information of
//  KINVEY, INC and is subject to applicable licensing agreements.
//  Unauthorized reproduction, transmission or distribution of this file and its
//  contents is a violation of applicable laws.

#import "KCSConnection.h"

@interface KCSAsyncConnection : KCSConnection <NSURLConnectionDataDelegate>


/*! The (HTTP) response from the server.  We only store the final responding server in a redirect chain */
@property (retain) NSURLResponse *lastResponse;

/*! Stored credentials for Kinvey access */
@property (retain) NSURLCredential *basicAuthCred;

/*! How long to wait for a response before timing out */
@property (readonly) double connectionTimeout;

@property (nonatomic, copy) NSURLRequest *request;

@property (nonatomic, readonly) NSInteger contentLength;
@property (nonatomic, readonly) double percentComplete;
@property (nonatomic) NSUInteger percentNotificationThreshold;





@end
