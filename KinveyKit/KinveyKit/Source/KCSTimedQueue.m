//
//  KCSTimedQueue.m
//  KinveyKit
//
//  Created by Michael Katz on 10/29/13.
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


#import "KCSTimedQueue.h"

@interface KCSTimedQueueObjWrapper : NSObject
@property (nonatomic, strong) NSDate* date;
@property (nonatomic, strong) id obj;
@end

@implementation KCSTimedQueueObjWrapper

+ (instancetype) wrap:(id)obj
{
    KCSTimedQueueObjWrapper* w = [[KCSTimedQueueObjWrapper alloc] init];
    w.date = [NSDate date];
    w.obj = obj;
    return w;
}

@end

@interface KCSTimedQueue ()
@property (nonatomic, strong) NSMutableArray* queue;

@end

@implementation KCSTimedQueue

- (id)init
{
    self = [super init];
    if (self) {
        _queue = [NSMutableArray array];
    }
    return self;
}

- (id)pop
{
    if (_queue.count == 0) {
        return nil;
    }
    id obj = [_queue[0] obj];
    [_queue removeObjectAtIndex:0];
    return obj;
}


- (void)push:(id)obj
{
    [_queue addObject:[KCSTimedQueueObjWrapper wrap:obj]];
}

- (NSUInteger)count
{
    return self.queue.count;
}

@end
