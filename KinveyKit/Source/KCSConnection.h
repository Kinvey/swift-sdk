//
//  KCSConnection.h
//  KinveyKit
//
//  Created by Brian Wilson on 11/23/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KinveyBlocks.h"

@class KCSConnectionResponse;


/*! Abstract base class for all network connections
 
 This class is used to declare the interfaces for all connection types
 */
@interface KCSConnection : NSObject

- (id)initWithCredentials:(NSURLCredential *)credentials;
- (id)initWithUsername:(NSString *)username password:(NSString *)password;
- (id)initWithConnection:(NSURLConnection *)theConnection; // For Mock testing


- (void)performRequest:(NSURLRequest *)theRequest
         progressBlock:(KCSConnectionProgressBlock)onProgress
       completionBlock:(KCSConnectionCompletionBlock)onCompletion
          failureBlock:(KCSConnectionFailureBlock)onFailure
      usingCredentials:(NSURLCredential *)credentials;


@end
