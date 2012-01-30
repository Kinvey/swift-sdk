//
//  NSString+KinveyAdditions.m
//  SampleApp
//
//  Created by Brian Wilson on 10/25/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "NSString+KinveyAdditions.h"
#import "NSURL+KinveyAdditions.h"

@implementation NSString (KinveyAdditions)

- (NSURL *)URLByAppendingQueryString:(NSString *)queryString {
    if (![queryString length]) {
        return [NSURL URLWithUnencodedString:self];
    }
    
    NSString *URLString = [[NSString alloc] initWithFormat:@"%@%@%@", self,
                           [self rangeOfString:@"?"].length > 0 ? @"&" : @"?", queryString];
    NSURL *theURL = [NSURL URLWithString:URLString];
    [URLString release];
    return theURL;
}

// Or:

- (NSString *)stringByAppendingQueryString:(NSString *)queryString {
    if (![queryString length]) {
        return self;
    }
    // rangeOfString returns an NSRange, which is {location/length}, so
    // if .length > 0, then we've found a '?' somewhere in the string so
    // we need to append the next string with a '&'
    return [NSString stringWithFormat:@"%@%@%@", self,
            [self rangeOfString:@"?"].length > 0 ? @"&" : @"?", queryString];
}

+ (NSString *)stringbyPercentEncodingString:(NSString *)string
{
    NSString *encodedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                  (CFStringRef) string,
                                                                                  NULL,
                                                                                  (CFStringRef) @"!*'();:@&=+$,/?%#[]{}",
                                                                                  kCFStringEncodingUTF8);
    
    // encodedString has a ref count of 1..., need to auto release it
    [encodedString autorelease];
    return encodedString;
}

- (NSString *)stringbyAppendingStringWithPercentEncoding:(NSString *)string;
{
    return [self stringByAppendingString:[NSString stringbyPercentEncodingString:string]];
}

@end
