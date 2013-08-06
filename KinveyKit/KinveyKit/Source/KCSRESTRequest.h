//
//  KCSRESTRequest.h
//  KinveyKit
//
//  Copyright (c) 2008-2013, Kinvey, Inc. All rights reserved.
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

#import "KCSGenericRESTRequest.h"

@interface KCSRESTRequest : KCSGenericRESTRequest

@property (nonatomic, copy) KCSConnectionCompletionBlock completionAction;
@property (nonatomic, copy) KCSConnectionFailureBlock failureAction;
@property (nonatomic, copy) KCSConnectionProgressBlock progressAction;

+ (instancetype) requestForResource:(NSString*)resource usingMethod:(NSInteger)requestMethod;

- (instancetype)mockRequestWithMockClass: (Class)connectionClass; // For testing ONLY!
- (instancetype)addHeaders: (NSDictionary *)theHeaders;
- (instancetype)addBody: (NSData *)theBody;
- (instancetype)withCompletionAction: (KCSConnectionCompletionBlock)complete failureAction:(KCSConnectionFailureBlock)failue progressAction: (KCSConnectionProgressBlock)progress;

// Modify known headers
- (void) setJsonBody:(id)bodyObject;
- (void)setContentType: (NSString *)contentType;
- (void)setContentLength: (NSInteger)contentLength;
- (void) setAuth:(NSString*)username password:(NSString*)password;

@end
