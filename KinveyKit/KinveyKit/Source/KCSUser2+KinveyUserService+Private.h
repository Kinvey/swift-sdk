//
//  KCSUser2+KinveyUserService+Private.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-04-06.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCSUser2+KinveyUserService.h"

extern NSString* const kKCSMICRefreshTokenKey;
extern NSString* const kKCSMICRedirectURIKey;

@interface KCSUser2 ()

+(void)oAuthTokenWithRefreshToken:(NSString*)refreshToken
                      redirectURI:(NSString*)redirectURI
                             sync:(BOOL)sync
                       completion:(KCSUser2CompletionBlock)completionBlock;

@end
