//
//  KCSPush.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/28/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSPush.h"
#import "KCSClient.h"

#ifndef NO_URBAN_AIRSHIP_PUSH
#import "UAirship.h"
#import "UAPush.h"
#endif


@implementation KCSPush


#ifndef NO_URBAN_AIRSHIP_PUSH
#pragma mark UA Init

- (void)initializeUrbanAirshipWithOptions: (NSDictionary *)options
{
    
    NSNumber *val = [options valueForKey:KCS_PUSH_IS_ENABLED_KEY];
    
    if ([val boolValue] == NO){
        // We don't want any of this code, so... we're done.
        return;
    }
    
    // Set up the UA stuff
    //Init Airship launch options
    
    NSMutableDictionary *airshipConfigOptions = [[[NSMutableDictionary alloc] init] autorelease];
    NSMutableDictionary *takeOffOptions = [[[NSMutableDictionary alloc] init] autorelease];
    
    
    if ([[options valueForKey:KCS_PUSH_MODE_KEY] isEqualToString:KCS_PUSH_DEBUG]){
        [airshipConfigOptions setValue:@"NO" forKey:@"APP_STORE_OR_AD_HOC_BUILD"];
        [airshipConfigOptions setValue:[options valueForKey:KCS_PUSH_KEY_KEY] forKey:@"DEVELOPMENT_APP_KEY"];
        [airshipConfigOptions setValue:[options valueForKey:KCS_PUSH_SECRET_KEY] forKey:@"DEVELOPMENT_APP_SECRET"];
    } else {
        [airshipConfigOptions setValue:@"YES" forKey:@"APP_STORE_OR_AD_HOC_BUILD"];
        [airshipConfigOptions setValue:@"Your production app key" forKey:@"PRODUCTION_APP_KEY"];
        [airshipConfigOptions setValue:@"Your production app secret" forKey:@"PRODUCTION_APP_SECRET"];
    }
    
    [takeOffOptions setValue:airshipConfigOptions forKey:UAirshipTakeOffOptionsAirshipConfigKey];
    
    // Create Airship singleton that's used to talk to Urban Airship servers.
    // Please replace these with your info from http://go.urbanairship.com
    [UAirship takeOff:takeOffOptions];
    
    // Register for notifications through UAPush for notification type tracking
    [[UAPush shared] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                         UIRemoteNotificationTypeSound |
                                                         UIRemoteNotificationTypeAlert)];
    
    
    [[UAPush shared] enableAutobadge:YES];
    [[UAPush shared] resetBadge];//zero badge
    
    
}
#pragma mark Push
// Push helpers

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    UALOG(@"Received remote notification: %@", userInfo);
    
    [[UAPush shared] handleNotification:userInfo applicationState:application.applicationState];
    [[UAPush shared] resetBadge]; // zero badge after push received
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    // Updates the device token and registers the token with UA
    [[UAPush shared] registerDeviceToken:deviceToken];
}

- (void)setPushBadgeNumber: (int)number
{
    [[UAPush shared] setBadgeNumber:number];
}

- (void)resetPushBadge
{
    [[UAPush shared] resetBadge];//zero badge
}

- (void) exposeSettingsViewInView: (UIViewController *)parentViewController
{
    [UAPush openApnsSettings:parentViewController animated:YES];
}

#endif /* NO_URBAN_AIRSHIP_PUSH */

@end
