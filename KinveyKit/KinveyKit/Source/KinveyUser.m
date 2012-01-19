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
#import "JSONKit.h"
#import "KinveyBlocks.h"
#import "KCSConnectionResponse.h"
#import "KinveyHTTPStatusCodes.h"
#import "KinveyErrorCodes.h"
#import "KCSErrorUtilities.h"
#import "KCSLogManager.h"
#import "KinveyCollection.h"
#import "KCSReachability.h"


@interface KCSUser()
@property (nonatomic, retain) NSString *userId;
@property (nonatomic, retain) NSMutableDictionary *userAttributes;

+ (void)registerUserWithUsername: (NSString *)uname withPassword: (NSString *)password withDelegate: (id<KCSUserActionDelegate>)delegate;
@end

@implementation KCSUser

@synthesize username=_username;
@synthesize password=_password;
@synthesize userId=_userId;
@synthesize userAttributes = _userAttributes;

- (id)init
{
    self = [super init];
    if (self){
        _username = [[NSString string] retain];
        _password = [[NSString string] retain];
        _userId = [[NSString string] retain];
        _userAttributes = [[NSMutableDictionary dictionary] retain];
    }
    return self;
}

- (void)dealloc
{
    [_username release];
    [_password release];
    [_userId release];
    [super dealloc];
}

+ (void)registerUserWithUsername:(NSString *)uname withPassword:(NSString *)password withDelegate:(id<KCSUserActionDelegate>)delegate
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
    
    __block KCSUser *createdUser = [[[KCSUser alloc] init] autorelease];
    createdUser.username = [KCSKeyChain getStringForKey:@"username"];
    
    if (createdUser.username == nil){
        // No user, generate it, note, use the APP KEY/APP SECRET!
        KCSAnalytics *analytics = [client analytics];
          
        // Make sure to leave username empty
        NSDictionary *userData = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [analytics UDID], @"UDID",
                                  [analytics UUID], @"UUID", nil];

        
        KCSRESTRequest *userRequest = [KCSRESTRequest requestForResource:[[KCSClient sharedClient] userBaseURL] usingMethod:kPostRESTMethod];
        
        
        [userRequest setContentType:KCS_JSON_TYPE];
        [userRequest addBody:[userData JSONData]];
        
        // Set up our callbacks
        KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
            [createdUser retain];
            // Ok, we're probably authenticated
            if (response.responseCode != KCS_HTTP_STATUS_CREATED){
                // Crap, authentication failed, not really sure how to proceed here!!!
                // I really don't know what to do here, we can't continue... Something died...
                KCSLogError(@"Received Response code %d, but expected %d with response: %@", response.responseCode, KCS_HTTP_STATUS_CREATED, [[response.responseData objectFromJSONData] JSONString]);
                CFShow(response);
                
                client.userIsAuthenticated = NO;
                client.userAuthenticationInProgress = NO;
                
                NSException* myException = [NSException
                                            exceptionWithName:@"KinveyInternalError"
                                            reason:@"The Kinvey Service has experienced an internal error and is unable to continue.  Please contact support with the supplied userInfo"
                                            userInfo:[NSDictionary dictionaryWithObject:[[response.responseData objectFromJSONData] JSONString] forKey:@"error"]];
                
                @throw myException;                
            }
            
            // Ok, we're really authd
            NSDictionary *dictionary = [response.responseData objectFromJSONData];
            createdUser.username = [dictionary objectForKey:@"username"];
            createdUser.password = [dictionary objectForKey:@"password"];
            createdUser.userId   = [dictionary objectForKey:@"_id"];
            
            assert(createdUser.username != nil && createdUser.password != nil && createdUser.userId != nil);
            
            [KCSKeyChain setString:createdUser.username forKey:@"username"];
            [KCSKeyChain setString:createdUser.password forKey:@"password"];
            [KCSKeyChain setString:createdUser.userId forKey:@"userId"];
            
            [[KCSClient sharedClient] setAuthCredentials:[NSURLCredential credentialWithUser:createdUser.username password:createdUser.password persistence:NSURLCredentialPersistenceNone]];
            [[KCSClient sharedClient] setCurrentUser:createdUser];
            
            // Indicate that threads are free to proceed
            client.userIsAuthenticated = YES;
            client.userAuthenticationInProgress = NO;
            
            [delegate user:createdUser actionDidCompleteWithResult:KCSUserCreated];
            [createdUser release];
        };
        
        KCSConnectionFailureBlock fBlock = ^(NSError *error){
            // I really don't know what to do here, we can't continue... Something died...
            KCSLogError(@"Internal Error: %@", error);

            client.userIsAuthenticated = NO;
            client.userAuthenticationInProgress = NO;

            NSException* myException = [NSException
                                        exceptionWithName:@"KinveyInternalError"
                                        reason:@"The Kinvey Service has experienced an internal error and is unable to continue.  Please contact support with the supplied userInfo"
                                        userInfo:[NSDictionary dictionaryWithObject:error forKey:@"error"]];
            
            @throw myException;
        };
        
        KCSConnectionProgressBlock pBlock = ^(KCSConnectionProgress *conn){};
        
        [[userRequest withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];
        
        
    } else {
        createdUser.password = [KCSKeyChain getStringForKey:@"password"];
        [[KCSClient sharedClient] setAuthCredentials:[NSURLCredential credentialWithUser:createdUser.username password:createdUser.password persistence:NSURLCredentialPersistenceNone]];
        client.userIsAuthenticated = YES;
        client.userAuthenticationInProgress = NO;
        [[KCSClient sharedClient] setCurrentUser:createdUser];
        [delegate user:createdUser actionDidCompleteWithResult:KCSUserFound];
    }
    
    
    
}

// These routines all do similar work, but the first two are for legacy support
- (void)initializeCurrentUserWithRequest: (KCSRESTRequest *)request
{
    [KCSUser registerUserWithUsername:nil withPassword:nil withDelegate:nil];
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
    [KCSUser registerUserWithUsername:nil withPassword:nil withDelegate:nil];
}

+ (void)userWithUsername: (NSString *)username
                password: (NSString *)password
            withDelegate: (id<KCSUserActionDelegate>)delegate
{
    [KCSUser registerUserWithUsername:username withPassword:password withDelegate:delegate];
}

+ (void)loginWithUserName: (NSString *)username
                 password: (NSString *)password
             withDelegate: (id<KCSUserActionDelegate>)delegate
{
    
    KCSClient *client = [KCSClient sharedClient];
    // Just log-in and set currentUser
    if ([client.kinveyReachability isReachable]){
        // Set up our callbacks
        KCSConnectionCompletionBlock cBlock = ^(KCSConnectionResponse *response){
            // Ok, we're probably authenticated
            KCSUser *createdUser = [[[KCSUser alloc] init] autorelease];
            createdUser.username = username;
            createdUser.password = password;
            if (response.responseCode != KCS_HTTP_STATUS_OK){
                // Crap, authentication failed, not really sure how to proceed here!!!
                client.userIsAuthenticated = NO;
                client.userAuthenticationInProgress = NO;
                client.currentUser = nil;
                // This is expected here, user auth failed, do the right thing
                NSDictionary *userInfo = [KCSErrorUtilities createErrorUserDictionaryWithDescription:@"Login Failed"
                                                                                   withFailureReason:@"Invalid Username or Password"
                                                                              withRecoverySuggestion:@"Try again with different username/password"
                                                                                 withRecoveryOptions:nil];
                NSError *error = [NSError errorWithDomain:KCSUserErrorDomain code:KCSLoginFailureError userInfo:userInfo];
                [delegate user:createdUser actionDidFailWithError:error];
            }
            
            // Ok, we're really authd
            NSDictionary *dictionary = [response.responseData objectFromJSONData];
            createdUser.userId   = [dictionary objectForKey:@"_id"];
            for (NSString *property in dictionary) {
                if ([property isEqualToString:@"_id"] ||
                    [property isEqualToString:@"username"] ||
                    [property isEqualToString:@"password"] ||
                    [property isEqualToString:@"UUID"] ||
                    [property isEqualToString:@"UDID"])
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
            
            [delegate user:createdUser actionDidCompleteWithResult:KCSUserFound];
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
        client.currentUser = [[[KCSUser alloc] init] autorelease];
        client.currentUser.username = username;
        client.currentUser.password = password;
        [[request withCompletionAction:cBlock failureAction:fBlock progressAction:pBlock] start];

    
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


///////////
// This is the implementation for the basic users services
///////////
+ (void)checkForExistingUsernameWithBlock: (KCSUsernameCheckBlock)checkBlock
{
    // TBD
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
        [self saveToCollection:[self userCollection] withDelegate:delegate];
    }
}

- (NSArray *)attributes
{
    return [self.userAttributes allKeys];
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
                      @"username", @"username",
                      @"password", @"password", nil] retain];
    }
    
    return mappedDict;
}
@end
