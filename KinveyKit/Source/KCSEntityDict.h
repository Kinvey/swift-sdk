//
//  KCSEntityDict.h
//  KinveyKit
//
//  Created by Brian Wilson on 10/21/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//
//  This is an example implementation of a persistable object
//  subclass this if you need to 

#import <Foundation/Foundation.h>
#import "KinveyPersistable.h"
#import "KCSClient.h"

/*! An entity dictionary object that can persist to Kinvey.

	To use this object, simply treat it as a dictionary and issue a fetch/persist to update it's
	data from Kinvey.
*/
@interface KCSEntityDict : NSObject <KCSPersistable>

/*! The delegate to be notified once a persist is complete.  @todo: This is probably OBE.*/
@property (assign) id<KCSPersistDelegate> delegate;

/*! @sa KCSPersistable */
- (void)persistDelegate:(id <KCSPersistDelegate>)delegate persistUsingClient:(KCSClient *)client;

/*! @sa KCSPersistable */
- (NSDictionary*)propertyToElementMapping;


@end
