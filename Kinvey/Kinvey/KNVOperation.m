//
//  KNVOperation.m
//  Kinvey
//
//  Created by Victor Barros on 2016-02-23.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KNVOperation.h"
#import <Kinvey/Kinvey-Swift.h>
@import ObjectiveC;

@implementation KNVOperation

-(instancetype)initWithCache:(id<KNVCache>)cache
                      client:(KNVClient *)client
                       clazz:(Class)clazz
{
    self = [super init];
    if (self) {
        self.cache = cache;
        self.client = client;
        self.clazz = clazz;
    }
    return self;
}

-(NSArray<NSObject<KNVPersistable>*>*)fromJsonArray:(NSArray<NSDictionary<NSString *,id>*>*)jsonArray
{
    NSMutableArray<NSObject<KNVPersistable>*>* results = [NSMutableArray arrayWithCapacity:jsonArray.count];
    for (NSDictionary<NSString *,id>* json in jsonArray) {
        [results addObject:[self fromJson:json]];
    }
    return results;
}

-(NSObject<KNVPersistable>*)fromJson:(NSDictionary<NSString *,id> *)json
{
    NSObject<KNVPersistable> *obj = [[self.clazz alloc] init];
    NSDictionary<NSString *, NSString *>* (*msgSend)(id, SEL) = (void *)objc_msgSend;
    NSDictionary<NSString *, NSString *> *propertyMapping = msgSend(self.clazz, @selector(kinveyPropertyMapping));
    [propertyMapping enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key0, NSString * _Nonnull key1, BOOL * _Nonnull stop) {
        id value = json[key0];
        if (value == [NSNull null]) {
            value = nil;
        }
        [obj setValue:value forKey:key1];
    }];
    return obj;
}

@end
