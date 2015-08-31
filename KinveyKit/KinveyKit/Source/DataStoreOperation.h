//
//  DataStoreOperation.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-31.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataStoreOperation : NSOperation

@property (nonatomic, copy) dispatch_block_t block;
@property (nonatomic) BOOL executing;
@property (nonatomic) BOOL finished;

@end
