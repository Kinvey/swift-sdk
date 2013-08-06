//
//  KCSDevice.h
//  KinveyKit
//
//  Created by Michael Katz on 11/2/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
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

@interface KCSDevice : NSObject

+ (KCSDevice*) currentDevice;

/* The current session's token for this device to receive notifications */
@property (nonatomic, strong) NSData *deviceToken;

/* Return the device's token as a string
 
 Return the current session's device token for push as an NSString.
 
 @return The NSString representing the device token.
 
 */
- (NSString *)deviceTokenString;

@end
