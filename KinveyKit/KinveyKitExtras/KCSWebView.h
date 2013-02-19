//
//  KCSWebView.h
//  KinveyKit
//
//  Created by Michael Katz on 2/7/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#ifndef KinveyKit_KCSWebView_h
#define KinveyKit_KCSWebView_h

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#define KCSWebViewClass UIWebView
#else
#define KCSWebViewClass WebView
#import <WebKit/WebKit.h>
#endif


#endif
