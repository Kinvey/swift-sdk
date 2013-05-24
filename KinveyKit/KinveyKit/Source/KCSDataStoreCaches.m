//
//  KCSDataStoreCaches.m
//  KinveyKit
//
//  Created by Michael Katz on 5/23/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
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
