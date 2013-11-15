//
//  KCSOfflineUpdate.m
//  KinveyKit
//
//  Created by Michael Katz on 11/12/13.
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


#import "KCSOfflineUpdate.h"

#import "KinveyCoreInternal.h"
#import "KinveyDataStoreInternal.h"

#define DELEGATEMETHOD(m) if (_delegate != nil && [_delegate respondsToSelector:@selector(m)])

@interface KCSOfflineUpdate ()
@property (nonatomic, weak) KCSEntityPersistence* persitence;
@property (nonatomic, weak) KCSObjectCache* cache;

@end

@implementation KCSOfflineUpdate

- (id) initWithCache:(KCSObjectCache*)cache peristenceLayer:(KCSEntityPersistence*)persitence
{
    self = [super init];
    if (self) {
        _persitence = persitence;
        _cache = cache;
    }
    return self;
}

- (void)dealloc
{
    [self stop];
}

- (void) start
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reach:) name:KCSReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:KCSActiveUserChangedNotification object:nil];
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(foreground:) name:UIApplicationDidBecomeActiveNotification object:nil];
#endif
    [self drainQueue];
}

- (void) stop
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reach:(NSNotification*)note
{
    KCSReachability* reachability = note.object;
    if (reachability.isReachable) {
        [self drainQueue];
    }
}

- (void)foreground:(NSNotification*)note
{
    KCSReachability* reachability = [KCSClient sharedClient].kinveyReachability;
    if (reachability.isReachable) {
        [self drainQueue];
    }
}

- (void) userUpdated:(NSNotification*)note
{
    if ([KCSUser activeUser] != nil) {
        [self drainQueue];
    }
}

- (void)hadASucessfulConnection
{
    [self drainQueue];
}

- (NSUInteger) count
{
    return [self.persitence unsavedCount];
}

- (void) drainQueue
{
    if (_delegate && [KCSUser activeUser] != nil) {
        NSArray* unsavedEntities = [self.persitence unsavedEntities];
        for (NSDictionary* d in unsavedEntities) {
             NSString* method = d[@"method"];
            if ([method isEqualToString:KCSRESTMethodDELETE]) {
                [self processDelete:d];
            } else {
                [self processSave:d];
            }
        }
    }
}

- (void)setDelegate:(id<KCSOfflineUpdateDelegate>)delegate
{
    _delegate = delegate;
    [self start];
}

#pragma mark - Saves
#warning make sure cannot restart in the middle
- (void) processSave:(NSDictionary*)saveInfo
{
    NSString* objId = saveInfo[KCSEntityKeyId];
    NSString* route = saveInfo[@"route"];
    NSString* collection = saveInfo[@"collection"];
    NSDate* lastSaveTime = saveInfo[@"time"];
    NSString* method = saveInfo[@"method"];
    
    
    BOOL shouldSave = YES;
    DELEGATEMETHOD(shouldSaveObject:inCollection:lastAttemptedSaveTime:) {
        shouldSave = [_delegate shouldSaveObject:objId inCollection:collection lastAttemptedSaveTime:lastSaveTime];
    }
    if (shouldSave == YES) {
        NSDictionary* entity = saveInfo[@"obj"];
        NSDictionary* headers = saveInfo[@"headers"];
        [self save:objId entity:entity route:route collection:collection headers:headers method:method];
    } else {
        [self.persitence removeUnsavedEntity:objId route:route collection:collection];
    }
}

- (NSDictionary*) optionsFromHeaders:(NSDictionary*)headers
{
    NSMutableDictionary* options = [NSMutableDictionary dictionary];
    if (self.useMock) {
        options[KCSRequestOptionUseMock] = @YES;
    }
    if (headers[KCSRequestOptionClientMethod]) {
        options[KCSRequestOptionClientMethod] = headers[KCSRequestOptionClientMethod];
    }
    return options;
}


- (void) save:(NSString*)objId entity:(NSDictionary*)entity route:(NSString*)route collection:(NSString*)collection headers:(NSDictionary*)headers method:(NSString*)method
{
    DELEGATEMETHOD(willSaveObject:inCollection:) {
        [_delegate willSaveObject:entity[KCSEntityKeyId] inCollection:collection];
    }
    
    id credentials = [KCSUser activeUser];
    if (!credentials) {
        NSError* error = [NSError createKCSError:KCSAppDataErrorDomain code:KCSDeniedError userInfo:@{KCSEntityKeyId : objId, NSLocalizedDescriptionKey : NSLocalizedString(@"Could not save object because there is no active user.",nil)}];
        [self addObject:entity route:route collection:collection headers:headers method:method error:error];
    }
    
    NSDictionary* options = [self optionsFromHeaders:headers];
    KCSRequest2* request = [KCSRequest2 requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        if (!error) {
            [self.persitence removeUnsavedEntity:objId route:route collection:collection];
            NSDictionary* updatedEntity = [response jsonObject];
            [self.cache updateCacheForObject:objId withEntity:updatedEntity atRoute:route collection:collection];
            DELEGATEMETHOD(didSaveObject:inCollection:) {
                [_delegate didSaveObject:objId inCollection:collection];
            }
            
        } else {
            [self addObject:entity route:route collection:collection headers:headers method:method error:error];
        }
    }
                                                        route:route
                                                      options:options
                                                  credentials:credentials];
    if ([method isEqualToString:KCSRESTMethodPOST]) {
        request.path = @[collection];
    } else {
        request.path = @[collection, objId];
    }
    request.method = method;
    request.headers = headers;
    request.body = entity;
    [request start];
}

#pragma mark - deletes
- (void) processDelete:(NSDictionary*)saveInfo
{
    NSString* objId = saveInfo[KCSEntityKeyId];
    NSString* route = saveInfo[@"route"];
    NSString* collection = saveInfo[@"collection"];
    NSDate* lastSaveTime = saveInfo[@"time"];
    NSString* method = saveInfo[@"method"];
    
    
    BOOL shouldDelete = YES;
    DELEGATEMETHOD(shouldDeleteObject:inCollection:lastAttemptedSaveTime:) {
        shouldDelete = [_delegate shouldDeleteObject:objId inCollection:collection lastAttemptedSaveTime:lastSaveTime];
    }
    if (shouldDelete == YES) {
        NSDictionary* entity = saveInfo[@"obj"];
        NSDictionary* headers = saveInfo[@"headers"];
        [self delete:objId entity:entity route:route collection:collection headers:headers method:method];
    } else {
        [self.persitence removeUnsavedEntity:objId route:route collection:collection];
    }
}

//TODO: support delete by query
- (void) delete:(NSString*)objId entity:(NSDictionary*)entity route:(NSString*)route collection:(NSString*)collection headers:(NSDictionary*)headers method:(NSString*)method
{
    DELEGATEMETHOD(willDeleteObject:inCollection:) {
        [_delegate willDeleteObject:entity[KCSEntityKeyId] inCollection:collection];
    }
    
    id credentials = [KCSUser activeUser];
    if (!credentials) {
        NSError* error = [NSError createKCSError:KCSAppDataErrorDomain code:KCSDeniedError userInfo:@{KCSEntityKeyId : objId, NSLocalizedDescriptionKey : NSLocalizedString(@"Could not delete object because there is no active user.",nil)}];
        [self addObject:entity route:route collection:collection headers:headers method:method error:error];
    }
    
    NSDictionary* options = [self optionsFromHeaders:headers];
    KCSRequest2* request = [KCSRequest2 requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        if (!error) {
            [self.persitence removeUnsavedEntity:objId route:route collection:collection];
            [self.cache deleteObject:objId route:route collection:collection];
            DELEGATEMETHOD(didDeleteObject:inCollection:) {
                //TODO: test this delete functionality
                [_delegate didDeleteObject:objId inCollection:collection];
            }
        } else {
            [self addObject:entity route:route collection:collection headers:headers method:method error:error];
        }
    }
                                                        route:route
                                                      options:options
                                                  credentials:credentials];
    request.path = @[collection, objId];

    request.method = method;
    request.headers = headers;
    request.body = entity;
    [request start];
}

#pragma mark - objects
- (NSString*) addObject:(NSDictionary*)entity route:(NSString*)route collection:(NSString*)collection headers:(NSDictionary*)headers method:(NSString*)method error:(NSError*)error
{
    BOOL shouldEnqueue = YES;
    DELEGATEMETHOD(shouldEnqueueObject:inCollection:onError:) { //TODO: test
        shouldEnqueue = [_delegate shouldEnqueueObject:entity[KCSEntityKeyId] inCollection:collection onError:error];
    }
    
    NSString* newid = nil;
    if (shouldEnqueue) {
        newid = [self.persitence addUnsavedEntity:entity route:route collection:collection method:method headers:headers];
        if (newid != nil) {
            DELEGATEMETHOD(didEnqueueObject:inCollection:) {
                [_delegate didEnqueueObject:newid inCollection:collection];
            }
        }
    }
    return newid;
}

- (BOOL) removeObject:(id)object objKey:(NSString*)key route:(NSString*)route collection:(NSString*)collection headers:(NSDictionary*)headers method:(NSString*)method error:(NSError*)error
{
    BOOL shouldEnqueue = YES;
    DELEGATEMETHOD(shouldEnqueueObject:inCollection:onError:) {
        shouldEnqueue = [_delegate shouldEnqueueObject:object inCollection:collection onError:error];
    }
    
    BOOL added = NO;
    if (shouldEnqueue) {
        added = [self.persitence addUnsavedDelete:key route:route collection:collection method:method headers:headers];
        if (added) {
            DELEGATEMETHOD(didEnqueueObject:inCollection:) {
                [_delegate didEnqueueObject:object inCollection:collection];
            }
        }
    }
    return added;
}

@end
