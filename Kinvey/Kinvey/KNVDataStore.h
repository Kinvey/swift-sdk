//
//  KNVDataStore.h
//  Kinvey
//
//  Created by Victor Barros on 2016-02-22.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KNVPersistable;

typedef NS_ENUM(NSUInteger, KNVDataStoreType) {
    KNVDataStoreTypeSync = 0,
    KNVDataStoreTypeCache = 1,
    KNVDataStoreTypeNetwork = 2,
};

@interface KNVDataStore<T> : NSObject

typedef void(^CompletionHandler)(T __nullable, NSError* __nullable);

@property (nonatomic, readonly) KNVDataStoreType type;

-(instancetype __nonnull)initWithType:(KNVDataStoreType)type
                             forClass:(Class __nonnull)clazz;

-(void)find:(CompletionHandler __nullable)completionHandler;

@end
