//
//  PropertyUtil.h
//  KinveyKit
//
//  Created by Michael Katz on 6/4/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PropertyUtil.h"

@interface PropertyUtil : NSObject

+ (NSDictionary *)classPropsFor:(Class)klass;

@end