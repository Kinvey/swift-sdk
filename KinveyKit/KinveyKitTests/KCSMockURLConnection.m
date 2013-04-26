//
//  KCSMockURLConnection.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/12/11.
//  Copyright (c) 2011-2013 Kinvey. All rights reserved.
//

#import "KCSMockURLConnection.h"
#import "KCSLogManager.h"

@implementation KCSMockURLConnection

// Methods we use:
// [NSURLConnection connectionWithRequest:self.request delegate:self];

// Delegates called
//- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
//- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
//- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
//- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
//- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
//- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
//- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
//- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
//- (void)connectionDidFinishLoading:(NSURLConnection *)connection
//-(NSURLRequest *)connection:(NSURLConnection *)connection
//            willSendRequest:(NSURLRequest *)request
//           redirectResponse:(NSURLResponse *)redirectResponse


- (id)initWithRequest:(NSURLRequest *)request delegate:(id)delegate
{
    self = [super initWithRequest:request delegate:delegate startImmediately:NO];
    if (self){
        _request = request;
        _delegate = delegate;
    }
    
    return self;
    
}


+ (NSURLConnection *)connectionWithRequest:(NSURLRequest *)request delegate:(id)delegate
{
    // We never want to start this!
    return [[KCSMockURLConnection alloc] initWithRequest:request delegate:delegate startImmediately:NO];
}

- (void)start
{
    KCSLogDebug(@"KCSMockURLConnection: Got request: %@ for delegate: %@", self.request, self.delegate);
    [_delegate connection:(NSURLConnection *)self didReceiveResponse:nil];
    [_delegate connection:(NSURLConnection *)self didReceiveData:nil];
    [_delegate connectionDidFinishLoading:(NSURLConnection *)self];
    KCSLogDebug(@"KCSMockURLConnection: We done!");
}

@end
