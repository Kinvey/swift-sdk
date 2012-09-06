//
//  KCSGenericRESTRequest.h
//  KinveyKit
//
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KinveyBlocks.h"

typedef enum {
    kGetRESTMethod     = 0,
    kPutRESTMethod     = 1,
    kPostRESTMethod    = 2,
    kDeleteRESTMethod  = 3
} KCSRESTMethod;

//TODO: Switch to static...
#define KCS_JSON_TYPE @"application/json; charset=utf-8"
#define KCS_DATA_TYPE @"application/octet-stream"

//TODO: make KinveyBlocks, KCSConnectionResponse, private and wrap reqfor resource

@interface KCSGenericRESTRequest : NSObject

@property (nonatomic, copy) NSString *resourceLocation;
@property (nonatomic, copy) NSMutableDictionary *headers;
@property (nonatomic) NSInteger method;
@property (nonatomic) BOOL isSyncRequest;
@property (nonatomic) BOOL followRedirects;

- (id)initWithResource:(NSString *)resource usingMethod: (NSInteger)requestMethod;

+ (KCSGenericRESTRequest *)requestForResource: (NSString *)resource usingMethod: (NSInteger)requestMethod withCompletionAction: (KCSConnectionCompletionBlock)complete failureAction:(KCSConnectionFailureBlock)failure progressAction: (KCSConnectionProgressBlock)progress;

- (void)start;
@end
