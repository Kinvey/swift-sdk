//
//  KCSDevice.h
//  KinveyKit
//
//  Created by Michael Katz on 11/2/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
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
