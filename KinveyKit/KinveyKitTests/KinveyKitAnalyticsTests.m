//
//  KinveyKitAnalyticsTests.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/19/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KinveyKitAnalyticsTests.h"
#import "KCSClient.h"
#import "KinveyAnalytics.h"
#import "KCSAnalytics+UniqueHardwareID.h"

@implementation KinveyKitAnalyticsTests

// All code under test must be linked into the Unit Test bundle
- (void)testGenerateUUIDUniquenessn
{
    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid6969"
                                                 withAppSecret:@"secret"
                                                  usingOptions:nil];
    KCSAnalytics *lytics = [[KCSClient sharedClient] analytics];
    
    NSString *UUID = [lytics generateUUID];
    assertThat([lytics generateUUID], isNot(UUID));
}

- (void)testUUIDNotUsingDeprecatedUDID
{
    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid6969"
                                                 withAppSecret:@"secret"
                                                  usingOptions:nil];
    
    KCSAnalytics *lytics = [[KCSClient sharedClient] analytics];
    
    assertThat(lytics.UUID, isNot(lytics.UDID));
}

- (void)testMACAddressGetsMACLikeAddress
{
    NSString *kinveyUDID = [[[KCSClient sharedClient] analytics] kinveyUDID];
    NSString *macAddr = [[[KCSClient sharedClient] analytics] getMacAddress];
    
    assertThat(kinveyUDID, is(macAddr));
}

@end
