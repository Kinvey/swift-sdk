//
//  NSString+KinveyAdditions.h
//  SampleApp
//
//  Created by Brian Wilson on 10/25/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

/*! Category to add some basic URL Query Support to NSStrings

    This category adds the ability to turn a string into a URL with query parameters, as well as the ability to
    add queries to an existing string representation of a URL.

    @note A query string to be added will be added using either a '?' or a '+' as appropriate.  Queries should omit the
    leading value.  For example:
    @code
        [@"http://kinvey.com/status" URLStringByAppendingQueryString: @"value=\"UP\""]
    @endcode
    will result in the string: http://kinvey.com/status?value="UP"

 */
@interface NSString (KinveyAdditions)

/*! Generate a NSURl by appending a query to an existing String
    @param queryString The URL Query to append to the current string.
    @returns The URL object made from the string/query.

 */
- (NSURL *)URLByAppendingQueryString:(NSString *)queryString;

/*! Generate a string by appending a query string.
    @param queryString The string to append as a query
    @returns The newly created string.
 */
- (NSString *)URLStringByAppendingQueryString:(NSString *)queryString;

@end
