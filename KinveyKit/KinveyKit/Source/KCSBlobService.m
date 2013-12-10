//
//  KCSBlobService.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/9/11.
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
