//
//  KinveyClient.m
//  KinveyKit
//
//  Created by Brian Wilson on 10/13/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//


#import "KCSClient.h"
#import "JSONKit.h"


#import "KinveyCollection.h"
#import "KinveyAnalytics.h"
#import "NSURL+KinveyAdditions.h"
#import "NSString+KinveyAdditions.h"


// Anonymous category on KCSClient, used to allow us to redeclare readonly properties
// readwrite.  This keeps KVO notation, while allowing private mutability.
@interface KCSClient ()
// Redeclare private iVars
@property (nonatomic, copy, readwrite) NSString *userAgent;
@property (nonatomic, copy, readwrite) NSString *libraryVersion;
@property (nonatomic, copy, readwrite) NSString *dataBaseURL;
@property (nonatomic, copy, readwrite) NSString *assetBaseURL;


// Do not expose this to clients yet... soon?
@property (retain) KCSAnalytics *analytics;
@end

@implementation KCSClient

@synthesize appKey=_appKey;
@synthesize appSecret=_appSecret;
@synthesize dataBaseURL=_dataBaseURL;
@synthesize assetBaseURL=_assetBaseURL;
@synthesize connectionTimeout=_connectionTimeout;
@synthesize options=_options;
@synthesize userAgent=_userAgent;
@synthesize libraryVersion=_libraryVersion;
@synthesize authCredentials=_authCredentials;
@synthesize cachePolicy=_cachePolicy;

@synthesize analytics=_analytics;

- (id)init
{
    self = [super init];
    
    if (self){
        self.libraryVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleVersionKey];
        self.userAgent = [[NSString alloc] initWithFormat:@"ios-kinvey-http/%@ kcs/%f", self.libraryVersion, MINIMUM_KCS_VERSION_SUPPORTED];
        self.connectionTimeout = 60.0; // Default timeout to 1 minute...
        _cachePolicy = NSURLCacheStorageNotAllowed; // Inhibit caching for now
    }
    
    return self;
}

+ (KCSClient *)sharedClient
{
    static KCSClient *sKCSClient;
    // This can be called on any thread, so we synchronise.  We only do this in 
    // the sKCSClient case because, once sKCSClient goes non-nil, it can 
    // never go nil again.
    
    if (sKCSClient == nil) {
        @synchronized (self) {
            sKCSClient = [[KCSClient alloc] init];
            assert(sKCSClient != nil);
        }
    }
    
    return sKCSClient;
}

- (KCSClient *)initializeKinveyServiceForAppKey:(NSString *)appKey withAppSecret:(NSString *)appSecret usingOptions:(NSDictionary *)options
{
    self.appKey = appKey;
    self.appSecret = appSecret;

    self.dataBaseURL = [[NSString alloc] initWithFormat:@"https://latestbeta.kinvey.com/appdata/%@/", self.appKey];
    // Until latestbeta is upgraded...
    self.assetBaseURL = [[NSString alloc] initWithFormat:@"https://latestbeta.kinvey.com/appdata/blob/%@/", self.appKey];

    // TODO extract options to something meaningful...
    self.options = options;
    self.authCredentials = [NSURLCredential credentialWithUser:appKey password:appSecret persistence:NSURLCredentialPersistenceNone];
    return self;
}

#pragma mark Collection Interface

// We don't want to own the collection, we just want to create the collection
// for the library client and instatiate ourselves as the KinveyClient to use
// for that collection

// Basically this is just a convienience method which I think may get
// Refactored out yet again
- (KCSCollection *)collectionFromString:(NSString *)collection
{
    return [KCSCollection collectionFromString:collection withKinveyClient:self];
}

// Basically this is just a convienience method which I think may get
// Refactored out yet again
- (KCSCollection *)collectionFromString:(NSString *)collection withClass:(Class)collectionClass
{
    return [KCSCollection collectionFromString:collection ofClass:collectionClass withKinveyClient:self];
}


@end