//
//  KinveyUser.h
//  KinveyKit
//
//  Created by Brian Wilson on 12/1/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KCSRESTRequest;

@interface KCSUser : NSObject

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *password;

//- (void)logout;
//- (void)loginWithUsername: (NSString *)username usingPassword: (NSString *)password;
- (void)initializeCurrentUserWithRequest: (KCSRESTRequest *)request;
- (void)initializeCurrentUser;

@end
