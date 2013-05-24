//
//  KCSQuery2.m
//  KinveyKit
//
//  Created by Michael Katz on 5/23/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "KCSQuery2.h"
#import "NSString+KinveyAdditions.h"

#import "KCS_SBJson.h"

@interface KCSQuery2 ()
@property (nonatomic, retain) NSMutableDictionary* internalRepresentation;
@end

@implementation KCSQuery2

+ (void)initialize
{
    KCSQueryAll = [[KCSQuery2 alloc] init];
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _internalRepresentation = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)description
{
    return [self queryString];
}

#pragma mark - stringification

- (NSString*) queryString
{
    return [NSString stringWithFormat:@"query=%@", [_internalRepresentation JSONRepresentation]];
}

- (NSString *)escapedQueryString
{
    return [NSString stringByPercentEncodingString:[self queryString]];
}


@end
