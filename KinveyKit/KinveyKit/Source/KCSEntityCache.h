//
//  KCSEntityCache.h
//  KinveyKit
//
//  Created by Michael Katz on 10/23/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KCSPersistable;
@class KCSQuery;
@class KCSGroup;
@class KCSReduceFunction;
@interface KCSEntityCache : NSObject


- (id) objectForId:(NSString*)objId;
- (NSArray*) resultsForIds:(NSArray*)keys;
- (NSArray*) resultsForQuery:(KCSQuery*)query;

- (void) addObject:(id<KCSPersistable>)obj;
- (void) addObjects:(NSArray*)objects;
- (void) setResults:(NSArray*)results forQuery:(KCSQuery*)query;
- (void) setResults:(KCSGroup*)results forGroup:(NSArray*)fields reduce:(KCSReduceFunction *)function condition:(KCSQuery *)condition;

- (void) removeQuery:(KCSQuery*) query;
- (void) removeIds:(NSArray*)keys;
- (void) removeGroup:(NSArray*)fields reduce:(KCSReduceFunction *)function condition:(KCSQuery *)condition;
@end

@interface KCSCachedStoreCaching : NSObject
+ (KCSEntityCache*) cacheForCollection:(NSString*)collectionName;

@end

