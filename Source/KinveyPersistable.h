//
//  KinveyPersistable.h
//  KinveyKit
//
//  Created by Brian Wilson on 10/17/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KCSPersistDelegate <NSObject>

- (void) persistDidFail: (id)error;
- (void) persistDidComplete: (NSObject *) result;

@end

@protocol KCSPersistable <NSObject>

// This name seems gimpy... but it conforms to the sytle guide, WTF mate?
- (void)persistDelegatePersist: (id <KCSPersistDelegate>) delegate;
- (NSDictionary*)propertyToElementMapping;

@end
