//
//  KCSMockConnection.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/12/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSMockConnection.h"
#import "KCSLogManager.h"

@implementation KCSMockConnection

@synthesize connectionShouldReturnNow = _connectionShouldReturnNow;
@synthesize connectionShouldFail = _connectionShouldFail;
@synthesize responseForSuccess = _responseForSuccess;
@synthesize progressActions = _progressActions;
@synthesize errorForFailure = _errorForFailure;
@synthesize delayInMSecs = _delayInMSecs;
@synthesize providedRequest = _providedRequest;
@synthesize providedCredentials = _providedCredentials;


#define BOOL_STRING(b) (b)?@"YES":@"NO"

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"Return now? %@\nShould Fail? %@\nOn Success: %@\nOn Progress: %@\nOn Error: %@\nDelay: %g\nReq: %@\n Cred: %@",
         BOOL_STRING(_connectionShouldReturnNow), BOOL_STRING(_connectionShouldFail),
            _responseForSuccess, _progressActions, _errorForFailure, _delayInMSecs, _providedRequest, _providedCredentials];
}


- (id)init
{
    self = [super init];
    if (self){
        _connectionShouldFail = NO;
        _connectionShouldReturnNow = NO;
        _delayInMSecs = 0.1; // Essentially "now"
        _providedCredentials = nil;
        _providedRequest = nil;
    }
    
    return self;
}

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
    KCSLogWarning(@"**** MOCK OBJECT TESTING IN PROGRESS, NO NETWORK! ****");
    if (!self.connectionShouldReturnNow){
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, self.delayInMSecs * NSEC_PER_MSEC);
        
        if ([self.progressActions count] > 0){
            KCSLogWarning(@"TBD functionality...");
        }
        
        if (self.connectionShouldFail) {
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                onFailure(self.errorForFailure);
            });
        } else {
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                onCompletion(self.responseForSuccess);
            });
        }
    } else {
        if (self.connectionShouldFail){
            onFailure(self.errorForFailure);
        } else {
            onCompletion(self.responseForSuccess);
        }
    }
    
    self.providedCredentials = credentials;
    self.providedRequest = theRequest;
    
}





@end
