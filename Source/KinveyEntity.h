//
//  KinveyEntity.h
//  KinveyKit
//
//  Created by Brian Wilson on 10/17/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KinveyPersistable.h"

@protocol KCSEntityDelegate <NSObject>

- (void) fetchDidFail: (id)error;
- (void) fetchDidComplete: (NSObject *) result;

@end

@interface NSObject (KCSEntity)

- (void)entityDelegate: (id <KCSEntityDelegate>) delagate shouldFetchOne: (NSString *)query;
- (void)entityDelegate: (id <KCSEntityDelegate>) delagate shouldFindByProperty: (NSString *)property withBoolValue: (BOOL) value;
- (void)entityDelegate: (id <KCSEntityDelegate>) delagate shouldFindByProperty: (NSString *)property withDateValue: (NSDate *) value;
- (void)entityDelegate: (id <KCSEntityDelegate>) delagate shouldFindByProperty: (NSString *)property withDoubleValue: (double) value;
- (void)entityDelegate: (id <KCSEntityDelegate>) delagate shouldFindByProperty: (NSString *)property withIntegerValue: (int) value;
- (void)entityDelegate: (id <KCSEntityDelegate>) delagate shouldFindByProperty: (NSString *)property withStringValue: (NSString *) value;
- (void)entityDelegate: (id <KCSEntityDelegate>) delagate shouldFindByProperty: (NSString *)property withCharValue: (char) value;

- (NSString *)objectId;
- (NSString *)valueForKey: (NSString *)key;


- (void)delagate: (id)delagate loadObjectWithId: (NSString *)objectId;
//- (void)setValue: (NSString *)value forKey: (NSString *)key;


@end
