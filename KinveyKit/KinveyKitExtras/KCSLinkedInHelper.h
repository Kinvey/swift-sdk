//
//  KCSLinkedInHelper.h
//  KinveyKit
//
//  Created by Michael Katz on 12/6/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
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
