//
//  KinveyClient.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
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
#import "KCSClientConfiguration.h"
#import "KCSHiddenMethods.h"

#pragma mark - Constants

NSString* const KCS_APP_KEY = @"KCS_APP_KEY";
NSString* const KCS_APP_SECRET = @"KCS_APP_SECRET";
NSString* const KCS_CONNETION_TIMEOUT = @"KCS_CONNECTION_TIMEOUT";


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


#if TARGET_OS_IPHONE
@property (nonatomic, strong, readwrite) KCSReachability *networkReachability;
@property (nonatomic, strong, readwrite) KCSReachability *kinveyReachability;

#endif

@property (strong, nonatomic) NSString *kinveyDomain;

///---------------------------------------------------------------------------------------
/// @name Connection Properties
///---------------------------------------------------------------------------------------

/*! Protocol used to connection to Kinvey Service (nominally HTTPS)*/
@property (nonatomic, strong) NSString *protocol;
@property (nonatomic, strong) NSString* port;

- (void)updateURLs;

@end

@implementation KCSClient


#if TARGET_OS_IPHONE
@synthesize networkReachability = _networkReachability;
@synthesize kinveyReachability = _kinveyReachability;
#endif

@synthesize kinveyDomain = _kinveyDomain;


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

- (instancetype)init
{
    self = [super init];
    
    if (self){
        _kinveyDomain = @"kinvey.com";
        _libraryVersion = __KINVEYKIT_VERSION__;
        _userAgent = [[NSString alloc] initWithFormat:@"ios-kinvey-http/%@ kcs/%@", self.libraryVersion, MINIMUM_KCS_VERSION_SUPPORTED];
        _analytics = [[KCSAnalytics alloc] init];
        _cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;  // Inhibit caching for now
        _protocol = @"https";
        _port = @"";
        _dateStorageFormatString = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'";
        
        if (![self respondsToSelector:@selector(testCanUseCategories)]) {
            NSException* myException = [NSException exceptionWithName:@"CategoriesNotLoaded" reason:@"KinveyKit setup: Categories could not be loaded. Be sure to set '-ObjC' in the 'Other Linker Flags'." userInfo:nil];
            @throw myException;
        }
    }
    
    return self;
}

- (void) setConfiguration:(KCSClientConfiguration*)configuration
{
    _configuration = configuration;

    NSString* oldAppKey = [KCSKeyChain getStringForKey:@"kinveykit.appkey"];
    if (oldAppKey != nil && [configuration.appKey isEqualToString:oldAppKey] == NO) {
        //clear the saved user if the kid changes
        [KCSUser clearSavedCredentials];
    }
    //TODO: use defaults
    [KCSKeyChain setString:configuration.appKey forKey:@"kinveykit.appkey"];

#if TARGET_OS_IPHONE
    _networkReachability = [KCSReachability reachabilityForInternetConnection];
    // This next initializer is Async.  It needs to DNS lookup the hostname (in this case the hard coded _serviceHostname)
    // We start this in init in the hopes that it will be (mostly) complete by the time we need to use it.
    // TODO: Investigate being notified of changes in KCS Client

    // We do this here because there is latency on DNS resolution of the hostname.  We need to do this ASAP when the hostname changes
    self.kinveyReachability = [KCSReachability reachabilityWithHostName:[NSString stringWithFormat:@"%@.%@", self.configuration.serviceHostname, self.kinveyDomain]];
#endif

    [self updateURLs];
    // Check to make sure appdata URL is good
    NSURL *tmpURL = [NSURL URLWithString:self.appdataBaseURL]; // Will get autoreleased during next drain
    if (!tmpURL){
        [[NSException exceptionWithName:@"KinveyInitializationError" reason:@"App Key contains invalid characters, check to make sure App Key is correct!" userInfo:nil] raise];
    }
    
    if (self.options[KCS_CONNETION_TIMEOUT]) {
        _connectionTimeout = [self.options[KCS_CONNETION_TIMEOUT] doubleValue];
    }

    
    if ([self.options objectForKey:KCS_LOG_SINK] != nil) {
        [KCSLogManager setLogSink:[self.options objectForKey:KCS_LOG_SINK]];
    }
}

- (NSString *)serviceHostname
{
    return self.configuration.serviceHostname;
}

- (NSDictionary *)options
{
    return self.configuration.options;
}



- (KCSClient *)initializeKinveyServiceForAppKey:(NSString *)appKey withAppSecret:(NSString *)appSecret usingOptions:(NSDictionary *)options
{
    self.configuration = [KCSClientConfiguration configurationWithAppKey:appKey secret:appSecret options:options];
    return self;
}

- (KCSClient *)initializeKinveyServiceWithPropertyList
{
    self.configuration = [KCSClientConfiguration configurationFromPlist];
    return self;
}

- (void)updateURLs
{
    self.appdataBaseURL  = [NSString stringWithFormat:@"%@://%@.%@%@/appdata/%@/", self.protocol, self.configuration.serviceHostname, self.kinveyDomain, self.port, self.appKey];
    self.resourceBaseURL = [NSString stringWithFormat:@"%@://%@.%@%@/blob/%@/", self.protocol, self.configuration.serviceHostname, self.kinveyDomain, self.port, self.appKey];
    self.userBaseURL     = [NSString stringWithFormat:@"%@://%@.%@%@/user/%@/", self.protocol, self.configuration.serviceHostname, self.kinveyDomain, self.port, self.appKey];
    //rpc/:kid/:username/user-password-reset-initiate
    self.rpcBaseURL      = [NSString stringWithFormat:@"%@://%@.%@%@/rpc/%@/", self.protocol, self.configuration.serviceHostname,self.kinveyDomain, self.port, self.appKey];

}

#pragma mark - User

- (void) setCurrentUser:(KCSUser *)currentUser
{
    if (currentUser != _currentUser) {
        [[NSNotificationCenter defaultCenter] postNotificationName:KCSActiveUserChangedNotification object:nil];
    }
    _currentUser = currentUser;
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

#pragma mark - Logging


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
    return [NSString stringWithFormat:@"%@://%@.%@%@/", self.protocol, self.configuration.serviceHostname, self.kinveyDomain, self.port];
}
@end
