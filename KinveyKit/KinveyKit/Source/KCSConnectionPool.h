//
//  KCSConnectionPool.h
//  KinveyKit
//
//  Copyright (c) 2008-2011, Kinvey, Inc. All rights reserved.
//
//  This software contains valuable confidential and proprietary information of
//  KINVEY, INC and is subject to applicable licensing agreements.
//  Unauthorized reproduction, transmission or distribution of this file and its
//  contents is a violation of applicable laws.

#import <Foundation/Foundation.h>

@class KCSConnection;

@interface KCSConnectionPool : NSObject

+ (KCSConnection *)asyncConnection;

+ (KCSConnection *)syncConnection;


+ (KCSConnection *)connectionWithConnectionType: (Class)connectionClass;

+ (void)drainPools;


@end
