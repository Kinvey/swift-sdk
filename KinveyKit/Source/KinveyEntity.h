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

// Included in helper class
@class JSONDecoder;

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
- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFetchOne: (NSString *)query usingClient: (KCSClient *)client;

/*! Fetch first entity with a given Boolean value for a property
*
* @param delegate Delegate object to inform upon completion or failure of this request
* @param property property to query
* @param value Boolean value (YES or NO) to query against value
* @param client Instance of client to communicate to the KCS services
*/
- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withBoolValue: (BOOL) value usingClient: (KCSClient *)client;

/*! Fetch first entity with a given Date value for a property
*
* WARNING: This method is not implemented yet and will raise an exception if used.
*
* @param delegate Delegate object to inform upon completion or failure of this request
* @param property property to query
* @param value Date value to query against value
* @param client Instance of client to communicate to the KCS services
*/
- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withDateValue: (NSDate *) value usingClient: (KCSClient *)client;

/*! Fetch first entity with a given Double value for a property
*
* @param delegate Delegate object to inform upon completion or failure of this request
* @param property property to query
* @param value Real value to query against value
* @param client Instance of client to communicate to the KCS services
*/
- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withDoubleValue: (double) value usingClient: (KCSClient *)client;

/*! Fetch first entity with a given Integer value for a property
*
* @param delegate Delegate object to inform upon completion or failure of this request
* @param property property to query
* @param value Integer to query against value
* @param client Instance of client to communicate to the KCS services
*/
- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withIntegerValue: (int) value usingClient: (KCSClient *)client;

/*! Fetch first entity with a given String value for a property
*
* @param delegate Delegate object to inform upon completion or failure of this request
* @param property property to query
* @param value String to query against value
* @param client Instance of client to communicate to the KCS services
*/
- (void)entityDelegate: (id <KCSEntityDelegate>) delegate shouldFindByProperty: (NSString *)property withStringValue: (NSString *) value usingClient: (KCSClient *)client;

/*! Return the "_id" value for this entity
*
* @returns the "_id" value for this entity.
*/
- (NSString *)objectId;

/*! Returns the value for a given property in this entity
*
* @param property The property that we're interested in.
* @returns the value of this property.
*/
- (NSString *)valueForProperty: (NSString *)property;

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
- (void)entityDelegate:(id <KCSEntityDelegate>)delegate loadObjectWithId:(NSString *)objectId usingClient:(KCSClient *)client;


/*! Set the Entity Collection that we should use to pull entities from
*   @param entityCollection The name of the collection to use.
*/
- (void)setEntityCollection: (NSString *)entityCollection;

/*! Return the Entity Collection that we are interested in using.
* @returns the Entity Collection currently in use.
*/
- (NSString *)entityColleciton;


@end



/////// Helper delegate object, internal use for KCSEntity...

/*!  Helper Class to map from Entity Requsts to KCS Requests
*
* This class is used to map between clients who implement the KCSEntityDelegate protocol and the KCSClientActionDelegate
* protocol.  Clients should implement the KCSEntityDelegate protocol and should not directly use this class.
*
*/
@interface KCSEntityDelegateMapper : NSObject <KCSClientActionDelegate>

/*!
* The client delegate to map.
*/
@property (retain) id<KCSEntityDelegate> mappedDelegate;

/*!
* The object to become the entity.
*/
@property (retain) NSObject *objectToLoad;

/*!
* A JSON Decoder convenience iVar
 */
@property (retain) JSONDecoder *jsonDecoder;

/*! Initialize the object
    @returns the instance of this object
 */
- (id)init;
/*! Free object resources

    DO NOT CALL THIS ROUTINE.  This is automatically used by the runtime.
 */
- (void) dealloc;
/*! Execute this upon notification of Action failure
    @param error Error object
 */
- (void) actionDidFail: (id)error;
/*! Execute this upon notificaiton of success
    @param result The returned JSON data.
 */
- (void) actionDidComplete: (NSObject *) result;

@end

/////// Helper delegate object, internal use for KCSEntity...
/*!  Helper Class to map from Persist Requsts to KCS Requests
*
* This class is used to map between clients who implement the KCSPersistDelegate protocol and the KCSClientActionDelegate
* protocol.  Clients should implement the KCSPersistDelegate protocol and should not directly use this class.
*
*/
@interface KCSPersistDelegateMapper : NSObject <KCSClientActionDelegate>

/*!
* The client delegate to map.
*/
@property (retain) id<KCSPersistDelegate> mappedDelegate;

/*! Execute this upon notification of Action failure
    @param error Error object
 */
- (void) actionDidFail: (id)error;
/*! Execute this upon notificaiton of success
    @param result The returned JSON data.
 */
- (void) actionDidComplete: (NSObject *) result;

@end