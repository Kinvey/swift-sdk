//
//  KCSClientConfiguration.m
//  KinveyKit
//
//  Created by Michael Katz on 8/16/13.
//  Copyright (c) 2013-2014 Kinvey. All rights reserved.
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

KK2(remove import)
#import "KCSClient.h"
#import "KinveyUser.h"

#import "KinveyCoreInternal.h"

#pragma mark - Constants

KCS_CONST_IMPL KCS_APP_KEY                = @"KCS_APP_KEY";
KCS_CONST_IMPL KCS_APP_SECRET             = @"KCS_APP_SECRET";
KCS_CONST_IMPL KCS_CONNECTION_TIMEOUT     = @"KCS_CONNECTION_TIMEOUT";
KCS_CONST_IMPL KCS_SERVICE_HOST           = @"KCS_SERVICE_HOST";
KCS_CONST_IMPL KCS_URL_CACHE_POLICY       = @"KCS_URL_CACHE_POLICY";
KCS_CONST_IMPL KCS_DATE_FORMAT            = @"KCS_DATE_FORMAT";
KCS_CONST_IMPL KCS_LOG_SINK               = @"KCS_LOG_SINK";
KCS_CONST_IMPL KCS_LOG_LEVEL              = @"KCS_LOG_LEVEL";
KCS_CONST_IMPL KCS_LOG_ADDITIONAL_LOGGERS = @"KCS_LOG_ADDITIONAL_LOGGERS";
KCS_CONST_IMPL KCS_CONFIG_RETRY_DISABLED  = @"KCS_CONFIG_RETRY_DISABLED";
KCS_CONST_IMPL KCS_DATA_PROTECTION_LEVEL  = @"KCS_DATA_PROTECTION_LEVEL";
KCS_CONST_IMPL KCS_USER_CLASS             = @"KCS_USER_CLASS";
KCS_CONST_IMPL KCS_KEEP_USER_LOGGED_IN_ON_BAD_CREDENTIALS = @"KCS_KEEP_USER_LOGGED_IN_ON_BAD_CREDENTIALS";
KCS_CONST_IMPL KCS_ALWAYS_USE_NSURLREQUEST = @"KCS_ALWAYS_USE_NSURLREQUEST";

#define KCS_HOST_PORT     @"KCS_HOST_PORT"
#define KCS_HOST_PROTOCOL @"KCS_HOST_PROTOCOL"
#define KCS_HOST_DOMAIN   @"KCS_HOST_DOMAIN"

#define KCS_DEFAULT_AUTH_HOSTNAME     @"auth"
#define KCS_DEFAULT_HOSTNAME          @"baas"
#define KCS_DEFAULT_HOST_PORT         @""
#define KCS_DEFAULT_HOST_PROTOCOL     @"https"
#define KCS_DEFAULT_HOST_DOMAIN       @"kinvey.com"
#define KCS_DEFAULT_CONNETION_TIMEOUT @10.0 // Default timeout to 10 seconds
#define KCS_DEFAULT_URL_CACHE_POLICY  @(NSURLRequestReloadIgnoringLocalAndRemoteCacheData)
#define KCS_DEFAULT_DATE_FORMAT       @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSS'Z'"

@interface KCSClientConfiguration ()
@end

@implementation KCSClientConfiguration

- (instancetype) init
{
    self = [super init];
    if (self) {
        _appKey = nil;
        _appSecret = nil;
        _options = @{KCS_CONNECTION_TIMEOUT    : KCS_DEFAULT_CONNETION_TIMEOUT,
                     KCS_URL_CACHE_POLICY      : KCS_DEFAULT_URL_CACHE_POLICY,
                     KCS_HOST_PORT             : KCS_DEFAULT_HOST_PORT,
                     KCS_HOST_PROTOCOL         : KCS_DEFAULT_HOST_PROTOCOL,
                     KCS_HOST_DOMAIN           : KCS_DEFAULT_HOST_DOMAIN,
                     KCS_DATE_FORMAT           : KCS_DEFAULT_DATE_FORMAT,
                     KCS_LOG_LEVEL             : @(0),
                     KCS_DATA_PROTECTION_LEVEL : @(KCSDataCompleteUntilFirstLogin),
                     KCS_USER_CLASS            : [KCSUser class]
                     };
        _serviceHostname = KCS_DEFAULT_HOSTNAME;
        _authHostname = KCS_DEFAULT_AUTH_HOSTNAME;
        
        
        KCSLogFormatter* formatter = [[KCSLogFormatter alloc] init];
        
        id<KCS_DDLogger> logger = [KCS_DDASLLogger sharedInstance];
        [logger setLogFormatter:formatter];
        [KCS_DDLog addLogger:logger];
        
        logger = [KCS_DDTTYLogger sharedInstance];
        [logger setLogFormatter:formatter];
        [KCS_DDLog addLogger:logger];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    KCSClientConfiguration* c = [[KCSClientConfiguration allocWithZone:zone] init];
    c.appKey = self.appKey;
    c.appSecret = self.appSecret;
    c.options = self.options;
    c.serviceHostname = self.serviceHostname;
    c.authHostname = self.authHostname;
    c.requestConfiguration = self.requestConfiguration.copy;
    
    return c;
}

+ (instancetype)configurationWithAppKey:(NSString *)appKey secret:(NSString *)appSecret
{
    return [self configurationWithAppKey:appKey
                                  secret:appSecret
                                 options:@{}];
}

+ (instancetype)configurationWithAppKey:(NSString *)appKey
                                 secret:(NSString *)appSecret
                                options:(NSDictionary *)optionsDictionary
{
    return [self configurationWithAppKey:appKey
                                  secret:appSecret
                                 options:optionsDictionary
                    requestConfiguration:nil];
}

+ (instancetype)configurationWithAppKey:(NSString *)appKey
                                 secret:(NSString *)appSecret
                                options:(NSDictionary *)optionsDictionary
                   requestConfiguration:(KCSRequestConfiguration *)requestConfiguration
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
    
    config.requestConfiguration = requestConfiguration;
    
    NSArray* loggers = config.options[KCS_LOG_ADDITIONAL_LOGGERS];
    for (id logger in loggers) {
        [KCS_DDLog addLogger:logger];
    }
    
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

- (void)setServiceHostname:(NSString *)serviceHostname
{
    if (serviceHostname == nil) {
        serviceHostname = KCS_DEFAULT_HOSTNAME;
    }
    _serviceHostname = [serviceHostname copy];
    if ([KCSClient sharedClient].configuration == self) {
        [[KCSClient sharedClient] setConfiguration:self];
    }
}

- (BOOL) valid
{
    return _appKey != nil && _appSecret != nil;
}

@end
