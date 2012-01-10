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
        _UUID = [self.UDID retain];
    }
    return self;
}

- (NSString *)generateUUID
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uuidString = nil;
    
    if (uuid){
        uuidString = (NSString *)CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
    }
    return uuidString;
}

@end
