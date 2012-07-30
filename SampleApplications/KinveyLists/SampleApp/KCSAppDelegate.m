//
//  KCSAppDelegate.m
//  SampleApp
//
//  Created by Brian Wilson on 10/24/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSAppDelegate.h"
#import <KinveyKit/KinveyKit.h>

@implementation KCSAppDelegate


@synthesize window = _window;
@synthesize imageCache=_imageCache;


- (void)dealloc
{
    [_window release];
    [_imageCache release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    // TODO: Need to add conditional for iPad
    
    // At this point we start the loading sequence, and signal (later) when it's done
    // This NEEEEDS to be done here...
//    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:@"kid1081" withAppSecret:@"0d934bb1c7f549a3836e2d92fa9ec402" usingOptions:nil];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"kid1081", KCS_APP_KEY_KEY,
                             @"0d934bb1c7f549a3836e2d92fa9ec402", KCS_APP_SECRET_KEY,
                             @"hqENfOc6T82t0XTF8MVbpA", KCS_PUSH_KEY_KEY,
                             @"0vu-VwMVRFeZsrm4Clb-Ew", KCS_PUSH_SECRET_KEY,
                             @"YES", KCS_PUSH_IS_ENABLED_KEY,
                             KCS_PUSH_DEBUG, KCS_PUSH_MODE_KEY, nil];
    
    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:[options valueForKey:KCS_APP_KEY_KEY] withAppSecret:[options valueForKey:KCS_APP_SECRET_KEY] usingOptions:options];
    [[KCSPush sharedPush] onLoadHelper:options];
    
    [[KCSClient sharedClient] setServiceHostname:@"console-staging"];
    
    [KCSClient configureLoggingWithNetworkEnabled:YES
                                     debugEnabled:YES
                                     traceEnabled:YES
                                   warningEnabled:YES
                                     errorEnabled:YES];


    // Initialize Image Cache
    NSMutableDictionary *cache = [[[NSMutableDictionary alloc] init] autorelease];
    self.imageCache = cache;
    
    return YES;
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [[KCSPush sharedPush] application:application didReceiveRemoteNotification:userInfo];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSLog(@"Device Token: %@", deviceToken);
    [[KCSPush sharedPush] application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Error: %@", error);
}


							
- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[KCSPush sharedPush] onUnloadHelper];
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
