//
//  KCSCachedStoreTests.h
//  KinveyKit
//
//  Created by Michael Katz on 5/10/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@class KCSMockConnection;

@interface KCSCachedStoreTests : SenTestCase
{
    KCSMockConnection* _conn;
    NSUInteger _callbackCount;
}

@end
