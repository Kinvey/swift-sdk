//
//  KinveyEntity.h
//  KinveyKit
//
//  Created by Brian Wilson on 10/17/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KinveyPersistable.h"
#import "KCSClient.h"

@protocol KCSEntityDelegate <NSObject>

- (void) fetchDidFail: (id)error;
- (void) fetchDidComplete: (NSObject *) result;

@end

@interface NSObject (KCSEntity) <KCSPersistable>

- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFetchOne: (NSString *)query usingClient: (KCSClient *)client;
- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withBoolValue: (BOOL) value usingClient: (KCSClient *)client;
- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withDateValue: (NSDate *) value usingClient: (KCSClient *)client;
- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withDoubleValue: (double) value usingClient: (KCSClient *)client;
- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withIntegerValue: (int) value usingClient: (KCSClient *)client;
- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withStringValue: (NSString *) value usingClient: (KCSClient *)client;

- (NSString *)objectId;
- (NSString *)valueForProperty: (NSString *)key;


- (void)delagate: (id)delagate loadObjectWithId: (NSString *)objectId;
- (void)setValue: (NSString *)value forProperty: (NSString *)key;

- (void)setEntityCollection: (NSString *)entityCollection;
- (NSString *)entityColleciton;


@end


/////// Helper delegate object
@interface KCSEntityDelegateMapper : NSObject <KCSClientActionDelegate>

@property (retain) id<KCSEntityDelegate> mappedDelegate;

- (void) actionDidFail: (id)error;
- (void) actionDidComplete: (NSObject *) result;

@end