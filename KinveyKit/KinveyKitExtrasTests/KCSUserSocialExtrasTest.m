//
//  KCSUserSocialExtrasTest.m
//  KinveyKit
//
//  Created by Michael Katz on 9/19/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
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
    [[[KCSClient sharedClient] currentUser] logout];
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
