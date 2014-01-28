//
//  KCSUserSocialExtrasTest.m
//  KinveyKit
//
//  Created by Michael Katz on 9/19/12.
//  Copyright (c) 2012-2014 Kinvey. All rights reserved.
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


#import "KCSUserSocialExtrasTest.h"
#import "KinveyKitExtras.h"
#import "KCSUser+SocialExtras.h"
#import "TestUtils.h"

@implementation KCSUserSocialExtrasTest

- (void) testTwitterReverseAuth
{
    [TestUtils justInitServer];
    
    // Ensure user is logged out
    [[KCSUser activeUser] logout];
    self.done = NO;
    
    [KCSUser getAccessDictionaryFromTwitterFromPrimaryAccount:^(NSDictionary *accessBlockOrNil, NSError *errorOrNil) {
        STAssertNoError;
        STAssertEquals((int)accessBlockOrNil.count, (int)2, @"should have two items");
        STAssertNotNil([accessBlockOrNil objectForKey:@"access_token"], @"should have an access token");
        STAssertNotNil([accessBlockOrNil objectForKey:@"access_token_secret"], @"should have an acess token secret");
        self.done = YES;
    }];
    [self poll];
}

@end
