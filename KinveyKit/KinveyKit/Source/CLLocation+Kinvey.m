//
//  CLLocation+Kinvey.m
//  KinveyKit
//
//  Created by Michael Katz on 8/20/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import "CLLocation+Kinvey.h"

@implementation CLLocation (Kinvey)

- (NSArray *)kinveyValue
{
    CLLocationCoordinate2D loc = [self coordinate];
    return @[@(loc.longitude), @(loc.latitude)];
}

+ (CLLocation*) locationFromKinveyValue:(NSArray*)kinveyValue
{
    return [[CLLocation alloc] initWithLatitude:[kinveyValue[1] doubleValue] longitude:[kinveyValue[0] doubleValue]];
}
@end
