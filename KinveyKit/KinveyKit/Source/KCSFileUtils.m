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

static BOOL _kcsFileUtilsDataUnavailable = NO;

#warning TODO: for complete and locked use XXCompleteUnlessOpen and listen for availability and then change  \ Can just try writeComplete || or writeUnlesOpen \/ keychain this device only

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
            key = _kcsFileUtilsDataUnavailable ? NSFileProtectionCompleteUnlessOpen : NSFileProtectionComplete;
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

+ (NSDataWritingOptions) dataOptions
{
    KCSDataProtectionLevel level = [[KCSClient2 sharedClient].configuration.options[KCS_DATA_PROTECTION_LEVEL] integerValue];
    NSDataWritingOptions options = NSDataWritingFileProtectionNone;
    switch (level) {
        case KCSDataComplete:
            options = NSDataWritingFileProtectionComplete;
            break;
        case KCSDataCompleteUnlessOpen:
            options = NSDataWritingFileProtectionCompleteUnlessOpen;
            break;
        case KCSDataCompleteUntilFirstLogin:
            options = NSDataWritingFileProtectionCompleteUntilFirstUserAuthentication;
            break;
        default:
            break;
    }
    return options;
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

+ (NSError*) writeData:(NSData*)data toURL:(NSURL*)url
{
    NSError* fileError = nil;
    
    [data writeToURL:url options:[self dataOptions] error:&fileError];
    if (fileError) {
        KCSLogError(KCS_LOG_CONTEXT_NETWORK, @"Error writing resume data: %@", fileError);
    }
    return fileError;
}

+ (void) touchFile:(NSURL*)url
{
    if ([[self filemanager] fileExistsAtPath:[url path]] == NO) {
        [[self filemanager] createFileAtPath:[url path] contents:nil attributes:@{NSFileProtectionKey : [self fileProtectionKey]}];
    }
}

+ (NSError*) moveFile:(NSURL*)source to:(NSURL*)destination
{
    NSError* error = nil;
    [[self filemanager] moveItemAtURL:source toURL:destination error:&error];
    if (!error) {
        [[self filemanager] setAttributes:@{NSFileProtectionKey : [self fileProtectionKey]} ofItemAtPath:[destination path] error:&error];
    }
    
    return error;
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


+ (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL
{
    if ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileWriteFileExistsError) {
        return YES;
    }
    return NO;
}

+ (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath
{
    if ([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == NSFileWriteFileExistsError) {
        return YES;
    }
    return NO;
}

#pragma mark - Data Protection

+ (void) dataDidBecomeAvailable
{
    _kcsFileUtilsDataUnavailable = NO;
    //iterate over files to match protection level
    NSDirectoryEnumerator* de = [[self filemanager] enumeratorAtPath:[[self filesFolder] path]];
    NSString* fpk = [self fileProtectionKey];
    for (NSString* path in de) {
        NSDictionary* attrs = [de fileAttributes];
        if (![attrs[NSFileProtectionKey] isEqual:fpk]) {
            attrs = @{NSFileProtectionKey : fpk};
            NSError* error = nil;
            [[self filemanager] setAttributes:attrs ofItemAtPath:path error:&error];
            KCSLogNSError(KCS_LOG_CONTEXT_FILESYSTEM, error);
        }
    }
}

+ (void) dataDidBecomeUnavailable
{
    _kcsFileUtilsDataUnavailable = YES;
}

@end
