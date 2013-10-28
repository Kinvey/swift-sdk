//
//  KCSEntityCache.m
//  KinveyKit
//
//  Created by Michael Katz on 10/23/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
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


#import "KCSEntityCache.h"

#import "KinveyPersistable.h"
#import "KinveyEntity.h"
#import "KCSQuery.h"

#import "NSArray+KinveyAdditions.h"
#import "KCSLogManager.h"

#import "KCSReduceFunction.h"

#import <CommonCrypto/CommonDigest.h>

#import "KCSAppdataStore.h"
#import "KinveyCollection.h"
#import "KinveyErrorCodes.h"

#import "KCSObjectMapper.h"
#import "KinveyUser.h"

#import "KCSEntityPersistence.h"


@interface KCSEntityCache () <NSCacheDelegate>
{
    NSMutableDictionary* _cache;
    NSMutableDictionary* _queryCache;
    NSMutableDictionary* _groupingCache;
    NSMutableOrderedSet* _unsavedObjs;
    
}
@property (nonatomic, strong) NSDictionary* saveContext;
@property (nonatomic, retain) NSString* persistenceId;
@end

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

+ (id<KCSEntityCache>)cacheForCollection:(NSString*)collection
{
    return [[self sharedCaches] cacheForCollection:collection];
}

#pragma mark - classes

- (instancetype) init
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

- (id<KCSEntityCache>)cacheForCollection:(NSString*)collection
{
    id<KCSEntityCache> cache = nil;
    @synchronized(self) {
        cache = [_caches objectForKey:collection];
        if (!cache) {
            BOOL useV2 = [[[KCSClient sharedClient].options valueForKey:KCS_CACHES_USE_V2] boolValue];
            if (useV2) {
                //TODO:     cache = [[KCSEntityCache2 alloc] initWithPersistenceId:collection];
            } else {
                cache = [[KCSEntityCache alloc] init];
            }
            [_caches setObject:cache forKey:collection];
            [cache setSaveContext:@{@"collection" : collection}];
        }
    }
    return cache;
}

- (void) clearCaches
{
    @synchronized(self) {
        for (KCSEntityCache* c in [_caches allValues]) {
            [c clearCaches];
        }
    }
}

@end



@interface CacheValue : NSObject <NSCoding>
@property (nonatomic) NSUInteger count;
@property (retain, nonatomic) id<KCSPersistable> object;
@property (nonatomic) BOOL unsaved;
@property (nonatomic, strong) NSDate* lastSavedTime;
@end
@implementation CacheValue

- (instancetype) init
{
    self = [super init];
    if (self) {
        _count = 1;
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _lastSavedTime = [aDecoder decodeObjectForKey:@"date"];
        _count = [aDecoder decodeIntForKey:@"count"];
        _unsaved = [aDecoder decodeBoolForKey:@"unsaved"];
        NSString* clName = [aDecoder decodeObjectForKey:@"classname"];
        NSDictionary* objData = [aDecoder decodeObjectForKey:@"object"];
        _object = [KCSObjectMapper makeObjectOfType:NSClassFromString(clName) withData:objData];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_lastSavedTime forKey:@"date"];
    [aCoder encodeInteger:_count forKey:@"count"];
    [aCoder encodeBool:_unsaved forKey:@"unsaved"];
    [aCoder encodeObject:NSStringFromClass([_object class]) forKey:@"classname"];
    NSError* error = nil;
    KCSSerializedObject* obj = [KCSObjectMapper makeKinveyDictionaryFromObject:_object error:&error];
    DBAssert(error == nil, @"error = %@", error);
    [aCoder encodeObject:[obj dataToSerialize] forKey:@"object"];
}
@end

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

@implementation KCSEntityCache
static uint counter;

#if TARGET_OS_IPHONE
void md5(NSString* s, unsigned char* result)
{
    const char *cStr = [s UTF8String];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result ); // This is the md5 call
}

NSString* KCSMongoObjectId()
{
    time_t timestamp = (time_t) [[NSDate date] timeIntervalSince1970];
    NSString *hostName = [[NSProcessInfo processInfo] hostName];
    unsigned char hostbytes[16];
    md5(hostName, hostbytes);
    int pid = getpid();
    counter = (counter + 1) % 16777216;
    NSString* s = [NSString stringWithFormat:
            @"%08lxx%02x%02x%02x%04x%06x",
            timestamp, hostbytes[0], hostbytes[1], hostbytes[2],
            pid, counter];
    return s;
}
#else

void md5(NSString* s, unsigned char* result)
{
    const char *cStr = [s UTF8String];
    CC_MD5( cStr, (CC_LONG) strlen(cStr), result ); // This is the md5 call
}

NSString* KCSMongoObjectId()
{
    int timestamp = (int) [[NSDate date] timeIntervalSince1970];
    NSString *hostName = [[NSProcessInfo processInfo] hostName];
    unsigned char hostbytes[16];
    md5(hostName, hostbytes);
    int pid = getpid();
    counter = (counter + 1) % 16777216;
    NSString* s = [NSString stringWithFormat:
                   @"%08x%02x%02x%02x%04x%06x",
                   timestamp, hostbytes[0], hostbytes[1], hostbytes[2],
                   pid, counter];
    return s;
}
#endif

+ (void)initialize
{
    [super initialize];
    counter = arc4random();
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _cache = [NSMutableDictionary dictionary];
        _queryCache = [NSMutableDictionary dictionary];
//        _queryCache.delegate = self;
        _groupingCache = [NSMutableDictionary dictionary];
        _unsavedObjs = [NSMutableOrderedSet orderedSet];
    }
    return self;
}

#pragma mark - peristence
- (void)setPersistenceId:(NSString *)key
{
    //TODO: maybe reuse context dictionary
    
    //TODO: reuse URLs in array oe dict
    //TODO: clear up if change
    _persistenceId = key;
    NSURL* url = [NSURL fileURLWithPath: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"com.kinvey.%@_cache.plist", key]]];
//    _cache = [NSMutableDictionary dictionaryWithContentsOfURL:url];
    _cache = [NSKeyedUnarchiver unarchiveObjectWithFile:[url path]];
    if (!_cache) {
        _cache = [NSMutableDictionary dictionary];
    }
    
    url = [NSURL fileURLWithPath: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"com.kinvey.%@_cacheq.plist", key]]];
    _queryCache = [NSKeyedUnarchiver unarchiveObjectWithFile:[url path]];//[NSMutableDictionary dictionaryWithContentsOfURL:url];
    if (!_queryCache) {
        _queryCache = [NSMutableDictionary dictionary];
    }
    
    url = [NSURL fileURLWithPath: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"com.kinvey.%@_cacheg.plist", key]]];
    _groupingCache = [NSKeyedUnarchiver unarchiveObjectWithFile:[url path]];// [NSMutableDictionary dictionaryWithContentsOfURL:url];
    if (!_groupingCache) {
        _groupingCache = [NSMutableDictionary dictionary];
    }

}

- (void) persist
{
    if (_persistenceId != nil) {
        //TODO handle errors
        NSURL* url = [NSURL fileURLWithPath: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"com.kinvey.%@_cache.plist", _persistenceId]]];
        BOOL wrote = [NSKeyedArchiver archiveRootObject:_cache toFile:[url path]];
        KCSLogTrace(@"writing cache: %d", wrote);
        DBAssert(wrote, @"should have written cache");
        url = [NSURL fileURLWithPath: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"com.kinvey.%@_cacheq.plist", _persistenceId]]];
        wrote = [NSKeyedArchiver archiveRootObject:_queryCache toFile:[url path]];
        KCSLogTrace(@"writing cache: %d", wrote);
        DBAssert(wrote, @"should have written cache");

        url = [NSURL fileURLWithPath: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"com.kinvey.%@_cacheg.plist", _persistenceId]]];
        wrote = [NSKeyedArchiver archiveRootObject:_groupingCache toFile:[url path]];
        KCSLogTrace(@"writing cache: %d", wrote);
        DBAssert(wrote, @"should have written cache");
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearCaches) name:KCSActiveUserChangedNotification object:nil];
    }
}

- (void) clearCaches
{
    if (_persistenceId != nil) {
        NSError* error = nil;

        NSURL* url = [NSURL fileURLWithPath: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"com.kinvey.%@_cache.plist", _persistenceId]]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
            [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
        }
        DBAssert(!error, @"error clearing cache: %@", error);

        url = [NSURL fileURLWithPath: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"com.kinvey.%@_cacheq.plist", _persistenceId]]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
            [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
        }
        DBAssert(!error, @"error clearing cache: %@", error);
        
        url = [NSURL fileURLWithPath: [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"com.kinvey.%@_cacheg.plist", _persistenceId]]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]]) {
            [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
        }
        DBAssert(!error, @"error clearing cache: %@", error);
    }
    [self dumpContents];
}

#pragma mark - querying
//TODO: empty results vs not cached
- (NSArray*) resultsForQuery:(KCSQuery*)query
{
    NSString* queryKey = [query JSONStringRepresentation];
    NSMutableOrderedSet* ids = [_queryCache objectForKey:queryKey];
    return ids == nil ? nil : [self resultsForIds:[ids array]];
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
    CacheValue* val = [_cache objectForKey:objId];
    id obj = nil;
    if (val != nil) {
        obj = val.object;
    }
    return obj;
}

#pragma mark - adding

- (void) addUnsavedObject:(id)obj
{
    NSString* objId = [obj kinveyObjectId];
    if (objId == nil) {
        objId = KCSMongoObjectId();
        KCSLogDebug(@"attempting to save a new object to the backend - assigning '%@' as id", objId);
        [obj setKinveyObjectId:objId];
    }
    if (objId != nil) {
        CacheValue* val = [_cache objectForKey:objId];
        if (val == nil) {
            val.count++;
        } else {
            val = [[CacheValue alloc] init];
            [_cache setObject:val forKey:objId];
        }
        val.object = obj;
        val.unsaved = YES;
        val.lastSavedTime = [NSDate date];
        [_unsavedObjs addObject:objId];
    } else {
        KCSLogDebug(@"attempting to cache an object without a set ID");
    }

}

- (void) addResult:(id)obj
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
        [_unsavedObjs removeObject:objId];
    } else {
        KCSLogDebug(@"attempting to cache an object without a set ID");
    }
}

- (void) addResults:(NSArray *)objects
{
    for (id n in objects) {
        [self addResult:n];
    }
}

//TODO make sure count is appropriate

- (void) setResults:(NSArray*)results forQuery:(KCSQuery*)query
{
    NSString* queryKey = [query JSONStringRepresentation];
    NSMutableOrderedSet* oldIds = [[_queryCache objectForKey:queryKey] mutableCopy];
    NSMutableOrderedSet* ids = [NSMutableOrderedSet orderedSetWithCapacity:oldIds.count];
    for (id n in results) {
        NSString* objId = [n kinveyObjectId];
        if (objId != nil) {
            [ids addObject:objId];
            [self addResult:n];
        }
    }
    [_queryCache setObject:ids forKey:queryKey];
    if (oldIds) {
        [oldIds removeObjectsInArray:[ids array]];
        [self removeIds:[oldIds array]];
    }
    [self persist];
}

- (void) setResults:(KCSGroup*)results forGroup:(NSArray*)fields reduce:(KCSReduceFunction *)function condition:(KCSQuery *)condition;
{
    NSString* key = cacheKeyForGroup(fields, function, condition);
    [_groupingCache setObject:results forKey:key];
    [self persist];
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
    NSMutableOrderedSet* keys = [_queryCache objectForKey:queryKey];
    [self removeIds:[keys array]];
    [_queryCache removeObjectForKey:queryKey];
    [self persist];
}

- (void) removeGroup:(NSArray*)fields reduce:(KCSReduceFunction *)function condition:(KCSQuery *)condition;
{
    NSString* key = cacheKeyForGroup(fields, function, condition);
    [_groupingCache removeObjectForKey:key];
    [self persist];
}


#pragma mark - mem management

- (void)dealloc
{
    [self dumpContents];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KCSActiveUserChangedNotification object:nil];
}

- (void) dumpContents
{
    [_cache removeAllObjects];
    [_queryCache removeAllObjects];
    [_groupingCache removeAllObjects];
    [_unsavedObjs removeAllObjects];
}

+ (void) clearAllCaches
{
    [[KCSCachedStoreCaching sharedCaches] clearCaches];
}

#pragma mark - Saving
//TODO: BACKGROUND STUFF

- (void) saveObject:(NSString*)objId
{
    CacheValue* v = [_cache objectForKey:objId];
    id<KCSPersistable> obj = v.object;
    
    
    if (_delegate && [_delegate respondsToSelector:@selector(willSave:lastSaveTime:)]) {
        [_delegate willSave:obj lastSaveTime:v.lastSavedTime];
    }
    
    KCSAppdataStore* store = [KCSAppdataStore storeWithCollection:[KCSCollection collectionFromString:[_saveContext objectForKey:@"collection"] ofClass:[obj class]] options:nil];
    [store saveObject:obj withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        //
        if (errorOrNil) {
            if ([errorOrNil.domain isEqualToString:KCSAppDataErrorDomain]) {
                //KCS Error
                v.unsaved = NO;
                [_unsavedObjs removeObject:objId];
                
                if (_delegate && [_delegate respondsToSelector:@selector(errorSaving:error:)]) {
                    [_delegate errorSaving:obj error:errorOrNil];
                }
                [self startSaving];
            } else {
                //Other error, like networking
                //requeue error
                [self startSaving];
            }
        } else {
            //save complete
            v.unsaved = NO;
            [_unsavedObjs removeObject:objId];
            if (_delegate && [_delegate respondsToSelector:@selector(didSave:)]) {
                [_delegate didSave:obj];
            }
            [self startSaving];
        }
    } withProgressBlock:nil];
}

//note saving an object could make it invalid for a query, but will show up until query is refetched
- (void) startSaving
{
    if (_unsavedObjs.count > 0) {
        NSString* objId = [_unsavedObjs firstObject];
        CacheValue* v = [_cache objectForKey:objId];
        id<KCSPersistable> obj = v.object;
       
        if (_delegate && [_delegate respondsToSelector:@selector(shouldSave:lastSaveTime:)]) {
            //test the delegate, if available
            if ([_delegate shouldSave:obj lastSaveTime:v.lastSavedTime]) {
                [self saveObject:objId];
            } else {
                v.unsaved = NO;
                [_unsavedObjs removeObject:objId];
            }
        } else {
           //otherwise client doesn't care about shouldSave: and then we should default the save
            [self saveObject:objId];
        }
    }
}

@end
