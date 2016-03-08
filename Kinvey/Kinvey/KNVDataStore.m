//
//  KNVDataStore.m
//  Kinvey
//
//  Created by Victor Barros on 2016-03-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KNVDataStore.h"
#import "KNVClient+Internal.h"

@interface KNVDataStore ()

@property KNVDataStoreType type;
@property KNVClient* client;
@property Class<KNVPersistable> cls;

@property id<__KNVSync>sync;
@property id<__KNVCache>cache;

@property KNVWritePolicy writePolicy;
@property KNVReadPolicy readPolicy;

@end

#define KNV_PERSISTABLE NSObject<KNVPersistable>*

#define KNV_DISPATCH_ASYNC_MAIN_QUEUE(R, completionHandler) \
^(R obj, NSError * _Nullable error) { \
    if (!completionHandler) return; \
    dispatch_async(dispatch_get_main_queue(), ^{ \
        completionHandler(obj, error); \
    }); \
}

#define KNV_DISPATCH_ASYNC_MAIN_QUEUE_2(R1, R2, completionHandler) \
^(R1 obj1, R2 obj2, NSError * _Nullable error) { \
    if (!completionHandler) return; \
    dispatch_async(dispatch_get_main_queue(), ^{ \
        completionHandler(obj1, obj2, error); \
    }); \
}

#define KNV_CHECK_DATA_STORE_TYPE(T, R) \
if (self.type != KNVDataStoreTypeSync) { \
    KNV_DISPATCH_ASYNC_MAIN_QUEUE(T, completionHandler)(R, [__KNVError InvalidStoreType]); \
    return [__KNVLocalRequest new]; \
}

#define KNV_CHECK_DATA_STORE_TYPE_2(T1, R1, T2, R2) \
if (self.type != KNVDataStoreTypeSync) { \
    KNV_DISPATCH_ASYNC_MAIN_QUEUE_2(T1, T2, completionHandler)(R1, R2, [__KNVError InvalidStoreType]); \
    return [__KNVLocalRequest new]; \
}

#define KNV_QUERY(query) [__KNVQuery query:query ? query : [KNVQuery new] persistableType:self.cls]

@implementation KNVDataStore

+(instancetype)getInstance:(KNVDataStoreType)type
                  forClass:(Class<KNVPersistable>)cls
{
    return [[KNVDataStore alloc] initWithType:type
                                     forClass:cls
                                       client:[KNVClient sharedClient]];
}

+(instancetype)getInstance:(KNVDataStoreType)type
                  forClass:(Class<KNVPersistable>)cls
                    client:(KNVClient*)client
{
    return [[KNVDataStore alloc] initWithType:type
                                     forClass:cls
                                       client:client];
}

-(instancetype)init
{
    NSString* reason = @"Please use the 'getInstance' class method";
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:reason
                                 userInfo:@{NSLocalizedDescriptionKey : reason,
                                            NSLocalizedFailureReasonErrorKey : reason}];
}

-(instancetype)initWithType:(KNVDataStoreType)type
                   forClass:(Class<KNVPersistable>)cls
                     client:(KNVClient*)client
{
    self = [super init];
    if (self) {
        self.type = type;
        switch (type) {
            case KNVDataStoreTypeCache:
                self.readPolicy = KNVReadPolicyBoth;
                self.writePolicy = KNVWritePolicyLocalThenNetwork;
                break;
            case KNVDataStoreTypeNetwork:
                self.readPolicy = KNVReadPolicyForceNetwork;
                self.writePolicy = KNVWritePolicyForceNetwork;
                break;
            case KNVDataStoreTypeSync:
                self.readPolicy = KNVReadPolicyForceLocal;
                self.writePolicy = KNVWritePolicyForceLocal;
                break;
        }
        self.cls = cls;
        self.client = client;
        self.cache = [client.client.cacheManager cache:[cls kinveyCollectionName]];
        self.sync = [client.client.syncManager sync:[cls kinveyCollectionName]];
    }
    return self;
}

-(id<KNVRequest>)save:(KNV_PERSISTABLE)persistable
    completionHandler:(KNVDataStoreHandler(KNV_PERSISTABLE))completionHandler
{
    return [self save:persistable
         writePolicty:self.writePolicy
    completionHandler:completionHandler];
}

-(id<KNVRequest>)save:(id<KNVPersistable>)persistable
         writePolicty:(KNVWritePolicy)writePolicy
    completionHandler:(KNVDataStoreHandler(KNV_PERSISTABLE))completionHandler
{
    __KNVSaveOperation* operation = [[__KNVSaveOperation alloc] initWithPersistable:persistable
                                                                        writePolicy:(enum WritePolicy)writePolicy
                                                                               sync:self.sync
                                                                              cache:self.cache
                                                                             client:self.client.client];
    id<KNVRequest> request = [operation execute:KNV_DISPATCH_ASYNC_MAIN_QUEUE(KNV_PERSISTABLE _Nullable, completionHandler)];
    return request;
}

-(id<KNVRequest>)findById:(NSString*)objectId
        completionHandler:(KNVDataStoreHandler(KNV_PERSISTABLE))completionHandler
{
    return [self findById:objectId
               readPolicy:self.readPolicy
        completionHandler:completionHandler];
}

-(id<KNVRequest>)findById:(NSString*)objectId
               readPolicy:(KNVReadPolicy)readPolicy
        completionHandler:(KNVDataStoreHandler(KNV_PERSISTABLE))completionHandler
{
    assert(objectId);
    __KNVGetOperation *operation = [[__KNVGetOperation alloc] initWithId:objectId
                                                              readPolicy:(enum ReadPolicy)readPolicy
                                                        persistableClass:self.cls
                                                                   cache:self.cache
                                                                  client:self.client.client];
    id<KNVRequest> request = [operation execute:KNV_DISPATCH_ASYNC_MAIN_QUEUE(KNV_PERSISTABLE, completionHandler)];
    return request;
}

-(id<KNVRequest>)find:(KNVDataStoreHandler(NSArray<KNV_PERSISTABLE>*))completionHandler
{
    return [self find:nil
    completionHandler:completionHandler];
}

-(id<KNVRequest>)find:(KNVQuery *)query
    completionHandler:(KNVDataStoreHandler(NSArray<KNV_PERSISTABLE>*))completionHandler
{
    return [self find:query
           readPolicy:self.readPolicy
    completionHandler:completionHandler];
}

-(id<KNVRequest>)find:(KNVQuery*)query
           readPolicy:(KNVReadPolicy)readPolicy
    completionHandler:(KNVDataStoreHandler(NSArray<KNV_PERSISTABLE>*))completionHandler
{
    __KNVFindOperation *operation = [[__KNVFindOperation alloc] initWithQuery:KNV_QUERY(query)
                                                                   readPolicy:(enum ReadPolicy)readPolicy
                                                             persistableClass:self.cls
                                                                        cache:self.cache
                                                                       client:self.client.client];
    id<KNVRequest> request = [operation execute:KNV_DISPATCH_ASYNC_MAIN_QUEUE(NSArray<KNV_PERSISTABLE>*, completionHandler)];
    return request;
}

-(id<KNVRequest>)remove:(KNV_PERSISTABLE)persistable
      completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler
{
    return [self remove:persistable
            writePolicy:self.writePolicy
      completionHandler:completionHandler];
}

-(id<KNVRequest>)remove:(KNV_PERSISTABLE)persistable
            writePolicy:(KNVWritePolicy)writePolicy
      completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler
{
    NSString* objectId = [__KNVPersistable kinveyObjectId:persistable];
    if (!objectId) {
        @throw [__KNVError ObjectIdMissing];
    }
    return [self removeById:objectId
                writePolicy:writePolicy
          completionHandler:completionHandler];
}

-(id<KNVRequest>)removeById:(NSString*)objectId
          completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler
{
    KNVQuery* query = [[KNVQuery alloc] initWithFormat:[NSString stringWithFormat:@"%@ == %%@", [__KNVPersistable idKey:self.cls]]
                                         argumentArray:@[objectId]];
    return [self removeWithQuery:query
               completionHandler:completionHandler];
}

-(id<KNVRequest>)removeById:(NSString*)objectId
                writePolicy:(KNVWritePolicy)writePolicy
          completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler
{
    KNVQuery* query = [[KNVQuery alloc] initWithFormat:[NSString stringWithFormat:@"%@ == %%@", [__KNVPersistable idKey:self.cls]]
                                         argumentArray:@[objectId]];
    return [self removeWithQuery:query
                     writePolicy:writePolicy
               completionHandler:completionHandler];
}

-(id<KNVRequest>)removeByIds:(NSArray<NSString*>*)ids
           completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler
{
    KNVQuery* query = [[KNVQuery alloc] initWithFormat:[NSString stringWithFormat:@"%@ IN %%@", [__KNVPersistable idKey:self.cls]]
                                         argumentArray:@[ids]];
    return [self removeWithQuery:query
               completionHandler:completionHandler];
}

-(id<KNVRequest>)removeByIds:(NSArray<NSString*>*)ids
                 writePolicy:(KNVWritePolicy)writePolicy
           completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler
{
    KNVQuery* query = [[KNVQuery alloc] initWithFormat:[NSString stringWithFormat:@"%@ IN %%@", [__KNVPersistable idKey:self.cls]]
                                         argumentArray:@[ids]];
    return [self removeWithQuery:query
                     writePolicy:writePolicy
               completionHandler:completionHandler];
}

-(id<KNVRequest>)removeAll:(KNVDataStoreHandler(NSUInteger))completionHandler
{
    return [self removeWithQuery:nil
               completionHandler:completionHandler];
}

-(id<KNVRequest>)removeAllWithWritePolicy:(KNVWritePolicy)writePolicy
                        completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler
{
    return [self removeWithQuery:nil
                     writePolicy:writePolicy
               completionHandler:completionHandler];
}

-(id<KNVRequest>)removeWithQuery:(KNVQuery*)query
               completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler
{
    return [self removeWithQuery:query
                     writePolicy:self.writePolicy
               completionHandler:completionHandler];
}

-(id<KNVRequest>)removeWithQuery:(KNVQuery*)query
                     writePolicy:(KNVWritePolicy)writePolicy
               completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler
{
    __KNVRemoveOperation *operation = [[__KNVRemoveOperation alloc] initWithQuery:KNV_QUERY(query)
                                                                       writePolicy:(enum WritePolicy)writePolicy
                                                                              sync:self.sync
                                                                   persistableType:self.cls
                                                                             cache:self.cache
                                                                            client:self.client.client];
    id<KNVRequest> request = [operation executeUInt:KNV_DISPATCH_ASYNC_MAIN_QUEUE(NSUInteger, completionHandler)];
    return request;
}

-(id<KNVRequest>)push:(KNVDataStoreHandler(NSUInteger))completionHandler
{
    KNV_CHECK_DATA_STORE_TYPE(NSUInteger, 0)
    
    __KNVPushOperation *operation = [[__KNVPushOperation alloc] initWithSync:self.sync
                                                             persistableType:self.cls
                                                                       cache:self.cache
                                                                      client:self.client.client];
    id<KNVRequest> request = [operation executeUInt:KNV_DISPATCH_ASYNC_MAIN_QUEUE(NSUInteger, completionHandler)];
    return request;
}

-(id<KNVRequest>)pull:(KNVDataStoreHandler(NSArray<KNV_PERSISTABLE>* _Nullable))completionHandler
{
    return [self pullWithQuery:nil
             completionHandler:completionHandler];
}

-(id<KNVRequest>)pullWithQuery:(KNVQuery*)query
             completionHandler:(KNVDataStoreHandler(NSArray<KNV_PERSISTABLE>*))completionHandler
{
    KNV_CHECK_DATA_STORE_TYPE(NSArray<KNV_PERSISTABLE>*, nil)
    
    __KNVPullOperation *operation = [[__KNVPullOperation alloc] initWithQuery:KNV_QUERY(query)
                                                                         sync:self.sync
                                                              persistableType:self.cls
                                                                        cache:self.cache
                                                                       client:self.client.client];
    id<KNVRequest> request = [operation execute:KNV_DISPATCH_ASYNC_MAIN_QUEUE(NSArray<KNV_PERSISTABLE>* _Nullable, completionHandler)];
    return request;
}

-(id<KNVRequest>)purge:(KNVDataStoreHandler(NSUInteger))completionHandler
{
    return [self purgeWithQuery:nil
              completionHandler:completionHandler];
}

-(id<KNVRequest>)purgeWithQuery:(KNVQuery*)query
              completionHandler:(KNVDataStoreHandler(NSUInteger))completionHandler
{
    KNV_CHECK_DATA_STORE_TYPE(NSUInteger, 0)
    
    __KNVPurgeOperation *operation = [[__KNVPurgeOperation alloc] initWithSync:self.sync
                                                               persistableType:self.cls
                                                                         cache:self.cache
                                                                        client:self.client.client];
    id<KNVRequest> request = [operation executeUInt:^(NSUInteger count, NSError * _Nullable error) {
        if (!error) {
            [self pullWithQuery:KNV_QUERY(query)
              completionHandler:^(NSArray * _Nullable array, NSError * _Nullable error) {
                if (completionHandler) completionHandler(count, error);
            }];
        } else {
            if (completionHandler) completionHandler(count, error);
        }
    }];
    return request;
}

-(id<KNVRequest>)sync:(KNVDataStoreHandler2(NSUInteger, NSArray<KNV_PERSISTABLE>*))completionHandler
{
    return [self syncWithQuery:nil
             completionHandler:completionHandler];
}

-(id<KNVRequest>)syncWithQuery:(KNVQuery*)query
             completionHandler:(KNVDataStoreHandler2(NSUInteger, NSArray<KNV_PERSISTABLE>*))completionHandler
{
    KNV_CHECK_DATA_STORE_TYPE_2(NSUInteger, 0, NSArray<KNV_PERSISTABLE>*, nil)
    
    __KNVMultiRequest *requests = [__KNVMultiRequest new];
    id<KNVRequest> request = [self push:^(NSUInteger count, NSError * _Nullable error) {
        if (!error) {
            id<KNVRequest> request = [self pullWithQuery:query
                                       completionHandler:^(NSArray * _Nullable results, NSError * _Nullable error)
            {
                if (completionHandler) completionHandler(count, results, error);
            }];
            [requests addRequest:(id<KNVRequest>)request];
        } else {
            if (completionHandler) completionHandler(count, nil, error);
        }
    }];
    [requests addRequest:(id<KNVRequest>)request];
    return requests;
}

@end
