//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <XCTest/XCTest.h>
#import "KinveyKit.h"
#import "TestUtils2.h"
#import "KCSMutableOrderedDictionary.h"
#import "KCSUser2+KinveyUserService.h"
#import "KinveyUser+Private.h"

@interface KCSUser2 ()

+(BOOL)isValidMICRedirectURI:(NSString *)redirectURI
                      forURL:(NSURL *)url
                      params:(NSDictionary**)params;

@end
