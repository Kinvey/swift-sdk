//
//  KCSRESTRequest.h
//  KinveyKit
//
//  Created by Brian Wilson on 11/28/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSConnection.h"

//NSString *blobLoc = [baseURL stringByAppendingFormat:@"/blob/%@/download-loc/%@", [[self kinveyClient] appKey], blobId];
//KCSBlobDelegateMapper *mappedDelegate = [[KCSBlobDelegateMapper alloc] initWithDelegate:delegate usingClient:_kinveyClient];


enum {
    kGetRESTMethod     = 0,
    kPutRESTMethod     = 1,
    kPostRESTMethod    = 2,
    kDeleteRESTMethod  = 3
};


@interface KCSRESTRequest : KCSConnection

@property (nonatomic, copy) NSString *resourceLocation;
@property (nonatomic, retain) KCSConnectionCompletionBlock completionAction;
@property (nonatomic, retain) KCSConnectionFailureBlock failureAction;
@property (nonatomic, retain) KCSConnectionProgressBlock progressAction;
@property (nonatomic, copy) NSMutableDictionary *headers;
@property (nonatomic) NSInteger method;
@property (nonatomic) BOOL isSyncRequest;

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
