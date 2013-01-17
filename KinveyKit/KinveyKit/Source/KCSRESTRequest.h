//
//  KCSRESTRequest.h
//  KinveyKit
//
//  Copyright (c) 2008-2013, Kinvey, Inc. All rights reserved.
//
//  This software contains valuable confidential and proprietary information of
//  KINVEY, INC and is subject to applicable licensing agreements.
//  Unauthorized reproduction, transmission or distribution of this file and its
//  contents is a violation of applicable laws.

#import "KCSConnection.h"

#import "KCSGenericRESTRequest.h"

@interface KCSRESTRequest : KCSGenericRESTRequest

@property (nonatomic, copy) KCSConnectionCompletionBlock completionAction;
@property (nonatomic, copy) KCSConnectionFailureBlock failureAction;
@property (nonatomic, copy) KCSConnectionProgressBlock progressAction;

+ (KCSRESTRequest *)requestForResource: (NSString *)resource usingMethod: (NSInteger)requestMethod;

- (id)mockRequestWithMockClass: (Class)connectionClass; // For testing ONLY!
- (id)addHeaders: (NSDictionary *)theHeaders;
- (id)addBody: (NSData *)theBody;
- (id)withCompletionAction: (KCSConnectionCompletionBlock)complete failureAction:(KCSConnectionFailureBlock)failue progressAction: (KCSConnectionProgressBlock)progress;

// Modify known headers
- (void) setJsonBody:(id)bodyObject;
- (void)setContentType: (NSString *)contentType;
- (void)setContentLength: (NSInteger)contentLength;
- (void) setAuth:(NSString*)username password:(NSString*)password;

@end
