//
//  KCSWebView.m
//  KinveyKit
//
//  Created by Michael Katz on 3/6/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "KCSWebView.h"

@implementation WebView (KCSWebView)

- (void)setDelegate:(id)delegate
{
    self.UIDelegate = delegate;
}

- (id)delegate
{
    return self.UIDelegate;
}

- (void) loadRequest:(NSURLRequest*)request
{
    [self setMainFrameURL:request.URL.absoluteString];
}

//TODO: handle uiwebviewdelegate methods

@end
