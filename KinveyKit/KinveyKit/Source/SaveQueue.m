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
#import "KinveyCollection.h"
#import "KinveyEntity.h"
#import "KinveyErrorCodes.h"
#import "KinveyPersistable.h"

@interface SaveQueue () <KCSPersistableDelegate> {
    NSMutableOrderedSet* _q;
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
    return [other isKindOfClass:[SaveQueueItem class]] &&
    [self objectId] != nil &&
    [other objectId] != nil &&
    [[self objectId] isEqualToString:[other objectId]];
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
@synthesize collection = _collection;

+ (SaveQueue*) saveQueueForCollection:(KCSCollection*)collection
{
    return [[KCSSaveQueues sharedQueues] queueForCollection:collection];
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
- (id<KCSPersistable>) objForItem: (SaveQueueItem*) item
{
    //tODO:    [KCSObjectMapper makeObjectOfType:self.backingCollection.objectTemplate withData:dictValue]
    id<KCSPersistable> obj = nil; //TODO
    return obj;
}

- (void) startSaving
{
    if ([self count] > 0) {
        SaveQueueItem* item = [self pop];
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
    //result is json dictionary
    
    if (_delegate && [_delegate respondsToSelector:@selector(didSave:)]) {
        [_delegate didSave:entity];
    }
}

- (void)entity:(id)entity operationDidFailWithError:(NSError *)error
{
    if (error) {
        if ([error.domain isEqualToString:KCSAppDataErrorDomain]) {
            //KCS Error
            if (_delegate && [_delegate respondsToSelector:@selector(errorSaving:error:)]) {
                [_delegate errorSaving:entity error:error];
            }
        } else {
            //Other error, like networking
            //requeue error
            [self addObject:entity]; //TODO: use serialized obj
        }
    }
}
@end
