//
//  NSURL+KinveyAdditions.h
//  SampleApp
//
//  Created by Brian Wilson on 10/25/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

/*! Category to add some basic URL Query Support to NSURLs

    This category adds the ability to add queries to an existing NSURL.

    @note A query string to be added will be added using either a '?' or a '+' as appropriate.  Queries should omit the
    leading value.  For example:
    @code
        [[NSURL urlWithString: @"http://kinvey.com/status"] URLByAppendingQueryString: @"value=\"UP\""]
    @endcode
    will result in the NSURL representing http://kinvey.com/status?value="UP"

 */
@interface NSURL (KinveyAdditions)

/*! Generate a NSURL by appending a query to an existing NSURL
    @param queryString The URL Query to append to the current string.
    @returns The URL object made from the URL/query.

 */
- (NSURL *)URLByAppendingQueryString:(NSString *)queryString;
+ (NSURL *)URLWithUnencodedString:(NSString *)string;

@end
