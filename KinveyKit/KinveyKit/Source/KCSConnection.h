//
//  KCSConnection.h
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

#import <Foundation/Foundation.h>
#import "KinveyBlocks.h"

@class KCSConnectionResponse;
@protocol KCSCredentials;

/*! Abstract base class for all network connections
 
 This class is used to declare the interfaces for all connection types
 */
@interface KCSConnection : NSObject

@property (nonatomic) BOOL followRedirects;
@property (nonatomic, retain) id<KCSCredentials> credentials;

// For Mock object injection
- (instancetype)initWithConnection:(NSURLConnection *)theConnection; // For Mock testing


- (void)performRequest:(NSURLRequest *)theRequest
         progressBlock:(KCSConnectionProgressBlock)onProgress
       completionBlock:(KCSConnectionCompletionBlock)onCompletion
          failureBlock:(KCSConnectionFailureBlock)onFailure
      usingCredentials:(NSURLCredential *)credentials;

- (void) cancel;

@end
