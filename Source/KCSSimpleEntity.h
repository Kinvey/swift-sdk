//
//  KCSSimpleEntity.h
//  KinveyKit
//
//  Created by Brian Wilson on 10/21/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//
//  This is an example implementation of a persistable object
//  subclass this if you need to 

#import <Foundation/Foundation.h>
#import "KinveyKit.h"

@interface KCSSimpleEntity : NSObject <KCSPersistable>

@property (assign) id<KCSPersistDelegate> delegate;


- (void)persistDelegatePersist: (id <KCSPersistDelegate>) delegate;
- (NSDictionary*)propertyToElementMapping;


@end
