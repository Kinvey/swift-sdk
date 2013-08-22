//
//  KCSClientConfiguration.m
//  KinveyKit
//
//  Created by Michael Katz on 8/16/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
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


#import "KCSClientConfiguration.h"

#import "KCSClient.h"
#import "KCSLogManager.h"

#define KCS_HOST_PORT @"KCS_HOST_PORT"
#define KCS_HOST_PROTOCOL @"KCS_HOST_PROTOCOL"
#define KCS_HOST_DOMAIN @"KCS_HOST_DOMAIN"

#define KCS_DEFAULT_HOSTNAME @"baas"
#define KCS_DEFAULT_HOST_PORT @""
#define KCS_DEFAULT_HOST_PROTOCOL @"https"
#define KCS_DEFAULT_HOST_DOMAIN @"kinvey.com"
#define KCS_DEFAULT_CONNETION_TIMEOUT @10.0 // Default timeout to 10 seconds
#define KCS_DEFAULT_URL_CACHE_POLICY NSURLRequestReloadIgnoringLocalAndRemoteCacheData
#define KCS_DEFAULT_DATE_FORMAT @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"

@interface KCSClientConfiguration ()
@end

@implementation KCSClientConfiguration

- (instancetype) init
{
    self = [super init];
    if (self) {
        _appKey = nil;
        _appSecret = nil;
        _options = @{KCS_CONNECTION_TIMEOUT : KCS_DEFAULT_CONNETION_TIMEOUT,
                     KCS_URL_CACHE_POLICY   : @(KCS_DEFAULT_URL_CACHE_POLICY),
                     KCS_HOST_PORT          : KCS_DEFAULT_HOST_PORT,
                     KCS_HOST_PROTOCOL      : KCS_DEFAULT_HOST_PROTOCOL,
                     KCS_HOST_DOMAIN        : KCS_DEFAULT_HOST_DOMAIN,
                     KCS_DATE_FORMAT        : KCS_DEFAULT_DATE_FORMAT
                     };
        _serviceHostname = KCS_DEFAULT_HOSTNAME;
    }
    return self;
}

+ (instancetype)configurationWithAppKey:(NSString *)appKey secret:(NSString *)appSecret
{
    return [self configurationWithAppKey:appKey secret:appSecret options:@{}];
}

+ (instancetype)configurationWithAppKey:(NSString *)appKey secret:(NSString *)appSecret options:(NSDictionary *)optionsDictionary
{
    KCSClientConfiguration* config = nil;
    
    if ([appKey hasPrefix:@"<"] || [appSecret hasPrefix:@"<"]) {
        config = [KCSClientConfiguration configurationFromEnvironment];
    }

    if (!config) {
        config = [[KCSClientConfiguration alloc] init];
        config.appKey = appKey;
        config.appSecret = appSecret;
    }
    
    NSMutableDictionary* newOptions = [config.options mutableCopy];
    [newOptions addEntriesFromDictionary:optionsDictionary];
    config.options = newOptions;
    
    return config;
}

+ (instancetype)configurationFromPlist:(NSString*)plist
{
    NSString *path = [[NSBundle mainBundle] pathForResource:plist ofType:@"plist"];
#if BUILD_FOR_UNIT_TEST
    path = [[[NSBundle bundleForClass:[self class]] URLForResource:plist withExtension:@"plist"] path];
#endif
    NSDictionary *opt = [NSDictionary dictionaryWithContentsOfFile:path];
    
    if (plist == nil){
        opt = [[NSBundle mainBundle] infoDictionary];
    }
    
    if (opt == nil) {
        [[NSException exceptionWithName:@"KinveyInitializationError" reason:[NSString stringWithFormat:@"Unable to read configuration plist: '%@'.", plist] userInfo:nil] raise];
    }
    
    NSString* appKey = [opt valueForKey:KCS_APP_KEY];
    NSString* appSecret = [opt valueForKey:KCS_APP_SECRET];
    
    return [self configurationWithAppKey:appKey
                                  secret:appSecret
                                 options:opt];
}


+ (instancetype) configurationFromEnvironment
{
    KCSClientConfiguration* configuration = nil;
    NSString* appKey = [[[NSProcessInfo processInfo] environment] objectForKey:KCS_APP_KEY];
    if (appKey) {
        NSString* appSecret = [[[NSProcessInfo processInfo] environment] objectForKey:KCS_APP_SECRET];
        if (appSecret) {
            configuration = [[KCSClientConfiguration alloc] init];
            configuration.appKey = appKey;
            configuration.appSecret = appSecret;
            
            NSString* serviceHostname = [[[NSProcessInfo processInfo] environment] objectForKey:KCS_SERVICE_HOST];
            configuration.serviceHostname = serviceHostname;
            return configuration;
        }
    }
    
    return configuration;
}

- (void) setAppKey:(NSString *)appKey
{
    if (appKey == nil || [appKey hasPrefix:@"<"]) {
        [[NSException exceptionWithName:@"KinveyInitializationError" reason:@"Nil or invalid appKey, cannot use Kinvey Service, no recovery available" userInfo:nil] raise];
    }
    _appKey = [appKey copy];
}

- (void) setAppSecret:(NSString *)appSecret
{
    if (appSecret == nil || [appSecret hasPrefix:@"<"]) {
        [[NSException exceptionWithName:@"KinveyInitializationError" reason:@"Nil or invalid appSecret, cannot use Kinvey Service, no recovery available" userInfo:nil] raise];
    }
    _appSecret = [appSecret copy];
}

- (void)setServiceHostname:(NSString *)serviceHostname
{
    // Note that we need to update the Kinvey Reachability host here...
    if (serviceHostname == nil) {
        serviceHostname = KCS_DEFAULT_HOSTNAME;
    }
    _serviceHostname = [serviceHostname copy]; // Implicit retain here
    if ([KCSClient sharedClient].configuration == self) {
        [[KCSClient sharedClient] setConfiguration:self];
    }
}

- (BOOL) valid
{
    return _appKey != nil && _appSecret != nil;
}

@end
