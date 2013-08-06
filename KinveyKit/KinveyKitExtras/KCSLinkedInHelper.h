//
//  KCSLinkedInHelper.h
//  KinveyKit
//
//  Created by Michael Katz on 12/6/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
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

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "KCSUser+SocialExtras.h"

@interface KCSLinkedInHelper : NSObject

@property (nonatomic, copy) NSString* apiKey;
@property (nonatomic, copy) NSString* secretKey;
@property (nonatomic, copy) NSString* acceptRedirect;
@property (nonatomic, copy) NSString* cancelRedirect;

#if TARGET_OS_IPHONE
@property (nonatomic, strong) UIWebView* webview;
#else
@property (nonatomic, strong) WebView* webview;
#endif

- (void) requestToken:(NSString*)linkedInScope completionBlock:(KCSLocalCredentialBlock)completionBlock;

@end
