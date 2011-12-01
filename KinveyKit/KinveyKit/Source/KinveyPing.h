//
//  KinveyPing.h
//  KinveyKit
//
//  Created by Brian Wilson on 11/30/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCSPingResult : NSObject

@property (readonly, nonatomic) NSString *description;
@property (readonly, nonatomic) BOOL pingWasSuccessful;

- (id)initWithDescription: (NSString *)description withResult: (BOOL)result;

@end

typedef void(^KCSPingBlock)(KCSPingResult *result);

@interface KCSPing : NSObject
+ (void)pingKinveyWithBlock:(KCSPingBlock)completionAction;
@end
