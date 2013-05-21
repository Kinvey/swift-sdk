//
//  KCSLogManager.h
//  KinveyKit
//
//  Created by Brian Wilson on 1/11/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCSLogSink.h"

// Convenience Macros
#define KCSLog(channel,format,...) \
[[KCSLogManager sharedLogManager] logChannel:(channel) file:__FILE__ lineNumber:__LINE__ \
withFormat:(format),##__VA_ARGS__]

#define KCSLogNetwork(format,...) \
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kNetworkChannel] file:__FILE__ lineNumber:__LINE__ \
withFormat:(format),##__VA_ARGS__]

#define KCSLogDebug(format,...) \
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kDebugChannel] file:__FILE__ lineNumber:__LINE__ \
withFormat:(format),##__VA_ARGS__]

#define KCSLogTrace(format,...) \
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kTraceChannel] file:__FILE__ lineNumber:__LINE__ \
withFormat:(format),##__VA_ARGS__]

#define KCSLogWarning(format,...) \
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kWarningChannel] file:__FILE__ lineNumber:__LINE__ \
withFormat:(format),##__VA_ARGS__]

#define KCSLogError(format,...) \
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kErrorChannel] file:__FILE__ lineNumber:__LINE__ withFormat:(format), ##__VA_ARGS__]

#define KCSLogNSError(msg, err) \
if (err) { \
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kErrorChannel] file:__FILE__ lineNumber:__LINE__ withFormat:(@"%@; error: (%@) "), msg, err]; \
}

#define KCSLogCache(format,...) \
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kCacheChannel] file:__FILE__ lineNumber:__LINE__ \
withFormat:(format),##__VA_ARGS__]

#define KCSLogForced(format,...) \
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kForcedChannel] file:__FILE__ lineNumber:__LINE__ \
withFormat:(format),##__VA_ARGS__]

#define KCSLogRequestId(format,...) \
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kNetworkChannel] file:__FILE__ lineNumber:__LINE__ \
withFormat:(format),##__VA_ARGS__]

@class KCSLogChannel;

@interface KCSLogManager : NSObject

+ (KCSLogManager *)sharedLogManager;
+ (void) setLogSink:(id<KCSLogSink>)sink;

+ (KCSLogChannel *)kNetworkChannel;
+ (KCSLogChannel *)kDebugChannel;
+ (KCSLogChannel *)kTraceChannel;
+ (KCSLogChannel *)kWarningChannel;
+ (KCSLogChannel *)kErrorChannel;
+ (KCSLogChannel *)kForcedChannel;
+ (KCSLogChannel *)kCacheChannel;

- (void)logChannel: (KCSLogChannel *)channel file:(char *)sourceFile lineNumber: (int)lineNumber withFormat:(NSString *)format, ...;

- (void)configureLoggingWithNetworkEnabled: (BOOL)networkIsEnabled
                              debugEnabled: (BOOL)debugIsEnabled
                              traceEnabled: (BOOL)traceIsEnabled
                            warningEnabled: (BOOL)warningIsEnabled
                              errorEnabled: (BOOL)errorIsEnabled;



@end
