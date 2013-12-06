//
//  KCSResourceStore.m
//  KinveyKit
//
//  Created by Brian Wilson on 5/3/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, understand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
//


#import "KCSResourceStore.h"

@interface KCSResourceStore ()

@end

@implementation KCSResourceStore

#pragma mark - Initialization

- (instancetype)init
{
    return [self initWithAuth:nil];
}

- (instancetype)initWithAuth: (KCSAuthHandler *)auth
{
    self = [super init];
    if (self) {
        _authHandler = auth;
    }
    return self;
}

+ (instancetype)store
{
    return [self storeWithOptions:nil];
}

+ (instancetype)storeWithOptions: (NSDictionary *)options
{
    KCSResourceStore *store = [[self alloc] init];
    [store configureWithOptions:options];
    return store;
}

+ (instancetype)storeWithAuthHandler: (KCSAuthHandler *)authHandler withOptions: (NSDictionary *)options
{
    KCSResourceStore *store = [[self alloc] initWithAuth:authHandler];
    [store configureWithOptions:options];
    
    return store;
}

- (void)saveObject: (id)object withCompletionBlock: (KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
   [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSFileStore uploadFile:options:completionBlock:progressBlock:] instead." userInfo:nil] raise];}

- (void)saveData:(NSData*)data toFile:(NSString*)file withCompletionBlock: (KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSFileStore uploadData:options:completionBlock:progressBlock:] instead." userInfo:nil] raise];
}

- (void)loadObjectWithID:(id)objectID withCompletionBlock:(KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"Use +[KCSFileStore downloadFile:completionBlock:progressBlock:] or +[KCSFileStore downloadData:completionBlock:progressBlock:] instead." userInfo:nil] raise];
}

- (void)queryWithQuery:(id)query withCompletionBlock: (KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"Use +[KCSFileStore downloadFileByQuery:completionBlock:progressBlock:] or +[KCSFileStore downloadDataByQuery:completionBlock:progressBlock:] instead." userInfo:nil] raise];
}

- (void)removeObject:(id)object withCompletionBlock: (KCSCountBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"Use +[KCSFileStore deleteFile:completionBlock:] instead." userInfo:nil] raise];
}

- (BOOL) configureWithOptions: (NSDictionary *)options
{
    if (options) {
    }
    
    // Even if nothing happened we return YES (as it's not a failure)
    return YES;
}

@end
