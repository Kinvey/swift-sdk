//
//  KCSClient+KinveyKit2.m
//  KinveyKit
//
//  Created by Michael Katz on 5/30/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "KCSClient+KinveyKit2.h"
#import "KCSLogManager.h"
#import "KCSBase64.h"

@implementation KCSClient (KinveyKit2)
- (NSString *)authString
{
    KCSLogDebug(@"Using app key/app secret for auth: (%@, <APP_SECRET>) => XXXXXXXXX", [[KCSClient sharedClient] appKey]);
    return KCSbasicAuthString(self.appKey, self.appSecret);
}
@end
