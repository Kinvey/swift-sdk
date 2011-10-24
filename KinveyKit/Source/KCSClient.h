//
//  KinveyClient.h
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONKit.h"

@protocol KCSClientActionDelegate <NSObject>

- (void) actionDidFail: (id)error;
- (void) actionDidComplete: (NSObject *) result;


@end

@interface KCSClient : NSObject <NSURLConnectionDelegate>

#pragma mark -
#pragma mark Properties

// TODO: Remove nonatomic property from fields (after verifying atomicity)
@property (retain, nonatomic) NSMutableData *receivedData;
@property (retain, nonatomic, readwrite) NSString *appKey;
@property (retain, nonatomic, readwrite) NSString *appSecret;
@property (retain, nonatomic) NSString *baseURI;
@property (retain, nonatomic) NSURLCredential *basicAuthCred;
@property (assign) id <KCSClientActionDelegate> actionDelegate;
@property (readonly) double connectionTimeout;


#pragma mark -
#pragma mark NSURLConnectionDelegate Implementation

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;
- (void)connection:(NSURLConnection *)connection didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection;

#pragma mark -
#pragma mark Initializers

- (id)init;
- (id)initWithAppKey:(NSString *)key andSecret: (NSString *)secret;
- (id)initWithAppKey:(NSString *)key andSecret: (NSString *)secret andBaseURI: (NSString *)uri;


// GET, PUT, POST, DELETE
- (void)clientActionDelegate: (id <KCSClientActionDelegate>)delegate forGetRequestAtPath: (NSString *)path;
- (void)clientActionDelegate: (id <KCSClientActionDelegate>)delegate forPutRequest: (NSData *)putRequest atPath: (NSString *)path;
- (void)clientActionDelegate: (id <KCSClientActionDelegate>)delegate forPostRequest: (NSData *)postRequest atPath: (NSString *)path;
- (void)clientActionDelegate: (id <KCSClientActionDelegate>)delegate forDeleteRequestAtPath: (NSString *)path;

@end
