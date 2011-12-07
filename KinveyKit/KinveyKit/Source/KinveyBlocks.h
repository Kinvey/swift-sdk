//
//  KinveyBlocks.h
//  KinveyKit
//
//  Created by Brian Wilson on 11/29/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#ifndef KinveyKit_KinveyBlocks_h
#define KinveyKit_KinveyBlocks_h

@class KCSConnectionProgress;
@class KCSConnectionResponse;

// Define the block types that we expect
typedef void(^KCSConnectionProgressBlock)(KCSConnectionProgress *);
typedef void(^KCSConnectionCompletionBlock)(KCSConnectionResponse *);
typedef void(^KCSConnectionFailureBlock)(NSError *);



#endif
