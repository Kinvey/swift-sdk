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

#import "KinveyCollection.h"

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

+ (id)store
{
    return [KCSCachedStore storeWithAuthHandler:nil withOptions:nil];
}

+ (id)storeWithOptions:(NSDictionary *)options
{
    return [KCSCachedStore storeWithAuthHandler:nil withOptions:options];
}

+ (id)storeWithAuthHandler: (KCSAuthHandler *)authHandler withOptions: (NSDictionary *)options
{
    KCSCachedStore* store = [[[KCSCachedStore alloc] initWithAuth:authHandler] autorelease];  
    [store configureWithOptions:options];
    return store;
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

- (void) cacheQuery:(id)query value:(NSArray*)objectsOrNil error:(NSError*)errorOrNil
{
    if (objectsOrNil == nil || (errorOrNil != nil && [[errorOrNil domain] isEqualToString:KCSNetworkErrorDomain] == NO)) {
        //remove the object from the cache, if it exists if the there was an error or return nil, but not if there was a network error (keep using the cached value)
        [_cache removeObjectForKey:query];
    } else {
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
        NSError* error = nil;
        if (obj == nil) {
            NSDictionary* userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Query not in cache" 
                                                                               withFailureReason:@"The specified query could not be found in the cache" 
                                                                          withRecoverySuggestion:@"Resend query with cache policy that allows network connectivity" 
                                                                             withRecoveryOptions:nil];
            error = [NSError errorWithDomain:KCSAppDataErrorDomain code:KCSNotFoundError userInfo:userInfo];
        }
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


@end
