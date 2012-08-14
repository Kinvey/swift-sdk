//
//  SaveQueue.m
//  KinveyKit
//
//  Created by Michael Katz on 8/7/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "SaveQueue.h"

#import "KCSObjectMapper.h"
#import "KCSReachability.h"

@interface SaveQueue () {
    NSMutableOrderedSet* _q;
}
@property (nonatomic, copy) NSString* collectionName;
@end


@interface KCSSaveQueues : NSObject {
    NSMutableDictionary* _queues;
}

+ (KCSSaveQueues*)sharedQueues;

- (SaveQueue*)queueForCollection:(NSString*)collection;

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

- (SaveQueue*)queueForCollection:(NSString*)collection
{
    SaveQueue* q = nil;
    @synchronized(self) {
        q = [_queues objectForKey:collection];
        if (!q) {
            q = [[[SaveQueue alloc] init] autorelease];
            q.collectionName = collection;
            [_queues setObject:q forKey:collection];
        }
    }
    return q;
}

@end


@implementation SaveQueueItem
@synthesize mostRecentSaveDate, object;



- (id) initWithObject:(KCSSerializedObject*)obj
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

- (BOOL)isEqual:(id)obj
{
    return [object isKindOfClass:[SaveQueueItem class]] &&
    [self objectId] != nil &&
    [obj objectId] != nil &&
    [[self objectId] isEqual:[obj objectId]];
}

- (NSString*) objectId
{
    return [object objectId];
}

- (NSUInteger)hash
{
    return [[self objectId] hash];
}

@end

@interface NSMutableOrderedSet (SaveQueue)
- (NSArray*) ids;
@end
@implementation NSMutableOrderedSet (SaveQueue)
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
@end


@implementation SaveQueue
@synthesize delegate = _delegate;
@synthesize collectionName = _collectionName;

+ (SaveQueue*) saveQueueForCollection:(NSString*)collectionName
{
    return [[KCSSaveQueues sharedQueues] queueForCollection:collectionName];
}

- (id)init
{
    self = [super init];
    if (self) {
        _q = [[NSMutableOrderedSet orderedSet] retain];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(online:) name:kKCSReachabilityChangedNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kKCSReachabilityChangedNotification object:nil];
    [_q release];
    [_collectionName release];
    [super dealloc];
}

- (void) addObject:(KCSSerializedObject*)obj
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

- (NSOrderedSet *)set
{
    return _q;
}

- (NSUInteger) count
{
    NSUInteger count = 0;
    @synchronized(_q) {
        count = [_q count];
    }
    return count;
}

- (SaveQueueItem*) pop //must check count first
{
    SaveQueueItem* item = nil;
    @synchronized(_q) {
        item = [_q objectAtIndex:0];
        [_q removeObjectAtIndex:0];
    }
    return item;
}

- (void) online:(NSNotification*)note
{
    KCSReachability* reachability = [note object];
    if (reachability.isReachable == YES) {
        [self startSaving];
    }
}

#pragma mark - Save Stuff
- (void) startSaving
{
    if ([self count] > 0) {
        SaveQueueItem* item = [self pop];
    //tODO:    [KCSObjectMapper makeObjectOfType:self.backingCollection.objectTemplate withData:dictValue]
        id<KCSPersistable> obj = nil; //TODO
        if (_delegate && [_delegate respondsToSelector:@selector(shouldSave:lastSaveTime:)]) {
            //test the delegate, if available
            if ([_delegate shouldSave:obj lastSaveTime:item.mostRecentSaveDate]) {
                [self saveObject:obj];
            }
        } else {
            //otherwise client doesn't care about shouldSave: and then we should default the save
            [self saveObject:obj];
        }
    }
}

- (void) saveObject:(id<KCSPersistable>)obj
{
    
}
@end
