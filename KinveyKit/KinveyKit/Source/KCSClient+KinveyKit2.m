//
//  KCSClient+KinveyKit2.m
//  KinveyKit
//
//  Created by Michael Katz on 5/30/13.
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
