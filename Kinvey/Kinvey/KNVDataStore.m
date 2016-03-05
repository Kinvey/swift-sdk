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

#define KNV_DISPATCH_ASYNC_MAIN_QUEUE(R, completionHandler) ^(R _Nullable obj, NSError * _Nullable error) { \
    if (!completionHandler) return; \
    dispatch_async(dispatch_get_main_queue(), ^{ \
        completionHandler(obj, error); \
    }); \
}

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
        self.cls = cls;
        self.client = client;
        self.cache = [client.client.cacheManager cache:[cls kinveyCollectionName]];
        self.sync = [client.client.syncManager sync:[cls kinveyCollectionName]];
    }
    return self;
}

-(id<KNVRequest>)save:(id<KNVPersistable>)persistable
    completionHandler:(KNVDataStoreHandler(id))completionHandler
{
    return [self save:persistable
         writePolicty:self.writePolicy
    completionHandler:completionHandler];
}

-(id<KNVRequest>)save:(id<KNVPersistable>)persistable
         writePolicty:(KNVWritePolicy)writePolicy
    completionHandler:(KNVDataStoreHandler(id))completionHandler
{
    __KNVSaveOperation* operation = [[__KNVSaveOperation alloc] initWithPersistable:persistable
                                                                        writePolicy:(enum WritePolicy)writePolicy
                                                                               sync:self.sync
                                                                              cache:self.cache
                                                                             client:self.client.client];
    id<KNVRequest> request = [operation execute:KNV_DISPATCH_ASYNC_MAIN_QUEUE(id, completionHandler)];
    return request;
}

-(id<KNVRequest>)find:(KNVDataStoreHandler(NSArray<id>*))completionHandler
{
    return [self find:nil
    completionHandler:completionHandler];
}

-(id<KNVRequest>)find:(KNVQuery *)query
    completionHandler:(KNVDataStoreHandler(NSArray<id>*))completionHandler
{
    return [self find:query
           readPolicy:self.readPolicy
    completionHandler:completionHandler];
}

-(id<KNVRequest>)find:(KNVQuery*)query
           readPolicy:(KNVReadPolicy)readPolicy
    completionHandler:(KNVDataStoreHandler(NSArray<id>*))completionHandler
{
    __KNVFindOperation *operation = [[__KNVFindOperation alloc] initWithQuery:query ? query : [KNVQuery new]
                                                                   readPolicy:(enum ReadPolicy)readPolicy
                                                             persistableClass:self.cls
                                                                        cache:self.cache
                                                                       client:self.client.client];
    id<KNVRequest> request = [operation execute:KNV_DISPATCH_ASYNC_MAIN_QUEUE(NSArray<id>*, completionHandler)];
    return request;
}

//public func find(query: Query = Query(), readPolicy: ReadPolicy? = nil, completionHandler: ArrayCompletionHandler?) -> Request {
//    let readPolicy = readPolicy ?? self.readPolicy
//    let operation = FindOperation(query: Query(query: query, persistableType: T.self), readPolicy: readPolicy, persistableType: T.self, cache: cache, client: client)
//    let request = operation.execute(dispatchAsyncMainQueue(completionHandler))
//    return request
//}

@end
