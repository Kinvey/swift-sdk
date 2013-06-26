//
//  KCSResourceStore.m
//  KinveyKit
//
//  Created by Brian Wilson on 5/3/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
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
    return [self storeWithAuthHandler:nil withOptions:nil];
}

+ (instancetype)storeWithOptions: (NSDictionary *)options
{
    return [self storeWithAuthHandler:nil withOptions:options];
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

- (void)removeObject:(id)object withCompletionBlock: (KCSCompletionBlock)completionBlock withProgressBlock: (KCSProgressBlock)progressBlock
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
