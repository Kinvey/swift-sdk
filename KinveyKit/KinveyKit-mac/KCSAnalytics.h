//
//  KCSAnalytics.h
//  KinveyKit
//
//  Created by Michael Katz on 1/30/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCSAnalytics : NSObject

@property (nonatomic, retain) NSString* analyticsHeaderName;
- (BOOL) supportsUDID;
@end
