//
//  KCSChaedStore.m
//  KinveyKit
//
//  Created by Michael Katz on 5/10/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSCachedStore.h"

#import "KCSAppdataStore.h"

#import "KCSClient.h"
#import "KCSReachability.h"

#import "KCSErrorUtilities.h"
#import "KinveyErrorCodes.h"
#import "NSArray+KinveyAdditions.h"

#import "KinveyCollection.h"
#import "KCSReduceFunction.h"

//Offload equality of group queries to simple object that uses a string representation
@interface KCSCacheKey : NSObject
{
    NSString* _representation;
}
@end

@implementation KCSCacheKey

- (id) initWithFields:(NSArray *)fields reduce:(KCSReduceFunction *)function condition:(KCSQuery *)condition
{
    self = [super init];
    if (self) {
        NSMutableString* representation = [NSMutableString string];
        for (NSString* field in fields) {
            [representation appendString:field];
        }
        [representation appendString:[function JSONStringRepresentationForFunction:fields]];
        if (condition != nil) {
            [representation appendString:[condition JSONStringRepresentation]];
        }
        _representation = [representation copy];
    }
    return self;
}

- (id) initWithObjectId:(id)objectId
{
    self = [super init];
    if (self) {
        NSString* idRepresentation = ([objectId isKindOfClass:[NSArray class]] == YES) ? [(NSArray*)objectId join:@","] : objectId;
        _representation = [[NSString stringWithFormat:@"objectid=%@",idRepresentation] retain];
    }
    return self;
}


- (void) dealloc
{
    [_representation release];
    [super dealloc];
}

- (NSString*) representation
{
    return _representation;
}

- (BOOL) isEqual:(id)object
{
    return [object isKindOfClass:[KCSCacheKey class]] && [_representation isEqual:[object representation]];
}

- (NSUInteger)hash
{
    return [_representation hash];
}

@end

@interface KCSCachedStoreCaching : NSObject {
    NSMutableDictionary* _caches;
}

+ (KCSCachedStoreCaching*)sharedCaches;

- (NSCache*)cacheForCollection:(NSString*)collection;

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

- (id) init
{
    self = [super init];
    if (self) {
        _caches = [[NSMutableDictionary dictionary] retain];
    }
    return self;
}

- (void) dealloc
{
    [_caches removeAllObjects];
    [_caches release];
    [super dealloc];
}

- (NSCache*)cacheForCollection:(NSString*)collection
{
    NSCache* cache = nil;
    @synchronized(self) {
        cache = [_caches objectForKey:collection];
        if (!cache) {
            cache = [[[NSCache alloc] init] autorelease];
            [_caches setObject:cache forKey:collection];
        }
    }
    return cache;
}

@end


@interface KCSAppdataStore (KCSCachedStore)
- (id)initWithAuth: (KCSAuthHandler *)auth;
- (KCSCollection*) backingCollection;
@end

@implementation KCSCachedStore
@synthesize cachePolicy = _cachePolicy;

#pragma mark - Initialization

- (BOOL)configureWithOptions: (NSDictionary *)options
{
    BOOL retVal = [super configureWithOptions:options];

    KCSCachePolicy cachePolicy = (options == nil || [options objectForKey:KCSStoreKeyCachePolicy] == nil) ? [KCSCachedStore defaultCachePolicy] : [[options objectForKey:KCSStoreKeyCachePolicy] intValue];
    self.cachePolicy = cachePolicy;
    
    KCSCollection* backingCollection = [self backingCollection];
    _cache = [[[KCSCachedStoreCaching sharedCaches] cacheForCollection:backingCollection.collectionName] retain];
    
    return retVal;
}

- (id)initWithAuth: (KCSAuthHandler *)auth
{
    self = [super initWithAuth:auth];
    if (self) {
        _cachePolicy = [KCSCachedStore defaultCachePolicy];
    }
    return self;
}

- (void) dealloc
{
    [_cache release];
    [super dealloc];
}

#pragma mark - Cache Policy

static KCSCachePolicy sDefaultCachePolicy = KCSCachePolicyNone;

+ (KCSCachePolicy) defaultCachePolicy
{
    return sDefaultCachePolicy;
}

+ (void) setDefaultCachePolicy:(KCSCachePolicy)cachePolicy
{
    sDefaultCachePolicy = cachePolicy;
}

#pragma mark - Querying/Fetching
NSError* createCacheError(NSString* message) 
{
    NSDictionary* userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:message
                                                                       withFailureReason:@"The specified query could not be found in the cache" 
                                                                  withRecoverySuggestion:@"Resend query with cache policy that allows network connectivity" 
                                                                     withRecoveryOptions:nil];
    return [NSError errorWithDomain:KCSAppDataErrorDomain code:KCSNotFoundError userInfo:userInfo];
}

#if BUILD_FOR_UNIT_TEST
int reachable = -1;
- (void) setReachable:(BOOL)reachOverwrite
{
    reachable = reachOverwrite;
}
#endif

- (BOOL) isKinveyReachable
{
#if BUILD_FOR_UNIT_TEST
    return reachable == -1 ? [[KCSClient sharedClient] kinveyReachability].isReachable : reachable;
#else
    return [[KCSClient sharedClient] kinveyReachability].isReachable;
#endif
}

- (BOOL) shouldCallNetworkFirst:(id)cachedResult cachePolicy:(KCSCachePolicy)cachePolicy
{
    return cachePolicy == KCSCachePolicyNone || 
          (cachePolicy == KCSCachePolicyNetworkFirst  && [self isKinveyReachable]) || 
          ((cachePolicy == KCSCachePolicyLocalFirst || cachePolicy == KCSCachePolicyBoth) && cachedResult == nil);
}

- (BOOL) shouldUpdateInBackground:(KCSCachePolicy)cachePolicy
{
    return cachePolicy == KCSCachePolicyLocalFirst || cachePolicy == KCSCachePolicyBoth;
}

- (BOOL) shouldIssueCallbackOnBackgroundQuery:(KCSCachePolicy)cachePolicy
{
    return cachePolicy == KCSCachePolicyBoth;
}

- (void) cacheQuery:(id)query value:(id)objectsOrNil error:(NSError*)errorOrNil
{
    if ((errorOrNil != nil && [[errorOrNil domain] isEqualToString:KCSNetworkErrorDomain] == NO) || (objectsOrNil == nil && errorOrNil == nil)) {
        //remove the object from the cache, if it exists if the there was an error or return nil, but not if there was a network error (keep using the cached value)
        [_cache removeObjectForKey:query];
    } else if (objectsOrNil != nil) {
        [_cache setObject:objectsOrNil forKey:query];
    }
}

- (void) queryNetwork:(id)query withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock
{
    [super queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        [self cacheQuery:query value:objectsOrNil error:errorOrNil];
        completionBlock(objectsOrNil, errorOrNil);
    } withProgressBlock:progressBlock];
}

- (void) completeQuery:(id)obj withCompletionBlock:(KCSCompletionBlock)completionBlock
{
    dispatch_async(dispatch_get_current_queue(), ^{
        NSError* error = (obj == nil) ? createCacheError(@"Query not in cache") : nil;
        completionBlock(obj, error); 
    });
}

- (void)queryWithQuery:(id)query withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock cachePolicy:(KCSCachePolicy)cachePolicy
{
    id obj = [_cache objectForKey:query]; //Hold on the to the object first, in case the cache is cleared during this process
    if ([self shouldCallNetworkFirst:obj cachePolicy:cachePolicy] == YES) {
        [self queryNetwork:query withCompletionBlock:completionBlock withProgressBlock:progressBlock];
    } else {
        [self completeQuery:obj withCompletionBlock:completionBlock];
        if ([self shouldUpdateInBackground:cachePolicy] == YES) {
            dispatch_async(dispatch_get_current_queue(), ^{
                [self queryNetwork:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                    if ([self shouldIssueCallbackOnBackgroundQuery:cachePolicy] == YES) {
                        completionBlock(objectsOrNil, errorOrNil);
                    }
                } withProgressBlock:nil];
            });
        }
    }

}

- (void)queryWithQuery:(id)query withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock
{
    [self queryWithQuery:query withCompletionBlock:completionBlock withProgressBlock:progressBlock cachePolicy:_cachePolicy];
}

#pragma mark - Group Caching Support
- (void)groupNetwork:(NSArray *)fields reduce:(KCSReduceFunction *)function condition:(KCSQuery *)condition completionBlock:(KCSGroupCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    [super group:fields reduce:function condition:condition completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        KCSCacheKey* key = [[[KCSCacheKey alloc] initWithFields:fields reduce:function condition:condition] autorelease];
        [self cacheQuery:key value:valuesOrNil error:errorOrNil];
        completionBlock(valuesOrNil, errorOrNil);
    } progressBlock:progressBlock];
}

- (void) completeGroup:(id)obj withCompletionBlock:(KCSGroupCompletionBlock)completionBlock
{
    dispatch_async(dispatch_get_current_queue(), ^{
        NSError* error = (obj == nil) ? createCacheError(@"Grouping query not in cache") : nil;
        completionBlock(obj, error); 
    });
}

- (void)group:(id)fieldOrFields reduce:(KCSReduceFunction *)function condition:(KCSQuery *)condition completionBlock:(KCSGroupCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock cachePolicy:(KCSCachePolicy)cachePolicy
{
    NSArray* fields = [NSArray wrapIfNotArray:fieldOrFields];
    KCSCacheKey* key = [[[KCSCacheKey alloc] initWithFields:fields reduce:function condition:condition] autorelease];
    id obj = [_cache objectForKey:key]; //Hold on the to the object first, in case the cache is cleared during this process
    if ([self shouldCallNetworkFirst:obj cachePolicy:cachePolicy] == YES) {
        [self groupNetwork:fields reduce:function condition:condition completionBlock:completionBlock progressBlock:progressBlock];
    } else {
        [self completeGroup:obj withCompletionBlock:completionBlock];
        if ([self shouldUpdateInBackground:cachePolicy] == YES) {
            dispatch_async(dispatch_get_current_queue(), ^{
                [self groupNetwork:fields reduce:function condition:condition completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
                    if ([self shouldIssueCallbackOnBackgroundQuery:cachePolicy] == YES) {
                        completionBlock(valuesOrNil, errorOrNil);
                    }
                } progressBlock:nil];
            });
        }
    }
}

- (void)group:(id)fieldOrFields reduce:(KCSReduceFunction *)function condition:(KCSQuery *)condition completionBlock:(KCSGroupCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    [self group:fieldOrFields reduce:function condition:condition completionBlock:completionBlock progressBlock:progressBlock cachePolicy:_cachePolicy];
}

#pragma mark Load Entity

- (void) loadEntityFromNetwork:(id)objectID withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock
{
    [super loadObjectWithID:objectID withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        KCSCacheKey* key = [[[KCSCacheKey alloc] initWithObjectId:objectID] autorelease];
        [self cacheQuery:key value:objectsOrNil error:errorOrNil];
        completionBlock(objectsOrNil, errorOrNil);
    } withProgressBlock:progressBlock];
}

- (void) completeLoad:(id)obj withCompletionBlock:(KCSCompletionBlock)completionBlock
{
    dispatch_async(dispatch_get_current_queue(), ^{
        NSError* error = (obj == nil) ? createCacheError(@"Load query not in cache" ) : nil;
        completionBlock(obj, error); 
    });
}

- (void)loadObjectWithID:(id)objectID 
     withCompletionBlock:(KCSCompletionBlock)completionBlock
       withProgressBlock:(KCSProgressBlock)progressBlock
             cachePolicy:(KCSCachePolicy)cachePolicy
{
    //TODO: update or combine logic
    KCSCacheKey* key = [[[KCSCacheKey alloc] initWithObjectId:objectID] autorelease];
    id obj = [_cache objectForKey:key]; //Hold on the to the object first, in case the cache is cleared during this process
    if ([self shouldCallNetworkFirst:obj cachePolicy:cachePolicy] == YES) {
        [self loadEntityFromNetwork:objectID withCompletionBlock:completionBlock withProgressBlock:progressBlock];
    } else {
        [self completeLoad:obj withCompletionBlock:completionBlock];
        if ([self shouldUpdateInBackground:cachePolicy] == YES) {
            dispatch_async(dispatch_get_current_queue(), ^{
                [self loadEntityFromNetwork:objectID withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                    if ([self shouldIssueCallbackOnBackgroundQuery:cachePolicy] == YES) {
                        completionBlock(objectsOrNil, errorOrNil);
                    }
                } withProgressBlock:nil];
            });
        }
    }
}

- (void)loadObjectWithID: (id)objectID 
     withCompletionBlock: (KCSCompletionBlock)completionBlock
       withProgressBlock: (KCSProgressBlock)progressBlock
{
    [self loadObjectWithID:objectID withCompletionBlock:completionBlock withProgressBlock:progressBlock cachePolicy:_cachePolicy];
}

#pragma mark - Saving
- (void)saveObject:(id)object withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock
{
    [super saveObject:object withCompletionBlock:completionBlock withProgressBlock:progressBlock];
}

@end
