//
//  KinveyCollection.h
//  KinveyKit
//
//  Created by Brian Wilson on 10/17/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KCSCollectionDelegate <NSObject>

- (void) fetchCollectionDidFail: (id)error;
- (void) fetchCollectionDidComplete: (NSObject *) result;

@end

@protocol KCSSimpleValueDelegate <NSObject>

- (void) simpleValueOperationDidFail: (id)error;
- (void) simpleValueOperationDidComplete: (int)result;

@end


@interface NSObject (KCSCollection)

#pragma mark Collection methods
- (void) collectionDelegateFetchAll: (id <KCSCollectionDelegate>)delegate;
- (void) collectionDelegateFetch: (id <KCSCollectionDelegate>)delegate;

#pragma mark query methods

- (void) addFilterCriteriaForProperty: (NSString *)property withBoolValue: (BOOL) value filteredByOperator: (NSString *)operator;
- (void) addFilterCriteriaForProperty: (NSString *)property withCharValue: (char) value filteredByOperator: (NSString *)operator;
- (void) addFilterCriteriaForProperty: (NSString *)property withDateValue: (NSDate *) value filteredByOperator: (NSString *)operator;
- (void) addFilterCriteriaForProperty: (NSString *)property withDoubleValue: (double) value filteredByOperator: (NSString *)operator;
- (void) addFilterCriteriaForProperty: (NSString *)property withIntegerValue: (int) value filteredByOperator: (NSString *)operator;
- (void) addFilterCriteriaForProperty: (NSString *)property withStringValue: (NSString *) value filteredByOperator: (NSString *)operator;

#pragma mark Convienience methods
- (void) simpleValueDelegateCollectionCount: (id <KCSSimpleValueDelegate>)delegate;

// TODO: AVG
// TODO: ETC

@end;
