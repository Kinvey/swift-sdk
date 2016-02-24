//
//  KNVOperation.h
//  Kinvey
//
//  Created by Victor Barros on 2016-02-23.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KNVClient;
@protocol KNVCache;
@protocol KNVPersistable;

@interface KNVOperation<T : NSObject<KNVPersistable>*> : NSObject

@property (nonatomic, strong) KNVClient* _Nonnull client;
@property (nonatomic, strong) id<KNVCache> _Nonnull cache;
@property (nonatomic, strong) Class _Nonnull clazz;

-(instancetype _Nonnull)initWithCache:(id<KNVCache> _Nonnull)cache
                               client:(KNVClient* _Nonnull)client
                                clazz:(Class _Nonnull)clazz;

-(NSArray<T>* _Nonnull)fromJsonArray:(NSArray<NSDictionary<NSString *,id>*>* _Nonnull)jsonArray;

-(T _Nonnull)fromJson:(NSDictionary<NSString*, id>* _Nonnull)json;

@end
