//
//  KCSPush.h
//  KinveyKit
//
//  Created by Brian Wilson on 11/28/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface KCSPush : NSObject

#ifndef NO_URBAN_AIRSHIP_PUSH

#pragma mark push notifications
// PUSH
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;

- (void)setPushBadgeNumber: (int)number;
- (void)resetPushBadge;

// - (void) exposeSettingsViewInView: (UIViewController *)parentViewController

#endif /* NO_URBAN_AIRSHIP_PUSH */

@end
