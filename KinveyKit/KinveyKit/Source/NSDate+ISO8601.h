//
//  NSDate+ISO8601.h
//  KinveyKit
//
//  Created by Brian Wilson on 12/23/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (ISO8601)

- (NSString *)stringWithISO8601Encoding;
+ (NSDate *)dateFromISO8601EncodedString: (NSString *)string;

@end
