//
//  KCSConnectionPool.h
//  KinveyKit
//
//  Created by Brian Wilson on 11/28/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KCSConnection;

@interface KCSConnectionPool : NSObject

+ (KCSConnection *)asyncConnection;

+ (KCSConnection *)syncConnection;


+ (KCSConnection *)connectionWithConnectionType: (Class)connectionClass;

+ (void)drainPools;


@end
