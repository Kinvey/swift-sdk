//
//  KCSEntityCache.m
//  KinveyKit
//
//  Created by Michael Katz on 10/23/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSEntityCache.h"

#import "KinveyPersistable.h"
#import "KinveyEntity.h"
#import "KCSQuery.h"

#import "NSArray+KinveyAdditions.h"
#import "KCSLogManager.h"

#import "KCSReduceFunction.h"

@interface KCSCachedStoreCaching () {
    NSMutableDictionary* _caches;
}

@end

@implementation KCSCachedStoreCaching

static KCSCachedStoreCaching* sCaching;

+ (KCSCachedStoreCaching*)sharedCaches
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sCaching = [[KCSCachedStoreCaching alloc] init];
    });
    return sCaching;
}

+ (KCSEntityCache*)cacheForCollection:(NSString*)collection
{
    return [[self sharedCaches] cacheForCollection:collection];
}

#pragma mark - classes

- (id) init
{
    self = [super init];
    if (self) {
        _caches = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void) dealloc
{
    [_caches removeAllObjects];
}

- (KCSEntityCache*)cacheForCollection:(NSString*)collection
{
    KCSEntityCache* cache = nil;
    @synchronized(self) {
        cache = [_caches objectForKey:collection];
        if (!cache) {
            cache = [[KCSEntityCache alloc] init];
            [_caches setObject:cache forKey:collection];
        }
    }
    return cache;
}

@end



@interface CacheValue : NSObject
@property (nonatomic) NSUInteger count;
@property (nonatomic) id<KCSPersistable> object;
@end
@implementation CacheValue

- (id) init
{
    self = [super init];
    if (self) {
        _count = 1;
    }
    return self;
}
@end


//Offload equality of group queries to simple object that uses a string representation
//NSString* kcsCacheKeyIds(id objectId)
//{
//    NSString* idRepresentation = ([objectId isKindOfClass:[NSArray class]] == YES) ? [(NSArray*)objectId join:@","] : objectId;
//    return [NSString stringWithFormat:@"objectid=%@", idRepresentation];
//}

//@interface KCSCacheKey : NSObject
//{
//    NSString* _representation;
//}
//@end
//
//@implementation KCSCacheKey
//


//
//- (id) initWithObjectId:(id)objectId
//{
//    self = [super init];
//    if (self) {
//        NSString* idRepresentation = ([objectId isKindOfClass:[NSArray class]] == YES) ? [(NSArray*)objectId join:@","] : objectId;
//        _representation = [[NSString stringWithFormat:@"objectid=%@",idRepresentation] retain];
//    }
//    return self;
//}
//
//
//- (void) dealloc
//{
//    [_representation release];
//    [super dealloc];
//}
//
//- (NSString*) representation
//{
//    return _representation;
//}
//
//- (BOOL) isEqual:(id)object
//{
//    return [object isKindOfClass:[KCSCacheKey class]] && [_representation isEqual:[object representation]];
//}
//
//- (NSUInteger)hash
//{
//    return [_representation hash];
//}
//
//@end


NSString* cacheKeyForGroup(NSArray* fields, KCSReduceFunction* function, KCSQuery* condition)
{
    NSMutableString* representation = [NSMutableString string];
    for (NSString* field in fields) {
        [representation appendString:field];
    }
    [representation appendString:[function JSONStringRepresentationForFunction:fields]];
    if (condition != nil) {
        [representation appendString:[condition JSONStringRepresentation]];
    }
    return representation;
}

@interface KCSEntityCache ()
{
    NSCache* _cache;
    NSCache* _queryCache;
    NSCache* _groupingCache;
}
@end

@implementation KCSEntityCache

- (id) init
{
    self = [super init];
    if (self) {
        _cache = [[NSCache alloc] init];
        _queryCache = [[NSCache alloc] init];
        _groupingCache = [[NSCache alloc] init];
    }
    return self;
}

#pragma mark - querying

- (NSArray*) resultsForQuery:(KCSQuery*)query
{
    NSString* queryKey = [query JSONStringRepresentation];
    NSMutableArray* ids = [_queryCache objectForKey:queryKey];
    return ids == nil ? nil : [self resultsForIds:ids];
}

- (NSArray*) resultsForIds:(NSArray*)keys
{
    NSMutableArray* vals = [NSMutableArray arrayWithCapacity:keys.count];
    for (NSString* key in keys) {
        id res = [self objectForId:key];
        if (res) {
            [vals addObject:res];
        }
    }
    return vals;
}

- (id) objectForId:(NSString*)objId
{
//    NSString* key = kcsCacheKeyIds(objId);
    CacheValue* val = [_cache objectForKey:objId];
    id obj = nil;
    if (val != nil) {
        obj = val.object;
    }
    return obj;
}

#pragma mark - adding

- (void) addObject:(id)obj
{
    NSString* objId = [obj kinveyObjectId];
    if (objId != nil) {
        CacheValue* val = [_cache objectForKey:objId];
        if (val) {
            val.count++;
            val.object = obj;
        } else {
            val = [[CacheValue alloc] init];
            val.object = obj;
            [_cache setObject:val forKey:objId];
        }
    } else {
        KCSLogDebug(@"attempting to cache an object without a set ID");
    }
}

- (void) addObjects:(NSArray *)objects
{
    for (id n in objects) {
        [self addObject:n];
    }
}

//TODO make sure count is appropriate

- (void) setResults:(NSArray*)results forQuery:(KCSQuery*)query
{
    NSString* queryKey = [query JSONStringRepresentation];
    NSMutableArray* oldIds = [_queryCache objectForKey:queryKey];
    NSMutableArray* ids = [NSMutableArray arrayWithCapacity:results.count];
    for (id n in results) {
        NSString* objId = [n kinveyObjectId];
        if (objId != nil) {
            [ids addObject:objId];
            [self addObject:n];
        }
    }
    [_queryCache setObject:ids forKey:queryKey];
    if (oldIds) {
        [oldIds removeObjectsInArray:ids];
        [self removeIds:oldIds];
    }
}

- (void) setResults:(KCSGroup*)results forGroup:(NSArray*)fields reduce:(KCSReduceFunction *)function condition:(KCSQuery *)condition;
{
    NSString* key = cacheKeyForGroup(fields, function, condition);
    [_groupingCache setObject:results forKey:key];
}

#pragma mark - removing

- (void) removeIds:(NSArray*)keys
{
    for (NSString* key in keys) {
        CacheValue* val = [_cache objectForKey:key];
        val.count--;
        if (val.count == 0) {
            [_cache removeObjectForKey:key];
        }
    }
}

- (void) removeQuery:(KCSQuery*) query
{
    NSString* queryKey = [query JSONStringRepresentation];
    NSArray* keys = [_queryCache objectForKey:queryKey];
    [self removeIds:keys];
    [_queryCache removeObjectForKey:queryKey];
}

- (void) removeGroup:(NSArray*)fields reduce:(KCSReduceFunction *)function condition:(KCSQuery *)condition;
{
    NSString* key = cacheKeyForGroup(fields, function, condition);
    [_groupingCache removeObjectForKey:key];
}



#pragma mark - mem management

- (void)dealloc
{
    [self dumpContents];
}

- (void) dumpContents
{
    [_cache removeAllObjects];
    [_queryCache removeAllObjects];
    [_groupingCache removeAllObjects];
}

@end
