//
//  KCSRequest.h
//  KinveyKit
//
//  Created by Michael Katz on 5/23/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
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

#import <Foundation/Foundation.h>

typedef enum KCSContextRoot : NSInteger {
    kKCSContextAPPDATA,
    kKCSContextUSER,
    kKCSContextBLOB,
    kKCSContextRPC
} KCSConextRoot;

typedef enum KCSRESTMethod : NSInteger {
    kKCSRESTMethodGET,
    kKCSRESTMethodPUT,
    kKCSRESTMethodPOST,
    kKCSRESTMethodDELETE
} KCSRESTMethod2;

@protocol KCSRequest <NSObject>

@end

@protocol KCSCredentials <NSObject>

- (NSString*) authString;

@end


@interface KCSNetworkRequest : NSObject <KCSRequest>

@property (nonatomic) KCSConextRoot contextRoot;
@property (nonatomic) KCSRESTMethod2 httpMethod;
@property (nonatomic, copy) NSArray* pathComponents;
@property (nonatomic, copy) NSString* queryString;
@property (nonatomic, retain, readonly) NSMutableDictionary* headers;
@property (nonatomic, copy) id body;
@property (nonatomic, weak) id<KCSCredentials> authorization;

- (void) run:(void (^)(id results, NSError* error))runBlock;
- (NSURLRequest*) nsurlRequest;

@end

@interface KCSCacheRequest : NSObject <KCSRequest>

@end
