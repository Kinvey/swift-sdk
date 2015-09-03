//
//  KCSTestCase.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-14.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KCSTestCase.h"
#import "KCS_DDLog.h"
#import "KCSHiddenMethods.h"
#import "KCSURLProtocol.h"

@implementation KCSTestCase

-(void)setUp
{
    [super setUp];
    
    [KCSRequest2 cancelAndWaitUntilAllOperationsAreFinished];
    [KCSFileRequestManager cancelAndWaitUntilAllOperationsAreFinished];
    [KCSAppdataStore cancelAndWaitUntilAllOperationsAreFinished];
    
    for (Class clazz in [KCSURLProtocol protocolClasses]) {
        [KCSURLProtocol unregisterClass:clazz];
    }
    
    [KCS_DDLog flushLog];
}

-(void)tearDown
{
    [KCSRequest2 cancelAndWaitUntilAllOperationsAreFinished];
    [KCSFileRequestManager cancelAndWaitUntilAllOperationsAreFinished];
    [KCSAppdataStore cancelAndWaitUntilAllOperationsAreFinished];
    
    for (Class clazz in [KCSURLProtocol protocolClasses]) {
        [KCSURLProtocol unregisterClass:clazz];
    }
    
    [KCS_DDLog flushLog];
    
    [super tearDown];
}

@end
