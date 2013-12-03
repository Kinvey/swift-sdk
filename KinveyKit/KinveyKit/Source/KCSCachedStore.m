//
//  KCSCachedStore.m
//  KinveyKit
//
//  Created by Michael Katz on 5/10/12.
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


#import "KCSCachedStore.h"

#import "KCSAppdataStore.h"

#import "KCSErrorUtilities.h"
#import "KinveyErrorCodes.h"
#import "NSArray+KinveyAdditions.h"

#import "KinveyCollection.h"
#import "KCSReduceFunction.h"

#import "KCSQuery2.h"
#import "KCSRequest2.h"
#import "KCSDataModel.h"

#import "KCSHiddenMethods.h"
#import "KCSReachability.h"

NSString* const KCSStoreKeyOfflineUpdateEnabled = @"offline.enabled";


@interface KCSAppdataStore (KCSCachedStore) 
- (instancetype)initWithAuth: (KCSAuthHandler *)auth;
- (KCSCollection*) backingCollection;
@property (nonatomic) BOOL offlineUpdateEnabled;
@end

@interface KCSCachedStore () {
}
@end

@implementation KCSCachedStore

#pragma mark - Initialization

- (BOOL)configureWithOptions: (NSDictionary *)options
{
    ifNil(options, @{});
    BOOL retVal = [super configureWithOptions:options];

    KCSCachePolicy cachePolicy = (options[KCSStoreKeyCachePolicy] == nil) ? [KCSCachedStore defaultCachePolicy] : [options[KCSStoreKeyCachePolicy] intValue];
    self.cachePolicy = cachePolicy;
    [[[KCSAppdataStore caches] dataModel] setClass:self.backingCollection.objectTemplate forCollection:self.backingCollection.collectionName];
    
    self.offlineUpdateEnabled = [options[KCSStoreKeyOfflineUpdateEnabled] boolValue];
    
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
          (cachePolicy == KCSCachePolicyNetworkFirst && [[KCSClient sharedClient].kinveyReachability isReachable]) ||
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
#warning check error condition
        [[KCSAppdataStore caches] removeQuery:[KCSQuery2 queryWithQuery1:query] route:KCSRESTRouteAppdata collection:self.backingCollection.collectionName];
    } else if (objectsOrNil != nil) {
        [[KCSAppdataStore caches] setObjects:objectsOrNil forQuery:[KCSQuery2 queryWithQuery1:query] route:KCSRESTRouteAppdata collection:self.backingCollection.collectionName];
    }
}

- (void) cacheObjects:(NSArray*)ids results:(id)objectsOrNil error:(NSError*)errorOrNil policy:(KCSCachePolicy)cachePolicy
{
    if ((errorOrNil != nil && [[errorOrNil domain] isEqualToString:KCSNetworkErrorDomain] == NO) || (objectsOrNil == nil && errorOrNil == nil)) {
        //remove the object from the cache, if it exists if the there was an error or return nil, but not if there was a network error (keep using the cached value)
        [[KCSAppdataStore caches] deleteObjects:ids route:KCSRESTRouteAppdata collection:self.backingCollection.collectionName];
    } else if (objectsOrNil != nil) {
        [[KCSAppdataStore caches] addObjects:objectsOrNil route:KCSRESTRouteAppdata collection:self.backingCollection.collectionName];
    }
}

- (void) queryNetwork:(id)query withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock policy:(KCSCachePolicy)cachePolicy
{
    [super queryWithQuery:query withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
        [self cacheQuery:query value:objectsOrNil error:errorOrNil policy:cachePolicy];
        completionBlock(objectsOrNil, errorOrNil);
    } withProgressBlock:progressBlock];
}

- (void) completeQuery:(id)objs withCompletionBlock:(KCSCompletionBlock)completionBlock
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSError* error = (objs == nil) ? createCacheError(@"Query not in cache") : nil;
        completionBlock(objs, error);
    });
}

- (void)queryWithQuery:(id)query withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock cachePolicy:(KCSCachePolicy)cachePolicy
{
    //Hold on the to the object first, in case the cache is cleared during this process
    id obj = [[KCSAppdataStore caches] pullQuery:[KCSQuery2 queryWithQuery1:query] route:KCSRESTRouteAppdata collection:self.backingCollection.collectionName];
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
    //TODO: reinstate GROUP caching?
    
//    if ((errorOrNil != nil && [[errorOrNil domain] isEqualToString:KCSNetworkErrorDomain] == NO) || (objectsOrNil == nil && errorOrNil == nil)) {
//        //remove the object from the cache, if it exists if the there was an error or return nil, but not if there was a network error (keep using the cached value)
//        [_cache removeGroup:fields reduce:function condition:condition];
//    } else if (objectsOrNil != nil) {
//        [_cache setResults:objectsOrNil forGroup:fields reduce:function condition:condition];
//    }
//
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
    //Hold on the to the object first, in case the cache is cleared during this process
    NSArray* objs = [[KCSAppdataStore caches] pullIds:keys route:KCSRESTRouteAppdata collection:self.backingCollection.collectionName];
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
