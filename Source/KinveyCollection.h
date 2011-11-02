//
//  KinveyCollection.h
//  KinveyKit
//
//  Created by Brian Wilson on 10/17/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!  Describes required selectors for requesting entities from the Kinvey Service.
*
* This Protocol should be implemented by a client for processing the results of a Entity request against the KCS
* service that deals with a collection of Entities.
*/
@protocol KCSCollectionDelegate <NSObject>

/*!
*  Called when a request fails for some reason (including network failure, internal server failure, request issues...)
*  @param error An object that encodes our error message (Documentation TBD)
*/
- (void) fetchCollectionDidFail: (id)error;

/*!
* Called when a request completes successfully.
* @param result The results of the completed request (Typically a list of NSData encoded JSON)
* @todo Should this code really just have a list object instead of a NSObject???
*/
- (void) fetchCollectionDidComplete: (NSObject *) result;

@end


/*! @todo This code is crufty and needs to be updated, TBD once we're done with the Sample App
	the simpleValue concept is not generic enough, since really we want to have an NSObject returned,
	so this is more of a filterScaler callback....
*/
@protocol KCSSimpleValueDelegate <NSObject>

- (void) simpleValueOperationDidFail: (id)error;
- (void) simpleValueOperationDidComplete: (int)result;

@end


/*!  Add ActiveRecord capabilities to the built-in root object (NSObject) of the AppKit/Foundation system.
*
* @todo This interface feels incorrect.
*/
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
