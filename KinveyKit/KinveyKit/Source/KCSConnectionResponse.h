//
//  KCSConnectionResponse.h
//  KinveyKit
//
//  Created by Brian Wilson on 11/23/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCSConnectionResponse : NSObject

@property (readonly) NSInteger responseCode; // See KinveyHTTPSStatusCodes for definitions
@property (retain, readonly) NSData *responseData;
@property (retain, readonly) NSDictionary *userData;

+ (KCSConnectionResponse *)connectionResponseWithCode:(NSInteger)code responseData:(NSData *)data userData:(NSDictionary *)userDefinedData; 

@end
