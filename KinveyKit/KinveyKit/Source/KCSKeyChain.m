 //
//  KCSKeyChain.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/1/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//
//  Copyright (c) 2008-2013, Kinvey, Inc. All rights reserved.
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
#import "KCSLogManager.h"
#import <Security/Security.h>

@implementation KCSKeyChain

+ (NSString *)appName {    
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    
	// (NSData*)CFBridgingRelease(data) to find a name for this application
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
	
	[existsQueryDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
	
	// Add the keys to the search dict
	[existsQueryDictionary setObject:@"service" forKey:(__bridge id)kSecAttrService];
	[existsQueryDictionary setObject:key forKey:(__bridge id)kSecAttrAccount];
    
	OSStatus res = SecItemCopyMatching((__bridge CFDictionaryRef)existsQueryDictionary, NULL);

    if (res == errSecItemNotFound){
        return NO;
    } else {
        res = SecItemDelete((__bridge CFDictionaryRef)existsQueryDictionary);
        NSAssert(res == errSecSuccess, @"Recieved %@ from SecItemDelete!", @(res));
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
	
	
	[existsQueryDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
	
	// Add the keys to the search dict
    existsQueryDictionary[(__bridge id)kSecAttrService] = @"service";
    existsQueryDictionary[(__bridge id)kSecAttrAccount] = key;
    
    CFTypeRef o = nil;
	OSStatus res = SecItemCopyMatching((__bridge CFDictionaryRef)existsQueryDictionary, &o);
	if (res == errSecItemNotFound) {
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
        
        NSMutableDictionary *addDict = [NSMutableDictionary dictionaryWithDictionary:existsQueryDictionary];
        addDict[(__bridge id)kSecValueData] = data;
        
        res = SecItemAdd((__bridge CFDictionaryRef)addDict, NULL);
        NSAssert1(res == errSecSuccess, @"Recieved %@ from SecItemAdd!", @(res));
	} else if (res == errSecSuccess) {
		// Modify an existing one
		// Actually pull it now of the keychain at this point.
        NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
		NSDictionary *attributeDict = [NSDictionary dictionaryWithObject:data forKey:(__bridge id)kSecValueData];
        
		res = SecItemUpdate((__bridge CFDictionaryRef)existsQueryDictionary, (__bridge CFDictionaryRef)attributeDict);
		NSAssert1(res == errSecSuccess, @"SecItemUpdated returned %@!", @(res));
		
	} else {
        KCSLogError(@"SecItemCopyMatching returned %@ for key '%@'!", @(res), key);
	}
	
	return YES;
}



+ (NSString *)getStringForKey:(NSString *)key {
    
    key = [NSString stringWithFormat:@"%@ - %@", [KCSKeyChain appName], key];
    
	NSMutableDictionary *existsQueryDictionary = [NSMutableDictionary dictionary];
	
	[existsQueryDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
	
	// Add the keys to the search dict
	[existsQueryDictionary setObject:@"service" forKey:(__bridge id)kSecAttrService];
	[existsQueryDictionary setObject:key forKey:(__bridge id)kSecAttrAccount];
	
	// We want the data back!
	CFTypeRef data = nil;
	
	[existsQueryDictionary setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
	
	OSStatus res = SecItemCopyMatching((__bridge CFDictionaryRef)existsQueryDictionary, (CFTypeRef *)&data);
	if (res == errSecSuccess) {
		NSString *string = [[NSString alloc] initWithData:(NSData*)CFBridgingRelease(data) encoding:NSUTF8StringEncoding];
		return string;
	} else if (res == errSecItemNotFound) {
		KCSLogError(@"SecItemCopyMatching returned %@ for key '%@'!", @(res), key);
	}		
	
	return nil;
}

//TODO: refactor and combine
+ (BOOL)setDict:(NSDictionary *)dict forKey:(NSString *)key
{
    if (dict == nil || key == nil) {
		return NO;
	}
    
    key = [NSString stringWithFormat:@"%@ - %@", [KCSKeyChain appName], key];
    
	// First check if it already exists, by creating a search dictionary and requesting that
    // nothing be returned, and performing the search anyway.
	NSMutableDictionary *existsQueryDictionary = [NSMutableDictionary dictionary];
	
    NSData* data = [NSKeyedArchiver archivedDataWithRootObject:dict];
	
	[existsQueryDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
	
	// Add the keys to the search dict
	[existsQueryDictionary setObject:@"service" forKey:(__bridge id)kSecAttrService];
	[existsQueryDictionary setObject:key forKey:(__bridge id)kSecAttrAccount];
    
    CFTypeRef o = nil;
	OSStatus res = SecItemCopyMatching((__bridge CFDictionaryRef)existsQueryDictionary, &o);
	if (res == errSecItemNotFound) {
        NSMutableDictionary *addDict = [NSMutableDictionary dictionaryWithDictionary:existsQueryDictionary];
        addDict[(__bridge id)kSecValueData] = data;
        
        res = SecItemAdd((__bridge CFDictionaryRef)addDict, &o);
        NSAssert1(res == errSecSuccess, @"Recieved %@ from SecItemAdd!", @(res));
	} else if (res == errSecSuccess) {
		// Modify an existing one
		// Actually pull it now of the keychain at this point.
		NSDictionary *attributeDict = [NSDictionary dictionaryWithObject:data forKey:(__bridge id)kSecValueData];
        
		res = SecItemUpdate((__bridge CFDictionaryRef)existsQueryDictionary, (__bridge CFDictionaryRef)attributeDict);
		NSAssert1(res == errSecSuccess, @"SecItemUpdated returned %@!", @(res));
		
	} else {
        KCSLogError(@"results = %@", o);
		NSAssert1(NO, @"Received %@ from SecItemCopyMatching!", @(res));
	}
	
	return YES;
}

+ (NSDictionary *)getDictForKey:(NSString *)key
{
    
    key = [NSString stringWithFormat:@"%@ - %@", [KCSKeyChain appName], key];
    
	NSMutableDictionary *existsQueryDictionary = [NSMutableDictionary dictionary];
	
	[existsQueryDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
	
	// Add the keys to the search dict
	[existsQueryDictionary setObject:@"service" forKey:(__bridge id)kSecAttrService];
	[existsQueryDictionary setObject:key forKey:(__bridge id)kSecAttrAccount];
	
	// We want the data back!
	CFTypeRef data = nil;
	
	[existsQueryDictionary setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
	
	OSStatus res = SecItemCopyMatching((__bridge CFDictionaryRef)existsQueryDictionary, (CFTypeRef *)&data);
	if (res == errSecSuccess) {
        NSDictionary* dict = [NSKeyedUnarchiver unarchiveObjectWithData:(NSData*)CFBridgingRelease(data)];
        return dict;
	} else {
		NSAssert1(res == errSecItemNotFound, @"SecItemCopyMatching returned %@!", @(res));
	}
	
	return nil;
}

@end
