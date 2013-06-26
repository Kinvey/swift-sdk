//
//  KCSBlobService.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/9/11.
//  Copyright (c) 2011-2013 Kinvey. All rights reserved.
//

#import "KCSBlobService.h"

@implementation KCSResourceResponse
@end

@implementation KCSResourceService

+ (void)downloadResource: (NSString *)resourceId withResourceDelegate: (id<KCSResourceDelegate>)delegate
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSResourceSerivce downloadResource:withResourceDelegate:] has been removed. Use +[KCSFileStore downloadFileByName:completionBlock:progressBlock:] or +[KCSFileStore downloadDataByName:completionBlock:progressBlock:] instead." userInfo:nil] raise];
}

+ (void)downloadResource:(NSString *)resourceId completionBlock:(KCSCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSResourceSerivce downloadResource:withResourceDelegate:] has been removed. Use +[KCSFileStore downloadFileByName:completionBlock:progressBlock:] or +[KCSFileStore downloadDataByName:completionBlock:progressBlock:] instead." userInfo:nil] raise];
}

+ (void)downloadResource:(NSString *)resourceId toFile:(NSString *)filename withResourceDelegate:(id<KCSResourceDelegate>)delegate
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSResourceSerivce downloadResource:withResourceDelegate:] has been removed. Use +[KCSFileStore downloadFileByName:completionBlock:progressBlock:] or +[KCSFileStore downloadDataByName:completionBlock:progressBlock:] instead." userInfo:nil] raise];
}

+ (void)downloadResource:(NSString *)resourceId toFile:(NSString *)filename completionBlock:(KCSCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSResourceSerivce downloadResource:withResourceDelegate:] has been removed. Use +[KCSFileStore downloadFileByName:completionBlock:progressBlock:] or +[KCSFileStore downloadDataByName:completionBlock:progressBlock:] instead." userInfo:nil] raise];
}

#pragma mark - Get Streaming

+ (void)getStreamingURLForResource:(NSString *)resourceId withResourceDelegate:(id<KCSResourceDelegate>)delegate
{
     [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSFileStore getStreamingURL(ByName):completionBlock:] instead." userInfo:nil] raise];
}

+ (void)getStreamingURLForResource:(NSString *)resourceId completionBlock:(KCSCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSFileStore getStreamingURL(ByName):completionBlock:] instead." userInfo:nil] raise];
}

#pragma mark - Save

+ (void)saveLocalResource:(NSString *)filename withDelegate:(id<KCSResourceDelegate>)delegate
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSFileStore uploadFile:options:completionBlock:progressBlock:] instead." userInfo:nil] raise];
}

+ (void)saveLocalResource:(NSString *)filename completionBlock:(KCSCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSFileStore uploadFile:options:completionBlock:progressBlock:] instead." userInfo:nil] raise];
}

+ (void)saveLocalResourceWithURL:(NSURL *)URL toResource:(NSString *)resourceId withDelegate:(id<KCSResourceDelegate>)delegate
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSFileStore uploadFile:options:completionBlock:progressBlock:] instead." userInfo:nil] raise];
}

+ (void)saveLocalResourceWithURL:(NSURL *)URL toResource:(NSString *)resourceId completionBlock:(KCSCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSFileStore uploadFile:options:completionBlock:progressBlock:] instead." userInfo:nil] raise];
}


+ (void)saveLocalResourceWithURL:(NSURL *)URL withDelegate:(id<KCSResourceDelegate>)delegate
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSFileStore uploadFile:options:completionBlock:progressBlock:] instead." userInfo:nil] raise];
}

+ (void)saveLocalResourceWithURL:(NSURL *)URL completionBlock:(KCSCompletionBlock)completionBlock progressBlock:(KCSProgressBlock)progressBlock
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSFileStore uploadFile:options:completionBlock:progressBlock:] instead." userInfo:nil] raise];
}

+ (void)saveLocalResource:(NSString *)filename
               toResource:(NSString *)resourceId
             withDelegate:(id<KCSResourceDelegate>)delegate
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSFileStore uploadFile:options:completionBlock:progressBlock:] instead." userInfo:nil] raise];
}

+ (void)saveLocalResource:(NSString *)filename
               toResource:(NSString *)resourceId
          completionBlock:(KCSCompletionBlock)completionBlock
            progressBlock:(KCSProgressBlock)progressBlock
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSFileStore uploadFile:options:completionBlock:progressBlock:] instead." userInfo:nil] raise];
}

+ (void)saveData:(NSData *)data
      toResource:(NSString *)resourceId
    withDelegate:(id<KCSResourceDelegate>)delegate
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSFileStore uploadData:options:completionBlock:progressBlock:] instead." userInfo:nil] raise];
}

+ (void)saveData:(NSData *)data
      toResource:(NSString *)resourceId
 completionBlock:(KCSCompletionBlock)completionBlock
   progressBlock:(KCSProgressBlock)progressBlock
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSFileStore uploadData:options:completionBlock:progressBlock:] instead." userInfo:nil] raise];
}

#pragma mark - Removing Files
+ (void)deleteResource:(NSString *)resourceId
          withDelegate:(id<KCSResourceDelegate>)delegate
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSFileStore deleteFile:completionBlock:] instead." userInfo:nil] raise];
}

+ (void)deleteResource:(NSString *)resourceId
       completionBlock:(KCSCompletionBlock)completionBlock
         progressBlock:(KCSProgressBlock)progressBlock
{
    [[NSException exceptionWithName:@"KCSFunctionalityRemoved" reason:@"+[KCSFileStore deleteFile:completionBlock:] instead." userInfo:nil] raise];
}

@end
