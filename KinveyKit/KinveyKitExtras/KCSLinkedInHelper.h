//
//  KCSLinkedInHelper.h
//  KinveyKit
//
//  Created by Michael Katz on 12/6/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "KCSUser+SocialExtras.h"

@interface KCSLinkedInHelper : NSObject

@property (nonatomic, copy) NSString* apiKey;
@property (nonatomic, copy) NSString* secretKey;
@property (nonatomic, copy) NSString* acceptRedirect;
@property (nonatomic, copy) NSString* cancelRedirect;

@property (nonatomic, retain) UIWebView* webview;

- (void) requestToken:(NSString*)linkedInScope completionBlock:(KCSLocalCredentialBlock)completionBlock;

@end
