//
//  KCSConnection.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/23/11.
//  Copyright (c) 2011-2013 Kinvey. All rights reserved.
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
#import "KCSLogManager.h"

@implementation KCSConnection

- (instancetype)initWithConnection:(NSURLConnection *)theConnection
{
    return nil; // Unsupported base-class constructor
}

- (void)performRequest:(NSURLRequest *)theRequest
         progressBlock:(KCSConnectionProgressBlock)onProgress
       completionBlock:(KCSConnectionCompletionBlock)onCompletion
          failureBlock:(KCSConnectionFailureBlock)onFailure
      usingCredentials:(NSURLCredential *)credentials
{
    KCSLogForced(@"EXCEPTION Encountered: Name => %@, Reason => %@", @"UnsupportedAbstractBaseClassUse", @"This method is only implemented in subclasses...");
    NSException* myException = [NSException
                                exceptionWithName:@"UnsupportedAbstractBaseClassUse"
                                reason:@"This method is only implemented in subclasses..."
                                userInfo:nil];
    
    @throw myException;

}

- (void) cancel
{
    [self doesNotRecognizeSelector:_cmd];
}

@end
