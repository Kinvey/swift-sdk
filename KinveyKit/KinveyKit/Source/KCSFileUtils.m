//
//  KCSFileUtils.m
//  KinveyKit
//
//  Created by Michael Katz on 10/25/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
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

#import "KCSFileUtils.h"
#import "KinveyCoreInternal.h"


@implementation KCSFileUtils

+ (NSFileManager*) filemanager
{
    static NSFileManager* manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[NSFileManager alloc] init];
        manager.delegate = self;
    });
    return manager;
}

+ (NSString*) fileProtectionKey
{
    KCSDataProtectionLevel level = [[KCSClient2 sharedClient].configuration.options[KCS_DATA_PROTECTION_LEVEL] integerValue];
    NSString* key = NSFileProtectionNone;
    switch (level) {
        case KCSDataComplete:
            key = NSFileProtectionComplete;
            break;
        case KCSDataCompleteUnlessOpen:
            key = NSFileProtectionCompleteUnlessOpen;
            break;
        case KCSDataCompleteUntilFirstLogin:
            key = NSFileProtectionCompleteUntilFirstUserAuthentication;
            break;
        default:
            break;
    }
    return key;
}

+ (NSString*) kinveyDir
{
    NSString* kinveyDir =  [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"kinvey"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:kinveyDir] == NO) {
        //TODO: security?
        NSError* error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:kinveyDir withIntermediateDirectories:YES attributes:@{NSFileProtectionKey : [self fileProtectionKey]} error:&error];
        KCSLogNSError(KCS_LOG_CONTEXT_FILESYSTEM, error);
    }
    return kinveyDir;
}

+ (NSString*) localPathForDB:(NSString*)dbname
{
    return [[self kinveyDir] stringByAppendingPathComponent:dbname];
}

+ (NSURL*) filesFolder
{
    NSURL* kinveyFolder = [NSURL fileURLWithPath:[self kinveyDir]];
    NSURL* folder = [kinveyFolder URLByAppendingPathComponent:@"files/"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[folder path]] == NO) {
        //TODO: security?
        NSError* error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:[folder path] withIntermediateDirectories:YES attributes:nil error:&error];
        KCSLogNSError(KCS_LOG_CONTEXT_FILESYSTEM, error);
    }
    return folder;
}

+ (NSURL*) fileURLForName:(NSString*)name
{
    NSURL* cachesDir = [KCSFileUtils filesFolder];
    NSString* tempName = [NSString stringByPercentEncodingString:[name stringByReplacingOccurrencesOfString:@"/" withString:@""]];
    NSURL*  destinationFile = [NSURL fileURLWithPathComponents:@[cachesDir.path, tempName]]; //concat weird paths, such as with spaces (#2704)
    return destinationFile;
}

+ (BOOL) clearFiles
{
    NSError* error = nil;
    BOOL removed = [[self filemanager] removeItemAtPath:[[self filesFolder] path] error:&error];
    KCSLogNSError(KCS_LOG_CONTEXT_FILESYSTEM, error);
    
    [self filesFolder];
    
    return removed;
}

#pragma mark - File manager

+ (BOOL)fileManager:(NSFileManager *)fileManager shouldRemoveItemAtPath:(NSString *)path
{
    return YES;
}

+ (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error removingItemAtPath:(NSString *)path
{
    return YES;
}
@end
