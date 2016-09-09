//
//  KCSKeychain2.m
//  KinveyKit
//
//  Created by Michael Katz on 12/11/13.
//  Copyright (c) 2013-2015 Kinvey. All rights reserved.
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

#import "KCSKeychain.h"
#import "KinveyCoreInternal.h"
#import "KCSClient.h"

#define KCS_KEYCHAIN_BUG_ERROR_CODE -34018

@implementation KCSKeychain2

+ (CFTypeRef) accessKey
{
    KCSDataProtectionLevel level = [[KCSClient2 sharedClient].configuration.options[KCS_DATA_PROTECTION_LEVEL] integerValue];
    CFTypeRef access = kSecAttrAccessibleAlwaysThisDeviceOnly;
    switch (level) {
        case KCSDataComplete:
            access = kSecAttrAccessibleWhenUnlockedThisDeviceOnly;
            break;
        case KCSDataCompleteUnlessOpen:
            access = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
            break;
        case KCSDataCompleteUntilFirstLogin:
            access = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
            break;
        default:
            break;
    }
    return access;
    
}

+ (NSString*) stringForSecErrorCode:(OSStatus) status
{
    NSString* message = nil;
    switch (status) {
        case errSecSuccess               : message = @"No error."; break;
        case errSecUnimplemented         : message = @"Function or operation not implemented."; break;
        case errSecIO                    : message = @"I/O error (bummers)"; break;
        case errSecOpWr                  : message = @"File already open with with write permission"; break;
        case errSecParam                 : message = @"One or more parameters passed to a function where not valid."; break;
        case errSecAllocate              : message = @"Failed to allocate memory."; break;
        case errSecUserCanceled          : message = @"User canceled the operation."; break;
        case errSecBadReq                : message = @"Bad parameter or invalid state for operation."; break;
        case errSecNotAvailable          : message = @"No keychain is available. You may need to restart your computer."; break;
        case errSecDuplicateItem         : message = @"The specified item already exists in the keychain."; break;
        case errSecItemNotFound          : message = @"The specified item could not be found in the keychain."; break;
        case errSecInteractionNotAllowed : message = @"User interaction is not allowed."; break;
        case errSecDecode                : message = @"Unable to decode the provided data."; break;
        case errSecAuthFailed            : message = @"The user name or passphrase you entered is not correct."; break;
        default:
            break;
    }
    return message;
}

static NSMutableDictionary* lastValidTokenMap = nil;

+(void)initialize
{
    [super initialize];
    
    lastValidTokenMap = [NSMutableDictionary dictionary];
}

+ (BOOL) setKinveyToken:(NSString*)token user:(NSString*)userId
{
    @synchronized (self) {
        NSData *tokenData = [token dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* attributes = @{(__bridge id)kSecAttrAccessible  : (__bridge id)[self accessKey],
                                     (__bridge id)kSecValueData       : tokenData,
                                     (__bridge id)kSecAttrDescription : @"Kinvey Auth Token",
                                     (__bridge id)kSecAttrAccount     : userId,
                                     (__bridge id)kSecAttrService     : @"com.kinvey.KinveyKit.authToken"
                                     };
        OSStatus status;
        if ([self kinveyTokenForUserId:userId]) {
            NSDictionary* query = @{(__bridge id)kSecClass       : (__bridge id)kSecClassGenericPassword,
                                    (__bridge id)kSecAttrAccount : userId,
                                    (__bridge id)kSecAttrService : @"com.kinvey.KinveyKit.authToken"
                                    };
            status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributes);
        } else {
            attributes = [attributes dictionaryByAddingDictionary:@{(__bridge id)kSecClass : (__bridge id)kSecClassGenericPassword}];
            status = SecItemAdd((__bridge CFDictionaryRef)(attributes), NULL);
        }
        BOOL success = status == errSecSuccess;
        if (!success) {
            KCSLogError(KCS_LOG_CONTEXT_USER, @"Could not write token to keychain. Err %@ (%@)", [self stringForSecErrorCode:status], @(status));
            if (status == KCS_KEYCHAIN_BUG_ERROR_CODE) {
                NSString* reason = [NSString stringWithFormat:@"Could not write token to keychain. Err %@ (%@)", [self stringForSecErrorCode:status], @(status)];
                NSDictionary* userInfo = @{
                    NSLocalizedDescriptionKey : reason,
                    NSLocalizedFailureReasonErrorKey : reason
                };
                @throw [NSException exceptionWithName:@"KinveyException"
                                               reason:reason
                                             userInfo:userInfo];
            }
        } else {
            if (token) {
                lastValidTokenMap[userId] = token;
            } else {
                [lastValidTokenMap removeObjectForKey:userId];
            }
        }
        return success;
    }
}

+ (NSString*) kinveyTokenForUserId:(NSString*)userId
{
    @synchronized (self) {
        CFTypeRef result = nil;
        NSDictionary* query = @{(__bridge id)kSecClass       : (__bridge id)kSecClassGenericPassword,
                                (__bridge id)kSecAttrAccount : userId,
                                (__bridge id)kSecAttrService : @"com.kinvey.KinveyKit.authToken",
                                (__bridge id)kSecReturnData  : @YES
                                };
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
        BOOL success = status == errSecSuccess;
        
        NSString* token = nil;
        if (!success) {
            /*
             TODO! FIXME!
             MLIBZ-381: SDK Keychain bug preventing login
             This is a workaround for MLIBZ-381 until Apple fix the bug in their API.
             
             Description of the workaround solution:
             Try to get the value from the keychain, if it fails with the error code that we know that causes the issue (-34018), we return the last valid value (in memory) that we have
             */
            if (status == KCS_KEYCHAIN_BUG_ERROR_CODE) {
                token = lastValidTokenMap[userId];
            } else {
                //if it's not the error code that we know that causes the issue (-34018), update the last valid value variable
                [lastValidTokenMap removeObjectForKey:userId];
                
                if (status != errSecItemNotFound) {
                    //only log if error is something other than not found
                    KCSLogError(KCS_LOG_CONTEXT_USER, @"Could not read token from keychain. Err %@ (%@)", [self stringForSecErrorCode:status], @(status));
                }
            }
        } else {
            if (result != nil) {
                token = [[NSString alloc] initWithData:(NSData*)CFBridgingRelease(result) encoding:NSUTF8StringEncoding];
                if (token) {
                    lastValidTokenMap[userId] = token;
                }
            }
        }
        
        return token;
    }
}

+ (BOOL) hasTokens
{
    @synchronized (self) {
        NSDictionary* query = @{(__bridge id)kSecClass       : (__bridge id)kSecClassGenericPassword,
                                (__bridge id)kSecAttrService : @"com.kinvey.KinveyKit.authToken",
                                };
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, NULL);
        
        BOOL success = status == errSecSuccess;
        if (!success) {
            if (status == KCS_KEYCHAIN_BUG_ERROR_CODE) {
                success = lastValidTokenMap.count > 0;
            } else {
                if (status != errSecItemNotFound) {
                    //only log if error is something other than not found (not founds are expected since this method is used to also check existence)
                    KCSLogError(KCS_LOG_CONTEXT_USER, @"Could not query token in the keychain. Err %@ (%@)", [self stringForSecErrorCode:status], @(status));
                }
            }
        }
        
        return success;
    }
}



+ (BOOL) deleteTokens
{
    @synchronized (self) {
        NSDictionary* query = @{(__bridge id)kSecClass       : (__bridge id)kSecClassGenericPassword,
                                (__bridge id)kSecAttrService : @"com.kinvey.KinveyKit.authToken",
                                };
        OSStatus status = SecItemDelete((__bridge CFDictionaryRef)(query));
        
        BOOL success = status == errSecSuccess;
        if (!success) {
            if (status != errSecItemNotFound) {
                //only log if error is something other than not found (not founds are expected since this method is used to also check existence)
                KCSLogError(KCS_LOG_CONTEXT_USER, @"Could not delete token from keychain. Err %@ (%@)", [self stringForSecErrorCode:status], @(status));
            }
        }
        
        [lastValidTokenMap removeAllObjects];
        
        return success;
    }
}

@end
