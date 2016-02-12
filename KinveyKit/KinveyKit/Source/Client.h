//
//  Client.h
//  Kinvey
//
//  Created by Victor Barros on 2016-02-12.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Client : NSObject

@property NSString* appKey;
@property NSString* appSecret;
@property NSURL* authHostName;
@property NSURL* apiHostName;
@property NSUInteger cachePolicy;
@property NSTimeInterval timeoutInterval;
@property NSString* clientAppVersion;
@property NSDictionary<NSString*, NSObject*>* customRequestProperties;
@property NSString* authorizationHeader;

-(instancetype)initWithAppKey:(NSString*)appKey
                    appSecret:(NSString*)appSecret
                  apiHostName:(NSURL*)apiHostName
                 authHostName:(NSURL*)authHostName;

@end
