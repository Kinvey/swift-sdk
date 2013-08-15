//
//  KCSPush.m
//  KinveyKit
//
//  Created by Brian Wilson on 11/28/11.
//  Copyright (c) 2011-2013 Kinvey. All rights reserved.
//

#import "KCSPush.h"
#import "KCSClient.h"
#import "KinveyUser.h"

#import "KCSLogManager.h"
#import "KinveyErrorCodes.h"
#import "NSMutableDictionary+KinveyAdditions.h"

#import "KCSRequest.h"
#import "KCSUser+KinveyKit2.h"

#define UAPushBadgeSettingsKey @"UAPushBadge"

@interface KCSPush()
@property (nonatomic, retain, readwrite) NSData  *deviceToken;
@property (nonatomic) BOOL hasToken;
@property (nonatomic) BOOL pushEnabled;
@end

@implementation KCSPush

- (instancetype)init
{
    self = [super init];
    if (self) {
        _deviceToken = nil;
    }
    return self;
}


#pragma mark - Init
+ (KCSPush *)sharedPush
{
    static KCSPush *sKCSPush;
    // This can be called on any thread, so we synchronise.  We only do this in 
    // the sKCSClient case because, once sKCSClient goes non-nil, it can 
    // never go nil again.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sKCSPush = [[KCSPush alloc] init];
        assert(sKCSPush != nil);
    });
    
    return sKCSPush;
}

- (BOOL) onLoadHelper:(NSDictionary *)options error:(NSError**)error
{
    [self doRegister];
    return YES;
}

+ (void) initializePushWithPushKey:(NSString*)pushKey pushSecret:(NSString*)pushSecretKey mode:(KCS_PUSH_MODE)pushMode enabled:(BOOL)enabled
{
    [self registerForPush];
}

+ (void) registerForPush
{
    [[KCSPush sharedPush] doRegister];
}

- (void) doRegister
{
    self.pushEnabled = YES;
    [self registerForRemoteNotifications];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UAPushBadgeSettingsKey];
    [self resetPushBadge];//zero badge
}

#pragma mark - Properties

- (BOOL) autobadgeEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:UAPushBadgeSettingsKey];
}

#pragma mark - unloading
- (void)onUnloadHelper
{
    //do nothing for now
}

#pragma mark - Events

- (void) registerForRemoteNotifications
{
    // Register for notifications
    if (self.pushEnabled) {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge |
                                                                               UIRemoteNotificationTypeSound |
                                                                               UIRemoteNotificationTypeAlert)];
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)notification
{
    KCSLogDebug(@"Received remote notification: %@", notification);
    
    UIApplicationState state = application.applicationState;
    
    if (state != UIApplicationStateActive) {
        KCSLogTrace(@"Received a push notification for an inactive application state.");
        return;
    }
    
    // Please refer to the following Apple documentation for full details on handling the userInfo payloads
	// http://developer.apple.com/library/ios/#documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/ApplePushService/ApplePushService.html#//apple_ref/doc/uid/TP40008194-CH100-SW1
	
	if ([[notification allKeys] containsObject:@"aps"]) {
        NSDictionary *apsDict = [notification objectForKey:@"aps"];
        
		if ([[apsDict allKeys] containsObject:@"alert"]) {
			//handle alert message?
		}
        
        //badge
        NSString *badgeNumber = [apsDict valueForKey:@"badge"];
        if (badgeNumber) {
			if([self autobadgeEnabled]) {
				[[UIApplication sharedApplication] setApplicationIconBadgeNumber:[badgeNumber intValue]];
			}
        }
		
        //sound
		NSString *soundName = [apsDict valueForKey:@"sound"];
		if (soundName) {
			//handle sound?
		}
        
	}//aps
    
	// Now remove all the UA and Apple payload items
	NSMutableDictionary *customPayload = [notification mutableCopy];
    [customPayload removeObjectForKey:@"aps"];
    [customPayload removeObjectForKey:@"_uamid"];
    [customPayload removeObjectForKey:@"_"];
	
	// If any top level items remain, those are custom payload, pass it to the handler
	// Note: There is some convenience built into this check, if for some reason there's a key collision
	//	and we're stripping yours above, it's safe to remove this conditional
	if([[customPayload allKeys] count] > 0) {
        //handle custom payload
    }
    
    [self resetPushBadge]; // zero badge after push received
}

#pragma mark - Device Tokens
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [self application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken completionBlock:nil];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken completionBlock:(void (^)(BOOL success, NSError* error))completionBlock
{
    self.hasToken = YES;
    
    // Capture the token for us to use later
    self.deviceToken = deviceToken;
    [self registerDeviceToken:completionBlock];
}

- (void) application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    self.hasToken = NO;
    
    KCSLogNSError(@"Failed to register for remote notifications", error);
    //TODO: simulator error: Error Domain=NSCocoaErrorDomain Code=3010 "remote notifications are not supported in the simulator" UserInfo=0xa6992d0 {NSLocalizedDescription=remote notifications are not supported in the simulator}
}

- (void) removeDeviceToken:(void (^)(BOOL success, NSError* error))completionBlock

{
    self.pushEnabled = NO;
    [self unRegisterDeviceToken:completionBlock];
    self.deviceToken = nil;
}

- (NSString *)deviceTokenString
{
    NSString *deviceToken = [[self.deviceToken description] stringByReplacingOccurrencesOfString: @"<" withString: @""];
    deviceToken = [deviceToken stringByReplacingOccurrencesOfString: @">" withString: @""] ;
    deviceToken = [deviceToken stringByReplacingOccurrencesOfString: @" " withString: @""];
    return deviceToken;
}

- (void) registerDeviceToken:(void (^)(BOOL success, NSError* error))completionBlock
{
    if (self.deviceToken != nil && [KCSUser activeUser] != nil && [KCSUser activeUser].deviceTokens != nil && [[KCSUser activeUser].deviceTokens containsObject:[self deviceTokenString]] == NO) {
        
        KCSNetworkRequest* request = [[KCSNetworkRequest alloc] init];
        request.httpMethod = kKCSRESTMethodPOST;
        request.contextRoot = kKCSContextPUSH;
        request.pathComponents = @[@"register-device"];
        request.body = @{@"userId"   : [KCSUser activeUser].userId,
                         @"deviceId" : [self deviceTokenString],
                         @"platform" : @"ios"};
        request.errorDomain = KCSUserErrorDomain;
        request.authorization = [KCSUser activeUser];
        
        [request run:^(id results, NSError *error) {
            if (error) {
                KCSLogError(@"Device token did not register");
            } else {
                KCSLogDebug(@"Device token registered");
                [[KCSUser activeUser].deviceTokens addObject:[self deviceTokenString]];
            }
            if (completionBlock) {
                completionBlock(error == nil, error);
            }
        }];
    } else {
        if (completionBlock) {
            completionBlock(NO, nil);
        }
    }
}

- (void) unRegisterDeviceToken:(void (^)(BOOL success, NSError* error))completionBlock
{
    if (self.deviceToken != nil && [KCSUser activeUser] != nil && [KCSUser activeUser].deviceTokens != nil && [[KCSUser activeUser].deviceTokens containsObject:[self deviceTokenString]] == YES) {
        
        KCSNetworkRequest* request = [[KCSNetworkRequest alloc] init];
        request.httpMethod = kKCSRESTMethodPOST;
        request.contextRoot = kKCSContextPUSH;
        request.pathComponents = @[@"unregister-device"];
        request.body = @{@"userId"   : [KCSUser activeUser].userId,
                         @"deviceId" : [self deviceTokenString],
                         @"platform" : @"ios"};
        request.errorDomain = KCSUserErrorDomain;
        request.authorization = [KCSUser activeUser];
        
        [request run:^(id results, NSError *error) {
            if (error) {
                KCSLogError(@"Device token did not un-register");
            } else {
                KCSLogDebug(@"Device token un-registered");
                [[KCSUser activeUser].deviceTokens removeObject:[self deviceTokenString]];
                self.deviceToken = nil;
            }
            if (completionBlock) {
                completionBlock(error == nil, error);
            }
        }];
    } else {
        self.deviceToken = nil;
        completionBlock(NO, nil);
    }
}

#pragma mark - Badges

- (void)setPushBadgeNumber: (int)number
{
    if ([[UIApplication sharedApplication] applicationIconBadgeNumber] == number) {
        return;
    }
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:number];
}

- (void)resetPushBadge
{
    [self setPushBadgeNumber:0];
}

/* TODO
 - (void)applicationDidBecomeActive {
 UALOG(@"Checking registration status after foreground notification");
 if (hasEnteredBackground) {
 registrationRetryDelay = 0;
 [self updateRegistration];
 }
 else {
 UALOG(@"Checking registration on app foreground disabled on app initialization");
 }
 }
 
 - (void)applicationDidEnterBackground {
 hasEnteredBackground = YES;
 [[NSNotificationCenter defaultCenter] removeObserver:self
 name:UIApplicationDidEnterBackgroundNotification
 object:[UIApplication sharedApplication]];
 }
 */

@end

