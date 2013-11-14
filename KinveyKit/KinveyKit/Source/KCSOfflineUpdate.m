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
@property (nonatomic, weak) KCSEntityPersistence* cache;

@end

@implementation KCSOfflineUpdate


- (id) initWithCache:(KCSEntityPersistence*)cache
{
    self = [super init];
    if (self) {
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
    [self drainQueue];
}

- (void) stop
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reach:(NSNotification*)note
{
    KCSReachability* reachability = note.object;
    if (reachability.isReachable == YES) {
        [self drainQueue];
    }
}

- (void)hadASucessfulConnection
{
    [self drainQueue];
}

//TODO test at persistence
//TODO test at cache
//TODO start when credentials are added : clear on logout - so we can have data before login

- (NSUInteger) count
{
    return [self.cache unsavedCount];
}

- (void) drainQueue
{
    if (_delegate) {
        NSArray* unsavedEntities = [self.cache unsavedEntities];
        for (NSDictionary* d in unsavedEntities) {
            [self process:d];
        }
    }
}

- (void)setDelegate:(id<KCSOfflineUpdateDelegate>)delegate
{
    _delegate = delegate;
    [self drainQueue];
}

#pragma mark - saveProcess
#warning make sure cannot restart in the middle
#warning TODO separate deletes and saves
- (void) process:(NSDictionary*)saveInfo
{
    NSString* objId = saveInfo[KCSEntityKeyId];
    NSString* route = saveInfo[@"route"];
    NSString* collection = saveInfo[@"collection"];
    NSDate* lastSaveTime = saveInfo[@"time"];

    BOOL shouldSave = YES;
    DELEGATEMETHOD(shouldSaveObject:inCollection:lastAttemptedSaveTime:) {
        shouldSave = [_delegate shouldSaveObject:objId inCollection:collection lastAttemptedSaveTime:lastSaveTime];
    }
    if (shouldSave == YES) {
        NSDictionary* entity = saveInfo[@"obj"];
        NSString* method = saveInfo[@"method"];
        NSDictionary* headers = saveInfo[@"headers"];
        [self save:objId entity:entity route:route collection:collection headers:headers method:method];
    } else {
        [self.cache removeUnsavedEntity:objId route:route collection:collection];
    }
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
    
    NSMutableDictionary* options = [NSMutableDictionary dictionary];
    if (self.useMock) {
        options[KCSRequestOptionUseMock] = @YES;
    }
    if (headers[KCSRequestOptionClientMethod]) {
        options[KCSRequestOptionClientMethod] = headers[KCSRequestOptionClientMethod];
    }
    
    KCSRequest2* request = [KCSRequest2 requestWithCompletion:^(KCSNetworkResponse *response, NSError *error) {
        if (!error) {
            [self.cache removeUnsavedEntity:objId route:route collection:collection];
            DELEGATEMETHOD(didSaveObject:inCollection:) {
#warning update object
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

#pragma mark - objects
- (NSString*) addObject:(NSDictionary*)entity route:(NSString*)route collection:(NSString*)collection headers:(NSDictionary*)headers method:(NSString*)method error:(NSError*)error
{
    BOOL shouldEnqueue = YES;
    DELEGATEMETHOD(shouldEnqueueObject:inCollection:onError:) {
        shouldEnqueue = [_delegate shouldEnqueueObject:KCSEntityKeyId inCollection:collection onError:error];
    }
    
    NSString* newid = nil;
    if (shouldEnqueue) {
        //TODO need to give id?
        newid = [self.cache addUnsavedEntity:entity route:route collection:collection method:method headers:headers];
        if (newid != nil) {
            DELEGATEMETHOD(didEnqueueObject:inCollection:) {
                [_delegate didEnqueueObject:newid inCollection:collection];
            }
        }
    }
    return newid;
}

@end
