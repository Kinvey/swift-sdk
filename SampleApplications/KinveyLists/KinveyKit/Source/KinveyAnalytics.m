//
//  KinveyAnalytics.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/9/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KinveyAnalytics.h"

@implementation KCSAnalytics

@synthesize UUID=_UUID;

- (id)init
{
    self = [super init];
    if (self){
        [self setUUID:[[UIDevice currentDevice] uniqueIdentifier]];
    }
    return self;
}

@end
