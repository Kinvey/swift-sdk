//
//  KNVFindOperation.m
//  Kinvey
//
//  Created by Victor Barros on 2016-02-23.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KNVFindOperation.h"
#import "KNVLocalRequest.h"
#import <Kinvey/Kinvey-Swift.h>
@import ObjectiveC;

@interface KNVFindOperation ()

@property (nonatomic, strong) KNVQuery* query;

@end

@implementation KNVFindOperation

-(id<KNVRequest>)executeLocal:(void (^)(id _Nullable, NSError * _Nullable))completionHandler
{
    KNVLocalRequest* request = [KNVLocalRequest new];
    [request execute:^{
        NSArray<NSDictionary<NSString *, id> *> *jsonArray = [self.cache findEntityByQuery:self.query];
        NSArray<NSObject<KNVPersistable>*>* array = [self fromJsonArray:jsonArray];
        if (completionHandler) completionHandler(array, nil);
    }];
    return request;
}

-(id<KNVRequest>)executeNetwork:(void (^)(id _Nullable, NSError * _Nullable))completionHandler
{
//    [self.client network]
    return nil;
}

@end
