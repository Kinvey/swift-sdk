//
//  NSString+KinveyAdditions.m
//  SampleApp
//
//  Created by Brian Wilson on 10/25/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "NSString+KinveyAdditions.h"

@implementation NSString (KinveyAdditions)

- (NSURL *)URLByAppendingQueryString:(NSString *)queryString {
    if (![queryString length]) {
        return [NSURL URLWithString:self];
    }
    
    NSString *URLString = [[NSString alloc] initWithFormat:@"%@%@%@", self,
                           [self rangeOfString:@"?"].length > 0 ? @"&" : @"?", queryString];
    NSURL *theURL = [NSURL URLWithString:URLString];
    [URLString release];
    return theURL;
}

// Or:

- (NSString *)URLStringByAppendingQueryString:(NSString *)queryString {
    if (![queryString length]) {
        return self;
    }
    return [NSString stringWithFormat:@"%@%@%@", self,
            [self rangeOfString:@"?"].length > 0 ? @"&" : @"?", queryString];
}

@end
