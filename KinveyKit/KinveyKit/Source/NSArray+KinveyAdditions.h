//
//  NSArray+KinveyAdditions.h
//  KinveyKit
//
//  Created by Michael Katz on 5/11/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

@interface NSArray (KinveyAdditions)

+ (NSArray*) wrapIfNotArray:(id)object;
+ (NSArray*) arrayWithObjectOrNil:(id) object;
+ (NSArray*) arrayIfDictionary:(id)object;

- (NSString*) join:(NSString*)delimiter;

@end
