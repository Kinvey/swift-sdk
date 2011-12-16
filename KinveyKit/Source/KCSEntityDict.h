//
//  KCSEntityDict.h
//  KinveyKit
//
//  Copyright (c) 2008-2011, Kinvey, Inc. All rights reserved.
//
//  This software contains valuable confidential and proprietary information of
//  KINVEY, INC and is subject to applicable licensing agreements.
//  Unauthorized reproduction, transmission or distribution of this file and its
//  contents is a violation of applicable laws.

#import <Foundation/Foundation.h>
#import "KinveyPersistable.h"
#import "KCSClient.h"

/*! An entity dictionary object that can save to Kinvey.

	To use this object, simply treat it as a dictionary and issue a fetch/save to update it's
	data from Kinvey.
*/
@interface KCSEntityDict : NSObject <KCSPersistable>

@end
