//
//  KNVDataStore.h
//  Kinvey
//
//  Created by Victor Barros on 2016-03-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KNVReadPolicy.h"

@class KNVQuery;
@protocol KNVPersistable;

NS_SWIFT_UNAVAILABLE("Please use 'DataStoreType' enum")
typedef NS_ENUM(NSUInteger, KNVDataStoreType) {
    KNVDataStoreTypeSync,
    KNVDataStoreTypeCache,
    KNVDataStoreTypeNetwork
};

#define KNVDataStoreNSUIntegerHandler void(^ _Nullable)(NSUInteger, NSError* _Nullable)
#define KNVDataStoreHandler(T) void(^ _Nullable)(T _Nullable, NSError* _Nullable)

NS_SWIFT_UNAVAILABLE("Please use 'DataStore' class")
@interface KNVDataStore<T: NSObject<KNVPersistable>*> : NSObject

+(instancetype _Nonnull)getInstance:(KNVDataStoreType)type
                           forClass:(Class _Nonnull)cls;

-(id<KNVRequest> _Nonnull)remove:(T _Nonnull)username
               completionHandler:(KNVDataStoreNSUIntegerHandler)completionHandler;

-(id<KNVRequest> _Nonnull)save:(T _Nonnull)persistable
             completionHandler:(KNVDataStoreHandler(T))completionHandler;

-(id<KNVRequest> _Nonnull)find:(KNVDataStoreHandler(NSArray<T>*))completionHandler;

-(id<KNVRequest> _Nonnull)find:(KNVQuery* _Nullable)query
             completionHandler:(KNVDataStoreHandler(NSArray<T>*))completionHandler;

-(id<KNVRequest> _Nonnull)find:(KNVQuery* _Nullable)query
                    readPolicy:(KNVReadPolicy)readPolicy
             completionHandler:(KNVDataStoreHandler(NSArray<T>*))completionHandler;

@end
