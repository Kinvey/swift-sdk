//
//  KCSConnection.h
//  KinveyKit
//
//  Copyright (c) 2008-2011, Kinvey, Inc. All rights reserved.
//
//  This software contains valuable confidential and proprietary information of
//  KINVEY, INC and is subject to applicable licensing agreements.
//  Unauthorized reproduction, transmission or distribution of this file and its
//  contents is a violation of applicable laws.

#import <Foundation/Foundation.h>
#import "KinveyBlocks.h"

@class KCSConnectionResponse;


/*! Abstract base class for all network connections
 
 This class is used to declare the interfaces for all connection types
 */
@interface KCSConnection : NSObject

@property (nonatomic) BOOL followRedirects;

// For Mock object injection
- (id)initWithConnection:(NSURLConnection *)theConnection; // For Mock testing


- (void)performRequest:(NSURLRequest *)theRequest
         progressBlock:(KCSConnectionProgressBlock)onProgress
       completionBlock:(KCSConnectionCompletionBlock)onCompletion
          failureBlock:(KCSConnectionFailureBlock)onFailure
      usingCredentials:(NSURLCredential *)credentials;


@end
