//
//  NSDictionary+KinveyAdditions.h
//  KinveyKit
//
//  Created by Michael Katz on 3/14/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (KinveyAdditions)
- (NSDictionary*) stripKeys:(NSArray*)keys;

@end
