//
//  KCSLogManager.h
//  KinveyKit
//
//  Created by Brian Wilson on 1/11/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

// Convenience Macros
#if KINVEY_DEBUG_ENABLED

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
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kErrorChannel] file:__FILE__ lineNumber:__LINE__ \
withFormat:(format),##__VA_ARGS__]

#else

#define KCSLog(channel,format,...)
#define KCSLogNetwork(format,...)
#define KCSLogDebug(format,...)
#define KCSLogTrace(format,...)
#define KCSLogWarning(format,...)
#define KCSLogError(format,...)

#endif

#define KCSLogForced(format,...) \
[[KCSLogManager sharedLogManager] logChannel:[KCSLogManager kForcedChannel] file:__FILE__ lineNumber:__LINE__ \
withFormat:(format),##__VA_ARGS__]


@class KCSLogChannel;

@interface KCSLogManager : NSObject

+ (KCSLogManager *)sharedLogManager;

+ (KCSLogChannel *)kNetworkChannel;
+ (KCSLogChannel *)kDebugChannel;
+ (KCSLogChannel *)kTraceChannel;
+ (KCSLogChannel *)kWarningChannel;
+ (KCSLogChannel *)kErrorChannel;
+ (KCSLogChannel *)kForcedChannel;


- (void)logChannel: (KCSLogChannel *)channel file:(char *)sourceFile lineNumber: (int)lineNumber withFormat:(NSString *)format, ...;

- (void)configureLoggingWithNetworkEnabled: (BOOL)networkIsEnabled
                              debugEnabled: (BOOL)debugIsEnabled
                              traceEnabled: (BOOL)traceIsEnabled
                            warningEnabled: (BOOL)warningIsEnabled
                              errorEnabled: (BOOL)errorIsEnabled;



@end
