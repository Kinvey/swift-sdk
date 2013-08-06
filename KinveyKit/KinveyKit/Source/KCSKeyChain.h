//
//  KCSKeyChain.h
//  KinveyKit
//
//  Copyright (c) 2008-2013, Kinvey, Inc. All rights reserved.
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


// DERIVED FROM Keychain.h
//
//  Keychain.h
//  OpenStack
//
//  Based on KeychainWrapper in BadassVNC by Dylan Barrie
//
//  Created by Mike Mayo on 10/1/10.
//  The OpenStack project is provided under the Apache 2.0 license.
//

#import <Foundation/Foundation.h>

// This wrapper helps us deal with Keychain-related things 
// such as storing API keys and passwords

@interface KCSKeyChain : NSObject

+ (BOOL)setString:(NSString *)string forKey:(NSString *)key;
+ (NSString *)getStringForKey:(NSString *)key;
+ (BOOL)removeStringForKey:(NSString *)key;

+ (BOOL)setDict:(NSDictionary *)dict forKey:(NSString *)key;
+ (NSDictionary *)getDictForKey:(NSString *)key;
@end
