//
//  KCSClient2.h
//  KinveyKit
//
//  Created by Michael Katz on 9/11/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KCSClientConfiguration;

@interface KCSClient2 : NSObject

+ (instancetype) sharedClient;

@property (nonatomic, strong) KCSClientConfiguration* configuration;

@end
