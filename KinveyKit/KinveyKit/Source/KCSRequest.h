//
//  KCSRequest.h
//  KinveyKit
//
//  Created by Michael Katz on 5/23/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
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
} KCSRESTMethod;

@protocol KCSRequest <NSObject>

@end


@interface KCSNetworkRequest : NSObject <KCSRequest>

@property (nonatomic) KCSConextRoot contextRoot;
@property (nonatomic) KCSRESTMethod httpMethod;
@property (nonatomic, copy) NSString* queryString;
@property (nonatomic, retain, readonly) NSMutableDictionary* headers;

- (void) run:(void (^)(NSData* data, NSError* error))runBlock;
- (NSURLRequest*) nsurlRequest;

@end

@interface KCSCacheRequest : NSObject <KCSRequest>

@end
