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
//#import "math.h"
#import <CommonCrypto/CommonDigest.h>

#import "KCSAppdataStore.h"
#import "KinveyCollection.h"
#import "KinveyErrorCodes.h"

@interface KCSEntityCache ()
{
    NSCache* _cache;
    NSCache* _queryCache;
    NSCache* _groupingCache;
    NSMutableOrderedSet* _unsavedObjs;
}
@property (nonatomic, strong) NSDictionary* saveContext;
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
            cache.saveContext = @{@"collection" : collection};
        }
    }
    return cache;
}

@end



@interface CacheValue : NSObject
@property (nonatomic) NSUInteger count;
@property (unsafe_unretained, nonatomic) id<KCSPersistable> object;
@property (nonatomic) BOOL unsaved;
@property (nonatomic, strong) NSDate* lastSavedTime;
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

void md5(NSString* s, unsigned char* result)
{
    const char *cStr = [s UTF8String];
    CC_MD5( cStr, strlen(cStr), result ); // This is the md5 call
}

NSString* KCSMongoObjectId()
{
    int timestamp = (time_t) [[NSDate date] timeIntervalSince1970];
//    NSString *processName = [[NSProcessInfo processInfo] processName];
//    unsigned char namebytes[16];
//    md5(processName, namebytes);
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

+ (void)initialize
{
    [super initialize];
    counter = arc4random();
}

- (id) init
{
    self = [super init];
    if (self) {
        _cache = [[NSCache alloc] init];
        _queryCache = [[NSCache alloc] init];
        _groupingCache = [[NSCache alloc] init];
        _unsavedObjs = [NSMutableOrderedSet orderedSet];
    }
    return self;
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
    NSMutableOrderedSet* oldIds = [_queryCache objectForKey:queryKey];
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
    NSMutableOrderedSet* keys = [_queryCache objectForKey:queryKey];
    [self removeIds:[keys array]];
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
    [_unsavedObjs removeAllObjects];
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
