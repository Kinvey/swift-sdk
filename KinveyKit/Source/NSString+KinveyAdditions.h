//
//  NSString+KinveyAdditions.h
//  SampleApp
//
//  Created by Brian Wilson on 10/25/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (KinveyAdditions)

- (NSURL *)URLByAppendingQueryString:(NSString *)queryString;
- (NSString *)URLStringByAppendingQueryString:(NSString *)queryString;

@end
