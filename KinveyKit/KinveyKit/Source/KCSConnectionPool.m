//
//  KCSConnectionPool.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/28/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSConnectionPool.h"
#import "KCSConnection.h"
#import "KCSAsyncConnection.h"
#import "KCSSyncConnection.h"
//#import "KC"

@implementation KCSConnectionPool

+ (KCSConnection *)asyncConnection
{
    return [KCSConnectionPool connectionWithConnectionType:[KCSAsyncConnection class]];
}

+ (KCSConnection *)syncConnection
{
    return [KCSConnectionPool connectionWithConnectionType:[KCSSyncConnection class]];
}

+ (KCSConnection *)connectionWithConnectionType: (Class)connectionClass
{
    // Cheat with single connection right now..., no pool
    return [[[connectionClass alloc] init] autorelease];

}

+ (void)drainPools
{
    // No Op for now, but otherwise would drain all pools, used to reset auth credentials...
}
@end
