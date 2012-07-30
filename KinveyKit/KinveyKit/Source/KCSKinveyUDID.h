//
//  KCSKinveyUDID.h
//  KinveyKit
//
//  Created by Brian Wilson on 3/28/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCSKinveyUDID : NSObject

+ (NSString *)uniqueIdentifier;
+ (NSString *)uniqueIdentifierFromOpenUDID;
+ (NSString *)uniqueIdentifierFromSecureUDID;

@end
