//
//  KCSObjectCache.m
//  KinveyKit
//
//  Created by Michael Katz on 10/28/13.
//  Copyright (c) 2013-2014 Kinvey. All rights reserved.
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
#import "KinveyUserService.h"

#import "KCSEntityPersistence.h"
#import "KCSOfflineUpdate.h"

#import "NSDate+ISO8601.h"

KK2(cleanup)
#import "KCSHiddenMethods.h"
#import "KCSQuery2+KCSInternal.h"

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


NSString* kinveyObjectMdProperty(id<KCSPersistable>obj)
{
    NSDictionary *kinveyMapping = [obj hostToKinveyPropertyMapping];
    for (NSString *key in kinveyMapping){
        NSString *jsonName = [kinveyMapping valueForKey:key];
        if ([jsonName isEqualToString:KCSEntityKeyMetadata]){
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

NSDate* kinveyObjectLmt(NSObject<KCSPersistable>* obj)
{
    NSString* objKey = kinveyObjectMdProperty(obj);
    KCSMetadata* kmd = ifNotNil(objKey, [obj valueForKey:objKey]);
    if (kmd){
        return kmd.lastModifiedTime;
    }
    return 0;
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
@end

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

- (void)dealloc
{
    _queryCache.delegate = nil;

    [self clear];

    [_queryCache removeAllObjects];
    _queryCache = nil;
    _caches = nil;

    self.offline = nil;
}

- (void) setOfflineUpdateDelegate:(id<KCSOfflineUpdateDelegate>)offlineUpdateDelegate
{
    self.offlineUpdateEnabled = offlineUpdateDelegate != nil;
    self.offline.delegate = offlineUpdateDelegate;
}

- (NSCache*) cacheForRoute:(NSString*)route collection:(NSString*)collection
{
    @synchronized (self) {
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
}

#pragma mark - Fetch Query

- (NSArray*) objectForId:(NSString*)_id cache:(NSCache*)cache route:(NSString*)route collection:(NSString*)collection
{
    __block id obj = [cache objectForKey:_id];
    if (!obj) {
        __block NSDictionary* entity;
        entity = [_persistenceLayer entityForId:_id route:route collection:collection];
        obj = [_dataModel objectFromCollection:collection data:entity];
    }
    return obj;
}

#warning wwdc - 712
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
        if (obj) {
            [objs addObject:obj];
        }
    }
    return objs;
}

- (NSString*) queryKey:(KCSQuery2*)query route:(NSString*)route collection:(NSString*)collection
{
    NSString* queryKey = [query keyString];
    return [NSString stringWithFormat:@"%@_%@_%@", route, collection, queryKey];
}


- (NSArray*) computeDelta:(KCSQuery2*)query route:(NSString*)route collection:(NSString*)collection referenceObjs: (NSArray*) refObjs;
{
    NSString* queryKey = [query keyString];
    NSString* key = [self queryKey:query route:route collection:collection];
    __block NSArray* ids = [_queryCache objectForKey:key];
    if (!ids) {
        //not in the local cache, pull from the db
        ids = [_persistenceLayer idsForQuery:queryKey route:route collection:collection];
        if ([ids count] == 0 && [query isAllQuery]) {
            ids = [_persistenceLayer allIds:route collection:collection];
        }
    }
    NSMutableArray* cachedObjs = [NSMutableArray arrayWithArray:[self objectsForIds:ids route:route collection:collection]];
    NSMutableArray* delta = [NSMutableArray array];
    
    NSMutableArray* refIds = [NSMutableArray array];
    for (int i=0; i<refObjs.count; i++) {
        id refObj =[refObjs objectAtIndex:i];
        NSString* refId = refObj[@"id"];
        NSDate* refLmt = [NSDate dateFromISO8601EncodedString:refObj[@"lmt"]]; //get lmt
        for (int j=0; j<cachedObjs.count; j++){
            id cachedObj = [cachedObjs objectAtIndex:j];
            id cachedId = kinveyObjectId(cachedObj);
            if ([refId isEqual: cachedId]){
                NSDate* cachedLmt = kinveyObjectLmt(cachedObj);
                if (![refLmt isEqualToDate:cachedLmt]){
                    [delta addObject: refId];

                }
                [cachedObjs removeObjectAtIndex:j];
                break;
            }
        }
        [refIds addObject:refId];
    }
    if (cachedObjs.count > 0){ //objects in the cache that don't appear in the fresh data
        [self deleteObjects:cachedObjs route:route collection:collection];
    }
    [_queryCache setObject:refIds forKey:key];
    [_persistenceLayer setIds:refIds forQuery:queryKey route:route collection:collection];


    return delta;
}


- (NSArray*) pullQuery:(KCSQuery2*)query route:(NSString*)route collection:(NSString*)collection
{
    NSArray* retVal;
    NSString* queryKey = [query keyString];
    NSString* key = [self queryKey:query route:route collection:collection];
    __block NSArray* ids = [_queryCache objectForKey:key];
    BOOL shouldCacheFromPersistence = NO;
    if (!ids) {
        //not in the local cache, pull from the db
        ids = [_persistenceLayer idsForQuery:queryKey route:route collection:collection];
        if ([ids count] > 0) {
            shouldCacheFromPersistence = YES;
        } else if ([query isAllQuery]) {
            ids = [_persistenceLayer allIds:route collection:collection];
            if ([ids count] > 0) {
                shouldCacheFromPersistence = YES;
            }
        }

    }
    
    retVal = [self objectsForIds:ids route:route collection:collection];
    
    if (shouldCacheFromPersistence) {
        [self setObjects:retVal forQuery:query route:route collection:collection];
    }
    
    return retVal;
}

- (NSArray*) pullIds:(NSArray*)ids route:(NSString*)route collection:(NSString*)collection
{
    ids = [NSArray wrapIfNotArray:ids];
    return [self objectsForIds:ids route:route collection:collection];
}


#pragma mark - Set Query

- (void) addObjects:(NSArray*)objects route:(NSString*)route  collection:(NSString*)collection
{
    NSCache* clnCache = [self cacheForRoute:route collection:collection];

    [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSDictionary* entity = [self.dataModel jsonEntityForObject:obj route:route collection:collection];
        DBAssert(entity != nil, @"should have an entity");
        [self updateObject:obj entity:entity route:route collection:collection collectionCache:clnCache];
    }];
}

      - (NSArray*) setObjects:(NSArray*)objArray forQuery:(KCSQuery2*)query route:(NSString*)route collection:(NSString*)collection
{
    NSArray* retVal = nil;
    NSString* queryKey = [query keyString];
    NSString* key = [self queryKey:query route:route collection:collection];
    
    if ([objArray count] > 0) {
        NSString* keyPath = [objArray[0] kinveyObjectIdHostProperty];
        __block NSArray* ids = [objArray valueForKeyPath:keyPath];
        if (ids == nil || ids.count != objArray.count) {
            //something went sideways
            DBAssert(NO, @"Could not get an _id for all entities");
            KCSLogError(KCS_LOG_CONTEXT_DATA, @"Could not get an _id for all entities");
            return nil;
        }
        
        NSCache* clnCache = [self cacheForRoute:route collection:collection];
        NSMutableArray* objs = [NSMutableArray arrayWithCapacity:ids.count];
        for (id<KCSPersistable> obj in objArray) {
            NSDictionary* entity = [_dataModel jsonEntityForObject:obj route:route collection:collection];
            [self updateObject:obj entity:entity route:route collection:collection collectionCache:clnCache];
            [objs addObject:obj];
        }
        
        [_queryCache setObject:ids forKey:key];
        [_persistenceLayer setIds:ids forQuery:queryKey route:route collection:collection];
        retVal = objs;
    }
    
    if (self.offlineUpdateEnabled) {
        [_offline hadASucessfulConnection];
    }
    return retVal;
}

- (BOOL) removeQuery:(KCSQuery2*)query route:(NSString*)route collection:(NSString*)collection
{
    NSString* queryKey = [query keyString];
    NSString* key = [self queryKey:query route:route collection:collection];
    
    [_queryCache removeObjectForKey:key];
    
    if (self.preCalculatesResults) {
        //TODO: remove this query from the results calculations
    }

    __block BOOL removeSuccessful = NO;
    removeSuccessful = [_persistenceLayer removeQuery:queryKey route:route collection:collection];
    return removeSuccessful;
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
- (BOOL) updateObject:(id<KCSPersistable>)object entity:(NSDictionary*)entity route:(NSString*)route collection:(NSString*)collection collectionCache:(NSCache*)clnCache
{
    NSString* key = entity[KCSEntityKeyId];
    if (!key) {
        KCSLogError(KCS_LOG_CONTEXT_DATA, @"No id provided for entity: %@, collection: %@", entity, collection);
        return NO;
    }
    [clnCache setObject:object forKey:entity[KCSEntityKeyId]];
    __block BOOL updated = NO;
    updated = [_persistenceLayer updateWithEntity:entity route:route collection:collection];
    
    if (updated && _preCalculatesResults) {
        [self preCalculateQueries:entity route:route collection:collection];
    }
    return updated;
}

- (BOOL) updateObject:(id<KCSPersistable>)object route:(NSString*)route collection:(NSString*)collection
{
    if (object == nil) {
        return NO;
    }
    NSDictionary* entity = [self.dataModel jsonEntityForObject:object route:route collection:collection];
    NSCache* clnCache = [self cacheForRoute:route collection:collection];
    
    BOOL updated = [self updateObject:object entity:entity route:route collection:collection collectionCache:clnCache];
    
    if (self.offlineUpdateEnabled) {
        //had a good save
        [_offline hadASucessfulConnection];
    }
    return updated;
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
    
    __block NSString* newid = nil;
    __block NSDictionary* bEntity = entity;
    NSCache* clnCache = [self cacheForRoute:route collection:collection];
    
    if (self.offlineUpdateEnabled == YES) {
        newid = [_offline addObject:bEntity route:route collection:collection headers:headers method:method error:error];
        if (newid != nil) {
            KK2(clean this up)
            NSString* oldid = kinveyObjectId(object);
            if ([newid isEqualToString:oldid] == NO) {
                KCSLogDebug(KCS_LOG_CONTEXT_DATA, @"Offline cache save updating object id: %@", newid);
                bEntity = [entity dictionaryByAddingDictionary:@{KCSEntityKeyId : newid}];
                setKinveyObjectId(object, newid);
            }
        }
    }
    
    if (_updatesLocalWithUnconfirmedSaves == YES) {
        [self updateObject:object entity:bEntity route:route collection:collection collectionCache:clnCache];
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

- (void) deleteObjects:(NSArray*)ids route:(NSString*)route collection:(NSString*)collection
{
    [ids enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self deleteObject:obj route:route collection:collection];
    }];
}

- (void) deleteByQuery:(KCSQuery2*)query route:(NSString*)route collection:(NSString*)collection
{
    if (self.preCalculatesResults) {
        //TODO: this
    }
}

- (NSString*) addUnsavedDelete:(NSString*)objId route:(NSString*)route collection:(NSString*)collection method:(NSString*)method headers:(NSDictionary*)headers error:(NSError*)error
{
    DBAssert(objId, @"should have object id");
    
    __block BOOL added = NO;
    if (self.offlineUpdateEnabled == YES) {
        added = [self.offline removeObject:objId objKey:objId route:route collection:collection headers:headers method:method error:error];
    }
    
    if (_updatesLocalWithUnconfirmedSaves == YES) {
        [self deleteObject:objId route:route collection:collection];
    }
    
    return added ? objId : nil;
}

- (id) addUnsavedDeleteQuery:(KCSQuery2*)deleteQuery route:(NSString*)route collection:(NSString*)collection method:(NSString*)method headers:(NSDictionary*)headers error:(NSError*)error
{
    DBAssert(deleteQuery, @"should have query");
    
    __block BOOL added = NO;
    if (self.offlineUpdateEnabled == YES) {
        added = [self.offline removeObject:deleteQuery objKey:[deleteQuery escapedQueryString] route:route collection:collection headers:headers method:method error:error];
    }
    
    if (_updatesLocalWithUnconfirmedSaves == YES) {
        [self deleteByQuery:deleteQuery route:route collection:collection];
    }
    
    return added ? deleteQuery : nil;
}

#pragma mark - Cache Delegate
- (void)cache:(NSCache *)cache willEvictObject:(id)obj
{
    KCSLogDebug(KCS_LOG_CONTEXT_DATA, @"Cache evicting: %@", cache.name);
}

#pragma mark - management
- (void)clear
{
    @synchronized (self) {
        [_persistenceLayer clearCaches];
        for (NSMutableDictionary* routeCache in [_caches allValues]) {
            for (NSCache* collectionCache in [routeCache allValues]) {
                collectionCache.delegate = nil;
                [collectionCache removeAllObjects];
            }
            [routeCache removeAllObjects];
        }
        [_caches removeAllObjects];

        [_queryCache removeAllObjects];
    }
}

- (void)jsonImport:(NSArray*)entities route:(NSString*)route collection:(NSString*)collection
{
    //TODO: populate queries
    //TODO: populate cache
    [_persistenceLayer import:entities route:route collection:collection];
}

- (NSArray*)jsonExport:(NSString*)route collection:(NSString*)collection
{
    __block NSArray* export = @[];
    export = [_persistenceLayer export:route collection:collection];
    return export;
}

#pragma mark - metadata

- (void) cacheAppKey:(NSString*)appKey
{
    NSMutableDictionary* metadata = [NSMutableDictionary dictionaryWithDictionary:[_persistenceLayer clientMetadata]];
    metadata[@"appkey"] = appKey;
    [_persistenceLayer setClientMetadata:metadata];
}

- (NSString*) cachedAppKey
{
    __block NSString* appKey = nil;
    NSDictionary* metadata = [_persistenceLayer clientMetadata];
    appKey = metadata[@"appkey"];
    return appKey;
}

- (void) cacheActiveUser:(id<KCSUser2>)user
{
    KCSCollection* userCollection = [KCSCollection userCollection];
    BOOL updated = [self updateObject:user route:[userCollection route] collection:userCollection.collectionName];
    
    if (updated) {
        NSString* userId = user.userId;
        setIfNil(userId, @"");
        NSMutableDictionary* metadata = [NSMutableDictionary dictionaryWithDictionary:[_persistenceLayer clientMetadata]];
        metadata[@"activeUser"] = userId;
        [_persistenceLayer setClientMetadata:metadata];
    }
}

- (id<KCSUser2>) lastActiveUser
{
    __block NSString* lastActiveUserId = nil;
    NSDictionary* metadata = [_persistenceLayer clientMetadata];
    NSString* activeUserStr = metadata[@"activeUser"];
    if ([activeUserStr length] > 0) {
        lastActiveUserId = activeUserStr;
    }
    id<KCSUser2> user = nil;
    if (lastActiveUserId) {
        KCSCollection* userCollection = [KCSCollection userCollection];
        NSArray* users = [self pullIds:@[lastActiveUserId] route:[userCollection route] collection:userCollection.collectionName];
        if (users.count == 1) {
            user = users[0];
        }
    }
    return user;
}

@end
