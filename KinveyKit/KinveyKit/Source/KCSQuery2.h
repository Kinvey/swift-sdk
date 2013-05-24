//
//  KCSQuery2.h
//  KinveyKit
//
//  Created by Michael Katz on 5/23/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

@class KCSQuery2;

FOUNDATION_EXPORT KCSQuery2* KCSQueryAll;

@interface KCSQuery2 : NSObject

- (NSString*) escapedQueryString;

@end
