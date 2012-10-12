//
//  NSMutableDictionary+KinveyAdditions.h
//  KinveyKit
//
//  Created by Michael Katz on 10/9/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableDictionary (KinveyAdditions)
- (id) popObjectForKey:(id) key;
- (void) append:(NSString*)appendant ontoKeySet:(NSArray*)keys recursive:(BOOL) recursive;
@end
