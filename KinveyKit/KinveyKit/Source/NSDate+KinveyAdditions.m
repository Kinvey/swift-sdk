//
//  NSDate+KinveyAdditions.m
//  KinveyKit
//
//  Created by Michael Katz on 8/1/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "NSDate+KinveyAdditions.h"

@implementation NSDate (KinveyAdditions)

- (BOOL) isLaterThan:(NSDate*)date
{
    return [self compare:date] == NSOrderedDescending;
}

- (BOOL) isEarlierThan:(NSDate*)date
{
    return [self compare:date] == NSOrderedAscending;
}
@end
