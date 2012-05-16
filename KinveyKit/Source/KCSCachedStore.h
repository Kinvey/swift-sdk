//
//  KCSCachedStore.h
//  KinveyKit
//
//  Created by Michael Katz on 5/10/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCSStore.h"
#import "KCSAppdataStore.h"

/** Cache Policies. These constants determine the caching behavior when used with KCSChacedStore query. */
typedef enum KCSCachePolicy {
    /** No Caching - all queries are sent to the server */
    KCSCachePolicyNone,
    KCSCachePolicyLocalOnly,
    KCSCachePolicyLocalFirst,
    KCSCachePolicyNetworkFirst,
    KCSCachePolicyBoth
} KCSCachePolicy;

#define KCSStoreKeyCachePolicy @"cachePolicy"

/**
 This application data store caches queries, depending on the policy.
 
 Available caching policies:
 
 - `KCSCachePolicyNone` - No caching, all queries are sent to the server.
 - `KCSCachePolicyLocalOnly` - Only the cache is queried, the server is never called. If a result is not in the cache, an error is returned.
 - `KCSCachePolicyLocalFirst` - The cache is queried and if the result is stored, the `completionBlock` is called with that value. The cache is then updated in the background. If the cache does not contain a result for the query, then the server is queried first.
 - `KCSCahcePolicyNetworkFirst` - The network is queried and the cache is updated with each result. The cached value is only returned when the network is unavailable. 
 - `KCSCahcePolicyBoth` - If available, the cached value is returned to `completionBlock`. The network is then queried and cache updated, aftewards. The `completionBlock` will be called again with the updated result from the server.
 
 For an individual store, the chace policy can inherit from the defaultCachePolicy, be set using storeWithOptions: factory constructor, supplying the enum for the key `KCSStoreKeyCahcePolicy`.
 */
@interface KCSCachedStore : KCSAppdataStore <KCSStore> {
    NSCache* _cache;
}

/** @name Cache Policy */

/** The cache policy used, by default, for this store */
@property (nonatomic, readwrite) KCSCachePolicy cachePolicy;

#pragma mark - Default Cache Policy
/** gets the default cache policy for all new KCSCachedStore's */
+ (KCSCachePolicy) defaultCachePolicy;
/** Sets the default cache policy for all new KCSCachedStore's.
 @param cachePolicy the default `KCSCachePolicy` for all new stores.
 */
+ (void) setDefaultCachePolicy:(KCSCachePolicy)cachePolicy;

/** @name Querying/Fetching */

/** Query or fetch an object (or objects) in the store.
 
 This method takes a query object and returns the value from the server or cache, depending on the supplied `cachePolicy`. 
 
 This method might be used when you know the network is unavailable and you want to use `KCSCachePolicyLocalOnly` until the network connection is reestablished, and then go back to using the store's normal policy.
 
 @param query A query to act on a store.  The store defines the type of queries it accepts, an object of type "KCSAllObjects" causes all objects to be returned.
 @param completionBlock A block that gets invoked when the query/fetch is "complete" (as defined by the store)
 @param progressBlock A block that is invoked whenever the store can offer an update on the progress of the operation.
 @param cachePolicy the policy for to use for this query only. 
 */
- (void)queryWithQuery:(id)query withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock cachePolicy:(KCSCachePolicy)cachePolicy;

#if BUILD_FOR_UNIT_TEST
- (void) setReachable:(BOOL)reachOverwrite;
#endif
@end
