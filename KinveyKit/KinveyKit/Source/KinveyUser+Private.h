//
//  KCSUserT.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-04-06.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import "KinveyUser.h"
#import <Kinvey/Kinvey-Swift.h>

@interface KCSUser()

@property (nonatomic, strong) NSMutableDictionary *userAttributes;

+(NSURL *)URLforLoginWithMICRedirectURI:(NSString *)redirectURI
                                 client:(Client*)client;

+(void)parseMICRedirectURI:(NSString *)redirectURI
                    forURL:(NSURL *)url
                    client:(Client*)client
       withCompletionBlock:(KCSUserCompletionBlock)completionBlock;

@end
