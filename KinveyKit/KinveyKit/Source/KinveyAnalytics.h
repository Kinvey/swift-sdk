//
//  KinveyAnalytics.h
//  KinveyKit
//
//  Copyright (c) 2008-2013, Kinvey, Inc. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, understand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
//

#import <Foundation/Foundation.h>

#define KCS_UUID_USER_DEFAULTS_KEY @"KCS_UUID"

/*! Interface to Kinvey Analytics Service.
 
 This objects is the single interface to all Kinvey Analytics services.  It should not be created directly, but should be used through
 the KCSClient property.
 */
@interface KCSAnalytics : NSObject

///---------------------------------------------------------------------------------------
/// @name User/Device Identification
///---------------------------------------------------------------------------------------

/*! The unique identifier for this device/user */
@property (strong, readonly) NSString *UUID;

/*! Kinvey's UDID representation */
@property (strong, readonly) NSString *UDID;

@property (strong, readonly) NSString *analyticsHeaderName;

/*! Generate a UUID
 
 This UUID is not persistent, but is meant to be a one-time UUID.
 
 @return The generated UUID, note this is an autoreleased string, please retain if necessary.
 */
- (NSString *)generateUUID;


/*! Returns all current information on the state of the device
 
 Use this method to gather the current state of the device.
 
 @return The dictionary of the current state of the device.
 
 */
- (NSDictionary *)deviceInformation;

- (NSString *)headerString;


- (BOOL) supportsUDID;

@end
