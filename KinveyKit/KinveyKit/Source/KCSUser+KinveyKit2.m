//
//  KCSUser+KinveyKit2.m
//  KinveyKit
//
//  Created by Michael Katz on 5/30/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "KCSUser+KinveyKit2.h"
#import "KCSLogManager.h"
#import "KCSBase64.h"

@implementation KCSUser (KinveyKit2)

- (NSString *)authString
{
    NSString *authString = nil;
    if (self.sessionAuth) {
        authString = [@"Kinvey " stringByAppendingString: self.sessionAuth];
        KCSLogDebug(@"Current user found, using sessionauth (%@) => XXXXXXXXX", self.username);
    } else {
        authString = KCSbasicAuthString(self.username, self.password);
        KCSLogDebug(@"Current user found (%@, XXXXXXXXX) => XXXXXXXXX", self.username);
    }
    return authString;
}

@end
