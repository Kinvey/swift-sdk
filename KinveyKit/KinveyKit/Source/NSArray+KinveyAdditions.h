//
//  NSArray+KinveyAdditions.h
//  KinveyKit
//
//  Created by Michael Katz on 5/11/12.
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//

@interface NSArray (KinveyAdditions)

+ (instancetype) wrapIfNotArray:(id)object;
+ (instancetype) arrayWithObjectOrNil:(id) object;
+ (instancetype) arrayIfDictionary:(id)object;
+ (instancetype) arrayWith:(NSUInteger)num copiesOf:(id<NSCopying>)val;

- (instancetype) arrayByPercentEncoding;
- (NSString*) join:(NSString*)delimiter;

@end
