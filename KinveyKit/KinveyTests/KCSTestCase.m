//
//  KCSTestCase.m
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-14.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KCSTestCase.h"
#import "KCS_DDLog.h"

@implementation KCSTestCase

-(void)tearDown
{
    [KCS_DDLog flushLog];
    
    [super tearDown];
}

@end
