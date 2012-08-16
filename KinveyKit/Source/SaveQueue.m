//
//  SaveQueue.m
//  KinveyKit
//
//  Created by Michael Katz on 8/7/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "SaveQueue.h"

#import <UIKit/UIKit.h>

#import "KCSObjectMapper.h"
#import "KCSReachability.h"
#import "KinveyCollection.h"
#import "KinveyEntity.h"
#import "KinveyErrorCodes.h"
#import "KinveyPersistable.h"

@interface SaveQueue () <KCSPersistableDelegate> {
    NSMutableArray* _q;
    id<KCSOfflineSaveDelegate> _delegate;
    UIBackgroundTaskIdentifier _bgTask;
}
@property (nonatomic, retain) KCSCollection* collection;
@end


@interface KCSSaveQueues : NSObject {
    NSMutableDictionary* _queues;
}

+ (KCSSaveQueues*)sharedQueues;

- (SaveQueue*)queueForCollection:(KCSCollection*)collection;

@end
@implementation KCSSaveQueues

static KCSSaveQueues* sQueues;

+ (KCSSaveQueues*)sharedQueues
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sQueues = [[KCSSaveQueues alloc] init];
    });
    return sQueues;
}

- (id) init
{
    self = [super init];
    if (self) {
        _queues = [[NSMutableDictionary dictionary] retain];
    }
    return self;
}

- (void) dealloc
{
    [_queues removeAllObjects];
    [_queues release];
    [super dealloc];
}

- (SaveQueue*)queueForCollection:(KCSCollection*)collection
{
    SaveQueue* q = nil;
    @synchronized(self) {
        q = [_queues objectForKey:collection.collectionName];
        if (!q) {
            q = [[[SaveQueue alloc] init] autorelease];
            q.collection = collection;
            [_queues setObject:q forKey:collection.collectionName];
        }
    }
    return q;
}

@end


@implementation SaveQueueItem
@synthesize mostRecentSaveDate, object;
- (id) initWithObject:(id<KCSPersistable>)obj
{
    self = [super init];
    if (self) {
        object = [obj retain];
        mostRecentSaveDate = [[NSDate date] retain];
    }
    return self;
}

- (void) dealloc
{
    [mostRecentSaveDate release];
    [object release];
    [super dealloc];
}

- (BOOL)isEqual:(id)other
{
    //objects are equal if their ids are equal, or if there is no id, if the objects themselves are equal. This preserves the set integrity if an object is saved twice but the first save never went through and id hasn't been assigned.
    BOOL isASaveItem = [other isKindOfClass:[SaveQueueItem class]];
    BOOL idsEqual = [self objectId] != nil && [other objectId] != nil && [[self objectId] isEqualToString:[other objectId]];
    BOOL objectsEqual = [self.object isEqual:[other object]];
    return isASaveItem && (idsEqual || objectsEqual);
}

- (NSString*) objectId
{
    return [(NSObject*)self.object kinveyObjectId];
}

- (NSUInteger)hash
{
    return [[self objectId] hash];
}

@end

@interface NSMutableArray (SaveQueue)
- (NSArray*) ids;
@end
@implementation NSMutableArray (SaveQueue)
- (NSArray*) ids
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:self.count];
    @synchronized(self) {
        for (SaveQueueItem* item in self) {
            NSString* objId = [item objectId];
            [array addObject:objId != nil ? objId : [NSNull null]];
        }
    }
    return array;
}

- (void) insertItem:(id)item
{
    // using the above sense of equals, this moves resaved items to the back of the queue
    if ([self containsObject:item]) {
        [self removeObject:item];
    }
    [self addObject:item];
}
@end


@implementation SaveQueue
@synthesize delegate = _delegate;
@synthesize collection = _collection;

+ (SaveQueue*) saveQueueForCollection:(KCSCollection*)collection
{
    return [[KCSSaveQueues sharedQueues] queueForCollection:collection];
}

- (id)init
{
    self = [super init];
    if (self) {
        _q = [[NSMutableArray array] retain];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(online:) name:kKCSReachabilityChangedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willBackground:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kKCSReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
    [_q release];
    [_collection release];
    [super dealloc];
}

- (void) addObject:(id<KCSPersistable>)obj
{
    SaveQueueItem* item = [[SaveQueueItem alloc] initWithObject:obj];
    @synchronized(_q) {
        [_q addObject:item];
    }
    [item release];
}

- (NSArray*) ids
{
    return [_q ids];
}

- (NSArray *)array
{
    return [NSArray arrayWithArray:_q];
}

- (NSUInteger) count
{
    NSUInteger count = 0;
    @synchronized(_q) {
        count = [_q count];
    }
    return count;
}

//- (SaveQueueItem*) pop //must check count first
//{
//    SaveQueueItem* item = nil;
//    @synchronized(_q) {
//        item = [_q objectAtIndex:0];
//        [_q removeObjectAtIndex:0];
//    }
//    return item;
//}

- (void) removeItem:(SaveQueueItem*)item
{
    [_q removeObject:item];
}

#pragma mark - respond to events

- (void) online:(NSNotification*)note
{
    KCSReachability* reachability = [note object];
    if (reachability.isReachable == YES) {
        [self saveNext];
    }
}

- (void) invalidateBgTask
{
    UIApplication* application = [UIApplication sharedApplication];
    [application endBackgroundTask:_bgTask];
    _bgTask = UIBackgroundTaskInvalid;
}

- (void) willBackground:(NSNotification*)note
{
    UIApplication* application = [UIApplication sharedApplication];
    _bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        // Clean up any unfinished task business by marking where you.
        // stopped or ending the task outright.
        //TODO: [self.connection cancel];
        [self invalidateBgTask];
    }];
}

- (void) didBecomeActive:(NSNotification*)note
{
    [self saveNext];
}

#pragma mark - Save Stuff
- (id<KCSPersistable>) objForItem: (SaveQueueItem*) item
{
    return item.object;
}

- (void) saveNext
{
    if ([KCSClient sharedClient].kinveyReachability.isReachable == NO ||
        [UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
    if ([self count] > 0) {
        SaveQueueItem* item = [_q objectAtIndex:0];
        id obj = [self objForItem:item];
        if (_delegate && [_delegate respondsToSelector:@selector(shouldSave:lastSaveTime:)]) {
            //test the delegate, if available
            if ([_delegate shouldSave:obj lastSaveTime:item.mostRecentSaveDate]) {
                [self saveObject:item];
            }
        } else {
            //otherwise client doesn't care about shouldSave: and then we should default the save
            [self saveObject:item];
        }
    }
}

- (void) saveObject:(SaveQueueItem*)item
{
    id<KCSPersistable> obj = [self objForItem:item];
    if (_delegate && [_delegate respondsToSelector:@selector(willSave:lastSaveTime:)]) {
        [_delegate willSave:obj lastSaveTime:item.mostRecentSaveDate];
    }
    [obj saveToCollection:_collection withDelegate:self];

}
//TODO: blob saves
//TODO: kinveyrefs
//TODO: kickoff saves on app restore and with reachability

#pragma mark - Persistable Delegate
- (void)entity:(id)entity operationDidCompleteWithResult:(NSObject *)result
{
    [_q removeObjectAtIndex:0]; //pop off the stack
    //result is json dictionary
    if (_delegate && [_delegate respondsToSelector:@selector(didSave:)]) {
        [_delegate didSave:entity];
    }
    [self saveNext];
}

- (void)entity:(id)entity operationDidFailWithError:(NSError *)error
{
    if (error) {
        if ([error.domain isEqualToString:KCSAppDataErrorDomain]) {
            //KCS Error
            [_q removeObjectAtIndex:0]; //pop off the stack
            if (_delegate && [_delegate respondsToSelector:@selector(errorSaving:error:)]) {
                [_delegate errorSaving:entity error:error];
            }
            [self saveNext];
        } else {
            //Other error, like networking
            //requeue error
            [self saveNext];
        }
    }
}
@end
