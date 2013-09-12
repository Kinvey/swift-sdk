//
//  KCSLog.h
//  KinveyKit
//
//  Created by Michael Katz on 8/7/13.
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

#ifndef KinveyKit_KCSLog_h
#define KinveyKit_KCSLog_h

#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDTTYLogger.h"

// We want to use the following log levels:
//
// Fatal
// Error
// Warn
// Notice
// Info
// Debug
//
// All we have to do is undefine the default values,
// and then simply define our own however we want.

// First undefine the default stuff we don't want to use.

#undef LOG_FLAG_ERROR
#undef LOG_FLAG_WARN
#undef LOG_FLAG_INFO
#undef LOG_FLAG_VERBOSE

#undef LOG_LEVEL_ERROR
#undef LOG_LEVEL_WARN
#undef LOG_LEVEL_INFO
#undef LOG_LEVEL_VERBOSE

#undef LOG_ERROR
#undef LOG_WARN
#undef LOG_INFO
#undef LOG_VERBOSE

#undef DDLogError//(frmt, ...)
#undef DDLogWarn//(frmt, ...)
#undef DDLogInfo//(frmt, ...)
#undef DDLogVerbose//(frmt, ...)

#undef DDLogCError//(frmt, ...)
#undef DDLogCWarn//(frmt, ...)
#undef DDLogCInfo//(frmt, ...)
#undef DDLogCVerbose//(frmt, ...)

// Now define everything how we want it

#define KINVEY_KIT_LOG_CONTEXT 2110

#define LOG_FLAG_FATAL   (1 << 0)  // 0...000001
#define LOG_FLAG_ERROR   (1 << 1)  // 0...000010
#define LOG_FLAG_WARN    (1 << 2)  // 0...000100
#define LOG_FLAG_NOTICE  (1 << 3)  // 0...001000
#define LOG_FLAG_INFO    (1 << 4)  // 0...010000
#define LOG_FLAG_DEBUG   (1 << 5)  // 0...100000

#define LOG_LEVEL_FATAL   (LOG_FLAG_FATAL)                     // 0...000001
#define LOG_LEVEL_ERROR   (LOG_FLAG_ERROR  | LOG_LEVEL_FATAL ) // 0...000011
#define LOG_LEVEL_WARN    (LOG_FLAG_WARN   | LOG_LEVEL_ERROR ) // 0...000111
#define LOG_LEVEL_NOTICE  (LOG_FLAG_NOTIC¡E | LOG_LEVEL_WARN  ) // 0...001111
#define LOG_LEVEL_INFO    (LOG_FLAG_INFO   | LOG_LEVEL_NOTICE) // 0...011111
#define LOG_LEVEL_DEBUG   (LOG_FLAG_DEBUG  | LOG_LEVEL_INFO  ) // 0...111111

//TODO:
#define ddLogLevel 255

#define LOG_FATAL   (ddLogLevel & LOG_FLAG_FATAL )
#define LOG_ERROR   (ddLogLevel & LOG_FLAG_ERROR )
#define LOG_WARN    (ddLogLevel & LOG_FLAG_WARN  )
#define LOG_NOTICE  (ddLogLevel & LOG_FLAG_NOTICE)
#define LOG_INFO    (ddLogLevel & LOG_FLAG_INFO  )
#define LOG_DEBUG   (ddLogLevel & LOG_FLAG_DEBUG )

#define KCS_STR_APPEND(a,b) [a stringByAppendingString:b]

#define KCSLogFatal(frmt, ...)    SYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_FATAL,  KINVEY_KIT_LOG_CONTEXT, KCS_STR_APPEND(@"[FATAL] ",frmt), ##__VA_ARGS__)
#define KCSLogError(frmt, ...)    SYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_ERROR,  KINVEY_KIT_LOG_CONTEXT, KCS_STR_APPEND(@"[ERROR] ",frmt), ##__VA_ARGS__)
#define KCSLogWarn(frmt, ...)    ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_WARN,   KINVEY_KIT_LOG_CONTEXT, KCS_STR_APPEND(@"[WARN] ",frmt), ##__VA_ARGS__)
#define KCSLogNotice(frmt, ...)  ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_NOTICE, KINVEY_KIT_LOG_CONTEXT, KCS_STR_APPEND(@"[NOTICE] ",frmt), ##__VA_ARGS__)
#define KCSLogInfo(frmt, ...)    ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_INFO,   KINVEY_KIT_LOG_CONTEXT, KCS_STR_APPEND(@"[INFO] ",frmt), ##__VA_ARGS__)
#define KCSLogDebug(frmt, ...)   ASYNC_LOG_OBJC_MAYBE(ddLogLevel, LOG_FLAG_DEBUG,  KINVEY_KIT_LOG_CONTEXT, KCS_STR_APPEND(@"[DEBUG] ",frmt), ##__VA_ARGS__)

#endif
