//
//  KCSChaedStore.m
//  KinveyKit
//
//  Created by Michael Katz on 5/10/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "KCSCachedStore.h"

#import "KCSAppdataStore.h"

#import "KCSErrorUtilities.h"
#import "KinveyErrorCodes.h"
#import "NSArray+KinveyAdditions.h"

#import "KinveyCollection.h"
#import "KCSReduceFunction.h"

#import "KCSEntityCache.h"

#import "KCSHiddenMethods.h"


@interface KCSAppdataStore (KCSCachedStore) 
- (instancetype)initWithAuth: (KCSAuthHandler *)auth;
- (KCSCollection*) backingCollection;
@end

@interface KCSCachedStore () {
    KCSEntityCache* _cache;
}

@end

@implementation KCSCachedStore

#pragma mark - Initialization

- (BOOL)configureWithOptions: (NSDictionary *)options
{
    BOOL retVal = [super configureWithOptions:options];

    KCSCachePolicy cachePolicy = (options == nil || [options objectForKey:KCSStoreKeyCachePolicy] == nil) ? [KCSCachedStore defaultCachePolicy] : [[options objectForKey:KCSStoreKeyCachePolicy] intValue];
    self.cachePolicy = cachePolicy;
    
    KCSCollection* backingCollection = [self backingCollection];
    _cache = [KCSCachedStoreCaching cacheForCollection:backingCollection.collectionName];
    if (cachePolicy == KCSCachePolicyReadOnceAndSaveLocal_Xperimental) {
        [_cache setPersistenceId:[options objectForKey:KCSStoreKeyLocalCachePersistanceKey_Xperimental]];
    }
    
    return retVal;
}

- (instancetype)initWithAuth: (KCSAuthHandler *)auth
{
    self = [super initWithAuth:auth];
    if (self) {
        _cachePolicy = [KCSCachedStore defaultCachePolicy];
    }
    return self;
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

- (BOOL) shouldCallNetworkFirst:(id)cachedResult cachePolicy:(KCSCachePolicy)cachePolicy
{
    return cachePolicy == KCSCachePolicyNone || 
          (cachePolicy == KCSCachePolicyNetworkFirst && [self isKinveyReachable]) || 
          (cachePolicy != KCSCachePolicyLocalOnly && cachedResult == nil);
}

- (BOOL) shouldUpdateInBackground:(KCSCachePolicy)cachePolicy
{
    return cachePolicy == KCSCachePolicyLocalFirst || cachePolicy == KCSCachePolicyBoth;
}

- (BOOL) shouldIssueCallbackOnBackgroundQuery:(KCSCachePolicy)cachePolicy
{
    return cachePolicy == KCSCachePolicyBoth;
}

- (void) cacheQuery:(KCSQuery*)query value:(id)objectsOrNil error:(NSError*)errorOrNil policy:(KCSCachePolicy)cachePolicy
{
    DBAssert([query isKindOfClass:[KCSQuery class]], @"should be a query");
    if ((errorOrNil != nil && [[errorOrNil domain] isEqualToString:KCSNetworkErrorDomain] == NO) || (objectsOrNil == nil && errorOrNil == nil)) {
        //remove the object from the cache, if it exists if the there was an error or return nil, but not if there was a network error (keep using the cached value)
        [_cache removeQuery:query];
    } else if (objectsOrNil != nil) {
        [_cache setResults:objectsOrNil forQuery:query];
    }
}

- (void) cacheObjects:(NSArray*)ids results:(id)objectsOrNil error:(NSError*)errorOrNil policy:(KCSCachePolicy)cachePolicy
{
    if ((errorOrNil != nil && [[errorOrNil domain] isEqualToString:KCSNetworkErrorDomain] == NO) || (objectsOrNil == nil && errorOrNil == nil)) {
        //remove the object from the cache, if it exists if the there was an error or return nil, but not if there was a network error (keep using the cached value)
        [_cache removeIds:ids];
    } else if (objectsOrNil != nil) {
        [_cache addResults:objectsOrNil];
    }
}

- (void) queryNetwork:(id)query withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock policy:(KCSCachePolicy)cachePolicy
{
    [super queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        [self cacheQuery:query value:objectsOrNil error:errorOrNil policy:cachePolicy];
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
    id obj = [_cache resultsForQuery:query]; //Hold on the to the object first, in case the cache is cleared during this process
    if ([self shouldCallNetworkFirst:obj cachePolicy:cachePolicy] == YES) {
        [self queryNetwork:query withCompletionBlock:completionBlock withProgressBlock:progressBlock policy:cachePolicy];
    } else {
        [self completeQuery:obj withCompletionBlock:completionBlock];
        if ([self shouldUpdateInBackground:cachePolicy] == YES) {
            dispatch_async(dispatch_get_current_queue(), ^{
                [self queryNetwork:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                    if ([self shouldIssueCallbackOnBackgroundQuery:cachePolicy] == YES) {
                        completionBlock(objectsOrNil, errorOrNil);
                    }
                } withProgressBlock:nil policy:cachePolicy];
            });
        }
    }

}

- (void)queryWithQuery:(id)query withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock
{
    [self queryWithQuery:query withCompletionBlock:completionBlock withProgressBlock:progressBlock cachePolicy:_cachePolicy];
}

#pragma mark - Group Caching Support
- (void) cacheGrouping:(NSArray*)fields reduce:(KCSReduceFunction *)function condition:(KCSQuery *)condition results:(KCSGroup*)objectsOrNil error:(NSError*)errorOrNil policy:(KCSCachePolicy)cachePolicy
{
    if ((errorOrNil != nil && [[errorOrNil domain] isEqualToString:KCSNetworkErrorDomain] == NO) || (objectsOrNil == nil && errorOrNil == nil)) {
        //remove the object from the cache, if it exists if the there was an error or return nil, but not if there was a network error (keep using the cached value)
        [_cache removeGroup:fields reduce:function condition:condition];
    } else if (objectsOrNil != nil) {
        [_cache setResults:objectsOrNil forGroup:fields reduce:function condition:condition];
    }

}

- (void)groupNetwork:(NSArray *)fields reduce:(KCSReduceFunction *)function condition:(KCSQuery *)condition completionBlock:(KCSGroupCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock policy:(KCSCachePolicy)cachePolicy
{
    [super group:fields reduce:function condition:condition completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
        [self cacheGrouping:fields reduce:function condition:condition results:valuesOrNil error:errorOrNil policy:cachePolicy ];
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
//TODO:
    //    KCSCacheKey* key = [[[KCSCacheKey alloc] initWithFields:fields reduce:function condition:condition] autorelease];
    id obj = nil; // [_cache objectForKey:key]; //Hold on the to the object first, in case the cache is cleared during this process
    if ([self shouldCallNetworkFirst:obj cachePolicy:cachePolicy] == YES) {
        [self groupNetwork:fields reduce:function condition:condition completionBlock:completionBlock progressBlock:progressBlock policy:cachePolicy];
    } else {
        [self completeGroup:obj withCompletionBlock:completionBlock];
        if ([self shouldUpdateInBackground:cachePolicy] == YES) {
            dispatch_async(dispatch_get_current_queue(), ^{
                [self groupNetwork:fields reduce:function condition:condition completionBlock:^(KCSGroup *valuesOrNil, NSError *errorOrNil) {
                    if ([self shouldIssueCallbackOnBackgroundQuery:cachePolicy] == YES) {
                        completionBlock(valuesOrNil, errorOrNil);
                    }
                } progressBlock:nil policy:cachePolicy];
            });
        }
    }
}

- (void)group:(id)fieldOrFields reduce:(KCSReduceFunction *)function condition:(KCSQuery *)condition completionBlock:(KCSGroupCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    [self group:fieldOrFields reduce:function condition:condition completionBlock:completionBlock progressBlock:progressBlock cachePolicy:_cachePolicy];
}

#pragma mark Load Entity

- (void) loadEntityFromNetwork:(NSArray*)objectIDs withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock policy:(KCSCachePolicy)cachePolicy
{
    [super loadObjectWithID:objectIDs withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        [self cacheObjects:objectIDs results:objectsOrNil error:errorOrNil policy:cachePolicy];
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
    NSArray* keys = [NSArray wrapIfNotArray:objectID];
    NSArray* objs = [_cache resultsForIds:keys]; //Hold on the to the object first, in case the cache is cleared during this process
    if ([self shouldCallNetworkFirst:objs cachePolicy:cachePolicy] == YES) {
        [self loadEntityFromNetwork:keys withCompletionBlock:completionBlock withProgressBlock:progressBlock policy:cachePolicy];
    } else {
        [self completeLoad:objs withCompletionBlock:completionBlock];
        if ([self shouldUpdateInBackground:cachePolicy] == YES) {
            dispatch_async(dispatch_get_current_queue(), ^{
                [self loadEntityFromNetwork:keys withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
                    if ([self shouldIssueCallbackOnBackgroundQuery:cachePolicy] == YES) {
                        completionBlock(objectsOrNil, errorOrNil);
                    }
                } withProgressBlock:nil policy:cachePolicy];
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
