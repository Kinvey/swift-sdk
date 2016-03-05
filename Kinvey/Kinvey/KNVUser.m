//
//  KNVUser.m
//  Kinvey
//
//  Created by Victor Barros on 2016-03-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KNVUser+Internal.h"

@interface KNVUser ()

@property (nonatomic, strong) __KNVUser *user;

@end

@implementation KNVUser

-(instancetype)initWithUser:(__KNVUser *)user
{
    self = [super init];
    if (self) {
        self.user = user;
    }
    return self;
}

+(id<KNVRequest>)existsWithUsername:(NSString *)username
                  completionHandler:(KNVUserExistsHandler)completionHandler
{
    return [self existsWithUsername:username
                             client:[KNVClient sharedClient]
                  completionHandler:completionHandler];
}

+(id<KNVRequest>)existsWithUsername:(NSString *)username
                             client:(KNVClient *)client
                  completionHandler:(KNVUserExistsHandler)completionHandler
{
    return [__KNVUser existsWithUsername:username
                                  client:client.client
                       completionHandler:completionHandler];
}

+(id<KNVRequest>)loginWithUsername:(NSString *)username
                          password:(NSString *)password
                 completionHandler:(KNVUserUserHandler)completionHandler
{
    return [self loginWithUsername:username
                          password:password
                            client:[KNVClient sharedClient]
                 completionHandler:completionHandler];
}

+(id<KNVRequest>)loginWithUsername:(NSString *)username
                          password:(NSString *)password
                            client:(KNVClient *)client
                 completionHandler:(KNVUserUserHandler)completionHandler
{
    return [__KNVUser loginWithUsername:username
                               password:password
                                 client:client.client
                      completionHandler:^(__KNVUser * _Nullable user, NSError * _Nullable error)
    {
        if (completionHandler) completionHandler(user ? [[KNVUser alloc] initWithUser:user] : nil, error);
    }];
}

+(id<KNVRequest>)signupWithUsername:(NSString *)username
                           password:(NSString *)password
                  completionHandler:(KNVUserUserHandler)completionHandler
{
    return [self signupWithUsername:username
                           password:password
                             client:[KNVClient sharedClient]
                  completionHandler:completionHandler];
}

+(id<KNVRequest>)signupWithUsername:(NSString *)username
                           password:(NSString *)password
                             client:(KNVClient *)client
                  completionHandler:(KNVUserUserHandler)completionHandler
{
    return [__KNVUser signupWithUsername:username
                                password:password
                                  client:client.client
                       completionHandler:^(__KNVUser * _Nullable user, NSError * _Nullable error)
    {
        if (completionHandler) completionHandler(user ? [[KNVUser alloc] initWithUser:user] : nil, error);
    }];
}

@end
