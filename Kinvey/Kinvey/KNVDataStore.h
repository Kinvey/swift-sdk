//
//  KNVDataStore.h
//  Kinvey
//
//  Created by Victor Barros on 2016-03-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KNVReadPolicy.h"
#import "KNVWritePolicy.h"

@class KNVQuery;
@protocol KNVPersistable;

NS_SWIFT_UNAVAILABLE("Please use 'DataStoreType' enum")
typedef NS_ENUM(NSUInteger, KNVDataStoreType) {
    KNVDataStoreTypeSync,
    KNVDataStoreTypeCache,
    KNVDataStoreTypeNetwork
};

#define KNVDataStoreHandler(T) void(^ _Nullable)(T, NSError* _Nullable)
#define KNVDataStoreHandler2(T1, T2) void(^ _Nullable)(T1, T2, NSError* _Nullable)

NS_SWIFT_UNAVAILABLE("Please use 'DataStore' class")
@interface KNVDataStore<T: NSObject<KNVPersistable>*> : NSObject

@property (nonatomic, assign) NSTimeInterval ttl;

+(instancetype _Nonnull)getInstance:(KNVDataStoreType)type
                           forClass:(Class _Nonnull)cls;

@end
