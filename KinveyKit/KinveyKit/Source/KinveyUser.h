//
//  KinveyUser.h
//  KinveyKit
//
//  Created by Brian Wilson on 12/1/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KCSRESTRequest;

/*! User in the Kinvey System
 
 All Kinvey requests must be made using an authorized user, if a user doesn't exist, an automatic user generation
 facility exists (given a username Kinvey can generate and store a password).  More user operations are available to the
 client, but are not required to be used.
 
 Since all requests *must* be made through a user, the library maintains the concept of a current user, which is the
 user used to make all requests.  Convienience routines are available to manage the state of this Current User.
 
 */
@interface KCSUser : NSObject

///---------------------------------------------------------------------------------------
/// @name User Information
///---------------------------------------------------------------------------------------
/*! Username of this Kinvey User */
@property (nonatomic, copy) NSString *username;
/*! Password of this Kinvey User */
@property (nonatomic, copy) NSString *password;

///---------------------------------------------------------------------------------------
/// @name KinveyKit Internal Services
///---------------------------------------------------------------------------------------
/*! Initialize the "Current User" for Kinvey
 
 This will cause the system to initialize the "Current User" to the known "primary" user for the device
 should no user exist, one is created.  If a non-nil request is provided, the request will be started after
 user authentication.
 
 @warning This routine is not intended for application developer use, this routine is used by the library runtime to ensure all requests are authenticated.
 
 @warning This is a *blocking* routine and will block on other threads that are authenticating.  There is a short timeout before authentication failure.
 
 @param request The REST request to perform after authentication.
 
*/
- (void)initializeCurrentUserWithRequest: (KCSRESTRequest *)request;

/*! Initialize the "Current User" for Kinvey
 
 This will cause the system to initialize the "Current User" to the known "primary" user for the device
 should no user exist, one is created.
 
 @warning This routine is not intended for application developer use, this routine is used by the library runtime to ensure all requests are authenticated.
 
 @warning This is a *blocking* routine and will block on other threads that are authenticating.  There is a short timeout before authentication failure.
 
 */
- (void)initializeCurrentUser;

@end
