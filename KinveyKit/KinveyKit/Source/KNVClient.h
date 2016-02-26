//
//  KNVClient.h
//  Kinvey
//
//  Created by Victor Barros on 2016-02-25.
//  Copyright © 2016 Kinvey. All rights reserved.
//

@import Foundation;

@protocol KNVClient <NSObject>

+ (__nonnull instancetype)sharedClient;
@property (nonatomic, readonly, copy) NSString * __nullable appKey;
@property (nonatomic, readonly, copy) NSString * __nullable appSecret;
@property (nonatomic, readonly, strong) NSURL * __nonnull apiHostName;
@property (nonatomic, readonly, strong) NSURL * __nonnull authHostName;
@property (nonatomic) NSURLRequestCachePolicy cachePolicy;
@property (nonatomic) NSTimeInterval timeoutInterval;
@property (nonatomic, copy) NSString * __nullable clientAppVersion;
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> * __nonnull customRequestProperties;
+ (NSURL * __nonnull)defaultApiHostName;
+ (NSURL * __nonnull)defaultAuthHostName;
- (nonnull instancetype)init;
+ (void)initialize;
- (nonnull instancetype)initWithAppKey:(NSString * __nonnull)appKey appSecret:(NSString * __nonnull)appSecret apiHostName:(NSURL * __nonnull)apiHostName authHostName:(NSURL * __nonnull)authHostName;
- (__nonnull instancetype)initializeWithAppKey:(NSString * __nonnull)appKey appSecret:(NSString * __nonnull)appSecret apiHostName:(NSURL * __nonnull)apiHostName authHostName:(NSURL * __nonnull)authHostName;
@property (nonatomic, readonly, copy) NSString * __nullable authorizationHeader;

@end
