//
//  NSDate+KinveyAdditions.h
//  KinveyKit
//
//  Created by Michael Katz on 8/1/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (KinveyAdditions)

- (BOOL) isLaterThan:(NSDate*)date;
- (BOOL) isEarlierThan:(NSDate*)date;


@end
