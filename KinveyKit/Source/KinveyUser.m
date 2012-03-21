//
//  KinveyUser.m
//  KinveyKit
//
//  Created by Brian Wilson on 12/1/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import "KinveyUser.h"
#import "KCSClient.h"
#import "KCSKeyChain.h"
#import "KCSRESTRequest.h"
#import "KinveyAnalytics.h"
#import "SBJson.h"
#import "KinveyBlocks.h"
#import "KCSConnectionResponse.h"
#import "KinveyHTTPStatusCodes.h"
#import "KinveyErrorCodes.h"
#import "KCSErrorUtilities.h"
#import "KCSLogManager.h"
#import "KinveyCollection.h"
#import "KCSReachability.h"
#import "KCSPush.h"


@interface KCSUser()
@property (nonatomic, retain) NSString *userId;
@property (nonatomic, retain) NSMutableDictionary *userAttributes;

+ (void)registerUserWithUsername: (NSString *)uname withPassword: (NSString *)password withDelegate: (id<KCSUserActionDelegate>)delegate forceNew: (BOOL)forceNew;
@end

@implementation KCSUser

@synthesize username=_username;
@synthesize password=_password;
@synthesize userId=_userId;
@synthesize userAttributes = _userAttributes;
@synthesize deviceTokens = _deviceTokens;


- (id)init
{
    self = [super init];
    if (self){
        _username = [[NSString string] retain];
        _password = [[NSString string] retain];
        _userId = [[NSString string] retain];
        _userAttributes = [[NSMutableDictionary dictionary] retain];
        _deviceTokens = nil;
    }
    return self;
}

- (void)dealloc
{
    [_username release];
    [_password release];
    [_userId release];
    [_userAttributes release];
    [_deviceTokens release];
    [super dealloc];
}

+ (void)registerUserWithUsername:(NSString *)uname withPassword:(NSString *)password withDelegate:(id<KCSUserActionDelegate>)delegate forceNew:(BOOL)forceNew
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
                if (delegate != nil){
                    // We're going to Make a failure happen here...
                    NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Unable to create user."
                                                                                       withFailureReason:@"User creation timed out with one request holding the lock." 
                                                                                  withRecoverySuggestion:@"Try request again later."
                                                                                     withRecoveryOptions:nil];

                    // No user, it's during creation
                    [delegate user:nil actionDidFailWithError:[NSError errorWithDomain:KCSUserErrorDomain
                                                                                   code:KCSUserCreationContentionTimeoutError
                                                                               userInfo:userInfo]];
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
        [KCSKeyChain removeStringForKey: @"username"];
        [KCSKeyChain removeStringForKey: @"password"];
    }
    
    __block KCSUser *createdUser = [[KCSUser alloc] init];
    
    createdUser.username = [KCSKeyChain getStringForKey:@"username"];
    
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
            [userJSONPaylod setObject:[NSArray arrayWithObject:sp.deviceToken] forKey:@"_deviceTokens"];
        }
        
        NSDictionary *userData = [NSDictionary dictionaryWithDictionary:userJSONPaylod];
        
        KCSRESTRequest *userRequest = [KCSRESTRequest requestForResource:[[KCSClient sharedClient] userBaseURL] usingMethod:kPostRESTMethod];
        
        
        [userRequest setContentType:KCS_JSON_TYPE];
        KCS_SBJsonWriter *writer = [[KCS_SBJsonWriter alloc] init];
        [userRequest addBody:[writer dataWithObject:userData]];
        [writer release];
        
        // Set up our callbacks
        KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
            KCS_SBJsonParser *parser = [[KCS_SBJsonParser alloc] init];

            // Don't need to retain, as we're not releasing until this block
            // [createdUser retain];
            
            // Ok, we're probably authenticated
            if (response.responseCode != KCS_HTTP_STATUS_CREATED){
                // Crap, authentication failed, not really sure how to proceed here!!!
                // I really don't know what to do here, we can't continue... Something died...
                KCSLogError(@"Received Response code %d, but expected %d with response: %@", response.responseCode, KCS_HTTP_STATUS_CREATED, [[parser objectWithData:response.responseData] JSONRepresentation]);
                
                client.userIsAuthenticated = NO;
                client.userAuthenticationInProgress = NO;
                
                // Execution is expected to terminate, but if it does not, make sure that parser is freed
                NSDictionary *errorDict = [NSDictionary dictionaryWithObject:[[parser objectWithData:response.responseData] JSONRepresentation] forKey:@"error"];
                [parser release];
                
                NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Unable to create user."
                                                                                   withFailureReason:[errorDict description]
                                                                              withRecoverySuggestion:@"Contact support."
                                                                                 withRecoveryOptions:nil];
                
                // No user, it's during creation
                [delegate user:nil actionDidFailWithError:[NSError errorWithDomain:KCSUserErrorDomain
                                                                              code:KCSUnexpectedError
                                                                          userInfo:userInfo]];
                // This must be released in all paths
                [createdUser release];
                return;
            }
            
            // Ok, we're really authd
            NSDictionary *dictionary = [parser objectWithData:response.responseData];
            createdUser.username = [dictionary objectForKey:@"username"];
            createdUser.password = [dictionary objectForKey:@"password"];
            createdUser.userId   = [dictionary objectForKey:@"_id"];
            createdUser.deviceTokens = [dictionary objectForKey:@"_deviceTokens"];
            
            assert(createdUser.username != nil && createdUser.password != nil && createdUser.userId != nil);
            
            [KCSKeyChain setString:createdUser.username forKey:@"username"];
            [KCSKeyChain setString:createdUser.password forKey:@"password"];
            [KCSKeyChain setString:createdUser.userId forKey:@"userId"];
            
            [[KCSClient sharedClient] setAuthCredentials:[NSURLCredential credentialWithUser:createdUser.username password:createdUser.password persistence:NSURLCredentialPersistenceNone]];
            [[KCSClient sharedClient] setCurrentUser:createdUser];
            
            // Indicate that threads are free to proceed
            client.userIsAuthenticated = YES;
            client.userAuthenticationInProgress = NO;
            
            // NB: The delegate MUST retain created user!
            [delegate user:createdUser actionDidCompleteWithResult:KCSUserCreated];

            // This must be released in all paths
            [createdUser release];

            [parser release];
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
            [delegate user:nil actionDidFailWithError:[NSError errorWithDomain:KCSUserErrorDomain
                                                                          code:KCSUnexpectedError
                                                                      userInfo:userInfo]];

            // This must be released in all paths
            [createdUser release];
            return;
        };
        
        KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *conn){};
        
        [userRequest withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock];
        [userRequest start];
        
        
    } else {
        createdUser.password = [KCSKeyChain getStringForKey:@"password"];
        [[KCSClient sharedClient] setAuthCredentials:[NSURLCredential credentialWithUser:createdUser.username password:createdUser.password persistence:NSURLCredentialPersistenceNone]];
        client.userIsAuthenticated = YES;
        client.userAuthenticationInProgress = NO;
        [[KCSClient sharedClient] setCurrentUser:createdUser];
        
        // Delegate must retain createdUser
        [delegate user:createdUser actionDidCompleteWithResult:KCSUserFound];

        // This must be released in all paths
        [createdUser release];

    }

    // NB: We don't release here since the blocks won't have a chance to retain this value until WAAAAAAY later
    // NB: I expect this is a good use for an autorelease pool.
    // [createdUser release];
    
    
    
}

// These routines all do similar work, but the first two are for legacy support
- (void)initializeCurrentUserWithRequest: (KCSRESTRequest *)request
{
    [KCSUser registerUserWithUsername:nil withPassword:nil withDelegate:nil forceNew:NO];
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
    [KCSUser registerUserWithUsername:nil withPassword:nil withDelegate:nil forceNew:NO];
}

+ (void)userWithUsername: (NSString *)username
                password: (NSString *)password
            withDelegate: (id<KCSUserActionDelegate>)delegate
{
    // Ensure the old user is gone...
    [KCSUser registerUserWithUsername:username withPassword:password withDelegate:delegate forceNew:YES];
}

+ (void)loginWithUsername: (NSString *)username
                 password: (NSString *)password
             withDelegate: (id<KCSUserActionDelegate>)delegate
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
            KCS_SBJsonParser *parser = [[KCS_SBJsonParser alloc] init];
            KCSUser *createdUser = [[KCSUser alloc] init];
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
                [delegate user:createdUser actionDidFailWithError:error];
                [createdUser release];
                [parser release];
                return;
            }
            
            // Ok, we're really authd
            NSDictionary *dictionary = [parser objectWithData:response.responseData];
            createdUser.userId   = [dictionary objectForKey:@"_id"];
            createdUser.deviceTokens = [dictionary objectForKey:@"_deviceTokens"];
            
            // We need to ignore the known properties, some are not stored with the user (UUID/UDID)
            // Somer are stored elsewhere, the rest get set as attributes.
            for (NSString *property in dictionary) {
                if ([property isEqualToString:@"_id"]      ||
                    [property isEqualToString:@"username"] ||
                    [property isEqualToString:@"password"] ||
                    [property isEqualToString:@"UUID"]     ||
                    [property isEqualToString:@"UDID"]     ||
                    [property isEqualToString:@"_deviceTokens"])
                {
                    // This is an "internal" property
                    continue;
                } else {
                    [createdUser setValue:[dictionary objectForKey:property] forAttribute:property];
                }
            }
            
            assert(createdUser.username != nil && createdUser.password != nil && createdUser.userId != nil);
            
            [KCSKeyChain setString:createdUser.username forKey:@"username"];
            [KCSKeyChain setString:createdUser.password forKey:@"password"];
            [KCSKeyChain setString:createdUser.userId forKey:@"userId"];
            
            [[KCSClient sharedClient] setAuthCredentials:[NSURLCredential credentialWithUser:createdUser.username password:createdUser.password persistence:NSURLCredentialPersistenceNone]];
            [[KCSClient sharedClient] setCurrentUser:createdUser];
            
            // Indicate that threads are free to proceed
            client.userIsAuthenticated = YES;
            client.userAuthenticationInProgress = NO;
            
            // Delegate must retain createdUser
            [delegate user:createdUser actionDidCompleteWithResult:KCSUserFound];
            
            // Clean up
            [createdUser release];
            [parser release];
        };
        
        KCSConnectionFailureBlock fBlock = ^(NSError *error){
            // I really don't know what to do here, we can't continue... Something died...
            KCSLogError(@"Internal Error: %@", error);
            
            client.userIsAuthenticated = NO;
            client.userAuthenticationInProgress = NO;
            client.currentUser = nil;
            
            [delegate user:nil actionDidFailWithError:error];
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
        
        [delegate user:nil actionDidFailWithError:error];
    }

}


- (void)logout
{
    
    if (![self isEqual:[[KCSClient sharedClient] currentUser]]){
        KCSLogError(@"Attempted to log out a user who is not the KCS Current User!");
    } else {
        
        self.username = nil;
        self.password = nil;
        self.userId = nil;
        
        [KCSKeyChain removeStringForKey:@"username"];
        [KCSKeyChain removeStringForKey:@"password"];
        [KCSKeyChain removeStringForKey:@"_id"];
        
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
        [self deleteFromCollection:[self userCollection] withDelegate:delegate];
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
        [self loadObjectWithID:self.userId fromCollection:[self userCollection] withDelegate:delegate];
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
            [tmpSet addObject:[[KCSPush sharedPush] deviceToken]];
            self.deviceTokens = [tmpSet allObjects];
        }
        [self saveToCollection:[self userCollection] withDelegate:delegate];
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
    KCSCollection *userColl =  [KCSCollection collectionFromString:@"" ofClass:[KCSUser class]];
    
    // Make sure requests go to the correct URL
    [userColl setBaseURL:[[KCSClient sharedClient] userBaseURL]];
    
    return userColl;
}


+ (NSDictionary *)kinveyObjectBuilderOptions
{
    static NSDictionary *options = nil;
    
    if (options == nil){
        options = [[NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithBool:YES], KCS_USE_DICTIONARY_KEY,
                    @"userAttributes", KCS_DICTIONARY_NAME_KEY, nil] retain];
    }
    
    return options;
}

- (NSDictionary *)hostToKinveyPropertyMapping
{
    static NSDictionary *mappedDict = nil;
    
    if (mappedDict == nil){
        mappedDict = [[NSDictionary dictionaryWithObjectsAndKeys:
                      @"_id", @"userId",
                      @"_deviceTokens", @"deviceTokens",
                      @"username", @"username",
                      @"password", @"password", nil] retain];
    }
    
    return mappedDict;
}
@end
