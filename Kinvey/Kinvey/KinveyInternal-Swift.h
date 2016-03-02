//
//  KinveyInternal-Swift.h
//  Kinvey
//
//  Created by Victor Barros on 2016-03-01.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Kinvey/Kinvey-Swift.h>

SWIFT_CLASS_NAMED("EntitySchema")
@interface KNVEntitySchema : NSObject
@property (nonatomic, readonly) Class <KNVPersistable> __nonnull persistableType;
@property (nonatomic, readonly) Class __nonnull anyClass;
@property (nonatomic, readonly, copy) NSString * __nonnull collectionName;
+ (KNVEntitySchema * __nullable)entitySchema:(Class __nonnull)type;
@end
