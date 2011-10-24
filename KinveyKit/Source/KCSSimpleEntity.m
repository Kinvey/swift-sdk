//
//  KCSSimpleEntity.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/21/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSSimpleEntity.h"




@implementation KCSSimpleEntity

@synthesize delegate;

// This name seems gimpy... but it conforms to the sytle guide, WTF mate?
- (void)persistDelegatePersist: (id <KCSPersistDelegate>) delegate
{
    
}

- (NSDictionary*)propertyToElementMapping
{
    return nil;
}


@end
