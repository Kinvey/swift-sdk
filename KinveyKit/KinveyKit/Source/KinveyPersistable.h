//
//  KinveyPersistable.h
//  KinveyKit
//
//  Created by Brian Wilson on 10/17/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

// Forward declaration to have access to the KCSClient definition in this protocol definition.
@class KCSCollection;

/*! Defines the implementation details of a class expecting to perform actions after the completion of a persist operation.

Developers interested in performing actions based on the state of a persist operation should conform to this protocol.

 */
@protocol KCSPersistDelegate <NSObject>

/*! Invoked when a persist operation fails
 @param entity The Object that was attempting to be persisted.
 @param error A detailed description of the error.
 */
- (void) entity: (id)entity persistDidFailWithError: (NSError *)error;

/*! Invoked when a persist operation completes successfully.
 @param entity The Object that was attempting to be persisted.
 @param result The result of the operation (Definition TBD)
 */
- (void) entity:(id)entity persistDidCompleteWithResult: (NSObject *)result;

@end

/*! Definies the interface for a persistable object.

This protocol is used to inform that this object is able to be persisted to the Kinvey Cloud Service.  The methods
defined in this protocol are used to determine what data to persist and then to actually persist the data.

The KCSEntity category on NSObject conforms to this protocol, providing a default implementation of this protocol
for all NSObject descendants.  You may directly implement this protocol in order to provide actions not accomplished by
the default methods provided.  See method documentation for important information about restrictions on clients when
implementing these methods.
 
 @bug Only hostToKinveyPropertyMapping should be implemented by the library user, the implementation provided by the KCSEntity category
 should be used for all other methods.
 
 */
@protocol KCSPersistable <NSObject>
///---------------------------------------------------------------------------------------
/// @name Persist Items
///---------------------------------------------------------------------------------------
/*!  Persist an Entity into KCS for a given KCS client and register a delegate to notify when complete.

  When overriding this method an implementer will most likely need to communicate with the KCSClient class,
 which has a different delegate interface.  An implementer will need to map between these delegates.  This does
 not apply to using the built-in implementation.
 
 @warning It is strongly advised to not override this method.

 @param collection An instance of a KCS collection to use in persisting this Entity
 @param delegate The delegate to inform upon the completion of the persist operation.
 

 */
- (void)persistToCollection: (KCSCollection *)collection withDelegate: (id <KCSPersistDelegate>)delegate;

///---------------------------------------------------------------------------------------
/// @name Delete Items
///---------------------------------------------------------------------------------------
/*! Delete an entity from Kinvey and register a delegate for notification.
 When overriding this method an implementer will most likely need to communicate with the KCSClient class,
 which has a different delegate interface.  An implementer will need to map between these delegates.  This does
 not apply to using the built-in implementation.
 
 @warning It is strongly advised to not override this method.
 
 @param delegate The delegate to inform upon the completion of the persist operation.
 @param collection The collection to remove the item from.
*/ 

- (void)deleteFromCollection: (KCSCollection *)collection withDelegate: (id<KCSPersistDelegate>)delegate;

///---------------------------------------------------------------------------------------
/// @name Map from Local to Kinvey property names
///---------------------------------------------------------------------------------------
/*! Provide the mapping from an Entity's representation to the Native Objective-C representation.
 
 
 
 A simple implementation of a mapping function is:

 Header file:
    @property (retain, readonly) NSDictionary *mapping;

 Implimentation File:
        @synthesize mapping;

        - (id)init
        {
            self = [super init];
            if (self){
                mapping = [NSDictionary dictionaryWithObjectsAndKeys:
                    @"EntityProperty1", @"InstanceVariableName1",
                    @"EntityProperty2", @"InstanceVariableName2", nil];

            }
        }
        - (NSDictionary *)propertyToElementMapping
        {
            return mapping;
        }

 
 
 @bug In this beta version of KCS this method has no default implementation and will raise an exception if the default
 implementation is used.

 @return The dictionary that maps from objective-c to Kinvey (JSON) mapping.

 */
- (NSDictionary*)hostToKinveyPropertyMapping;

@end
