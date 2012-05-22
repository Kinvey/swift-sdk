//
//  ASTTestClass.m
//  KinveyKit
//
//  Created by Michael Katz on 5/21/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "ASTTestClass.h"

@implementation ASTTestClass

@synthesize objId = _objId;
@synthesize objCount = _objCount;
@synthesize objDescription = _objDescription;

- (NSDictionary *)hostToKinveyPropertyMapping
{
    NSDictionary *map = nil;
    
    if (map == nil){
        map = [NSDictionary dictionaryWithObjectsAndKeys:
               @"_id", @"objId",
               @"objCount", @"objCount",
               @"objDescription", @"objDescription", nil];
    }
    
    return map;
}

@end