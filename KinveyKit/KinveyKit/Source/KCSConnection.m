//
//  KCSConnection.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/23/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSConnection.h"
#import "KCSLogManager.h"

@implementation KCSConnection

@synthesize followRedirects=_followRedirects;

- (id)initWithConnection:(NSURLConnection *)theConnection
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


@end
