//
//  PropertyUtil.h
//  KinveyKit
//
//  Created by Michael Katz on 6/4/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCSPropertyUtil.h"

@interface KCSPropertyUtil : NSObject

+ (NSDictionary *)classPropsFor:(Class)klass;

@end
