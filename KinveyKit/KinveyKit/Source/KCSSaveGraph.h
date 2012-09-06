//
//  KCSSaveGraph.h
//  KinveyKit
//
//  Created by Michael Katz on 9/6/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KCSSerializedObject;
@class KCSResource;
@protocol KCSPersistable;

typedef void(^KCSCompletionWrapperBlock_t)();

@interface KCSCompletionWrapper : NSObject
{
    NSMutableArray* _references;
    NSMutableArray* _waitingBlocks;
    NSMutableArray* _resaveBlocks;
    NSMutableArray* _resaveWaiters;
    KCSCompletionWrapperBlock_t _doAfterWaitingResave;
}
@property (nonatomic) double size;
@property (nonatomic) double pc;
@property (nonatomic) uint type;
@property (nonatomic, readonly) NSArray* references;
@property (nonatomic, retain) id handle;
@property (atomic) BOOL loading;
@property (atomic) BOOL done;
@property (atomic) uint resaveCount;
@property (atomic, readonly, retain) NSMutableSet* waitingObjects;
@property (atomic, readonly, retain) NSMutableArray* waitingBlocks;

- (void) finished;
- (void) resaveComplete;
- (void) ifNotLoaded:(KCSCompletionWrapperBlock_t)noloadedBlock otherwiseWhenLoaded:(KCSCompletionWrapperBlock_t)loadedBlock andResaveAfterReferencesSaved:(KCSCompletionWrapperBlock_t)resaveBlock;
- (void) doAfterWaitingResaves:(KCSCompletionWrapperBlock_t)doAfterBlock;
@end

@interface KCSSaveGraph : NSObject
{
    NSMutableArray* _resourceSeen;
    double _totalBytes;
    NSMutableSet* _entitySeen;
}

@property (nonatomic, readonly, getter = percentDone) double percentDone;

- (id) initWithEntityCount:(NSUInteger)entityCount;

- (id) markEntity:(KCSSerializedObject*)serializedObj;
- (id) addReference:(id<KCSPersistable>)reference entity:(KCSCompletionWrapper*)wp;
- (id) addResource:(KCSResource*)resource entity:(KCSCompletionWrapper*)wp;
- (void) tell:(id)reference toWaitForResave:(id)referer;
@end
