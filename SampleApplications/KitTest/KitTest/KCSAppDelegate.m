//
//  KCSAppDelegate.m
//  KitTest
//
//  Created by Brian Wilson on 11/14/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KCSAppDelegate.h"

#import "KCSViewController.h"
#import "ImageViewController.h"
#import "RootViewController.h"

#import <KinveyKit/KinveyKit.h>

@implementation KCSAppDelegate

@synthesize window = _window;
@synthesize viewController = _viewController;
@synthesize imageViewController=_imageViewController;
@synthesize rootViewController=_rootViewController;
@synthesize kinvey=_kinvey;

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [_imageViewController release];
    [_rootViewController release];
    [_kinvey release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    self.viewController = [[[KCSViewController alloc] initWithNibName:@"KCSViewController" bundle:nil] autorelease];
    self.imageViewController = [[[ImageViewController alloc] initWithNibName:@"ImageView" bundle:nil] autorelease];
    self.rootViewController = [[[RootViewController alloc] initWithNibName:@"RootViewController" bundle:nil] autorelease];

    self.window.rootViewController = self.rootViewController;
    
    // Add our primary as a subview of the rootViewController.
    [self.rootViewController.view insertSubview:self.viewController.view atIndex:0];
    
    ///////////////////////////
    // START OF KINVEY CODE
    //////////////////////////
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"kid1089", KCS_APP_KEY_KEY,
                             @"ad8f7ea0538147f89a7f75dd95491fdf", KCS_APP_SECRET_KEY,
                             @"OzPSPvSJTyq0LTOIdff_dA", KCS_PUSH_KEY_KEY,
                             @"ETHhR_GCRsq5QqhRLCp0ew", KCS_PUSH_SECRET_KEY,
                             @"NO", KCS_PUSH_IS_ENABLED_KEY,
                             KCS_PUSH_DEBUG, KCS_PUSH_MODE_KEY, nil];
                             
    [[KCSClient sharedClient] initializeKinveyServiceForAppKey:[options valueForKey:KCS_APP_KEY_KEY] withAppSecret:[options valueForKey:KCS_APP_SECRET_KEY] usingOptions:options];
    [[KCSPush sharedPush] onLoadHelper:options];
    
    
    
    self.viewController.rootViewController = _rootViewController;
    self.imageViewController.rootViewController = _rootViewController;

    self.rootViewController.imageViewController = _imageViewController;
    self.rootViewController.viewController = _viewController;

    [self.viewController prepareDataForView];
    ///////////////////////////
    // END OF KINVEY CODE
    //////////////////////////
    
    [self.window makeKeyAndVisible];
    
    
    [KCSPing pingKinveyWithBlock:^(KCSPingResult *result) {
        NSString *title;
        
        if (result.pingWasSuccessful){
            title = [NSString stringWithString:@"Kinvey Ping Success :)"];
        } else {
            title = [NSString stringWithString:@"Kinvey Ping Failed :("];            
        }
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: title
                                                        message: [result description]
                                                       delegate: nil
                                              cancelButtonTitle: @"OK"
                                              otherButtonTitles: nil];
        [alert show];
        [alert release];
    }];
        
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
