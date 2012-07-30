//
//  KinveyKitAsyncConnectionTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/12/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KinveyKitAsyncConnectionTests.h"
#import "KCSConnection.h"
#import "KCSAsyncConnection.h"
#import "KCSMockURLConnection.h"


@implementation KinveyKitAsyncConnectionTests

- (void)setUp
{
    
}

- (void)testMockInit
{
    KCSMockURLConnection *urlConnection = [[KCSMockURLConnection alloc] init];
    KCSConnection *connection = [[KCSAsyncConnection alloc] initWithConnection:urlConnection];
    
    STAssertNoThrow([connection performRequest:nil progressBlock:NULL completionBlock:NULL failureBlock:NULL usingCredentials:nil],
                    @"Nil connection test");
    
}

@end
