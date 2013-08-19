//
//  KCSDataStoreCaches.m
//  KinveyKit
//
//  Created by Michael Katz on 5/23/13.
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


#import "KCSDataStoreCaches.h"

@interface KCSDataStoreCaches ()
@property (nonatomic, retain) NSMutableDictionary* caches;

@end

@implementation KCSDataStoreCaches

static KCSDataStoreCaches* sCaching;

+ (instancetype)sharedCaches
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sCaching = [[KCSDataStoreCaches alloc] init];
    });
    return sCaching;
}

+ (KCSEntityCache2*)cacheForCollection:(NSString*)collection
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
            cache = [[KCSEntityCache2 alloc] initWithPersistenceId:collection];
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
