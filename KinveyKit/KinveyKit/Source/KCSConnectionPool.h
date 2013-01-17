//
//  KCSConnectionPool.h
//  KinveyKit
//
//  Copyright (c) 2008-2012, Kinvey, Inc. All rights reserved.
//
//  This software contains valuable confidential and proprietary information of
//  KINVEY, INC and is subject to applicable licensing agreements.
//  Unauthorized reproduction, transmission or distribution of this file and its
//  contents is a violation of applicable laws.

#import <Foundation/Foundation.h>

@class KCSConnection;

@interface KCSConnectionPool : NSObject

// Known Connection types
+ (KCSConnection *)asyncConnection;

// Arbitrary Connection types
+ (KCSConnection *)connectionWithConnectionType: (Class)connectionClass;

// Singleton Access
+ (KCSConnectionPool *)sharedPool;


#pragma mark - Pool management

// Fill pools with default types
- (void)fillPools;

// Fill pools with specific types
- (void)fillAsyncPoolWithConnections: (Class)connectionClass;

- (void)topPoolsWithConnection: (KCSConnection *)connection;

// Empty all pools
- (void)drainPools;


@end
