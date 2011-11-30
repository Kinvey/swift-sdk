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

/*!  Describes required selectors for requesting entities from the Kinvey Service.
*
* This Protocol should be implemented by a client for processing the results of an Entity request against the KCS
* service.
*/
@protocol KCSEntityDelegate <NSObject>

/*!
*  Called when a request fails for some reason (including network failure, internal server failure, request issues...)
*  @param error An object that encodes our error message (Documentation TBD)
*/
- (void) fetchDidFail: (id)error;

/*!
* Called when a request completes successfully.
* @param result The result of the completed request (Typically NSData encoded JSON)
*/
- (void) fetchDidComplete: (NSObject *) result;

@end

/*!  Add ActiveRecord capabilities to the built-in root object (NSObject) of the AppKit/Foundation system.
*
* This category is used to cause any NSObject to be able to be persisted into the Kinvey Cloud Service.
*/
@interface NSObject (KCSEntity) <KCSPersistable>

/*! Fetch one instance of this entity from KCS
*
* @param delegate Delegate object to inform upon completion or failure of this request
* @param query Arbitrary JSON query to execute on KCS (See Queries in KCS documentation for details on Queries)
* @param client Instance of client to communicate to the KCS services
*/
- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFetchOne: (NSString *)query fromCollection: (KCSCollection *)collection;

/*! Fetch first entity with a given Boolean value for a property
*
* @param delegate Delegate object to inform upon completion or failure of this request
* @param property property to query
* @param value Boolean value (YES or NO) to query against value
* @param client Instance of client to communicate to the KCS services
*/
- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withBoolValue: (BOOL) value fromCollection: (KCSCollection *)collection;

/*! Fetch first entity with a given Date value for a property
*
* WARNING: This method is not implemented yet and will raise an exception if used.
*
* @param delegate Delegate object to inform upon completion or failure of this request
* @param property property to query
* @param value Date value to query against value
* @param client Instance of client to communicate to the KCS services
*/
- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withDateValue: (NSDate *) value fromCollection: (KCSCollection *)collection;

/*! Fetch first entity with a given Double value for a property
*
* @param delegate Delegate object to inform upon completion or failure of this request
* @param property property to query
* @param value Real value to query against value
* @param client Instance of client to communicate to the KCS services
*/
- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withDoubleValue: (double) value fromCollection: (KCSCollection *)collection;

/*! Fetch first entity with a given Integer value for a property
*
* @param delegate Delegate object to inform upon completion or failure of this request
* @param property property to query
* @param value Integer to query against value
* @param client Instance of client to communicate to the KCS services
*/
- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withIntegerValue: (int) value fromCollection: (KCSCollection *)collection;

/*! Fetch first entity with a given String value for a property
*
* @param delegate Delegate object to inform upon completion or failure of this request
* @param property property to query
* @param value String to query against value
* @param client Instance of client to communicate to the KCS services
*/
- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withStringValue: (NSString *) value fromCollection: (KCSCollection *)collection;

/*! Return the "_id" value for this entity
*
* @returns the "_id" value for this entity.
*/
- (NSString *)kinveyObjectId;

/*! Returns the value for a given property in this entity
*
* @param property The property that we're interested in.
* @returns the value of this property.
*/
//- (NSString *)valueForProperty: (NSString *)property;

/*! Set a value for a given property
* @param value The value to set for the given property
* @param property The property to assign this value to.
*/
- (void)setValue: (NSString *)value forProperty: (NSString *)property;


/*! Load an entity with a specific ID and replace the current object
* @param delegate The delegate to notify upon completion of the load.
* @param objectId The ID of the entity to request
* @param client Instance of client to connect to the KCS service.
*/
- (void)entityDelegate:(id <KCSEntityDelegate>)delegate loadObjectWithId:(NSString *)objectId fromCollection:(KCSCollection *)collection;


///*! Set the Entity Collection that we should use to pull entities from
//*   @param entityCollection The name of the collection to use.
//*/
//- (void)setEntityCollection: (NSString *)entityCollection;
//
///*! Return the Entity Collection that we are interested in using.
//* @returns the Entity Collection currently in use.
//*/
//- (NSString *)entityColleciton;


@end
