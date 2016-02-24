//
//  KNVGetOperation.m
//  Kinvey
//
//  Created by Victor Barros on 2016-02-23.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KNVGetOperation.h"
#import "KNVLocalRequest.h"
#import <Kinvey/Kinvey-Swift.h>

@interface KNVGetOperation ()

@property (nonatomic, strong) NSString* objectId;

@end

@implementation KNVGetOperation

-(id<KNVRequest>)executeLocal:(void (^)(id _Nullable, NSError * _Nullable))completionHandler
{
    KNVLocalRequest* request = [[KNVLocalRequest alloc] init];
    [request execute:^{
        NSDictionary<NSString *, id> *json = [self.cache findEntity:self.objectId];
        if (json) {
            if (completionHandler) completionHandler(nil, nil);
        } else {
            if (completionHandler) completionHandler(nil, nil);
        }
    }];
    return request;
}

@end
