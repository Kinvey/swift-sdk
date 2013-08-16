//
//  KCSClientConfiguration.h
//  KinveyKit
//
//  Created by Michael Katz on 8/16/13.
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


#import <Foundation/Foundation.h>

/** Configuration wrapper for setting up a KCSClient. Configurations are adjustable at compile- or run-time. See the guides at http://devecenter.kinvey.com for how configurations work with app environments.
 
 @since 1.20.0
 */
@interface KCSClientConfiguration : NSObject

@property (nonatomic, copy) NSString* appKey;
@property (nonatomic, copy) NSString* appSecret;
@property (nonatomic, copy) NSDictionary* options;

+ (instancetype) configurationWithAppKey:(NSString*)appKey secret:(NSString*)appSecret;
+ (instancetype) configurationWithAppKey:(NSString*)appKey secret:(NSString*)appSecret options:(NSDictionary*)dictionary;
+ (instancetype) configurationFromPlist;

@end
