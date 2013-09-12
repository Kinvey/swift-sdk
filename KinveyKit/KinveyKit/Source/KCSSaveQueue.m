//
//  SaveQueue.m
//  KinveyKit
//
//  Created by Michael Katz on 8/7/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
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


#import "KCSSaveQueue.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import <objc/runtime.h>

#import "KCSObjectMapper.h"
#import "KinveyCollection.h"
#import "KinveyEntity.h"
#import "KinveyErrorCodes.h"
#import "KinveyPersistable.h"
#import "KCSLogManager.h"
#import "NSDate+ISO8601.h"
#import "KCSReachability.h"

@interface KCSClient (KCSSaveQueue)
- (id) kinveyDomain;
@end

@protocol KCSSaveQueueUpdateDelegate <NSObject>
- (void)queueUpdated;
@end

@interface KCSSaveQueue () <KCSPersistableDelegate, NSCoding> 
@property (nonatomic, strong) KCSCollection* collection;
@property (nonatomic, strong) NSMutableArray* q;
@property (nonatomic, unsafe_unretained) id<KCSSaveQueueUpdateDelegate> updateDelegate;
- (void) saveNext;
@end


@interface KCSSaveQueues : NSObject <KCSSaveQueueUpdateDelegate> {
    NSMutableDictionary* _queues;
}

+ (KCSSaveQueues*)sharedQueues;

@end
@implementation KCSSaveQueues

static KCSSaveQueues* sQueues;

static BOOL sFirstReached;

+ (KCSSaveQueues*)sharedQueues
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sQueues = [[KCSSaveQueues alloc] init];
        [sQueues restoreQueues];
        sFirstReached = NO;
    });
    return sQueues;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _queues = [NSMutableDictionary dictionary];
    }
    return self;
}

- (KCSSaveQueue*)queueForCollection:(KCSCollection*)collection identifier:(NSString*)queueIdentifier
{
    KCSSaveQueue* q = nil;
    @synchronized(self) {
        q = [_queues objectForKey:queueIdentifier];
        if (!q) {
            q = [[KCSSaveQueue alloc] init];
            q.collection = collection;
            [_queues setObject:q forKey:queueIdentifier];
            q.updateDelegate = self;
        }
    }
    return q;
}
- (NSString*) savefile
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString* filename = [NSString stringWithFormat:@"com.kinvey.%@.abc", [KCSClient sharedClient].appKey];
    NSString *cacheFile = [documentsDirectory stringByAppendingPathComponent:filename];
    return cacheFile;
}

- (NSDictionary*) cachedQueues
{
    NSData* d = [NSData dataWithContentsOfFile:[self savefile]];
    if (d == nil || d.length == 0) {
        return @{};
    }
    NSKeyedUnarchiver* ua = [[NSKeyedUnarchiver alloc] initForReadingWithData:d];
    NSDictionary* dict = @{};
    @try {
        dict = [ua decodeObject];
    }
    @catch (NSException *exception) {
        KCSLogError(@"error restoring queues: %@",exception);
    }
    return dict;
}

- (void) restoreQueues
{
    NSDictionary* qs = [self cachedQueues];
    _queues = [NSMutableDictionary dictionaryWithDictionary:qs];
    for (KCSSaveQueue* q in [_queues allValues]) {
        q.updateDelegate = self;
        dispatch_async(dispatch_get_current_queue(), ^{
            [q saveNext];
        });
    }
}

- (void) persistQueues
{
    NSMutableData* data = [NSMutableData data];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:_queues];
    [archiver finishEncoding];
    NSError* error = nil;
    //TODO: enable security
    [data writeToFile:[self savefile] options:NSDataWritingAtomic error:&error];
    if (error) {
        KCSLogError(@"error saving queues %@", error);
    }
}

- (void) doSave
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [self persistQueues];
    });
}

- (void) queueUpdated
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doSave) object:nil];
    [self performSelector:@selector(doSave) withObject:nil afterDelay:0.1];
}

@end


@implementation KCSSaveQueueItem
- (instancetype) initWithObject:(id<KCSPersistable>)obj
{
    self = [super init];
    if (self) {
        _object = obj;
        _mostRecentSaveDate = [NSDate date];
    }
    return self;
}


- (BOOL)isEqual:(id)other
{
    //objects are equal if their ids are equal, or if there is no id, if the objects themselves are equal. This preserves the set integrity if an object is saved twice but the first save never went through and id hasn't been assigned.
    BOOL isASaveItem = [other isKindOfClass:[KCSSaveQueueItem class]];
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
        for (KCSSaveQueueItem* item in self) {
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


@implementation KCSSaveQueue

+ (KCSSaveQueue*) saveQueueForCollection:(KCSCollection*)collection uniqueIdentifier:(NSString*)identifier
{
    return [[KCSSaveQueues sharedQueues] queueForCollection:collection identifier:identifier];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _q = [NSMutableArray array];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(online:) name:KCSReachabilityChangedNotification object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willBackground:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    if (self) {
        NSString* cn = [aDecoder decodeObjectForKey:@"cn"];
        NSString* cc = [aDecoder decodeObjectForKey:@"cc"];
        NSArray* o = [aDecoder decodeObjectForKey:@"o"];
        Class klass = NSClassFromString(cc);
        self.collection = [KCSCollection collectionFromString:cn ofClass:klass];
        
        for (NSDictionary* d in o) {
            NSDate* date = [NSDate dateFromISO8601EncodedString:[d objectForKey:@"d"]];
            NSDictionary* p = [d objectForKey:@"i"];
            id<KCSPersistable> obj = [KCSObjectMapper makeObjectOfType:klass withData:p];
            KCSSaveQueueItem* item = [[KCSSaveQueueItem alloc] init];
            item.object = obj;
            item.mostRecentSaveDate = date;
            [_q addObject:item];
        }
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.collection.collectionName forKey:@"cn"];
    Class template = self.collection.objectTemplate;
    const char* tname = class_getName(template);
    NSString* className = [NSString stringWithCString: tname encoding:NSUTF8StringEncoding];
    [aCoder encodeObject:className forKey:@"cc"];
    
    NSMutableArray* objs = [NSMutableArray arrayWithCapacity:_q.count];
    for (KCSSaveQueueItem* i in _q) {
        NSDictionary *d = @{ @"d" : [i.mostRecentSaveDate stringWithISO8601Encoding], //TODO: handle errors
        @"i" : [KCSObjectMapper makeKinveyDictionaryFromObject:i.object error:NULL].dataToSerialize
        };
        [objs addObject:d];
    }
    [aCoder encodeObject:objs forKey:@"o"];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KCSReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

- (void) addObject:(id<KCSPersistable>)obj
{
    KCSSaveQueueItem* item = [[KCSSaveQueueItem alloc] initWithObject:obj];
    @synchronized(_q) {
        [_q addObject:item];
    }
    [self.updateDelegate queueUpdated];
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

- (void) removeItem:(KCSSaveQueueItem*)item
{
    [_q removeObject:item];
    [self.updateDelegate queueUpdated];
}

- (void) removeFirstItem
{
    if (_q.count > 0) {
        [_q removeObjectAtIndex:0];
        [self.updateDelegate queueUpdated];
    }
}

#pragma mark - respond to events

- (void) online:(NSNotification*)note
{
    sFirstReached = YES;
    KCSReachability* reachability = [note object];
    if (reachability.isReachable == YES) {
        [self saveNext];
    }
}

//- (void) invalidateBgTask
//{
//    UIApplication* application = [UIApplication sharedApplication];
//    [application endBackgroundTask:_bgTask];
//    _bgTask = UIBackgroundTaskInvalid;
//}
//
//- (void) willBackground:(NSNotification*)note
//{
//    UIApplication* application = [UIApplication sharedApplication];
//    _bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
//        // Clean up any unfinished task business by marking where you.
//        // stopped or ending the task outright.
//        [self invalidateBgTask];
//    }];
//}

- (void) didBecomeActive:(NSNotification*)note
{
    [self saveNext];
}

#pragma mark - Save Stuff
- (id<KCSPersistable>) objForItem: (KCSSaveQueueItem*) item
{
    return item.object;
}

- (void) saveNext
{
    if ((sFirstReached && [[KCSClient sharedClient].kinveyReachability isReachable] == NO) ||
        [UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }

    if ([self count] > 0) {
        KCSSaveQueueItem* item = [_q objectAtIndex:0];
        id obj = [self objForItem:item];
        if (_delegate && [_delegate respondsToSelector:@selector(shouldSave:lastSaveTime:)]) {
            //test the delegate, if available
            if ([_delegate shouldSave:obj lastSaveTime:item.mostRecentSaveDate]) {
                [self saveObject:item];
            } else {
                [self removeItem:item];
            }
        } else {
            //otherwise client doesn't care about shouldSave: and then we should default the save
            [self saveObject:item];
        }
    }
}

- (void) saveObject:(KCSSaveQueueItem*)item
{
    id<KCSPersistable> obj = [self objForItem:item];
    if (_delegate && [_delegate respondsToSelector:@selector(willSave:lastSaveTime:)]) {
        [_delegate willSave:obj lastSaveTime:item.mostRecentSaveDate];
    }
    [obj saveToCollection:_collection withDelegate:self];
    
}
//TODO: blob saves
//TODO: kinveyrefs

#pragma mark - Persistable Delegate
- (void)entity:(id)entity operationDidCompleteWithResult:(NSObject *)result
{
    [self removeFirstItem]; //pop off the stack
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
            [self removeFirstItem]; //pop off the stack
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
