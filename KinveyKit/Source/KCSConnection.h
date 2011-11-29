//
//  KCSConnection.h
//  KinveyKit
//
//  Created by Brian Wilson on 11/23/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KCSConnectionResponse;


@interface KCSConnection : NSObject

// Define the block types that we expect
typedef void(^KCSConnectionProgressBlock)(KCSConnection *connection);
typedef void(^KCSConnectionCompletionBlock)(KCSConnectionResponse *connection);
typedef void(^KCSConnectionFailureBlock)(NSError *connection);

- (id)initWithCredentials:(NSURLCredential *)credentials;
- (id)initWithUsername:(NSString *)username password:(NSString *)password;
- (id)initWithConnection:(NSURLConnection *)theConnection; // For Mock testing


- (void)performRequest:(NSURLRequest *)theRequest
         progressBlock:(KCSConnectionProgressBlock)onProgress
       completionBlock:(KCSConnectionCompletionBlock)onCompletion
          failureBlock:(KCSConnectionFailureBlock)onFailure
      usingCredentials:(NSURLCredential *)credentials;


@end
