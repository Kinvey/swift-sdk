//
//  KinveyPing.h
//  KinveyKit
//
//  Copyright (c) 2008-2011, Kinvey, Inc. All rights reserved.
//
//  This software contains valuable confidential and proprietary information of
//  KINVEY, INC and is subject to applicable licensing agreements.
//  Unauthorized reproduction, transmission or distribution of this file and its
//  contents is a violation of applicable laws.

#import <Foundation/Foundation.h>

/*! Result returned from the Ping operation.
 
 The response from "pinging" Kinvey.
 
 */
@interface KCSPingResult : NSObject

///---------------------------------------------------------------------------------------
/// @name Obtaining Information
///---------------------------------------------------------------------------------------
/*! The description returned by the ping, can be error information, or a success message, the results are not meant to be shown to an end-user in a production application. */
@property (readonly, nonatomic) NSString *description;
/*! The result of the ping, YES if a round-trip request went from the device to Kinvey and back to the device.  NO otherwise. */
@property (readonly, nonatomic) BOOL pingWasSuccessful;

///---------------------------------------------------------------------------------------
/// @name Initialization & disposal
///---------------------------------------------------------------------------------------
/*! Create a Ping Response
 
 This is the designated initializer for Ping Responses.  The description can be anything, but should be releated to the result,
 but result must be NO unless a roundtrip request completed successfully.
 @param description The description of the result
 @param result YES if a complete roundtrip request was successful, NO otherwise.
 @return The KCSPingResult object.
 */
- (id)initWithDescription: (NSString *)description withResult: (BOOL)result;

@end

/*! Callback upon ping request finishing
 
 This block is used as a callback by the Ping service and is called on both success and failure.  The block is responsible for checking
 the KCSPingResult pingWasSuccessful property to determine success or failure.
 */
typedef void(^KCSPingBlock)(KCSPingResult *result);


/*! Ping Services
 
 Helper class to perform roundtrip pings to the Kinvey Service.
 
 */
@interface KCSPing : NSObject
///---------------------------------------------------------------------------------------
/// @name Pinging the Kinvey Service
///---------------------------------------------------------------------------------------
/*! Ping Kinvey and perform a callback when complete.
 
 This method makes a request on Kinvey and uses the callback to indicate the completion.
 
 @warning This request is authenticated, so indirectly verifies *all* steps that are required to talk to the Kinvey Service.
 
 @bug This Ping uses the same timeout as all other requests, so it is not suitable for determining network reachability.

 @param completionAction The callback to perform on completion.
 */
+ (void)pingKinveyWithBlock:(KCSPingBlock)completionAction;
@end
