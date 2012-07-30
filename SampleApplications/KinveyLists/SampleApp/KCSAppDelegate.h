//
//  KCSAppDelegate.h
//  SampleApp
//
//  Created by Brian Wilson on 10/24/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KCSClient;

@interface KCSAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) NSMutableDictionary *imageCache;

@end
