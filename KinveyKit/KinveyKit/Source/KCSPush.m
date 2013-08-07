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
#import "KCSDevice.h"
#import "NSMutableDictionary+KinveyAdditions.h"

#import "KCSRequest.h"
#import "KCSUser+KinveyKit2.h"

#define UAPushBadgeSettingsKey @"UAPushBadge"

@interface KCSPush()
- (BOOL)initializeUrbanAirshipWithOptions: (NSDictionary *)options error:(NSError**)error;
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
    return [self initializeUrbanAirshipWithOptions:options error:error];
}

+ (void) initializePushWithPushKey:(NSString*)pushKey pushSecret:(NSString*)pushSecretKey mode:(KCS_PUSH_MODE)pushMode enabled:(BOOL)enabled
{
    NSString* modeString;
    switch (pushMode) {
        case KCS_PUSHMODE_DEVELOPMENT:
            modeString = KCS_PUSH_DEVELOPMENT;
            break;
        case KCS_PUSHMODE_PRODUCTION:
            modeString = KCS_PUSH_DEVELOPMENT;
            break;
        default:
            [[NSException exceptionWithName:@"Invalid Push Setup" reason:@"Push Mode should be one of Development or Production" userInfo:nil] raise];
            break;
    }
    
    NSError* error = nil;
    BOOL setUp = [[KCSPush sharedPush] initializeUrbanAirshipWithOptions:@{ KCS_PUSH_IS_ENABLED_KEY : enabled ? @"YES" : @"NO",
                                                       KCS_PUSH_KEY_KEY : pushKey,
                                                    KCS_PUSH_SECRET_KEY : pushSecretKey,
                                                      KCS_PUSH_MODE_KEY : modeString
                  } error:&error];
    if (setUp == NO) {
        NSAssert(error == nil, @"Push not set up correctly: %@", error);
    }
}

#warning remove options in doc & api
- (BOOL) initializeUrbanAirshipWithOptions:(NSDictionary *)options error:(NSError**)error
{
    if (fieldExistsAndIsNO(options, KCS_PUSH_IS_ENABLED_KEY)){
        // We don't want any of this code, so... we're done.
        self.pushEnabled = NO;
        return NO;
    }
    
    self.pushEnabled = YES;
    [self registerForRemoteNotifications];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UAPushBadgeSettingsKey];
    [self resetPushBadge];//zero badge
    
    return YES;
}

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
    self.hasToken = YES;
    
    // Capture the token for us to use later
    self.deviceToken = deviceToken;
    [KCSDevice currentDevice].deviceToken = deviceToken;
    
    if ([KCSUser activeUser] != nil) {
        //if we have a current user, saving it will register the device token with the user collection on the backend
        //nil delegate because this is a silent try, and there's nothing to do if error
        [self registerDeviceToken];
    }
}

- (void) application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    self.hasToken = NO;
    
    KCSLogNSError(@"Failed to register for remote notifications", error);
    //TODO: simulator error: Error Domain=NSCocoaErrorDomain Code=3010 "remote notifications are not supported in the simulator" UserInfo=0xa6992d0 {NSLocalizedDescription=remote notifications are not supported in the simulator}
}

- (void) removeDeviceToken
{
    self.pushEnabled = NO;
    self.deviceToken = nil;
    [KCSDevice currentDevice].deviceToken = nil;
#warning remove from server
#warning remove kcsdevice
}

- (NSString *)deviceTokenString
{
    NSString *deviceToken = [[self.deviceToken description] stringByReplacingOccurrencesOfString: @"<" withString: @""];
    deviceToken = [deviceToken stringByReplacingOccurrencesOfString: @">" withString: @""] ;
    deviceToken = [deviceToken stringByReplacingOccurrencesOfString: @" " withString: @""];
    return deviceToken;
}

- (void) registerDeviceToken
{
    KCSNetworkRequest* request = [[KCSNetworkRequest alloc] init];
    request.httpMethod = kKCSRESTMethodPOST;
    request.contextRoot = kKCSContextPUSH;
    request.pathComponents = @[@"register-device"];
    request.body = @{@"userId"   : [KCSUser activeUser].userId,
                     @"deviceId" : [self deviceTokenString],
                     @"platform" : @"ios"};
    
    request.authorization = [KCSUser activeUser];
    
    [request run:^(id results, NSError *error) {
        //TODO handle here
        if (error) {
            KCSLogError(@"Device token did not register");
        } else {
            KCSLogDebug(@"Device token registered");
        }
    }];

}

- (void) unRegisterDeviceToken
{
    KCSNetworkRequest* request = [[KCSNetworkRequest alloc] init];
    request.httpMethod = kKCSRESTMethodPOST;
    request.contextRoot = kKCSContextPUSH;
    request.pathComponents = @[@"unregister-device"];
    request.body = @{@"userId"   : [KCSUser activeUser].userId,
                     @"deviceId" : [self deviceTokenString],
                     @"platform" : @"ios"};
    
    request.authorization = [KCSUser activeUser];
    
    [request run:^(id results, NSError *error) {
        //TODO handle here
        if (error) {
            KCSLogError(@"Device token did not un-register");
        } else {
            KCSLogDebug(@"Device token un-registered");
        }
    }];
    
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

