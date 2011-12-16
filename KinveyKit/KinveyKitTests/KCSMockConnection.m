//
//  KCSMockConnection.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/12/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSMockConnection.h"

@implementation KCSMockConnection


- (id)initWithConnection:(NSURLConnection *)theConnection
{
    // We're already a mock object, so we're never going to touch the NSURLConnection...
    return [self init];
    
}


- (void)performRequest:(NSURLRequest *)theRequest
         progressBlock:(KCSConnectionProgressBlock)onProgress
       completionBlock:(KCSConnectionCompletionBlock)onCompletion
          failureBlock:(KCSConnectionFailureBlock)onFailure
      usingCredentials:(NSURLCredential *)credentials
{
    
}




@end
