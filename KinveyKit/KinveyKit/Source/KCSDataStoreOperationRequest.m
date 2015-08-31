//
//  KCSDataStoreOperationRequest.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-31.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KCSDataStoreOperationRequest.h"

@implementation KCSDataStoreOperationRequest

+(instancetype)requestWithDataStoreOperation:(DataStoreOperation *)dataStoreOperation
{
    return [[self alloc] initWithDataStoreOperation:dataStoreOperation];
}

-(instancetype)initWithDataStoreOperation:(DataStoreOperation *)dataStoreOperation
{
    self = [super init];
    if (self) {
        self.dataStoreOperation = dataStoreOperation;
    }
    return self;
}

-(BOOL)isCancelled
{
    @synchronized (self) {
        return self.dataStoreOperation.isCancelled || self.request.isCancelled;
    }
}

-(void)cancel
{
    @synchronized (self) {
        self.dataStoreOperation.completionBlock = nil;
        [self.dataStoreOperation cancel];
        
        [self.request cancel];
        
        [super cancel];
    }
}

@end
