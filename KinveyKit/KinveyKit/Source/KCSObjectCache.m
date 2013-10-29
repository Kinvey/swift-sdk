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

@interface KCSObjectCache () <NSCacheDelegate>
@property (nonatomic, strong) KCSEntityPersistence* persistenceLayer;
@property (nonatomic, strong) NSMutableDictionary* caches;
@property (nonatomic, strong) NSCache* queryCache;
@property (nonatomic, strong) KCSDataModel* dataModel;
@property (nonatomic) BOOL preCalculatesResults;
@end

@implementation KCSObjectCache

- (id)init
{
    self = [super init];
    if (self) {
        //TODO: fix this!
        _persistenceLayer = [[KCSEntityPersistence alloc] initWithPersistenceId:@"x"];
        _caches = [NSMutableDictionary dictionaryWithCapacity:3];
        _caches[KCSRESTRouteAppdata] = [NSMutableDictionary dictionaryWithCapacity:5];
        _caches[KCSRESTRouteUser] = [NSMutableDictionary dictionaryWithCapacity:1];
        _caches[KCSRESTRouteBlob] = [NSMutableDictionary dictionaryWithCapacity:1];
        _queryCache = [[NSCache alloc] init];
        _queryCache.delegate = self;
        _queryCache.name = @"General Query Cache";
        
        _dataModel = [[KCSDataModel alloc] init];
        _preCalculatesResults = YES;
    }
    return self;
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

- (NSString*) queryKey:(KCSQuery*)query route:(NSString*)route collection:(NSString*)collection
{
    NSString* queryKey = [query parameterStringRepresentation];
    return [NSString stringWithFormat:@"%@_%@_%@", route, collection, queryKey];
}


- (NSArray*) pullQuery:(KCSQuery*)query route:(NSString*)route collection:(NSString*)collection
{
    NSString* queryKey = [query parameterStringRepresentation];
    NSString* key = [self queryKey:query route:route collection:collection];
    NSArray* ids = [_queryCache objectForKey:key];
    if (!ids) {
       ids = [_persistenceLayer idsForQuery:queryKey route:route collection:collection];
    }
    
    return [self objectsForIds:ids route:route collection:collection];
}


#pragma mark - Set Query
//TODO: setEntities? 
- (NSArray*) setObjects:(NSArray*)jsonArray forQuery:(KCSQuery*)query route:(NSString*)route collection:(NSString*)collection
{
    NSString* queryKey = [query parameterStringRepresentation];
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
        [clnCache setObject:obj forKey:entity[KCSEntityKeyId]];
        [objs addObject:obj];
        [_persistenceLayer updateWithEntity:entity route:route collection:collection];
    }
    
    [_queryCache setObject:ids forKey:key];
    [_persistenceLayer setIds:ids forQuery:queryKey route:route collection:collection];
    
    if (_preCalculatesResults == YES) {
        [self preCalculateQueries:jsonArray route:route collection:collection];
    }
    
    return objs;
}

- (void) preCalculateQueries:(NSArray*)entities route:(NSString*)route collection:(NSString*)collection
{
    //TODO:
    //TODO also: check pre-calc on on local query or pull
}


#pragma mark - Cache Delegate
- (void)cache:(NSCache *)cache willEvictObject:(id)obj
{
    KCSLogDebug(KCS_LOG_CONTEXT_DATA, @"Cache evicting: %@", cache.name);
}

@end
