//
//  KCSAppdataStore.m
//  KinveyKit
//
//  Created by Brian Wilson on 5/1/12.
//  Copyright (c) 2012-2014 Kinvey. All rights reserved.
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

#import "KCSAppdataStore.h"

#import "KCSObjectCache.h"
#import "EXTScope.h"



@interface DataStoreOperation : NSOperation
@property (nonatomic, copy) dispatch_block_t block;
@property (nonatomic) BOOL executing;
@property (nonatomic) BOOL finished;
@end

@implementation DataStoreOperation

- (void)start
{
    [self setExecuting:YES];
    _block();
}

- (BOOL)isConcurrent
{
    return NO;
}

- (BOOL)isReady
{
    return YES;
}

- (BOOL)isCancelled
{
    return NO;
}

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing
{
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isExecuting
{
    return _executing;
}

- (BOOL)isFinished
{
    return _finished;
}
@end

@interface KCSBackgroundAppdataStore()
@end

@implementation KCSAppdataStore

static NSOperationQueue* queue;

+ (void)initialize
{
    queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 5;
    [queue setName:@"com.kinvey.KinveyKit.DataStoreQueue"];
}


+ (KCSObjectCache*)caches
{
    static KCSObjectCache* sDataCaches;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sDataCaches = [[KCSObjectCache alloc] init];
    });
    return sDataCaches;
}

+ (instancetype) storeWithCollection:(KCSCollection*)collection options:(NSDictionary*)options;
{
    return [super storeWithCollection:collection options:options];
}

+ (instancetype)storeWithCollection:(KCSCollection*)collection authHandler:(KCSAuthHandler *)authHandler withOptions: (NSDictionary *)options
{
    return [super storeWithCollection:collection authHandler:authHandler withOptions:options];
}

- (void)loadObjectWithID: (id)objectID
     withCompletionBlock: (KCSCompletionBlock)completionBlock
       withProgressBlock: (KCSProgressBlock)progressBlock;
{
    if (objectID == nil) {
        [[NSException exceptionWithName:NSInvalidArgumentException reason:@"objectId is `nil`." userInfo:nil] raise];
    }
    
    DataStoreOperation* op = [[DataStoreOperation alloc] init];
    @weakify(op);
    op.block = ^{
        [super loadObjectWithID:objectID withCompletionBlock:^(NSArray* obj, NSError* error){
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(obj, error);
            });
            @strongify(op);
            op.finished = YES;
        } withProgressBlock:progressBlock];
    };
    [queue addOperation:op];
}

- (void)queryWithQuery:(id)query withCompletionBlock: (KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    
    DataStoreOperation* op = [[DataStoreOperation alloc] init];
    @weakify(op);
    op.block = ^{
        [super queryWithQuery:query withCompletionBlock:^(NSArray* obj, NSError* error){
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(obj, error);
            });
            @strongify(op);
            op.finished = YES;
        } withProgressBlock:progressBlock];
    };
    [queue addOperation:op];
}

- (void)group:(id)fieldOrFields reduce:(KCSReduceFunction *)function condition:(KCSQuery *)condition completionBlock:(KCSGroupCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    DataStoreOperation* op = [[DataStoreOperation alloc] init];
    @weakify(op);
    op.block = ^{
        [super group:fieldOrFields reduce:function condition:condition completionBlock:^(KCSGroup* valuesOrNil, NSError* errorOrNil){
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(valuesOrNil, errorOrNil);
            });
            @strongify(op);
            op.finished = YES;
        } progressBlock:progressBlock];
    };
    [queue addOperation:op];
}

- (void)group:(id)fieldOrFields reduce:(KCSReduceFunction *)function completionBlock:(KCSGroupCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    [self group:fieldOrFields reduce:function condition:[KCSQuery query] completionBlock:completionBlock progressBlock:progressBlock];
}

- (void)saveObject:(id)object withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock
{
    DataStoreOperation* op = [[DataStoreOperation alloc] init];
    @weakify(op);
    op.block = ^{
        [super saveObject:object withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(objectsOrNil, errorOrNil);
            });
            @strongify(op);
            op.finished = YES;
        } withProgressBlock:progressBlock];
    };
    [queue addOperation:op];
}

- (void) removeObject:(id)object withCompletionBlock:(KCSCountBlock)completionBlock withProgressBlock:(KCSProgressBlock)progressBlock
{
    DataStoreOperation* op = [[DataStoreOperation alloc] init];
    @weakify(op);
    op.block = ^{
        [super removeObject:object withCompletionBlock:^(unsigned long count, NSError *errorOrNil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionBlock(count, errorOrNil);
            });
            @strongify(op);
            op.finished = YES;
       } withProgressBlock:progressBlock];
    };
    [queue addOperation:op];
}

#pragma mark - Information
- (void)countWithBlock:(KCSCountBlock)countBlock
{
    [self countWithQuery:nil completion:countBlock];
}

- (void)countWithQuery:(KCSQuery*)query completion:(KCSCountBlock)countBlock
{
    DataStoreOperation* op = [[DataStoreOperation alloc] init];
    @weakify(op);
    op.block = ^{
        [super countWithQuery:query completion:^(unsigned long count, NSError *errorOrNil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                countBlock(count, errorOrNil);
            });
            @strongify(op);
            op.finished = YES;
      }];
    };
    [queue addOperation:op];
}

@end
