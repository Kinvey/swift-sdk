//
//  KCSObjectCache.m
//  KinveyKit
//
//  Created by Michael Katz on 10/28/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, understand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
//


#import "KCSObjectCache.h"

#import "KinveyCoreInternal.h"
#import "KinveyDataStoreInternal.h"

//TODO: util this?
NSString* kinveyObjectIdHostProperty(id<KCSPersistable>obj)
{
    NSDictionary *kinveyMapping = [obj hostToKinveyPropertyMapping];
    for (NSString *key in kinveyMapping){
        NSString *jsonName = [kinveyMapping valueForKey:key];
        if ([jsonName isEqualToString:KCSEntityKeyId]){
            return key;
        }
    }
    return nil;
}

NSString* kinveyObjectId(NSObject<KCSPersistable>* obj)
{
    NSString* objKey = kinveyObjectIdHostProperty(obj);
    return ifNotNil(objKey, [obj valueForKey:objKey]);
}

void setKinveyObjectId(NSObject<KCSPersistable>* obj, NSString* objId)
{
    NSString* objKey = kinveyObjectIdHostProperty(obj);
    if (objKey == nil) {
        NSString* exp = [NSString stringWithFormat:@"Cannot set the 'id', the entity of class '%@' does not map KCSEntityKeyId in -hostToKinveyPropertyMapping.", [obj class]];
        @throw [NSException exceptionWithName:@"KCSEntityNoId" reason:exp userInfo:@{@"object" : obj}];
    } else {
        [obj setValue:objId forKey:objKey];
    }
}


@interface KCSObjectCache () <NSCacheDelegate>
@property (nonatomic, strong) KCSEntityPersistence* persistenceLayer;
@property (nonatomic, strong) KCSOfflineUpdate* offline;
@property (nonatomic, strong) NSMutableDictionary* caches;
@property (nonatomic, strong) NSCache* queryCache;
@property (nonatomic, strong) KCSDataModel* dataModel;
@end

#warning SYNCHRONIZATION

@implementation KCSObjectCache

- (id)init
{
    self = [super init];
    if (self) {
        _persistenceLayer = [[KCSEntityPersistence alloc] initWithPersistenceId:@"offline"];
        _offline = [[KCSOfflineUpdate alloc] initWithCache:self peristenceLayer:_persistenceLayer]; //normally sending self is a bad idea, this constructor doesn't use these values -- but there is high coupling
        _caches = [NSMutableDictionary dictionaryWithCapacity:3];
        _caches[KCSRESTRouteAppdata] = [NSMutableDictionary dictionaryWithCapacity:5];
        _caches[KCSRESTRouteUser] = [NSMutableDictionary dictionaryWithCapacity:1];
        _caches[KCSRESTRouteBlob] = [NSMutableDictionary dictionaryWithCapacity:1];
        _queryCache = [[NSCache alloc] init];
        _queryCache.delegate = self;
        _queryCache.name = @"General Query Cache";
        
        _dataModel = [[KCSDataModel alloc] init];

        _preCalculatesResults = YES;
        _updatesLocalWithUnconfirmedSaves = YES;
    }
    return self;
}

- (void) setOfflineUpdateDelegate:(id<KCSOfflineUpdateDelegate>)offlineUpdateDelegate
{
    self.offlineUpdateEnabled = offlineUpdateDelegate != nil;
    self.offline.delegate = offlineUpdateDelegate;
}

- (NSCache*) cacheForRoute:(NSString*)route collection:(NSString*)collection
{
    NSMutableDictionary* routeCaches = _caches[route];
    if (!routeCaches) {
        routeCaches = [NSMutableDictionary dictionary];
        _caches[route] = routeCaches;
    }
    NSCache* cache = routeCaches[collection];
    if (!cache) {
        cache = [[NSCache alloc] init];
        cache.name = [NSString stringWithFormat:@"%@/%@", route, collection];
        cache.delegate = self;
        routeCaches[collection] = cache;
    }
    return cache;
}

#pragma mark - Fetch Query

- (NSArray*) objectForId:(NSString*)_id cache:(NSCache*)cache route:(NSString*)route collection:(NSString*)collection
{
    id obj = [cache objectForKey:_id];
    if (!obj) {
        NSDictionary* entity = [_persistenceLayer entityForId:_id route:route collection:collection];
        obj = [_dataModel objectFromCollection:collection data:entity];
    }
    return obj;
}

- (NSArray*) objectsForIds:(NSArray*)ids route:(NSString*)route collection:(NSString*)collection
{
    if (ids == nil) {
        return nil;
    }
    if (ids.count == 0) {
        return @[];
    }
    
    NSMutableArray* objs = [NSMutableArray arrayWithCapacity:ids.count];
    NSCache* cache = [self cacheForRoute:route collection:collection];
    for (NSString* _id in ids) {
        id obj = [self objectForId:_id cache:cache route:route collection:collection];
        if (!obj) {
            obj = [NSNull null];
        }
        [objs addObject:obj];
    }
    return objs;
}

- (NSString*) queryKey:(KCSQuery2*)query route:(NSString*)route collection:(NSString*)collection
{
    NSString* queryKey = [query keyString];
    return [NSString stringWithFormat:@"%@_%@_%@", route, collection, queryKey];
}


- (NSArray*) pullQuery:(KCSQuery2*)query route:(NSString*)route collection:(NSString*)collection
{
    NSString* queryKey = [query keyString];
    NSString* key = [self queryKey:query route:route collection:collection];
    NSArray* ids = [_queryCache objectForKey:key];
    if (!ids) {
       ids = [_persistenceLayer idsForQuery:queryKey route:route collection:collection];
    }
    
    return [self objectsForIds:ids route:route collection:collection];
}


#pragma mark - Set Query
//TODO: setEntities? 
- (NSArray*) setObjects:(NSArray*)jsonArray forQuery:(KCSQuery2*)query route:(NSString*)route collection:(NSString*)collection
{
    NSString* queryKey = [query keyString];
    NSString* key = [self queryKey:query route:route collection:collection];
    
    NSArray* ids = [jsonArray valueForKeyPath:KCSEntityKeyId];
    if (ids == nil || ids.count != jsonArray.count) {
        //something went sideways
        DBAssert(NO, @"Could not get an _id for all entities");
        KCSLogError(KCS_LOG_CONTEXT_DATA, @"Could not get an _id for all entities");
        return nil;
    }

    NSCache* clnCache = [self cacheForRoute:route collection:collection];
    NSMutableArray* objs = [NSMutableArray arrayWithCapacity:ids.count];
    for (NSDictionary* entity in jsonArray) {
        id<KCSPersistable> obj = [_dataModel objectFromCollection:collection data:entity];
        [self updateObject:obj entity:entity route:route collection:collection collectionCache:clnCache];
        [objs addObject:obj];
    }
    
    [_queryCache setObject:ids forKey:key];
    [_persistenceLayer setIds:ids forQuery:queryKey route:route collection:collection];
    
    if (self.offlineUpdateEnabled) {
        [_offline hadASucessfulConnection];
    }
    
    return objs;
}

- (void) preCalculateQueries:(NSDictionary*)entity route:(NSString*)route collection:(NSString*)collection
{
    //TODO:
    //TODO also: check pre-calc on on local query or pull
}

- (void) preCalculateQueriesByRemoving:(NSString*)objId route:(NSString*)route collection:(NSString*)collection
{
    //TODO:
}

#pragma mark - Saving
- (void) updateObject:(id<KCSPersistable>)object entity:(NSDictionary*)entity route:(NSString*)route collection:(NSString*)collection collectionCache:(NSCache*)clnCache
{
    [clnCache setObject:object forKey:entity[KCSEntityKeyId]];
    [_persistenceLayer updateWithEntity:entity route:route collection:collection];
    
    if (_preCalculatesResults == YES) {
        [self preCalculateQueries:entity route:route collection:collection];
    }

}

- (void) updateObject:(id<KCSPersistable>)object route:(NSString*)route collection:(NSString*)collection
{
    NSDictionary* entity = [self.dataModel jsonEntityForObject:object route:route collection:collection];
    NSCache* clnCache = [self cacheForRoute:route collection:collection];

    [self updateObject:object entity:entity route:route collection:collection collectionCache:clnCache];
    
    if (self.offlineUpdateEnabled) {
        //had a good save
        [_offline hadASucessfulConnection];
    }
}

- (void) updateCacheForObject:(NSString*)objId withEntity:(NSDictionary*)entity atRoute:(NSString*)route collection:(NSString*)collection
{
    //TODO: global update notification? for objects not in the cache but still in memory
    NSCache* clnCache = [self cacheForRoute:route collection:collection];
    id<KCSPersistable> object = [clnCache objectForKey:objId];
    if (!object) {
        object = [self.dataModel objectFromCollection:collection data:entity];
    } else {
        [self.dataModel updateObject:object withEntity:entity atRoute:route collection:collection];
    }
    
    [self updateObject:object entity:entity route:route collection:collection collectionCache:clnCache];
}

- (NSString*) addUnsavedObject:(id<KCSPersistable>)object entity:(NSDictionary*)entity route:(NSString*)route collection:(NSString*)collection method:(NSString*)method headers:(NSDictionary*)headers error:(NSError*)error
{
    DBAssert(object, @"should have object");
    DBAssert(entity, @"should have entity");
    
    NSCache* clnCache = [self cacheForRoute:route collection:collection];
    NSString* newid = nil;
    
    if (self.offlineUpdateEnabled == YES) {
        newid = [_offline addObject:entity route:route collection:collection headers:headers method:method error:error];
        if (newid != nil) {
            KK2(clean this up)
            NSString* oldid = kinveyObjectId(object);
            if ([newid isEqualToString:oldid] == NO) {
                KCSLogDebug(KCS_LOG_CONTEXT_DATA, @"Offline cache save updating object id: %@", newid);
                entity = [entity dictionaryByAddingDictionary:@{KCSEntityKeyId : newid}];
                setKinveyObjectId(object, newid);
            }
        }
    }
    
    if (_updatesLocalWithUnconfirmedSaves == YES) {
        [self updateObject:object entity:entity route:route collection:collection collectionCache:clnCache];
    }
    
    return newid;
}

#pragma mark - deleting

- (void) deleteObject:(NSString*)objId route:(NSString*)route collection:(NSString*)collection
{
    NSCache* clnCache = [self cacheForRoute:route collection:collection];
    [clnCache removeObjectForKey:objId];
    [self.persistenceLayer removeEntity:objId route:route collection:collection];
    
    if (_preCalculatesResults == YES) {
        [self preCalculateQueriesByRemoving:objId route:route collection:collection];
    }
    
    if (self.offlineUpdateEnabled) {
        //had a good save
        [_offline hadASucessfulConnection];
    }

}

#pragma mark - Cache Delegate
- (void)cache:(NSCache *)cache willEvictObject:(id)obj
{
    KCSLogDebug(KCS_LOG_CONTEXT_DATA, @"Cache evicting: %@", cache.name);
}

#pragma mark - management
- (void)clear
{ //TODO: worry about synchronization
    [_persistenceLayer clearCaches];
    [_caches[KCSRESTRouteAppdata] removeAllObjects];
    [_caches[KCSRESTRouteUser] removeAllObjects];
    [_caches[KCSRESTRouteBlob] removeAllObjects];
    [_caches removeAllObjects];
    [_queryCache removeAllObjects];
}

@end
