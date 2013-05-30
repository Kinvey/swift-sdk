//
//  KCSCustomEndpoints.h
//  KinveyKit
//
//  Created by Michael Katz on 5/30/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCSCustomEndpoints : NSObject

+ (void) callEndpoint:(NSString*)endpoint params:(NSDictionary*)params completionBlock:(void (^)(id results, NSError* error))completionBlock;

@end
