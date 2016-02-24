//
//  KNVReadOperation.h
//  Kinvey
//
//  Created by Victor Barros on 2016-02-23.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KNVReadPolicy.h"
#import "KNVOperation.h"
#import "KNVRequest.h"

@interface KNVReadOperation<T : NSObject<KNVPersistable>*, R> : KNVOperation<T>

@property (nonatomic, assign) KNVReadPolicy readPolicy;

-(id<KNVRequest> __nonnull)execute:(void (^ __nullable)(R __nullable, NSError* __nullable))completionHandler;
-(id<KNVRequest> __nonnull)executeLocal:(void (^ __nullable)(R __nullable, NSError* __nullable))completionHandler;
-(id<KNVRequest> __nonnull)executeNetwork:(void (^ __nullable)(R __nullable, NSError* __nullable))completionHandler;

@end
