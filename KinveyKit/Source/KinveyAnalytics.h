//
//  KinveyAnalytics.h
//  KinveyKit
//
//  Created by Brian Wilson on 11/9/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

/*! Interface to Kinvey Analytics Service.
 
 This objects is the single interface to all Kinvey Analytics services.  It should not be created directly, but should be used through
 the KCSClient property.
 */
@interface KCSAnalytics : NSObject

///---------------------------------------------------------------------------------------
/// @name User/Device Identification
///---------------------------------------------------------------------------------------

/*! The unique identifier for this device/user */
@property (retain) NSString *UUID;


@end