//
//  KCSConnectionPool.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/28/11.
//  Copyright (c) 2011-2013 Kinvey. All rights reserved.
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


#import "KCSConnectionPool.h"
#import "KCSConnection.h"
#import "KCSAsyncConnection.h"
#import "KCSLogManager.h"


@interface KCSConnectionPool ()

@property (strong, nonatomic) Class asyncConnectionType;
@property (strong, nonatomic) NSMutableDictionary *genericConnectionPools;
@property (nonatomic) BOOL poolIsFilled;

@property (strong, nonatomic) NSMutableArray *genericPoolStack;

void verifyConnectionType(id connectionClass);

@end

@implementation KCSConnectionPool

#pragma mark -
#pragma mark Singleton Implementation
- (instancetype)init
{
    self = [super init];
    if (self){
        _genericConnectionPools = [[NSMutableDictionary alloc] init];
        self.asyncConnectionType = [KCSAsyncConnection class];
        _poolIsFilled = NO;
        _genericPoolStack = [[NSMutableArray alloc] init];
    }
    return self;
}

+ (KCSConnectionPool *)sharedPool
{
    static KCSConnectionPool *sKCSConnection;
    // This can be called on any thread, so we synchronize.  We only do this in 
    // the sKCSConnection case because, once sKCSConnection goes non-nil, it can 
    // never go nil again.
    
    if (sKCSConnection == nil) {
        @synchronized (self) {
            sKCSConnection = [[KCSConnectionPool alloc] init];
            assert(sKCSConnection != nil);
        }
    }
    
    return sKCSConnection;
}


#pragma mark -
#pragma mark Singleton Pool Management
- (void)fillPools
{
    // Basically a NO-OP until we implement pools
    self.asyncConnectionType = [KCSAsyncConnection class];
    
    self.poolIsFilled = YES;
}

- (void)fillAsyncPoolWithConnections:(Class)connectionClass
{
    // Note that we have to allocate an object before testing the class, since I don't know the way to
    // do a direct comparison, I could use the underlying structure of the objc types, but that
    // feels more hacky than the temp copy here.
    verifyConnectionType([[connectionClass alloc] init]);
    self.asyncConnectionType = connectionClass;
}


- (void)drainPools
{
    self.asyncConnectionType = [KCSAsyncConnection class];
    self.poolIsFilled = NO;
    [self.genericPoolStack removeAllObjects];
}

- (void)topPoolsWithConnection:(KCSConnection *)connection
{
    [self.genericPoolStack addObject:connection];
    self.poolIsFilled = YES;
}

#pragma mark - Client Access
+ (KCSConnection *)asyncConnection
{
    Class asyncClass = [[KCSConnectionPool sharedPool] asyncConnectionType];
    return [KCSConnectionPool connectionWithConnectionType:asyncClass];    
}


+ (KCSConnection *)connectionWithConnectionType: (Class)connectionClass
{
    KCSConnectionPool *pool = [KCSConnectionPool sharedPool];
    if (pool.poolIsFilled && [pool.genericPoolStack count] > 0){
        // Return the filled pool object
        KCSConnection *conn = [pool.genericPoolStack lastObject];
        [pool.genericPoolStack removeLastObject];
        return conn;
    } else {
        // Make the object
        id obj = [[connectionClass alloc] init] ;
        
        // Check the object
        verifyConnectionType(obj);
        
        // Return the object
        return obj;
    }
}


#pragma mark -
#pragma mark Utilities
/////// !!! NB: This routine will kill your application is connectionClass is NOT a connection class
/////// !!!     This is by design, as we can't recover...
void verifyConnectionType(id connectionClass)
{
    if (![connectionClass isKindOfClass:[KCSConnection class]]) {
        KCSLogForced(@"EXCEPTION Encountered: Name => %@, Reason => %@", @"InternalRuntimeError", @"Kinvey somehow created an invalid connection and can't recover, please contact support@kinvey.com");
        NSException* myException = [NSException
                                    exceptionWithName:@"InternalRuntimeError"
                                    reason:@"Kinvey somehow created an invalid connection and can't recover, please contact support@kinvey.com"
                                    userInfo:nil];
        
        @throw myException;
    }
}

@end
