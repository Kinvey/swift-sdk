//
//  KCSKeyChain.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/1/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//
//  Copyright (c) 2008-2011, Kinvey, Inc. All rights reserved.
//
//  This software contains valuable confidential and proprietary information of
//  KINVEY, INC and is subject to applicable licensing agreements.
//  Unauthorized reproduction, transmission or distribution of this file and its
//  contents is a violation of applicable laws.


// DERIVED FROM Keychain.m
//
//  Keychain.m
//  OpenStack
//
//  Based on KeychainWrapper in BadassVNC by Dylan Barrie
//
//  Created by Mike Mayo on 10/1/10.
//  The OpenStack project is provided under the Apache 2.0 license.
//

#import "KCSKeyChain.h"
#import <Security/Security.h>

@implementation KCSKeyChain

+ (NSString *)appName {    
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    
	// Attempt to find a name for this application
	NSString *appName = [bundle objectForInfoDictionaryKey:@"CFBundleDisplayName"];
	if (!appName) {
		appName = [bundle objectForInfoDictionaryKey:@"CFBundleName"];	
	}
    return appName;
}

+ (BOOL)removeStringForKey:(NSString *)key
{
    if (key == nil){
        return NO;
    }
    
    key = [NSString stringWithFormat:@"%@ - %@", [KCSKeyChain appName], key];
    
	// First check if it already exists, by creating a search dictionary and requesting that 
    // nothing be returned, and performing the search anyway.
	NSMutableDictionary *existsQueryDictionary = [NSMutableDictionary dictionary];
	
	[existsQueryDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
	
	// Add the keys to the search dict
	[existsQueryDictionary setObject:@"service" forKey:(id)kSecAttrService];
	[existsQueryDictionary setObject:key forKey:(id)kSecAttrAccount];
    
	OSStatus res = SecItemCopyMatching((CFDictionaryRef)existsQueryDictionary, NULL);

    if (res == errSecItemNotFound){
        return NO;
    } else {
        res = SecItemDelete((CFDictionaryRef)existsQueryDictionary);
        NSAssert1(res == errSecSuccess, @"Recieved %d from SecItemDelete!", res);
    }
    
    return YES;
}

+ (BOOL)setString:(NSString *)string forKey:(NSString *)key {
	if (string == nil || key == nil) {
		return NO;
	}
    
    key = [NSString stringWithFormat:@"%@ - %@", [KCSKeyChain appName], key];
    
	// First check if it already exists, by creating a search dictionary and requesting that 
    // nothing be returned, and performing the search anyway.
	NSMutableDictionary *existsQueryDictionary = [NSMutableDictionary dictionary];
	
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
	
	[existsQueryDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
	
	// Add the keys to the search dict
	[existsQueryDictionary setObject:@"service" forKey:(id)kSecAttrService];
	[existsQueryDictionary setObject:key forKey:(id)kSecAttrAccount];
    
	OSStatus res = SecItemCopyMatching((CFDictionaryRef)existsQueryDictionary, NULL);
	if (res == errSecItemNotFound) {
		if (string != nil) {
			NSMutableDictionary *addDict = existsQueryDictionary;
			[addDict setObject:data forKey:(id)kSecValueData];
            
			res = SecItemAdd((CFDictionaryRef)addDict, NULL);
			NSAssert1(res == errSecSuccess, @"Recieved %d from SecItemAdd!", res);
		}
	} else if (res == errSecSuccess) {
		// Modify an existing one
		// Actually pull it now of the keychain at this point.
		NSDictionary *attributeDict = [NSDictionary dictionaryWithObject:data forKey:(id)kSecValueData];
        
		res = SecItemUpdate((CFDictionaryRef)existsQueryDictionary, (CFDictionaryRef)attributeDict);
		NSAssert1(res == errSecSuccess, @"SecItemUpdated returned %d!", res);
		
	} else {
		NSAssert1(NO, @"Received %d from SecItemCopyMatching!", res);
	}
	
	return YES;
}

+ (NSString *)getStringForKey:(NSString *)key {
    
    key = [NSString stringWithFormat:@"%@ - %@", [KCSKeyChain appName], key];
    
	NSMutableDictionary *existsQueryDictionary = [NSMutableDictionary dictionary];
	
	[existsQueryDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
	
	// Add the keys to the search dict
	[existsQueryDictionary setObject:@"service" forKey:(id)kSecAttrService];
	[existsQueryDictionary setObject:key forKey:(id)kSecAttrAccount];
	
	// We want the data back!
	NSData *data = nil;
	
	[existsQueryDictionary setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
	
	OSStatus res = SecItemCopyMatching((CFDictionaryRef)existsQueryDictionary, (CFTypeRef *)&data);
	[data autorelease];
	if (res == errSecSuccess) {
		NSString *string = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		return string;
	} else {
		NSAssert1(res == errSecItemNotFound, @"SecItemCopyMatching returned %d!", res);
	}		
	
	return nil;
}

@end