//
//  KCSRESTRequest.h
//  KinveyKit
//
//  Created by Brian Wilson on 11/28/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSConnection.h"

enum {
    kGetRESTMethod     = 0,
    kPutRESTMethod     = 1,
    kPostRESTMethod    = 2,
    kDeleteRESTMethod  = 3
};

// Switch to static...
#define KCS_JSON_TYPE @"application/json; charset=utf-8"
#define KCS_DATA_TYPE @"application/octet-stream"


@interface KCSRESTRequest : NSObject

@property (nonatomic, copy) NSString *resourceLocation;
@property (nonatomic, copy) KCSConnectionCompletionBlock completionAction;
@property (nonatomic, copy) KCSConnectionFailureBlock failureAction;
@property (nonatomic, copy) KCSConnectionProgressBlock progressAction;
@property (nonatomic, copy) NSMutableDictionary *headers;
@property (nonatomic) NSInteger method;
@property (nonatomic) BOOL isSyncRequest;
@property (nonatomic) BOOL followRedirects;

+ (KCSRESTRequest *)requestForResource: (NSString *)resource usingMethod: (NSInteger)requestMethod;

- (id)syncRequest;
- (id)addHeaders: (NSDictionary *)theHeaders;
- (id)addBody: (NSData *)theBody;
- (id)withCompletionAction: (KCSConnectionCompletionBlock)complete failureAction:(KCSConnectionFailureBlock)failue progressAction: (KCSConnectionProgressBlock)progress;

// Modify known headers
- (void)setContentType: (NSString *)contentType;
- (void)setContentLength: (NSInteger)contentLength;

- (void)start;
@end
