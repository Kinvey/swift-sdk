//
//  KCSDataStoreCaches.h
//  KinveyKit
//
//  Created by Michael Katz on 5/23/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCSEntityCache2.h"

@interface KCSDataStoreCaches : NSObject
+ (KCSEntityCache2*)cacheForCollection:(NSString*)collection;
@end
