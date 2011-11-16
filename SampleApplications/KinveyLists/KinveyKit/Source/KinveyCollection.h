//
//  KinveyCollection.h
//  KinveyKit
//
//  Created by Brian Wilson on 10/17/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCSClient.h"

@class JSONDecoder;


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
@protocol KCSInformationDelegate <NSObject>
- (void) informationOperationDidFail: (id)error;
- (void) informationOperationDidComplete: (int)result;

@end

#define KCS_EQUALS_OPERATOR 0
#define KCS_LESS_THAN_OPERATOR 1
#define KCS_GREATER_THAN_OPERATOR 2
#define KCS_LESS_THAN_OR_EQUAL_OPERATOR 3
#define KCS_GREATER_THAN_OR_EQUAL_OPERATOR 4


/*! Object for managing a collection of KinveyEntities
*
*/
@interface KCSCollection : NSObject

// Usage concept
// In controller
// self.objectCollection = [[KCSCollection alloc] init];
// self.objectCollection.collectionName = @"lists";
// self.objectColleciton.objectTemplate = [[MyObject alloc] init];
// self.objectCollection.kinveyConnection = [globalConnection];
//
// And later...
// [self.objectCollection collectionDelegateFetchAll: ()

/*! String representation of the name of the Kinvey Collection. */
@property (retain) NSString *collectionName;
/*! An instance of an object stored by this collection */
@property (retain) NSObject *objectTemplate;
/*! Kinvey Client needed to access the Kinvey Service. */
@property (retain) KCSClient *kinveyClient;
/*! A cached copy of the last results from Kinvey (handy if you forget to copy them in your delegate) */
@property (retain) NSArray *lastFetchResults;

@property (retain) NSMutableArray *filters;

// TODO: Need a way to story the query portion of the library.

#pragma mark Basic Methods

/*! Fetch all of the entities in the collection
 *  @param delegate The delegate that we'll notify upon completion of the request.
 */
- (void)collectionDelegateFetchAll: (id <KCSCollectionDelegate>)delegate;


#pragma mark Query Methods
- (void)addFilterCriteriaForProperty: (NSString *)property withBoolValue: (BOOL) value filteredByOperator: (int)operator;
- (void)addFilterCriteriaForProperty: (NSString *)property withDoubleValue: (double)value filteredByOperator: (int)operator;
- (void)addFilterCriteriaForProperty: (NSString *)property withIntegerValue: (int)value filteredByOperator: (int)operator;
- (void)addFilterCriteriaForProperty: (NSString *)property withStringValue: (NSString *)value filteredByOperator: (int)operator;

- (void)collectionDelegateFetch: (id <KCSCollectionDelegate>)delegate;

#pragma mark Utility Methods

- (void)informationDelegateCollectionCount: (id <KCSInformationDelegate>)delegate;

// AVG is not in the REST docs anymore


@end
