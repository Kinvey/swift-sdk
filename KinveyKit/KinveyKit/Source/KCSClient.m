//
//  KinveyClient.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
//  Copyright (c) 2011-2013 Kinvey. All rights reserved.
//


#import "KCSClient.h"
#import "KinveyUser.h"


#import "KinveyCollection.h"
#import "KinveyAnalytics.h"
#import "NSURL+KinveyAdditions.h"
#import "NSString+KinveyAdditions.h"
#import "KCSReachability.h"
#import "KCSLogManager.h"

#import "KCSStore.h"
#import "KCSClient+ConfigurationTest.h"
#import "KCSKeyChain.h"

#import "KinveyVersion.h"

#import "KCSEntityCache.h"

// Anonymous category on KCSClient, used to allow us to redeclare readonly properties
// readwrite.  This keeps KVO notation, while allowing private mutability.
@interface KCSClient ()
// Redeclare private iVars
@property (nonatomic, copy, readwrite) NSString *userAgent;
@property (nonatomic, copy, readwrite) NSString *libraryVersion;
@property (nonatomic, copy, readwrite) NSString *appdataBaseURL;
@property (nonatomic, copy, readwrite) NSString *resourceBaseURL;
@property (nonatomic, copy, readwrite) NSString *userBaseURL;
@property (nonatomic, copy, readwrite) NSString *rpcBaseURL;

@property (nonatomic, copy, readwrite) NSString *appKey;
@property (nonatomic, copy, readwrite) NSString *appSecret;


@property (atomic, strong) NSRecursiveLock *authInProgressLock;
@property (atomic, strong) NSRecursiveLock *authCompleteLock;

@property (nonatomic, strong, readwrite) NSDictionary *options;

#if TARGET_OS_IPHONE
@property (nonatomic, strong, readwrite) KCSReachability *networkReachability;
@property (nonatomic, strong, readwrite) KCSReachability *kinveyReachability;

#endif

@property (strong, nonatomic, readonly) NSString *kinveyDomain;

///---------------------------------------------------------------------------------------
/// @name Connection Properties
///---------------------------------------------------------------------------------------
/*! Protocol used to connection to Kinvey Service (nominally HTTPS)*/
@property (nonatomic, copy, readonly) NSString *protocol;

- (void)killAppViaExceptionNamed: (NSString *)class withReason: (NSString *)reason;
- (void)updateURLs;

@end

@implementation KCSClient

@synthesize userIsAuthenticated=_userIsAuthenticated;
@synthesize userAuthenticationInProgress=_userAuthenticationInProgress;

#if TARGET_OS_IPHONE
@synthesize networkReachability = _networkReachability;
@synthesize kinveyReachability = _kinveyReachability;
#endif

@synthesize kinveyDomain = _kinveyDomain;


- (instancetype)init
{
    self = [super init];
    
    if (self){
        _kinveyDomain = @"kinvey.com";
        _libraryVersion = __KINVEYKIT_VERSION__;
        _userAgent = [[NSString alloc] initWithFormat:@"ios-kinvey-http/%@ kcs/%@", self.libraryVersion, MINIMUM_KCS_VERSION_SUPPORTED];
        _connectionTimeout = 10.0; // Default timeout to 10 seconds
        _analytics = [[KCSAnalytics alloc] init];
        _cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;  // Inhibit caching for now
        _protocol = @"https";
        _userIsAuthenticated = NO;
        _userAuthenticationInProgress = NO;
        _authCompleteLock   = [[NSRecursiveLock alloc] init];
        _authInProgressLock = [[NSRecursiveLock alloc] init];
        _serviceHostname = @"baas";
        _dateStorageFormatString = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'";
//        _dateStorageFormatString = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSZ";
        
#if TARGET_OS_IPHONE
        _networkReachability = [KCSReachability reachabilityForInternetConnection];
        // This next initializer is Async.  It needs to DNS lookup the hostname (in this case the hard coded _serviceHostname)
        // We start this in init in the hopes that it will be (mostly) complete by the time we need to use it.
        // TODO: Investigate being notified of changes in KCS Client
        _kinveyReachability = [KCSReachability reachabilityWithHostName:[NSString stringWithFormat:@"%@.%@", _serviceHostname, _kinveyDomain]];
#endif
        
        if (![self respondsToSelector:@selector(testCanUseCategories)]) {
            NSException* myException = [NSException exceptionWithName:@"CategoriesNotLoaded" reason:@"KinveyKit setup: Categories could not be loaded. Be sure to set '-ObjC' in the 'Other Linker Flags'." userInfo:nil];
            @throw myException;
        }
    }
    
    return self;
}


- (BOOL)userIsAuthenticated
{
    BOOL retVal;
    
    [_authCompleteLock lock];
    retVal = _userIsAuthenticated;
    [_authCompleteLock unlock];
    return retVal;
}

- (void)setUserIsAuthenticated:(BOOL)userIsAuthenticated
{
    [_authCompleteLock lock];
    _userIsAuthenticated = userIsAuthenticated;
    [_authCompleteLock unlock];
}

- (BOOL)userAuthenticationInProgress
{
    BOOL retVal;
    [_authInProgressLock lock];
    retVal = _userAuthenticationInProgress;
    [_authInProgressLock unlock];
    return retVal;
}

- (void)setUserAuthenticationInProgress:(BOOL)userAuthenticationInProgress
{
    [_authInProgressLock lock];
    _userAuthenticationInProgress = userAuthenticationInProgress;
    [_authInProgressLock unlock];
}

- (void)setServiceHostname:(NSString *)serviceHostname
{
    // Note that we need to update the Kinvey Reachability host here...
    if (serviceHostname == nil) {
        serviceHostname = @"baas";
    }
    _serviceHostname = [serviceHostname copy]; // Implicit retain here
    [self updateURLs];
    
#if TARGET_OS_IPHONE
    // We do this here because there is latency on DNS resolution of the hostname.  We need to do this ASAP when the hostname changes
    self.kinveyReachability = [KCSReachability reachabilityWithHostName:[NSString stringWithFormat:@"%@.%@", self.serviceHostname, self.kinveyDomain]];
#endif
}

+ (KCSClient *)sharedClient
{
    static KCSClient *sKCSClient;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sKCSClient = [[self alloc] init];
        NSAssert(sKCSClient != nil, @"Unable to instantiate KCSClient");
    });

    return sKCSClient;
}

- (KCSClient *)initializeKinveyServiceForAppKey:(NSString *)appKey withAppSecret:(NSString *)appSecret usingOptions:(NSDictionary *)options
{
    
    if (appKey == nil) {
        [self killAppViaExceptionNamed:@"KinveyInitializationError"
                            withReason:@"Nil value used for appKey, cannot use Kinvey Service, no recovery available"];
    } else if (appSecret == nil) {
        [self killAppViaExceptionNamed:@"KinveyInitializationError"
                            withReason:@"Nil value used for appKey, cannot use KinveyService, no recovery available"];
    }
    
    NSString* oldAppKey = [KCSKeyChain getStringForKey:@"kinveykit.appkey"];
    if (oldAppKey != nil && [appKey isEqualToString:oldAppKey] == NO) {
        //clear the saved user if the kid changes
        [KCSUser clearSavedCredentials];
    }
    [KCSKeyChain setString:appKey forKey:@"kinveykit.appkey"];
    
    self.appKey = appKey;
    self.appSecret = appSecret;
    
    _serviceHostname = @"baas";
    
    [self updateURLs];
    
    // TODO extract options to something meaningful...
    self.options = options;
    self.authCredentials = [NSURLCredential credentialWithUser:appKey password:appSecret persistence:NSURLCredentialPersistenceNone];
    
    // Check to make sure appdata URL is good
    NSURL *tmpURL = [NSURL URLWithString:self.appdataBaseURL]; // Will get autoreleased during next drain
    if (!tmpURL){
        [self killAppViaExceptionNamed:@"KinveyInitializationError"
                            withReason:@"App Key contains invalid characters, check to make sure App Key is correct!"];
    }
    
    if ([self.options objectForKey:KCS_LOG_SINK] != nil) {
        [KCSLogManager setLogSink:[self.options objectForKey:KCS_LOG_SINK]];
    }
    
    return self;
}

- (KCSClient *)initializeKinveyServiceWithPropertyList
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"KinveyOptions" ofType:@"plist"];
    NSDictionary *opt = [NSDictionary dictionaryWithContentsOfFile:path];
    
    if (opt == nil){
        // Something failed, bail
        [self killAppViaExceptionNamed:@"KinveyInitializationError"
                            withReason:@"Failed to open plist, cannot run service, no recovery available."];
    }
    
    return [self initializeKinveyServiceForAppKey:[opt valueForKey:KCS_APP_KEY_KEY] 
                                    withAppSecret:[opt valueForKey:KCS_APP_SECRET_KEY]
                                     usingOptions:opt];
}

- (void)updateURLs
{
    self.appdataBaseURL  = [NSString stringWithFormat:@"%@://%@.%@/appdata/%@/", self.protocol, self.serviceHostname, self.kinveyDomain, self.appKey];
    self.resourceBaseURL = [NSString stringWithFormat:@"%@://%@.%@/blob/%@/", self.protocol, self.serviceHostname, self.kinveyDomain, self.appKey];
    self.userBaseURL     = [NSString stringWithFormat:@"%@://%@.%@/user/%@/", self.protocol, self.serviceHostname, self.kinveyDomain, self.appKey];
    //rpc/:kid/:username/user-password-reset-initiate
    self.rpcBaseURL      = [NSString stringWithFormat:@"%@://%@.%@/rpc/%@/", self.protocol, self.serviceHostname, self.kinveyDomain, self.appKey];

}

#pragma mark - User

- (void) setCurrentUser:(KCSUser *)currentUser
{
    _currentUser = currentUser;
    [[NSNotificationCenter defaultCenter] postNotificationName:KCSActiveUserChangedNotification object:nil];
}

#pragma mark - Store Interface
- (id<KCSStore>)store: (NSString *)storeType forResource: (NSString *)resource
{
    return [self store:storeType forResource:resource withClass:nil withAuthHandler:nil];
}

- (id<KCSStore>)store: (NSString *)storeType forResource: (NSString *)resource withAuthHandler: (KCSAuthHandler *)authHandler
{
    return [self store:storeType forResource:resource withClass:nil withAuthHandler:authHandler];
}

- (id<KCSStore>)store: (NSString *)storeType
        forResource: (NSString *)resource
          withClass: (Class)collectionClass
{
    return [self store:storeType forResource:resource withClass:collectionClass withAuthHandler:nil];
}

- (id<KCSStore>)store: (NSString *)storeType
        forResource: (NSString *)resource
          withClass: (Class)collectionClass
    withAuthHandler: (KCSAuthHandler *)authHandler
{
    Class storeClass = NSClassFromString(storeType);
    
    if (storeClass == nil){
        // Object not found
        KCSLogError(@"Store class %@ not found!", storeType);
        return nil;
    }


    id<KCSStore> store = [[storeClass alloc] init];
    [store setAuthHandler:authHandler];
    
    if (resource && collectionClass){
        KCSCollection *backing = [KCSCollection collectionFromString:resource ofClass:collectionClass];
        NSDictionary *options = [NSDictionary dictionaryWithObject:backing forKey:@"resource"];
        [store configureWithOptions:options];
    }
    
    return store;
}


#pragma mark Collection Interface

// We don't want to own the collection, we just want to create the collection
// for the library client and instatiate ourselves as the KinveyClient to use
// for that collection

// Basically this is just a convienience method which I think may get
- (KCSCollection *)collectionFromString:(NSString *)collection withClass:(Class)collectionClass
{
    return [KCSCollection collectionFromString:collection ofClass:collectionClass];
}

// Notice the name?  Unless the user really tries to stop this, their app will die
// only use this if you think killing the app is a good idea (so it doesn't die later perhaps?)
- (void)killAppViaExceptionNamed: (NSString *)name withReason: (NSString *)reason
{
    KCSLogForced(@"EXCEPTION Encountered: Name => %@, Reason => %@", name, reason);
    NSException* myException = [NSException exceptionWithName:name
                                                       reason:reason
                                                     userInfo:nil];
    
    @throw myException;
    
}


+ (void)configureLoggingWithNetworkEnabled: (BOOL)networkIsEnabled
                              debugEnabled: (BOOL)debugIsEnabled
                              traceEnabled: (BOOL)traceIsEnabled
                            warningEnabled: (BOOL)warningIsEnabled
                              errorEnabled: (BOOL)errorIsEnabled
{
    [[KCSLogManager sharedLogManager] configureLoggingWithNetworkEnabled:networkIsEnabled
                                                            debugEnabled:debugIsEnabled
                                                            traceEnabled:traceIsEnabled
                                                          warningEnabled:warningIsEnabled
                                                            errorEnabled:errorIsEnabled];
}


#pragma mark - Utilites
- (void)clearCache
{
    [KCSEntityCache clearAllCaches];
}

#pragma mark - KinveyKit2
- (NSString*) kid
{
    return _appKey;
}

- (NSString*) baseURL
{
    return [NSString stringWithFormat:@"%@://%@.%@/", self.protocol, self.serviceHostname, self.kinveyDomain];
}
@end
