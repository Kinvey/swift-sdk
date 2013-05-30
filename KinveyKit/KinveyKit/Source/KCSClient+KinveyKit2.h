//
//  KCSClient+KinveyKit2.h
//  KinveyKit
//
//  Created by Michael Katz on 5/30/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import <KinveyKit/KinveyKit.h>

@protocol KCSRequestInfoProvider <NSObject>

- (NSString*) kid;
- (NSString*) baseURL;

@end

@interface KCSClient (KinveyKit2) <KCSRequestInfoProvider>

@end
