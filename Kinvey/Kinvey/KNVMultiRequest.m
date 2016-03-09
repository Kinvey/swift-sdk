//
//  KNVMultiRequest.m
//  Kinvey
//
//  Created by Victor Barros on 2016-02-23.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KNVMultiRequest.h"

@interface KNVMultiRequest ()

@property (nonatomic, strong) NSMutableArray<id<KNVRequest>>* requests;
@property (nonatomic) BOOL canceled;

@end

@implementation KNVMultiRequest

-(void)addRequest:(id<KNVRequest>)request
{
    if (self.canceled) {
        [request cancel];
    }
    [self.requests addObject:request];
}

-(BOOL)executing
{
    for (id<KNVRequest> request in self.requests) {
        if ([request executing]) {
            return YES;
        }
    }
    return NO;
}

-(BOOL)canceled
{
    for (id<KNVRequest> request in self.requests) {
        if ([request canceled]) {
            return YES;
        }
    }
    return _canceled;
}

-(void)cancel
{
    self.canceled = YES;
    for (id<KNVRequest> request in self.requests) {
        [request cancel];
    }
}

@end