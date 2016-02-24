//
//  KNVReadOperation.m
//  Kinvey
//
//  Created by Victor Barros on 2016-02-23.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KNVReadOperation.h"
#import "KNVMultiRequest.h"

@implementation KNVReadOperation

-(id<KNVRequest>)execute:(void (^)(id _Nullable, NSError * _Nullable))completionHandler
{
    switch (self.readPolicy) {
        case KNVReadPolicyForceLocal:
            return [self executeLocal:completionHandler];
        case KNVReadPolicyForceNetwork:
            return [self executeNetwork:completionHandler];
        case KNVReadPolicyBoth: {
            KNVMultiRequest* requests = [[KNVMultiRequest alloc] init];
            [self executeLocal:^(id _Nullable obj, NSError * _Nullable error) {
                if (completionHandler) completionHandler(obj, error);
                [requests addRequest:[self executeNetwork:completionHandler]];
            }];
            return requests;
        }
    }
}

-(id<KNVRequest>)executeLocal:(void (^)(id _Nullable, NSError * _Nullable))completionHandler
{
    abort();
}

-(id<KNVRequest>)executeNetwork:(void (^)(id _Nullable, NSError * _Nullable))completionHandler
{
    abort();
}

@end
