//
//  KCSDataStore.m
//  KinveyKit
//
//  Created by Michael Katz on 5/23/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "KCSDataStore.h"

#import "KCSQuery2.h"
#import "KCSRequest.h"
#import "KCSDataStoreCaches.h"

#import "KinveyErrorCodes.h"

#import "EXTScope.h"

@interface KCSDataStore ()
@property (nonatomic, strong) NSString* collectionName;
@property (nonatomic) BOOL cacheEnabled;
@end

@implementation KCSDataStore

+ (void)initialize
{
    KCSUserCollectionName = @"user";
}

- (instancetype) init
{
    return [self initWithCollection:nil];
}

- (instancetype)initWithCollection:(NSString*)collection
{
    NSParameterAssert(collection);
    
    self = [super init];
    if (self) {
        _collectionName = collection;
    }
    return self;
}

enum KCSContextRoot contextRootForCollection(NSString* collectionName)
{
    return (collectionName == KCSUserCollectionName || [collectionName isEqualToString:KCSUserCollectionName])  ?  kKCSContextUSER : kKCSContextAPPDATA;
}

#pragma mark - Query

- (id<KCSRequest>) query:(KCSQuery2*)query completion:(void (^)(NSArray* objects, NSError* error))completionBlock
{
    ifNil(query, KCSQueryAll);
    
    id<KCSRequest> request = nil;
    
    if ([self goToNetwork:query] == YES) {
        request = [self queryAgainstNetwork:query completion:completionBlock];
    } else {
        //query cache
        request = [self queryAgainstCache:query completion:completionBlock];
    }
    
    return request;
}

#pragma mark Query-Helpers

- (BOOL) goToNetwork:(KCSQuery2*) query
{
    return _cacheEnabled == NO;
}


- (id<KCSRequest>) queryAgainstNetwork:(KCSQuery2*)query completion:(void (^)(NSArray* objects, NSError* error))completionBlock
{    
    KCSNetworkRequest* request = [[KCSNetworkRequest alloc] init];
    request.contextRoot = contextRootForCollection(_collectionName);
    request.queryString = [query escapedQueryString];
    
    @weakify(self);
    @weakify(query);
    @weakify(completionBlock);
    [request run:^(NSData *data, NSError *error) {
        @strongify(self);
        @strongify(query);
        @strongify(completionBlock);
        [self handleNetworkResponse:data error:error query:query completion:completionBlock];
    }];
    
    return request;
}

- (void) handleNetworkResponse:(NSData*)data error:(NSError*)error query:(KCSQuery2*)query completion:(void (^)(NSArray* objects, NSError* error))completionBlock
{
    if (error != nil) {
        //query local on error? yes - goto query else return error
        if ([self queryCacheOnError:error] == YES) {
            // return from cache
            [self queryAgainstCache:query completion:completionBlock];
        } else {
            //return error
            completionBlock(nil, error);
        }
    } else {
        //insert update entities
        //TODO #
    }
}

- (BOOL) queryCacheOnError:(NSError*) error
{
    return
    _cacheEnabled == YES &&
    error != nil && isNetworkError(error);
}

BOOL isNetworkError(NSError* error)
{
    return [error.domain isEqualToString:KCSNetworkErrorDomain];
}

- (id<KCSRequest>) queryAgainstCache:(KCSQuery2*)query completion:(void (^)(NSArray* objects, NSError* error))completionBlock
{
    //TODO #
    KCSCacheRequest* request = [[KCSCacheRequest alloc] init];
    
    KCSEntityCache2* cache = [KCSDataStoreCaches cacheForCollection:_collectionName];
    
    
    return request;
}

@end
