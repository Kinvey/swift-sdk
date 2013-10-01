//
//  KinveyUser.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/1/11.
//  Copyright (c) 2011-2013 Kinvey. All rights reserved.
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
#import "KCSHiddenMethods.h"
#import "NSString+KinveyAdditions.h"
#import "NSMutableDictionary+KinveyAdditions.h"
#import "KinveyCollection.h"

#import "KCSObjectMapper.h"
#import "KCSRESTRequest.h"
#import "KCSPush.h"

#pragma mark - Constants

NSString* const KCSUserAccessTokenKey = @"access_token";
NSString* const KCSUserAccessTokenSecretKey = @"access_token_secret";
NSString* const KCSActiveUserChangedNotification = @"Kinvey.ActiveUser.Changed";

NSString* const KCSUserAttributeUsername = @"username";
NSString* const KCSUserAttributeSurname = @"last_name";
NSString* const KCSUserAttributeGivenname = @"first_name";
NSString* const KCSUserAttributeEmail = @"email";
NSString* const KCSUserAttributeFacebookId = @"_socialIdentity.facebook.id";

#pragma mark - defines & functions

#define kKeychainPasswordKey @"password"
#define kKeychainUsernameKey @"username"
#define kKeychainUserIdKey @"_id"
#define kKeychainAuthTokenKey @"authtoken"
#define kKeychainPropertyDictKey @"propertyDict"

#define kDeviceTokensKey @"_devicetokens"

#define KCSUserAttributeOAuthTokens @"_oauth"
@class GTMOAuth2Authentication;

void setActive(KCSUser* user)
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    [KCSClient sharedClient].currentUser = user;
#pragma clang diagnostic pop
}

@interface KCSUser()
@property (nonatomic, strong) NSMutableDictionary *userAttributes;
@property (nonatomic, strong) NSDictionary* oauthTokens;
@property (nonatomic, strong) NSMutableDictionary* push;
@end

@implementation KCSUser

- (instancetype) init
{
    self = [super init];
    if (self){
        _username = @"";
        _password = @"";
        _userId = @"";
        _userAttributes = [NSMutableDictionary dictionary];
        _oauthTokens = [NSMutableDictionary dictionary];
        _sessionAuth = nil;
        _surname = nil;
        _email = nil;
        _givenName = nil;
        _push = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (BOOL) hasSavedCredentials
{
    return ([KCSKeyChain getStringForKey:kKeychainPasswordKey] || [KCSKeyChain getStringForKey:kKeychainAuthTokenKey]) && [KCSKeyChain getStringForKey:kKeychainUsernameKey] && [KCSKeyChain getStringForKey:kKeychainUserIdKey];
}

+ (void) clearSavedCredentials
{
    [KCSKeyChain removeStringForKey: kKeychainUsernameKey];
    [KCSKeyChain removeStringForKey: kKeychainPasswordKey];
    [KCSKeyChain removeStringForKey: kKeychainUserIdKey];
    [KCSKeyChain removeStringForKey: kKeychainAuthTokenKey];
    [KCSKeyChain removeStringForKey: kKeychainPropertyDictKey];
}

+ (void) setupCurrentUser:(KCSUser*)user properties:(NSDictionary*)dictionary password:(NSString*)password username:(NSString*)username completionBlock:(KCSUserCompletionBlock)block
{
    [KCSKeyChain setDict:dictionary forKey:kKeychainPropertyDictKey];
    
    NSMutableDictionary* properties = [dictionary mutableCopy];
    
    NSString* propUsername = [properties popObjectForKey:@"username"];
    NSString* propPassword = [properties popObjectForKey:@"password"];
    NSString* propId = [properties popObjectForKey:@"_id"];
    
    user.username = propUsername != nil ? propUsername : username;
    user.password = propPassword != nil ? propPassword : password;
    user.userId   = propId;
    
    if (user.userId == nil || user.username == nil) {
        //prevent that weird assertion that Colden was seeinƒƒg
        return;
    }
    
    NSMutableDictionary* tokens = [[properties popObjectForKey:@"_push"] mutableCopy];
    user.push = tokens;
    user.oauthTokens = [properties popObjectForKey:KCSUserAttributeOAuthTokens];
    
    user.surname = [properties popObjectForKey:KCSUserAttributeSurname];
    user.givenName = [properties popObjectForKey:KCSUserAttributeGivenname];
    user.email = [properties popObjectForKey:KCSUserAttributeEmail];
    
    NSDictionary* metadata = [properties popObjectForKey:@"_kmd"];
    NSDictionary* emailVerification = [metadata objectForKey:@"emailVerification"];
    NSString* verificationStatus = [emailVerification objectForKey:@"status"];
    user->_emailVerified = [verificationStatus isEqualToString:@"confirmed"];
    
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
    
    assert(user.username != nil && user.userId != nil);
    
    [KCSKeyChain setString:user.username forKey:kKeychainUsernameKey];
    [KCSKeyChain setString:user.userId forKey:kKeychainUserIdKey];
    
    if (password != nil) {
        //password auth
        [KCSKeyChain setString:user.password forKey:kKeychainPasswordKey];
    }
    if (sessionAuth != nil) {
        //session auth
        [KCSKeyChain setString:user.sessionAuth forKey:kKeychainAuthTokenKey];
    }
    
    setActive(user);
    
    [[KCSPush sharedPush] registerDeviceToken:^(BOOL success, NSError *error) {
        block(user, error, -1);
    }];
}

static KCSRESTRequest* lastBGUpdate = nil;

- (void) refreshFromServer:(KCSCompletionBlock)completionBlock
{
    if ([KCSUser activeUser] != self) {
        KCSLogError(@"Error: Attempting to refresh a non-activeUser");
        NSDictionary* errorInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"User refresh is not on active user" withFailureReason:@"" withRecoverySuggestion:@"" withRecoveryOptions:@[]];
        NSError* error = [NSError errorWithDomain:KCSUserErrorDomain code:KCSUserObjectNotActiveError userInfo:errorInfo];
        completionBlock(nil, error);
        return;
    }
    if (self.userId == nil) {
        KCSLogError(@"Error refreshing user, no user id.");
        NSDictionary* errorInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"User refresh is not on active user" withFailureReason:@"" withRecoverySuggestion:@"" withRecoveryOptions:@[]];
        NSError* error = [NSError errorWithDomain:KCSUserErrorDomain code:KCSUserObjectNotActiveError userInfo:errorInfo];
        completionBlock(nil, error);
        return;
    }
    [lastBGUpdate cancel];
    
    lastBGUpdate = [KCSRESTRequest requestForResource:[[[KCSClient sharedClient] userBaseURL] stringByAppendingFormat:@"%@", self.userId] usingMethod:kGetRESTMethod];
    [lastBGUpdate setContentType:KCS_JSON_TYPE];
    
    // Set up our callbacks
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        lastBGUpdate = nil;

        if ([KCSUser activeUser] != self) {
            KCSLogError(@"Error: Attempting to refresh a non-activeUser");
            NSDictionary* errorInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"User refresh is not on active user" withFailureReason:@"" withRecoverySuggestion:@"" withRecoveryOptions:@[]];
            NSError* error = [NSError errorWithDomain:KCSUserErrorDomain code:KCSUserObjectNotActiveError userInfo:errorInfo];
            completionBlock(nil, error);
            return;
        }
        
        // Ok, we're really auth'd
        if ([response responseCode] < 300) {
            NSDictionary *dictionary = (NSDictionary*) [response jsonResponseValue];
            [KCSUser setupCurrentUser:self properties:dictionary password:self.password username:self.username completionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
                completionBlock(@[user], errorOrNil);
            }];
        } else {
            KCSLogError(@"Internal Error Updating user: %@", [response jsonResponseValue]);
            NSError* error = [KCSErrorUtilities createError:[response jsonResponseValue] description:@"Error updating active User" errorCode:response.responseCode domain:KCSUserErrorDomain requestId:response.requestId];
            completionBlock(@[self], error);
        }
    };
    
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        lastBGUpdate = nil;
        KCSLogError(@"Internal Error Updating user: %@", error);
        completionBlock(nil, error);
    };
    
    [lastBGUpdate withCompletionAction:cBlock failureAction:fBlock progressAction:nil];
    [lastBGUpdate start];
}

#pragma mark - Create new Users

+ (void)registerUserWithUsername:(NSString *)uname withPassword:(NSString *)password withCompletionBlock:(KCSUserCompletionBlock)completionBlock forceNew:(BOOL)forceNew
{
    // Did we get a username and password?  If we did, then we're not interested in being already logged in
    // If we didn't, we need to check to see if there are keychain items.
    
    if (forceNew){
        [KCSUser clearSavedCredentials];
    }
    
    KCSUser *createdUser = [[KCSUser alloc] init];
    createdUser.username = [KCSKeyChain getStringForKey:kKeychainUsernameKey];
    
    if (createdUser.username == nil){
        // No user, generate it, note, use the APP KEY/APP SECRET!
        NSMutableDictionary *userJSONPaylod = [NSMutableDictionary dictionary];
        // Build the dictionary that will be JSON-ified here
        
        // Next we check for the username and password
        if (uname && password){
            [userJSONPaylod setObject:uname forKey:@"username"];
            [userJSONPaylod setObject:password forKey:@"password"];
        }
        
        NSDictionary *userData = [NSDictionary dictionaryWithDictionary:userJSONPaylod];
        
        KCSRESTRequest *userRequest = [KCSRESTRequest requestForResource:[[KCSClient sharedClient] userBaseURL] usingMethod:kPostRESTMethod];
        
        
        [userRequest setContentType:KCS_JSON_TYPE];
        KCS_SBJsonWriter *writer = [[KCS_SBJsonWriter alloc] init];
        [userRequest addBody:[writer dataWithObject:userData]];
        
        // Set up our callbacks
        KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
            
            // Ok, we're probably authenticated
            if (response.responseCode != KCS_HTTP_STATUS_CREATED){
                // Crap, authentication failed, not really sure how to proceed here!!!
                // I really don't know what to do here, we can't continue... Something died...
                KCSLogError(@"Received Response code %d, but expected %d with response: %@", response.responseCode, KCS_HTTP_STATUS_CREATED, [response stringValue]);
                
                NSError* error = nil;
                if (response.responseCode == KCS_HTTP_STATUS_CONFLICT) {
                    error = [KCSErrorUtilities createError:(NSDictionary*)[response jsonResponseValue] description:@"User already exists" errorCode:KCSConflictError domain:KCSUserErrorDomain requestId:response.requestId];
                } else {
                    error = [KCSErrorUtilities createError:(NSDictionary*)[response jsonResponseValue] description:@"Unable to create user" errorCode:response.responseCode domain:KCSUserErrorDomain requestId:response.requestId];
                    
                }
                
                completionBlock(nil, error, 0);
                return;
            }
            
            // Ok, we're really authd
            NSDictionary *dictionary = (NSDictionary*) [response jsonResponseValue];
            [self setupCurrentUser:createdUser properties:dictionary password:password username:uname completionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
                //TODO: handle register error
                
                // NB: The delegate MUST retain created user!
                completionBlock(createdUser, nil, KCSUserCreated);
            }];
        };
        
        KCSConnectionFailureBlock fBlock = ^(NSError *error){
            // I really don't know what to do here, we can't continue... Something died...
            KCSLogError(@"Internal Error: %@", error);
            completionBlock(nil, error, 0);
            return;
        };
        
        KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *conn){};
        
        [userRequest withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock];
        [userRequest start];
        
        
    } else {
        createdUser.password = [KCSKeyChain getStringForKey:kKeychainPasswordKey];
        createdUser.userId = [KCSKeyChain getStringForKey:kKeychainUserIdKey];
        createdUser.sessionAuth = [KCSKeyChain getStringForKey:kKeychainAuthTokenKey];
        
        setActive(createdUser);
        [createdUser refreshFromServer:^(NSArray *objectsOrNil, NSError *errorOrNil) {
            completionBlock(createdUser, errorOrNil, KCSUserFound);
        }];
    }
}

+ (void)createAutogeneratedUser:(KCSUserCompletionBlock)completionBlock
{
    [self registerUserWithUsername:nil withPassword:nil withCompletionBlock:completionBlock forceNew:YES];
}

+ (void) userWithUsername:(NSString *)username password:(NSString *)password withCompletionBlock:(KCSUserCompletionBlock)completionBlock
{
    if (!username) [[NSException exceptionWithName:NSInvalidArgumentException reason:@"username should not be nil. Use [KCSUser createAutogeneratedUser:] to create an auto-generated user" userInfo:nil] raise];
    if (!password) [[NSException exceptionWithName:NSInvalidArgumentException reason:@"password should not be nil. Use [KCSUser createAutogeneratedUser:] to create an auto-generated user" userInfo:nil] raise];
    [self registerUserWithUsername:username withPassword:password withCompletionBlock:completionBlock forceNew:YES];
}

+ (void)userWithUsername: (NSString *)username
                password: (NSString *)password
            withDelegate: (id<KCSUserActionDelegate>)delegate
{
    [self userWithUsername:username password:password withCompletionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        if (delegate != nil) {
            if (errorOrNil != nil) {
                [delegate user:user actionDidFailWithError:errorOrNil];
            } else {
                [delegate user:user actionDidCompleteWithResult:result];
            }
        }
    }];
}


# pragma mark - Init from credentials
+ (KCSUser *)initAndActivateWithSavedCredentials
{
    if ([KCSUser hasSavedCredentials] == YES) {
        KCSUser *createdUser = [[KCSUser alloc] init];
        createdUser.username = [KCSKeyChain getStringForKey:kKeychainUsernameKey];
        createdUser.password = [KCSKeyChain getStringForKey:kKeychainPasswordKey];
        createdUser.userId = [KCSKeyChain getStringForKey:kKeychainUserIdKey];
        createdUser.sessionAuth = [KCSKeyChain getStringForKey:kKeychainAuthTokenKey];
        
        NSDictionary* properties = [KCSKeyChain getDictForKey:kKeychainPropertyDictKey];
        setActive(createdUser);
        if (properties) {
            [self setupCurrentUser:createdUser properties:properties password:createdUser.password username:createdUser.username completionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
                //TODO: handle error
            }];
        }
        [createdUser refreshFromServer:^(NSArray *objectsOrNil, NSError *errorOrNil) {
            //TODO: handle error
        }];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    return [KCSClient sharedClient].currentUser;
#pragma clang diagnostic pop
}

// These routines all do similar work, but the first two are for legacy support
- (void)initializeCurrentUserWithRequest: (KCSRESTRequest *)request
{
    [KCSUser activeUser];
    if (request){
        [request start];
    }
}

- (void)initializeCurrentUser
{
    [KCSUser activeUser];
}

#pragma mark - Login

+ (void)loginWithUsername: (NSString *)username
                 password: (NSString *)password
      withCompletionBlock:(KCSUserCompletionBlock)completionBlock
{
    if (!username) [[NSException exceptionWithName:NSInvalidArgumentException reason:@"username should not be nil." userInfo:nil] raise];
    if (!password) [[NSException exceptionWithName:NSInvalidArgumentException reason:@"password should not be nil." userInfo:nil] raise];

    
    KCSClient *client = [KCSClient sharedClient];
    
    // Just log-in and set currentUser
    // Set up our callbacks
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
        // Ok, we're probably authenticated
        KCSUser *createdUser = [[KCSUser alloc] init];
        createdUser.username = username;
        createdUser.password = password;
        if (response.responseCode != KCS_HTTP_STATUS_OK){
            setActive(nil);
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
        [self setupCurrentUser:createdUser properties:dictionary password:password username:username completionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
            //TODO: handle registration error
            
            // Delegate must retain createdUser
            completionBlock(createdUser, nil, KCSUserFound);
        }];
    };
    
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        // I really don't know what to do here, we can't continue... Something died...
        KCSLogError(@"Internal Error: %@", error);
        
        setActive(nil);
        
        completionBlock(nil, error, 0);
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *conn){};
    
    
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:[client.userBaseURL stringByAppendingString:@"_me"] usingMethod:kGetRESTMethod];
    
    // We need to init the current user to something before trying this

    // Create a temp user with uname/password and use it it init currentUser
    KCSUser *tmpCurrentUser = [[KCSUser alloc] init];
    tmpCurrentUser.username = username;
    tmpCurrentUser.password = password;
    setActive(tmpCurrentUser);
    
    [request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock];
    [request start];
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
    KCSUser* createdUser = [[KCSUser alloc] init];
    NSString* authToken = [dictionary valueForKeyPath:@"_kmd.authtoken"];
    
    NSError* error = nil;
    int status = 0;
    if (authToken != nil) {
        status = KCSUserFound;
    } else {
        NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Login Failed"
                                                                           withFailureReason:@"User could not be authorized"
                                                                      withRecoverySuggestion:@"Try again with different access token"
                                                                         withRecoveryOptions:nil];
        error = [NSError errorWithDomain:KCSUserErrorDomain code:KCSLoginFailureError userInfo:userInfo];
    }
    [self setupCurrentUser:createdUser properties:dictionary password:nil username:nil completionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
        //TODO: handle registration error
        
        
        // Delegate must retain createdUser
        completionBlock(createdUser, error, status);
    }];

}

//TODO: constants for fields
+ (NSDictionary*) loginDictForProvder:(KCSUserSocialIdentifyProvider)provder accessDictionary:(NSDictionary*)accessDictionary
{
    NSDictionary* dict = @{};
    NSString* accessToken = [accessDictionary objectForKey:KCSUserAccessTokenKey];
    NSString* accessTokenSecret = [accessDictionary objectForKey:KCSUserAccessTokenSecretKey];
    switch (provder) {
        case KCSSocialIDFacebook: {
            NSString* appId = [accessDictionary objectForKey:KCS_FACEBOOK_APP_KEY];
            if (appId == nil) {
                appId = [[KCSClient sharedClient].options objectForKey:KCS_FACEBOOK_APP_KEY];
                if (appId == nil) {
                    appId = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FacebookAppID"];
                    if (appId == nil) {
                        // could not locate in the access dictionary, client, or plist, error
                        KCSLogWarning(@"No Facebook App Id provided in access dictionary, or KCSClient options key");
                        DBAssert(appId != nil, @"No Facebook App Id provided");
                    }
                }
            }
            dict = appId != nil ?  @{@"_socialIdentity" : @{@"facebook" : @{@"access_token" : accessToken, @"appid" : appId}}} :
                                   @{@"_socialIdentity" : @{@"facebook" : @{@"access_token" : accessToken}}};
        }
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
        case KCSSocialIDLinkedIn: {
            NSString* linkedInKey = [[KCSClient sharedClient].options objectForKey:KCS_LINKEDIN_API_KEY];
            NSString* linkedInSecret = [[KCSClient sharedClient].options objectForKey:KCS_LINKEDIN_SECRET_KEY];
            DBAssert(linkedInKey != nil && linkedInSecret != nil, @"LinkedIn info should not be nil.");
            if (linkedInKey != nil && linkedInSecret != nil) {
                dict = @{@"_socialIdentity" : @{@"linkedIn" : @{@"access_token" : accessToken,
                @"access_token_secret" : accessTokenSecret,
                @"consumer_key" : linkedInKey,
                @"consumer_secret" : linkedInSecret}}};
            }
        }
            break;
        case KCSSocialIDSalesforce: {
            NSString* idUrl = [accessDictionary objectForKey:KCS_SALESFORCE_IDENTITY_URL];
            NSString* refreshToken = [accessDictionary objectForKey:KCS_SALESFORCE_REFRESH_TOKEN];
            NSString* clientId = [accessDictionary objectForKey:KCS_SALESFORCE_CLIENT_ID];
            if (clientId == nil) {
                clientId = [[KCSClient sharedClient].options objectForKey:KCS_SALESFORCE_CLIENT_ID];
            }
            DBAssert(idUrl != nil, @"salesForce info should not be nil.");
            if (idUrl != nil && accessToken != nil) {
                dict = @{@"_socialIdentity" : @{@"salesforce" : @{@"access_token" : accessToken,
                                                                KCS_SALESFORCE_IDENTITY_URL : idUrl,
                                                                  KCS_SALESFORCE_REFRESH_TOKEN: refreshToken,
                                                                  KCS_SALESFORCE_CLIENT_ID : clientId}}};
            }

        }
            break;
        default:
            dict = accessDictionary;
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
        
        setActive(nil);

        completionBlock(nil, error, 0);
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *conn){};
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response) {
        if ([response responseCode] >= 400) {
            KCSUser *createdUser = [[KCSUser alloc] init];
            
            setActive(nil);
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
    
    [loginRequest setContentType:KCS_JSON_TYPE];
    [loginRequest withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock];
    [loginRequest start];
}

+ (void)loginWithWithSocialIdentity:(KCSUserSocialIdentifyProvider)provider accessDictionary:(NSDictionary*)accessDictionary withCompletionBlock:(KCSUserCompletionBlock)completionBlock
{
    [self loginWithSocialIdentity:provider accessDictionary:accessDictionary withCompletionBlock:completionBlock];
}

+ (void)loginWithSocialIdentity:(KCSUserSocialIdentifyProvider)provider accessDictionary:(NSDictionary*)accessDictionary withCompletionBlock:(KCSUserCompletionBlock)completionBlock;
{
    KCSClient *client = [KCSClient sharedClient];
    KCSRESTRequest *loginRequest = [KCSRESTRequest requestForResource:[client.userBaseURL stringByAppendingString:@"login"] usingMethod:kPostRESTMethod];
    NSDictionary* loginDict = [self loginDictForProvder:provider accessDictionary:accessDictionary];
    [loginRequest setJsonBody:loginDict];
    
    // We need to init the current user to something before trying this
    
    KCSConnectionFailureBlock fBlock = ^(NSError *error){
        // I really don't know what to do here, we can't continue... Something died...
        KCSLogError(@"Internal Error: %@", error);
        
        setActive(nil);
        
        completionBlock(nil, error, 0);
    };
    
    KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *conn){};
    
    KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response) {
        if ([response responseCode] != KCS_HTTP_STATUS_OK) {
            //This is new user, log in
            dispatch_async(dispatch_get_main_queue(), ^{
                [KCSUser registerUserWithSocialIdentity:provider accessDictionary:accessDictionary withCompletionBlock:completionBlock];
            });
        } else { //successful
            [self setupSessionAuthUser:response client:client completionBlock:completionBlock];
        }
    };
    
    KCSUser *tmpCurrentUser = [[KCSUser alloc] init];
    tmpCurrentUser.username = @"";
    tmpCurrentUser.password = @"";
    setActive(tmpCurrentUser);
    
    [loginRequest setContentType:KCS_JSON_TYPE];
    [loginRequest withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock];
    [loginRequest start];
}

- (void)logout
{
    if (![self isEqual:[KCSUser activeUser]]){
        KCSLogError(@"Attempted to log out a user who is not the KCS Current User!");
    } else {
        [lastBGUpdate cancel];
        
        self.username = nil;
        self.password = nil;
        self.userId = nil;
        
        // Extract all of the items from the Array into a set, so adding the "new" device token does
        // the right thing.  This might be less efficient than just iterating, but these routines have
        // been optimized, we do this now, since there's no other place guarenteed to merge.
        // Login/create store this info
        
//TODO: comment out to keep the user from being f'ed up. Reinstate once working on the server-side.
//        KCSDevice *sp = [KCSDevice currentDevice];
//        
//        if (sp.deviceToken != nil){
//            NSMutableSet *tmpSet = [NSMutableSet setWithArray:self.deviceTokens];
//            [tmpSet removeObject:[sp deviceTokenString]];
//            self.deviceTokens = [tmpSet allObjects];
//            [self saveToCollection:[KCSCollection userCollection] withCompletionBlock:^(NSArray *objectsOrNil, NSError *errorOrNil) {
//                if (errorOrNil) {
//                    KCSLogError(@"Error saving user when removing device tokens: %@", errorOrNil);
//                }
//            } withProgressBlock:nil];
//        }
        [[KCSPush sharedPush] setDeviceToken:nil];
        
        [KCSUser clearSavedCredentials];
        
        // Set the currentUser to nil
        setActive(nil);
    }
}


- (void)removeWithDelegate: (id<KCSPersistableDelegate>)delegate
{
    if (![self isEqual:[[KCSClient sharedClient] currentUser]]){
        NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Receiver is not current user."
                                                                           withFailureReason:@"An operation only applicable to the current user was tried on a different user."
                                                                      withRecoverySuggestion:@"Only perform this action on [[KCSClient sharedClient] currentUser]"
                                                                         withRecoveryOptions:nil];
        NSError *userError = [NSError errorWithDomain:KCSUserErrorDomain code:KCSOperationRequiresCurrentUserError userInfo:userInfo];
        [delegate entity:self operationDidFailWithError:userError];
    } else {
        [self deleteFromCollection:[KCSCollection userCollection] withDelegate:delegate];
    }
}

- (void) removeWithCompletionBlock:(KCSCompletionBlock)completionBlock
{
    if (![self isEqual:[KCSUser activeUser]]){
        NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Receiver is not current user."
                                                                           withFailureReason:@"An operation only applicable to the current user was tried on a different user."
                                                                      withRecoverySuggestion:@"Only perform this action on [[KCSClient sharedClient] currentUser]"
                                                                         withRecoveryOptions:nil];
        NSError *userError = [NSError errorWithDomain:KCSUserErrorDomain code:KCSOperationRequiresCurrentUserError userInfo:userInfo];
        completionBlock(nil, userError);
    } else {
        [self deleteFromCollection:[KCSCollection userCollection] withCompletionBlock:completionBlock withProgressBlock:nil];
    }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
- (void)loadWithDelegate: (id<KCSEntityDelegate>)delegate
{
    if (![self isEqual:[[KCSClient sharedClient] currentUser]]){
        NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Receiver is not current user."
                                                                           withFailureReason:@"An operation only applicable to the current user was tried on a different user."
                                                                      withRecoverySuggestion:@"Only perform this action on [[KCSClient sharedClient] currentUser]"
                                                                         withRecoveryOptions:nil];
        NSError *userError = [NSError errorWithDomain:KCSUserErrorDomain code:KCSOperationRequiresCurrentUserError userInfo:userInfo];
        [delegate entity:self fetchDidFailWithError:userError];
    } else {
        [self loadObjectWithID:self.userId fromCollection:[KCSCollection userCollection] withDelegate:delegate];
    }
}
#pragma clang diagnostic pop

- (void)saveWithDelegate: (id<KCSPersistableDelegate>)delegate
{
    if (![self isEqual:[[KCSClient sharedClient] currentUser]]){
        NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Receiver is not current user."
                                                                           withFailureReason:@"An operation only applicable to the current user was tried on a different user."
                                                                      withRecoverySuggestion:@"Only perform this action on [[KCSClient sharedClient] currentUser]"
                                                                         withRecoveryOptions:nil];
        NSError *userError = [NSError errorWithDomain:KCSUserErrorDomain code:KCSOperationRequiresCurrentUserError userInfo:userInfo];
        [delegate entity:self operationDidFailWithError:userError];
    } else {
        [self saveToCollection:[KCSCollection userCollection] withDelegate:delegate];
    }
}


- (void) saveWithCompletionBlock:(KCSCompletionBlock)completionBlock
{
    if (![self isEqual:[KCSUser activeUser]]){
        NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Receiver is not current user."
                                                                           withFailureReason:@"An operation only applicable to the current user was tried on a different user."
                                                                      withRecoverySuggestion:@"Only perform this action on [[KCSClient sharedClient] currentUser]"
                                                                         withRecoveryOptions:nil];
        NSError *userError = [NSError errorWithDomain:KCSUserErrorDomain code:KCSOperationRequiresCurrentUserError userInfo:userInfo];
        completionBlock(nil, userError);
    } else {
        
        //-- save to collection
        KCSSerializedObject *obj = [KCSObjectMapper makeKinveyDictionaryFromObject:self error:NULL];
        BOOL isPostRequest = obj.isPostRequest;
        NSString *objectId = obj.objectId;
        NSDictionary *dictionaryToMap = obj.dataToSerialize;
        
        NSString *resource = nil;
        KCSCollection* collection = [KCSCollection userCollection];
        if ([collection.collectionName isEqualToString:@""]){
            resource = [collection.baseURL stringByAppendingFormat:@"%@", objectId];
        } else {
            resource = [collection.baseURL stringByAppendingFormat:@"%@/%@", collection.collectionName, objectId];
        }
        
        
        NSInteger HTTPMethod;
        
        // If we need to post this, then do so
        if (isPostRequest){
            HTTPMethod = kPostRESTMethod;
        } else {
            HTTPMethod = kPutRESTMethod;
        }
        // Prepare our request
        KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:HTTPMethod];
        // This is a JSON request
        [request setContentType:KCS_JSON_TYPE];
        // Make sure to include the UTF-8 encoded JSONData...
        KCS_SBJsonWriter *writer = [[KCS_SBJsonWriter alloc] init];
        [request addBody:[writer dataWithObject:dictionaryToMap]];
        
        // Prepare our handlers
        KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response) {
            NSDictionary *jsonResponse = (NSDictionary*) [response jsonResponseValue];
            
            if (response.responseCode != KCS_HTTP_STATUS_CREATED && response.responseCode != KCS_HTTP_STATUS_OK){
                NSError* error = [KCSErrorUtilities createError:jsonResponse description:@"Entity operation was unsuccessful." errorCode:response.responseCode domain:KCSAppDataErrorDomain requestId:response.requestId];
                completionBlock(nil, error);
            } else {
                [KCSUser setupCurrentUser:self properties:jsonResponse password:self.password username:self.username completionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
                    //TODO: handle registration error
                    completionBlock(@[self], nil);
                }];
            }
        };
        
        KCSConnectionFailureBlock fBlock = ^(NSError *error){
            completionBlock(nil, error);
        };
        
        // Make the request happen
        [[request withCompletionAction:cBlock failureAction:fBlock progressAction:^(KCSConnectionProgress *conn){}] start];
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

- (void) removeValueForAttribute:(NSString*)attribute
{
    if (![self.userAttributes objectForKey:attribute]) {
        KCSLogWarning(@"trying to remove attribute '%@'. This attribute does not exist for the user.", attribute);
    }
    [self.userAttributes removeObjectForKey:attribute];
}

#pragma mark - Kinvey Entity

- (KCSCollection *)userCollection
{
    return [KCSCollection userCollection];
}

+ (NSDictionary *)kinveyObjectBuilderOptions
{
    static NSDictionary *options = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = @{KCS_USE_DICTIONARY_KEY : @(YES),
                   KCS_DICTIONARY_NAME_KEY : @"userAttributes"};
    });
    
    return options;
}

- (NSDictionary *)hostToKinveyPropertyMapping
{
    static NSDictionary *mappedDict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mappedDict = @{@"userId" : KCSEntityKeyId,
                      @"push" : @"_push",
                      @"username" : KCSUserAttributeUsername,
                      @"password" : @"password",
                      @"email" : KCSUserAttributeEmail,
                      @"givenName" : KCSUserAttributeGivenname,
                      @"surname" : KCSUserAttributeSurname,
                      @"metadata" : KCSEntityKeyMetadata,
                      @"oauthTokens" : KCSUserAttributeOAuthTokens,
        };
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

+ (void) sendPasswordResetForUser:(NSString*)usernameOrEmail withCompletionBlock:(KCSUserSendEmailBlock)completionBlock
{
    // /rpc/:kid/:username/user-password-reset-initiate
    // /rpc/:kid/:email/user-password-reset-initiate
    NSString* pwdReset = [[[[KCSClient sharedClient] rpcBaseURL] stringByAppendingStringWithPercentEncoding:usernameOrEmail] stringByAppendingString:@"/user-password-reset-initiate"];
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

+ (void) sendForgotUsername:(NSString*)email withCompletionBlock:(KCSUserSendEmailBlock)completionBlock
{
    NSParameterAssert(email);
    
    NSString* pwdReset = [[[KCSClient sharedClient] rpcBaseURL] stringByAppendingString:@"user-forgot-username"];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:pwdReset usingMethod:kPostRESTMethod];
    [request addHeaders:@{@"Content-Type":@"application/json"}];
    [request setJsonBody:@{@"email" : email}];
    
    request = [request withCompletionAction:^(KCSConnectionResponse *response) {
        //response will be a 204 if accepted by server
        completionBlock(response.responseCode == KCS_HTTP_STATUS_NO_CONTENT, nil);
    } failureAction:^(NSError *error) {
        //do error
        completionBlock(NO, error);
    } progressAction:nil];
    [request start];
}

+ (void) checkUsername:(NSString*)potentialUsername withCompletionBlock:(KCSUserCheckUsernameBlock)completionBlock
{
    NSParameterAssert(potentialUsername != nil);
    
    // /rpc/:appKey/check-username-exists
    NSString* checkExists = [[[KCSClient sharedClient] rpcBaseURL] stringByAppendingString:@"check-username-exists"];
    KCSRESTRequest *request = [KCSRESTRequest requestForResource:checkExists usingMethod:kPostRESTMethod];
    [request setJsonBody:@{@"username": potentialUsername}];
    [request setContentType:KCS_JSON_TYPE];
    request = [request withCompletionAction:^(KCSConnectionResponse *response) {
        NSDictionary* dict = [response jsonResponseValue];
        if (response.responseCode == KCS_HTTP_STATUS_OK) {
            completionBlock(potentialUsername, [dict[@"usernameExists"] boolValue], nil);
        } else {
            NSError* error = [KCSErrorUtilities createError:dict description:@"Error checking user name" errorCode:response.responseCode domain:KCSUserErrorDomain requestId:response.requestId];
            completionBlock(potentialUsername, NO, error);
        }
        //response will be a 204 if accepted by server
        //completionBlock(response.responseCode == KCS_HTTP_STATUS_NO_CONTENT, nil);
    } failureAction:^(NSError *error) {
        //do error
        completionBlock(potentialUsername, NO ,error);
    } progressAction:nil];
    [request start];
}


#pragma mark - properties
- (void)setSurname:(NSString *)surname
{
    _surname = [surname copy];
    NSMutableDictionary* properties = [[KCSKeyChain getDictForKey:kKeychainPropertyDictKey] mutableCopy];
    if (!properties) {
        properties = [NSMutableDictionary dictionary];
    }
    [properties setValue:_surname forKey:KCSUserAttributeSurname];
    [KCSKeyChain setDict:properties forKey:kKeychainPropertyDictKey];
}

- (void)setGivenName:(NSString *)givenName
{
    _givenName = [givenName copy];
    NSMutableDictionary* properties = [[KCSKeyChain getDictForKey:kKeychainPropertyDictKey] mutableCopy];
    if (!properties) {
        properties = [NSMutableDictionary dictionary];
    }
    [properties setValue:_givenName forKey:KCSUserAttributeGivenname];
    [KCSKeyChain setDict:properties forKey:kKeychainPropertyDictKey];
}

- (void)setEmail:(NSString *)email
{
    _email = [email copy];
    NSMutableDictionary* properties = [[KCSKeyChain getDictForKey:kKeychainPropertyDictKey] mutableCopy];
    if (!properties) {
        properties = [NSMutableDictionary dictionary];
    }
    [properties setValue:_email forKey:KCSUserAttributeEmail];
    [KCSKeyChain setDict:properties forKey:kKeychainPropertyDictKey];
}

+ (KCSUser *)activeUser
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated"
    KCSUser* user = [KCSClient sharedClient].currentUser;
#pragma clang diagnostic pop
    if (!user) {
        user = [self initAndActivateWithSavedCredentials];
    }
    return user;
}

- (NSMutableSet*) deviceTokens
{
    if (_push == nil) {
        self.push = [NSMutableDictionary dictionary];
    }
    if (_push[kDeviceTokensKey] == nil) {
        _push[kDeviceTokensKey] = [NSMutableSet set];
    } else if ([_push[kDeviceTokensKey] isKindOfClass:[NSArray class]]) {
        _push[kDeviceTokensKey] = [NSMutableSet setWithArray:_push[kDeviceTokensKey]];
    }
    return _push[kDeviceTokensKey];
}

- (void) changePassword:(NSString*)newPassword completionBlock:(KCSCompletionBlock)completionBlock
{
    if (![self isEqual:[KCSUser activeUser]]){
        NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Receiver is not current user."
                                                                           withFailureReason:@"An operation only applicable to the current user was tried on a different user."
                                                                      withRecoverySuggestion:@"Only perform this action on [[KCSClient sharedClient] currentUser]"
                                                                         withRecoveryOptions:nil];
        NSError *userError = [NSError errorWithDomain:KCSUserErrorDomain code:KCSOperationRequiresCurrentUserError userInfo:userInfo];
        completionBlock(nil, userError);
    } else {
        NSString* uname = self.username;
        NSString* pwd = [self.password copy];
        
        self.password = newPassword;
        
        KCSSerializedObject *obj = [KCSObjectMapper makeKinveyDictionaryFromObject:self error:NULL];
        BOOL isPostRequest = obj.isPostRequest;
        NSString *objectId = obj.objectId;
        NSDictionary *dictionaryToMap = obj.dataToSerialize;
        
        NSString *resource = nil;
        KCSCollection* collection = [KCSCollection userCollection];
        if ([collection.collectionName isEqualToString:@""]){
            resource = [collection.baseURL stringByAppendingFormat:@"%@", objectId];
        } else {
            resource = [collection.baseURL stringByAppendingFormat:@"%@/%@", collection.collectionName, objectId];
        }
        
        
        NSInteger HTTPMethod;
        
        // If we need to post this, then do so
        if (isPostRequest){
            HTTPMethod = kPostRESTMethod;
        } else {
            HTTPMethod = kPutRESTMethod;
        }
        
        
        // Prepare our request
        KCSRESTRequest *request = [KCSRESTRequest requestForResource:resource usingMethod:HTTPMethod];
        
        // This is a JSON request
        [request setContentType:KCS_JSON_TYPE];
        
        // Make sure to include the UTF-8 encoded JSONData...
        KCS_SBJsonWriter *writer = [[KCS_SBJsonWriter alloc] init];
        [request addBody:[writer dataWithObject:dictionaryToMap]];
        
        // Prepare our handlers
        KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response) {
            NSDictionary *jsonResponse = (NSDictionary*) [response jsonResponseValue];
            
            if (response.responseCode != KCS_HTTP_STATUS_CREATED && response.responseCode != KCS_HTTP_STATUS_OK){
                NSError* error = [KCSErrorUtilities createError:jsonResponse description:@"Entity operation was unsuccessful." errorCode:response.responseCode domain:KCSAppDataErrorDomain requestId:response.requestId];
                completionBlock(nil, error);
            } else {
                [KCSUser setupCurrentUser:self properties:jsonResponse password:newPassword username:self.username completionBlock:^(KCSUser *user, NSError *errorOrNil, KCSUserActionResult result) {
                    //TODO: handle registration error
                    completionBlock(@[self], nil);
                }];
                
            }
        };
        
        KCSConnectionFailureBlock fBlock = ^(NSError *error){
            completionBlock(nil, error);
        };
        
        KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *conn){};
        [request setAuth:uname password:pwd];
        
        [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
    }
}
@end
