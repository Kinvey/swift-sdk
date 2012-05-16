//
//  KCSStore.m
//  KinveyKit
//
//  Created by Michael Katz on 5/11/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import "KCSStore.h"

@implementation KCSAllObjects

- (BOOL) isEqual:(id)object
{
    return [object isKindOfClass:[self class]];
}

- (NSUInteger)hash
{
    return [NSStringFromClass([self class]) hash];
}
@end
