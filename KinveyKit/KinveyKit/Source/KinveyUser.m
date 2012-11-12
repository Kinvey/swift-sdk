//
//  KinveyUser.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/1/11.
//  Copyright (c) 2011-2012 Kinvey. All rights reserved.
//

#import "KinveyUser.h"
#import "KCSClient.h"
#import "KCSKeyChain.h"
#import "KCSRESTRequest.h"
#import "KinveyAnalytics.h"
#import "KCS_SBJson.h"
#import "KinveyBlocks.h"
#import "KCSConnectionResponse.h"
#import "KinveyHTTPStatusCodes.h"
#import "KinveyErrorCodes.h"
#import "KCSErrorUtilities.h"
#import "KCSLogManager.h"
#import "KinveyCollection.h"
#import "KCSReachability.h"
#import "KCSHiddenMethods.h"
#import "NSString+KinveyAdditions.h"
#import "NSMutableDictionary+KinveyAdditions.h"
#import "KinveyCollection.h"
#import "KCSPush.h"

#define kKeychainPasswordKey @"password"
#define kKeychainUsernameKey @"username"
#define kKeychainUserIdKey @"_id"
#define kKeychainAuthTokenKey @"authtoken"
#define kKeychainPropertyDictKey @"propertyDict"

#define KCSUserAttributeOAuthTokens @"_oauth"
@class GTMOAuth2Authentication;

@interface KCSUser()
@property (nonatomic, retain) NSString *userId;
@property (nonatomic, retain) NSMutableDictionary *userAttributes;
@property (nonatomic, retain) NSDictionary* oauthTokens;

+ (void)registerUserWithUsername:(NSString *)uname withPassword:(NSString *)password withCompletionBlock:(KCSUserCompletionBlock)completionBlock forceNew:(BOOL)forceNew;
@end

@implementation KCSUser

- (id)init
{
    self = [super init];
    if (self){
        _username = [[NSString string] retain];
        _password = [[NSString string] retain];
        _userId = [[NSString string] retain];
        _userAttributes = [[NSMutableDictionary dictionary] retain];
        _deviceTokens = nil;
        _oauthTokens = [[NSMutableDictionary dictionary] retain];
        _sessionAuth = nil;
        _surname = nil;
        _email = nil;
        _givenName = nil;
    }
    return self;
}

- (void)dealloc
{
    [_surname release];
    [_givenName release];
    [_email release];
    [_username release];
    [_password release];
    [_userId release];
    [_userAttributes release];
    [_deviceTokens release];
    [_oauthTokens release];
    [_sessionAuth release];
    [super dealloc];
}

+ (BOOL) hasSavedCredentials
{
    return ([KCSKeyChain getStringForKey:kKeychainPasswordKey] && [KCSKeyChain getStringForKey:kKeychainUsernameKey]) || ([KCSKeyChain getStringForKey:kKeychainAuthTokenKey]);
}

+ (void) clearSavedCredentials
{
    [KCSKeyChain removeStringForKey: kKeychainUsernameKey];
    [KCSKeyChain removeStringForKey: kKeychainPasswordKey];
    [KCSKeyChain removeStringForKey: kKeychainUserIdKey];
    [KCSKeyChain removeStringForKey: kKeychainAuthTokenKey];
    [KCSKeyChain removeStringForKey: kKeychainPropertyDictKey];
}

+ (void) setupCurrentUser:(KCSUser*)user properties:(NSDictionary*)dictionary password:(NSString*)password username:(NSString*)username
{
    [KCSKeyChain setDict:dictionary forKey:kKeychainPropertyDictKey];

    NSMutableDictionary* properties = [dictionary mutableCopy];
    
    NSString* propUsername = [properties popObjectForKey:@"username"];
    NSString* propPassword = [properties popObjectForKey:@"password"];
    
    user.username = propUsername != nil ? propUsername : username;
    user.password = propPassword != nil ? propPassword : password;
    user.userId   = [properties popObjectForKey:@"_id"];
    user.deviceTokens = [properties popObjectForKey:@"_deviceTokens"];
    user.oauthTokens = [properties popObjectForKey:KCSUserAttributeOAuthTokens];
    
    user.surname = [properties popObjectForKey:KCSUserAttributeSurname];
    user.givenName = [properties popObjectForKey:KCSUserAttributeGivenname];
    user.email = [properties popObjectForKey:KCSUserAttributeEmail];
    
    NSDictionary* metadata = [properties popObjectForKey:@"_kmd"];
    NSDictionary* emailVerification = [metadata objectForKey:@"emailVerification"];
    NSString* verificationStatus = [emailVerification objectForKey:@"status"];
    user->_emailVerified = [verificationStatus isEqualToString:@"Confirmed"];
    
    NSString* sessionAuth = [metadata objectForKey:@"authtoken"]; //get the session auth
    if (sessionAuth) {
        user.sessionAuth = sessionAuth;
    }
    
    [properties removeObjectForKey:@"UUID"];
    [properties removeObjectForKey:@"UDID"];
    
    [properties enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        @try {
            [user setValue:obj forAttribute:key];
        }
        @catch (NSException *exception) {
            KCSLogWarning(@"Cannot set ('%@') for key: %@, on USER object",obj, key);
        }
    }];
    
    [properties release];
    
    assert(user.username != nil && user.userId != nil);
    
    [KCSKeyChain setString:user.username forKey:kKeychainUsernameKey];
    [KCSKeyChain setString:user.userId forKey:kKeychainUserIdKey];
    
    KCSClient *client = [KCSClient sharedClient];
    if (sessionAuth != nil) {
        //session auth
        [client setAuthCredentials:[NSURLCredential credentialWithUser:user.username password:user.sessionAuth persistence:NSURLCredentialPersistenceNone]];
        [KCSKeyChain setString:user.sessionAuth forKey:kKeychainAuthTokenKey];
    } else {
        //password auth
        [KCSKeyChain setString:user.password forKey:kKeychainPasswordKey];
        [client setAuthCredentials:[NSURLCredential credentialWithUser:user.username password:user.password persistence:NSURLCredentialPersistenceNone]];
        
    }
    
    
    [client setCurrentUser:user];
    
    // Indicate that threads are free to proceed
    client.userIsAuthenticated = YES;
    client.userAuthenticationInProgress = NO;
}

+ (void) updateUserInBackground:(KCSUser*)user 
{
    KCSRESTRequest *userRequest = [KCSRESTRequest requestForResource:[[[KCSClient sharedClient] userBaseURL] stringByAppendingFormat:@"%@", user.userId] usingMethod:kGetRESTMethod];
    [userRequest setContentType:KCS_JSON_TYPE];
    KCS_SBJsonWriter *writer = [[KCS_SBJsonWriter alloc] init];
    [writer release];
    
    // Set up our callbacks
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        
        // Ok, we're really authd
        if ([response responseCode] < 300) {
            NSDictionary *dictionary = (NSDictionary*) [response jsonResponseValue];
            [self setupCurrentUser:user properties:dictionary password:user.password username:user.username];
        } else {
            KCSLogError(@"Internal Error Updating user: %@", [response jsonResponseValue]);
        }
    };
    
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        KCSLogError(@"Internal Error Updating user: %@", error);
        return;
    };
    
    [userRequest withCompletionAction:cBlock failureAction:fBlock progressAction:nil];
    [userRequest start];
}

+ (void)registerUserWithUsername:(NSString *)uname withPassword:(NSString *)password withCompletionBlock:(KCSUserCompletionBlock)completionBlock forceNew:(BOOL)forceNew
{
    BOOL localInitInProgress = NO;
    KCSClient *client = [KCSClient sharedClient];
    
    @synchronized(client){
        if (client.userAuthenticationInProgress == NO){
            client.userAuthenticationInProgress = YES;
            localInitInProgress = YES;
        }
    }
    
    // Note!!! This is a spin lock!  If we hold the lock for 10 seconds we're hosed, so this timeout
    // is REALLY big, hopefully we only hit it when the network is down (likely a minute timeout, so these guys will start timing out early...)
    NSDate *timeoutTime = [NSDate dateWithTimeIntervalSinceNow:10];
    
    if (!localInitInProgress && !client.userIsAuthenticated){
        while (!client.userIsAuthenticated) {
            NSDate *now = [NSDate dateWithTimeIntervalSinceNow:0];
            // From NSDate documentation:
            //      The receiver and anotherDate are exactly equal to each other, NSOrderedSame
            //      The receiver is later in time than anotherDate, NSOrderedDescending
            //      The receiver is earlier in time than anotherDate, NSOrderedAscending.
            // So we're checking to see if now (the receiver) is later than timeoutTime (anotherDate), so we use NSOrderedDescending.
            if ([now compare:timeoutTime] == NSOrderedDescending){
                // TIMEOUT!  Give up!
                // We're not in a critical section and we don't have anything locked, so do some work before we quit.
                if (completionBlock != nil){
                    // We're going to Make a failure happen here...
                    NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Unable to create user."
                                                                                       withFailureReason:@"User creation timed out with one request holding the lock."
                                                                                  withRecoverySuggestion:@"Try request again later."
                                                                                     withRecoveryOptions:nil];
                    
                    // No user, it's during creation
                    NSError* error = [NSError errorWithDomain:KCSUserErrorDomain
                                                         code:KCSUserCreationContentionTimeoutError
                                                     userInfo:userInfo];
                    completionBlock(nil, error, 0);
                    return;
                } else {
                    // There is no request, the current user was not initialized by us, but someone was initializing the user, so we can
                    // just return and assume that all is well.
                    KCSLogWarning(@"While trying to initialize the current user this call was blocked by an existing attempt to initialize the current user.");
                    return;
                }
                break;
            }
        }
    }
    
    
    // Did we get a username and password?  If we did, then we're not interested in being already logged in
    // If we didn't, we need to check to see if there are keychain items.
    
    if (forceNew){
        [KCSUser clearSavedCredentials];
    }
    
    KCSUser *createdUser = [[[KCSUser alloc] init] autorelease];
    
    createdUser.username = [KCSKeyChain getStringForKey:kKeychainUsernameKey];
    
    if (createdUser.username == nil){
        // No user, generate it, note, use the APP KEY/APP SECRET!
        KCSAnalytics *analytics = [client analytics];
        
        
        // Build the dictionary that will be JSON-ified here
        
        // We have three optional, internal fields and 2 manditory fields
        NSMutableDictionary *userJSONPaylod = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                               [analytics UDID], @"UDID",
                                               [analytics UUID], @"UUID", nil];
        
        // Next we check for the username and password
        if (uname && password){
            [userJSONPaylod setObject:uname forKey:@"username"];
            [userJSONPaylod setObject:password forKey:@"password"];
        }
        
        // Finally we check for the device token, we're creating the user,
        // so we just need to set the one value, no merging/etc
        KCSPush *sp = [KCSPush sharedPush];
        if (sp.deviceToken != nil){
            [userJSONPaylod setObject:@[[sp deviceTokenString]] forKey:@"_deviceTokens"];
        }
        
        NSDictionary *userData = [NSDictionary dictionaryWithDictionary:userJSONPaylod];
        
        KCSRESTRequest *userRequest = [KCSRESTRequest requestForResource:[[KCSClient sharedClient] userBaseURL] usingMethod:kPostRESTMethod];
        
        
        [userRequest setContentType:KCS_JSON_TYPE];
        KCS_SBJsonWriter *writer = [[KCS_SBJsonWriter alloc] init];
        [userRequest addBody:[writer dataWithObject:userData]];
        [writer release];
        
        // Set up our callbacks
        KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
            
            // Ok, we're probably authenticated
            if (response.responseCode != KCS_HTTP_STATUS_CREATED){
                // Crap, authentication failed, not really sure how to proceed here!!!
                // I really don't know what to do here, we can't continue... Something died...
                KCSLogError(@"Received Response code %d, but expected %d with response: %@", response.responseCode, KCS_HTTP_STATUS_CREATED, [response stringValue]);
                
                client.userIsAuthenticated = NO;
                client.userAuthenticationInProgress = NO;
                
                NSError* error = nil;
                if (response.responseCode == KCS_HTTP_STATUS_CONFLICT) {
                    error = [KCSErrorUtilities createError:(NSDictionary*)[response jsonResponseValue] description:@"User already exists" errorCode:KCSConflictError domain:KCSUserErrorDomain];
                } else {
                    error = [KCSErrorUtilities createError:(NSDictionary*)[response jsonResponseValue] description:@"Unable to create user" errorCode:response.responseCode domain:KCSUserErrorDomain];
                    
                }
                
                completionBlock(nil, error, 0);
                return;
            }
            
            // Ok, we're really authd
            NSDictionary *dictionary = (NSDictionary*) [response jsonResponseValue];
            [self setupCurrentUser:createdUser properties:dictionary password:password username:uname];
            
            // NB: The delegate MUST retain created user!
            completionBlock(createdUser, nil, KCSUserCreated);
        };
        
        KCSConnectionFailureBlock fBlock = ^(NSError *error){
            // I really don't know what to do here, we can't continue... Something died...
            KCSLogError(@"Internal Error: %@", error);
            
            client.userIsAuthenticated = NO;
            client.userAuthenticationInProgress = NO;
            
            NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:error, @"error",
                                       @"The Kinvey Service has experienced an internal error and is unable to continue.  Please contact support with the supplied userInfo", @"reason", nil];
            
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Unable to create user."
                                                                               withFailureReason:[errorDict description]
                                                                          withRecoverySuggestion:@"Contact support."
                                                                             withRecoveryOptions:nil];
            
            // No user, it's during creation
            NSError* newError = [NSError errorWithDomain:KCSUserErrorDomain
                                                    code:KCSUnexpectedError
                                                userInfo:userInfo];
            completionBlock(nil, newError, 0);
            return;
        };
        
        KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *conn){};
        
        [userRequest withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock];
        [userRequest start];
        
        
    } else {
        createdUser.password = [KCSKeyChain getStringForKey:kKeychainPasswordKey];
        createdUser.userId = [KCSKeyChain getStringForKey:kKeychainUserIdKey];
        createdUser.sessionAuth = [KCSKeyChain getStringForKey:kKeychainAuthTokenKey];
        NSString* password = (createdUser.sessionAuth == nil) ? createdUser.password : createdUser.sessionAuth;
        [[KCSClient sharedClient] setAuthCredentials:[NSURLCredential credentialWithUser:createdUser.username password:password persistence:NSURLCredentialPersistenceNone]];
        
        NSDictionary* properties = [KCSKeyChain getDictForKey:kKeychainPropertyDictKey];
        if (properties) {
            [self setupCurrentUser:createdUser properties:properties password:createdUser.password username:createdUser.username];
        }
        
        client.userIsAuthenticated = YES;
        client.userAuthenticationInProgress = NO;
        [[KCSClient sharedClient] setCurrentUser:createdUser];
        [self updateUserInBackground:createdUser];
        
        // Delegate must retain createdUser
        completionBlock(createdUser, nil, KCSUserFound);
    }
}

+ (void)registerUserWithUsername:(NSString *)uname withPassword:(NSString *)password withDelegate:(id<KCSUserActionDelegate>)delegate forceNew:(BOOL)forceNew
{
    [self registerUserWithUsername:uname withPassword:password withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        if (delegate != nil) {
            if (errorOrNil != nil) {
                [delegate user:user actionDidFailWithError:errorOrNil];
            } else {
                [delegate user:user actionDidCompleteWithResult:result];
            }
        }
    } forceNew:forceNew];
}

// These routines all do similar work, but the first two are for legacy support
- (void)initializeCurrentUserWithRequest: (KCSRESTRequest *)request
{
    [KCSUser registerUserWithUsername:nil withPassword:nil withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        //... do nothing with result
    } forceNew:NO];
    if (request){
        [request start];
    }
}

- (void)initializeCurrentUser
{
    [self initializeCurrentUserWithRequest:nil];
}

+ (void)initCurrentUser
{
    [KCSUser registerUserWithUsername:nil withPassword:nil withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        //... do nothing with result
    } forceNew:NO];
}

+ (void)userWithUsername: (NSString *)username
                password: (NSString *)password
            withDelegate: (id<KCSUserActionDelegate>)delegate
{
    // Ensure the old user is gone...
    [KCSUser registerUserWithUsername:username withPassword:password withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        if (delegate != nil) {
            if (errorOrNil != nil) {
                [delegate user:user actionDidFailWithError:errorOrNil];
            } else {
                [delegate user:user actionDidCompleteWithResult:result];
            }
        }
    } forceNew:YES];
}

+ (void) userWithUsername:(NSString *)username password:(NSString *)password withCompletionBlock:(KCSUserCompletionBlock)completionBlock
{
    [KCSUser registerUserWithUsername:username withPassword:password withCompletionBlock:completionBlock forceNew:YES];
}

+ (void)loginWithUsername: (NSString *)username
                 password: (NSString *)password
      withCompletionBlock:(KCSUserCompletionBlock)completionBlock
{
    KCSClient *client = [KCSClient sharedClient];
    
    // Just log-in and set currentUser
    // Note that isReachable is slightly redundant here, as
    // the actual request also does the reachable check, however we'd like to know
    // here before branching to the blocks
    if ([client.kinveyReachability isReachable]){
        // Set up our callbacks
        KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
            // Ok, we're probably authenticated
            KCSUser *createdUser = [[[KCSUser alloc] init] autorelease];
            createdUser.username = username;
            createdUser.password = password;
            if (response.responseCode != KCS_HTTP_STATUS_OK){
                client.userIsAuthenticated = NO;
                client.userAuthenticationInProgress = NO;
                client.currentUser = nil;
                // This is expected here, user auth failed, do the right thing
                NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Login Failed"
                                                                                   withFailureReason:@"Invalid Username or Password"
                                                                              withRecoverySuggestion:@"Try again with different username/password"
                                                                                 withRecoveryOptions:nil];
                NSError *error = [NSError errorWithDomain:KCSUserErrorDomain code:KCSLoginFailureError userInfo:userInfo];
                // Delegate must retain createdUser
                completionBlock(createdUser, error, 0);
                return;
            }
            // Ok, we're really authd
            NSDictionary *dictionary = (NSDictionary*) [response jsonResponseValue];
            [self setupCurrentUser:createdUser properties:dictionary password:password username:username];
            
            // Delegate must retain createdUser
            completionBlock(createdUser, nil, KCSUserFound);
        };
        
        KCSConnectionFailureBlock fBlock = ^(NSError *error){
            // I really don't know what to do here, we can't continue... Something died...
            KCSLogError(@"Internal Error: %@", error);
            
            client.userIsAuthenticated = NO;
            client.userAuthenticationInProgress = NO;
            client.currentUser = nil;
            
            completionBlock(nil, error, 0);
        };
        
        KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *conn){};
        
        
        KCSRESTRequest *request = [KCSRESTRequest requestForResource:[client.userBaseURL stringByAppendingString:@"_me"] usingMethod:kGetRESTMethod];
        
        // We need to init the current user to something before trying this
        client.userAuthenticationInProgress = YES;
        
        // Create a temp user with uname/password and use it it init currentUser
        KCSUser *tmpCurrentUser = [[[KCSUser alloc] init] autorelease];
        tmpCurrentUser.username = username;
        tmpCurrentUser.password = password;
        client.currentUser = tmpCurrentUser;
        
        [request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock];
        [request start];
        
        
    } else {
        NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Unable to reach Kinvey"
                                                                           withFailureReason:@"Reachability determined that  Kinvey was not reachable, login cannot proceed."
                                                                      withRecoverySuggestion:@"Check to make sure device is not in Airplane mode and has a signal or try again later"
                                                                         withRecoveryOptions:nil];
        NSError *error = [NSError errorWithDomain:KCSNetworkErrorDomain
                                             code:KCSKinveyUnreachableError
                                         userInfo:userInfo];
        completionBlock(nil, error, 0);
    }
}


+ (void)loginWithUsername: (NSString *)username
                 password: (NSString *)password
             withDelegate: (id<KCSUserActionDelegate>)delegate
{
    [self loginWithUsername:username password:password withCompletionBlock:^(KCSUser* user, NSError* errorOrNil, KCSUserActionResult result) {
        if (errorOrNil != nil) {
            [delegate user:nil actionDidFailWithError:errorOrNil];
        } else {
            [delegate user:user actionDidCompleteWithResult:result];
        }
    }];
}

+ (void) setupSessionAuthUser:(KCSConnectionResponse*)response client:(KCSClient*)client completionBlock:(KCSUserCompletionBlock)completionBlock
{
    // Ok, we're really authd
    [self clearSavedCredentials];
    NSDictionary *dictionary = (NSDictionary*) [response jsonResponseValue];
    KCSUser* createdUser = [[[KCSUser alloc] init] autorelease];
    [self setupCurrentUser:createdUser properties:dictionary password:nil username:nil];
    
    NSError* error = nil;
    int status = 0;
    if (createdUser.sessionAuth != nil) {
        status = KCSUserFound;
    } else {
        client.userIsAuthenticated = NO;
        NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Login Failed"
                                                                           withFailureReason:@"User could not be authorized"
                                                                      withRecoverySuggestion:@"Try again with different access token"
                                                                         withRecoveryOptions:nil];
        error = [NSError errorWithDomain:KCSUserErrorDomain code:KCSLoginFailureError userInfo:userInfo];
    }
    // Delegate must retain createdUser
    completionBlock(createdUser, error, status);
}


+ (NSDictionary*) loginDictForProvder:(KCSUserSocialIdentifyProvider)provder accessDictionary:(NSDictionary*)accessDictionary
{
    NSDictionary* dict = @{};
    NSString* accessToken = [accessDictionary objectForKey:KCSUserAccessTokenKey];
    NSString* accessTokenSecret = [accessDictionary objectForKey:KCSUserAccessTokenSecretKey];
    switch (provder) {
        case KCSSocialIDFacebook:
            dict = @{@"_socialIdentity" : @{@"facebook" : @{@"access_token" : accessToken}}};
            break;
        case KCSSocialIDTwitter: {
            NSString* twitterKey = [[KCSClient sharedClient].options objectForKey:KCS_TWITTER_CLIENT_KEY];
            NSString* twitterSecret = [[KCSClient sharedClient].options objectForKey:KCS_TWITTER_CLIENT_SECRET];
            DBAssert(twitterKey != nil && twitterSecret != nil, @"twitter info should not be nil.");
            if (twitterKey != nil && twitterSecret != nil) {
                dict = @{@"_socialIdentity" : @{@"twitter" : @{@"access_token" : accessToken,
                @"access_token_secret" : accessTokenSecret,
                @"consumer_key" : twitterKey,
                @"consumer_secret" : twitterSecret}}};
            }
        }
            break;
    }
    return dict;
}


+ (void)registerUserWithSocialIdentity:(KCSUserSocialIdentifyProvider)provider accessDictionary:(NSDictionary*)accessDictionary withCompletionBlock:(KCSUserCompletionBlock)completionBlock
{
    //TODO: combine with below
    KCSClient *client = [KCSClient sharedClient];
    KCSRESTRequest *loginRequest = [KCSRESTRequest requestForResource:client.userBaseURL usingMethod:kPostRESTMethod];
    NSDictionary* loginDict = [self loginDictForProvder:provider accessDictionary:accessDictionary];
    [loginRequest setJsonBody:loginDict];
    
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        // I really don't know what to do here, we can't continue... Something died...
        KCSLogError(@"Internal Error: %@", error);
        
        client.userIsAuthenticated = NO;
        client.userAuthenticationInProgress = NO;
        client.currentUser = nil;
        
        completionBlock(nil, error, 0);
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *conn){};
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response) {
        if ([response responseCode] >= 400) {
            KCSUser *createdUser = [[[KCSUser alloc] init] autorelease];
            
            client.userIsAuthenticated = NO;
            client.userAuthenticationInProgress = NO;
            client.currentUser = nil;
            // This is expected here, user auth failed, do the right thing
            NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Login Failed"
                                                                               withFailureReason:@"Invalid social identity credentials"                                                                          withRecoverySuggestion:@"Try again with access token"
                                                                             withRecoveryOptions:nil];
            NSError *error = [NSError errorWithDomain:KCSUserErrorDomain code:KCSLoginFailureError userInfo:userInfo];
            // Delegate must retain createdUser
            completionBlock(createdUser, error, 0);
            return;
        } else { //successful
            [self setupSessionAuthUser:response client:client completionBlock:completionBlock];
        }
        
    };
    
    client.userAuthenticationInProgress = YES;
    [loginRequest setContentType:KCS_JSON_TYPE];
    [loginRequest withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock];
    [loginRequest start];
}

+ (void)registerUserWithFacebookAcccessToken:(NSString*)accessToken withCompletionBlock:(KCSUserCompletionBlock)completionBlock
{
    [self registerUserWithSocialIdentity:KCSSocialIDFacebook accessDictionary:@{KCSUserAccessTokenKey : accessToken} withCompletionBlock:completionBlock];
}

+ (void)loginWithFacebookAccessToken:(NSString*)accessToken withCompletionBlock:(KCSUserCompletionBlock)completionBlock
{
    [self loginWithWithSocialIdentity:KCSSocialIDFacebook accessDictionary:@{KCSUserAccessTokenKey : accessToken} withCompletionBlock:completionBlock];
}

+ (void)loginWithWithSocialIdentity:(KCSUserSocialIdentifyProvider)provider accessDictionary:(NSDictionary*)accessDictionary withCompletionBlock:(KCSUserCompletionBlock)completionBlock
{
    KCSClient *client = [KCSClient sharedClient];
    KCSRESTRequest *loginRequest = [KCSRESTRequest requestForResource:[client.userBaseURL stringByAppendingString:@"login"] usingMethod:kPostRESTMethod];
    NSDictionary* loginDict = [self loginDictForProvder:provider accessDictionary:accessDictionary];
    [loginRequest setJsonBody:loginDict];
    
    // We need to init the current user to something before trying this
    client.userAuthenticationInProgress = YES;
    
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        // I really don't know what to do here, we can't continue... Something died...
        KCSLogError(@"Internal Error: %@", error);
        
        client.userIsAuthenticated = NO;
        client.userAuthenticationInProgress = NO;
        client.currentUser = nil;
        
        completionBlock(nil, error, 0);
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *conn){};
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response) {
        if ([response responseCode] != KCS_HTTP_STATUS_OK) {
            //This is new user, log in
            dispatch_async(dispatch_get_current_queue(), ^{
                [KCSUser registerUserWithSocialIdentity:provider accessDictionary:accessDictionary withCompletionBlock:completionBlock];
            });
        } else { //successful
            [self setupSessionAuthUser:response client:client completionBlock:completionBlock];
        }
    };
    
    KCSUser *tmpCurrentUser = [[[KCSUser alloc] init] autorelease];
    tmpCurrentUser.username = @"";
    tmpCurrentUser.password = @"";
    client.currentUser = tmpCurrentUser;
    
    [loginRequest setContentType:KCS_JSON_TYPE];
    [loginRequest withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock];
    [loginRequest start];
}

- (void)logout
{
    
    if (![self isEqual:[[KCSClient sharedClient] currentUser]]){
        KCSLogError(@"Attempted to log out a user who is not the KCS Current User!");
    } else {
        
        self.username = nil;
        self.password = nil;
        self.userId = nil;
        
        [KCSUser clearSavedCredentials];
        
        // Set the currentUser to nil
        [[KCSClient sharedClient] setCurrentUser:nil];
        
        [[KCSClient sharedClient] setUserIsAuthenticated:NO];
    }
}


- (void)removeWithDelegate: (id<KCSPersistableDelegate>)delegate
{
    if (![self isEqual:[[KCSClient sharedClient] currentUser]]){
        NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Receiver is not current user."
                                                                           withFailureReason:@"An operation only applicable to the current user was tried on a different user."
                                                                      withRecoverySuggestion:@"Only perform this action on [[KCSClient sharedClient] currentUser]"
                                                                         withRecoveryOptions:nil];
        NSError *userError = [NSError errorWithDomain:KCSUserErrorDomain code:KCSOperationREquiresCurrentUserError userInfo:userInfo];
        [delegate entity:self operationDidFailWithError:userError];
    } else {
        [self deleteFromCollection:[KCSCollection userCollection] withDelegate:delegate];
    }
}

- (void)loadWithDelegate: (id<KCSEntityDelegate>)delegate
{
    if (![self isEqual:[[KCSClient sharedClient] currentUser]]){
        NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Receiver is not current user."
                                                                           withFailureReason:@"An operation only applicable to the current user was tried on a different user."
                                                                      withRecoverySuggestion:@"Only perform this action on [[KCSClient sharedClient] currentUser]"
                                                                         withRecoveryOptions:nil];
        NSError *userError = [NSError errorWithDomain:KCSUserErrorDomain code:KCSOperationREquiresCurrentUserError userInfo:userInfo];
        [delegate entity:self fetchDidFailWithError:userError];
    } else {
        [self loadObjectWithID:self.userId fromCollection:[KCSCollection userCollection] withDelegate:delegate];
    }
    
}

- (void)saveWithDelegate: (id<KCSPersistableDelegate>)delegate
{
    if (![self isEqual:[[KCSClient sharedClient] currentUser]]){
        NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Receiver is not current user."
                                                                           withFailureReason:@"An operation only applicable to the current user was tried on a different user."
                                                                      withRecoverySuggestion:@"Only perform this action on [[KCSClient sharedClient] currentUser]"
                                                                         withRecoveryOptions:nil];
        NSError *userError = [NSError errorWithDomain:KCSUserErrorDomain code:KCSOperationREquiresCurrentUserError userInfo:userInfo];
        [delegate entity:self operationDidFailWithError:userError];
    } else {
        // Extract all of the items from the Array into a set, so adding the "new" device token does
        // the right thing.  This might be less efficient than just iterating, but these routines have
        // been optimized, we do this now, since there's no other place guarenteed to merge.
        // Login/create store this info
        KCSPush *sp = [KCSPush sharedPush];
        
        if (sp.deviceToken != nil){
            NSMutableSet *tmpSet = [NSMutableSet setWithArray:self.deviceTokens];
            [tmpSet addObject:[sp deviceTokenString]];
            self.deviceTokens = [tmpSet allObjects];
        }
        [self saveToCollection:[KCSCollection userCollection] withDelegate:delegate];
    }
}


- (id)getValueForAttribute: (NSString *)attribute
{
    // These hard-coded attributes are for legacy usage of the library
    if ([attribute isEqualToString:@"username"]){
        return self.username;
    } else if ([attribute isEqualToString:@"password"]){
        return self.password;
    } else if ([attribute isEqualToString:@"_id"]){
        return self.userId;
    } else {
        return [self.userAttributes objectForKey:attribute];
    }
}

- (void)setValue: (id)value forAttribute: (NSString *)attribute
{
    // These hard-coded attributes are for legacy usage of the library
    if ([attribute isEqualToString:@"username"]){
        self.username = (NSString *)value;
    } else if ([attribute isEqualToString:@"password"]){
        self.password = (NSString *)value;
    } else if ([attribute isEqualToString:@"_id"]){
        self.userId = (NSString *)value;
    } else {
        [self.userAttributes setObject:value forKey:attribute];
    }
    
}

- (KCSCollection *)userCollection
{
    return [KCSCollection userCollection];
}


+ (NSDictionary *)kinveyObjectBuilderOptions
{
    static NSDictionary *options = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [@{KCS_USE_DICTIONARY_KEY : @(YES),
                   KCS_DICTIONARY_NAME_KEY : @"userAttributes"} retain];
    });
    
    return options;
}

- (NSDictionary *)hostToKinveyPropertyMapping
{
    static NSDictionary *mappedDict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mappedDict = [@{@"userId" : KCSEntityKeyId,
                      @"deviceTokens" : @"_deviceTokens",
                      @"username" : KCSUserAttributeUsername,
                      @"password" : @"password",
                      @"email" : KCSUserAttributeEmail,
                      @"givenName" : KCSUserAttributeGivenname,
                      @"surname" : KCSUserAttributeSurname,
                      @"metadata" : KCSEntityKeyMetadata,
                      @"oauthTokens" : KCSUserAttributeOAuthTokens,
                      } retain];
    });
    
    return mappedDict;
}

- (void) setOAuthToken:(NSString*)token forService:(NSString*)service
{
    [_oauthTokens setValue:token forKey:service];
}

#if NEVER
- (BOOL)authorizeFromKeychainForName:(NSString *)serviceName
                oauth2Authentication:(GTMOAuth2Authentication *)newAuth {
    [newAuth setAccessToken:nil];
    
    BOOL didGetTokens = NO;
    //    GTMOAuth2Keychain *keychain = [GTMOAuth2Keychain defaultKeychain];
    //    NSString *password = [keychain passwordForService:keychainItemName
    //                                              account:kGTMOAuth2AccountName
    //                                                error:nil];
    NSString* token = [_oauthTokens valueForKey:serviceName];
    if (token != nil) {
        [newAuth setKeysForResponseString:token];
        didGetTokens = YES;
    }
    return didGetTokens;
}
#endif

- (NSString*) debugDescription
{
    return [NSString stringWithFormat:@"KCSUser: %@",[NSDictionary dictionaryWithObjectsAndKeys:self.username, @"username", self.email, @"email", self.givenName, @"given name", self.surname, @"surname", nil]];
}

#pragma mark - Password

+ (void) sendPasswordResetForUser:(NSString*)username withCompletionBlock:(KCSUserSendEmailBlock)completionBlock
{
    // /rpc/:kid/:username/user-password-reset-initiate
    NSString* pwdReset = [[[[KCSClient sharedClient] rpcBaseURL] stringByAppendingStringWithPercentEncoding:username] stringByAppendingString:@"/user-password-reset-initiate"];
    //[NSString stringWithFormat:@"%@/user-password-reset-initiate",username]];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:pwdReset usingMethod:kPostRESTMethod];
    request = [request withCompletionAction:^(KCSConnectionResponse *response) {
        //response will be a 204 if accepted by server
        completionBlock(response.responseCode == KCS_HTTP_STATUS_NO_CONTENT, nil);
    } failureAction:^(NSError *error) {
        //do error
        completionBlock(NO, error);
    } progressAction:nil];
    [request start];
}

+ (void) sendEmailConfirmationForUser:(NSString*)username withCompletionBlock:(KCSUserSendEmailBlock)completionBlock
{
    //req.post /rpc/:kid/:username/user-email-verification-initiate
    NSString* verifyEmail = [[[[KCSClient sharedClient] rpcBaseURL] stringByAppendingStringWithPercentEncoding:username] stringByAppendingString:@"/user-email-verification-initiate"];
    //[[[KCSClient sharedClient] rpcBaseURL] stringByAppendingStringWithPercentEncoding:[NSString stringWithFormat:@"%@/user-email-verification-initiate",username]];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:verifyEmail usingMethod:kPostRESTMethod];
    request = [request withCompletionAction:^(KCSConnectionResponse *response) {
        //response will be a 204 if accepted by server
        completionBlock(response.responseCode == KCS_HTTP_STATUS_NO_CONTENT, nil);
    } failureAction:^(NSError *error) {
        //do error
        completionBlock(NO, error);
    } progressAction:nil];
    [request start];
}

#pragma mark - properties
- (void)setSurname:(NSString *)surname
{
    _surname = [surname copy];
    NSMutableDictionary* properties = [[KCSKeyChain getDictForKey:kKeychainPropertyDictKey] mutableCopy];
    if (!properties) {
        properties = [[NSMutableDictionary dictionary] retain];
    }
    [properties setValue:_surname forKey:KCSUserAttributeSurname];
    [KCSKeyChain setDict:properties forKey:kKeychainPropertyDictKey];
    [properties release];
}

- (void)setGivenName:(NSString *)givenName
{
    _givenName = [givenName copy];
    NSMutableDictionary* properties = [[KCSKeyChain getDictForKey:kKeychainPropertyDictKey] mutableCopy];
    if (!properties) {
        properties = [[NSMutableDictionary dictionary] retain];
    }
    [properties setValue:_givenName forKey:KCSUserAttributeGivenname];
    [KCSKeyChain setDict:properties forKey:kKeychainPropertyDictKey];
    [properties release];
}

- (void)setEmail:(NSString *)email
{
    _email = [email copy];
    NSMutableDictionary* properties = [[KCSKeyChain getDictForKey:kKeychainPropertyDictKey] mutableCopy];
    if (!properties) {
        properties = [[NSMutableDictionary dictionary] retain];
    }
    [properties setValue:_email forKey:KCSUserAttributeEmail];
    [KCSKeyChain setDict:properties forKey:kKeychainPropertyDictKey];
    [properties release];
}
@end
