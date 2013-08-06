//
//  KCSBlockDefs.h
//  KinveyKit
//
//  Created by Brian Wilson on 5/2/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#ifndef KinveyKit_KCSBlockDefs_h
#define KinveyKit_KCSBlockDefs_h

@class KCSGroup;

typedef void(^KCSCompletionBlock)(NSArray *objectsOrNil, NSError *errorOrNil);

/*! A progress block.
 @param objects if there are any valid objects available. Could be `nil` or empty.
 @param percentComplete the percentage of the total progress made so far. Suitable for a progress indicator.
 */
typedef void(^KCSProgressBlock)(NSArray *objects, double percentComplete);

/*! A completion block where the result is a coumt.
 @param count the resulting count of the operation
 @param errorOrNil an non-nil object if an error occurred.
 */
typedef void(^KCSCountBlock)(unsigned long count, NSError *errorOrNil);

typedef void(^KCSGroupCompletionBlock)(KCSGroup* valuesOrNil, NSError* errorOrNil);

#endif
