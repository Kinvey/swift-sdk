//
//  NSURL+KinveyAdditions.m
//  SampleApp
//
//  Created by Brian Wilson on 10/25/11.
//  Copyright (c) 2011-2013 Kinvey. All rights reserved.
//

#import "NSURL+KinveyAdditions.h"

@implementation NSURL (KinveyAdditions)

- (NSURL *)URLByAppendingQueryString:(NSString *)queryString
{
    if (![queryString length]) {
        return self;
    }
    
    NSString *URLString = [NSString stringWithFormat:@"%@%@%@", [self absoluteString],
                           [self query] ? @"&" : @"?", queryString];
    NSURL *theURL = [NSURL URLWithString:URLString];
    return theURL;
}


+ (NSURL *)URLWithUnencodedString:(NSString *)string
{
    NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL,
                                            (CFStringRef) string,
                                            NULL,
                                            (CFStringRef) @"!*'();:@&=+$,/?%#[]{}",
                                            kCFStringEncodingUTF8));

    NSURL *returnedURL = [NSURL URLWithString:encodedString];
    
    return returnedURL;
}

@end
