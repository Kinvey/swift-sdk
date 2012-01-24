//
//  KinveyAnalytics.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/9/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KinveyAnalytics.h"

@implementation KCSAnalytics

@synthesize UUID=_UUID;
@synthesize UDID=_UDID;

- (id)init
{
    self = [super init];
    if (self){
        _UDID = [[[UIDevice currentDevice] uniqueIdentifier] retain];
        _UUID = nil;
    }
    return self;
}

- (void)dealloc
{
    [_UDID release];
    [_UUID release];
    [super dealloc];
}

- (NSString *)generateUUID
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uuidString = nil;
    
    if (uuid){
        uuidString = (NSString *)CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
    }
    // CreateString creates the string, so we own this string.
    // We must ensure it gets destroyed
    return [uuidString autorelease];
}

// Always return the same UUID for all users.
- (NSString *)UUID
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:KCS_UUID_USER_DEFAULTS_KEY] == nil) {
        [defaults setObject:[self generateUUID] forKey:KCS_UUID_USER_DEFAULTS_KEY];
        [defaults synchronize];
    }
    
    // Return the stored version
    return [defaults objectForKey:KCS_UUID_USER_DEFAULTS_KEY];

}

@end
