//
//  KCSEntityCache2.h
//  KinveyKit
//
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

#import <Foundation/Foundation.h>
#import "KCSEntityCache.h"

@interface KCSEntityPersistence : NSObject // <KCSEntityCache>
@property (nonatomic, strong) NSDictionary* saveContext;
@property (nonatomic, retain) NSString* persistenceId;

- (instancetype) initWithPersistenceId:(NSString*)key;

- (NSArray*)idsForQuery:(NSString*)query route:(NSString*)route collection:(NSString*)collection;
- (BOOL) setIds:(NSArray*)theseIds forQuery:(NSString*)query route:(NSString*)route collection:(NSString*)collection;

- (BOOL) updateWithEntity:(NSDictionary*)entity route:(NSString*)route collection:(NSString*)collection;
- (NSDictionary*) entityForId:(NSString*)_id route:(NSString*)route collection:(NSString*)collection;
- (BOOL) removeEntity:(NSString*)_id route:(NSString*)route collection:(NSString*)collection;

- (NSString*) addUnsavedEntity:(NSDictionary*)entity route:(NSString*)route collection:(NSString*)collection method:(NSString*)method headers:(NSDictionary*)headers;
- (BOOL) removeUnsavedEntity:(NSString*)unsavedId route:(NSString*)route collection:(NSString*)collection;
- (NSArray*) unsavedEntities;
- (int) unsavedCount;


/* 
 This is not transactional, returns on first failure, but will still hold any previouslly passed objects.
 */
- (BOOL) import:(NSArray*)entities route:(NSString*)route collection:(NSString*)collection;

#pragma mark - Management
- (void) clearCaches;

@end

