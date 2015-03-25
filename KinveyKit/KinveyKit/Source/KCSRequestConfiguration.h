//
//  KCSRequestConfiguration.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-03-20.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCSRequestConfiguration : NSObject

@property (nonatomic, strong) NSString *clientAppVersion;
@property (nonatomic, strong) NSDictionary *customRequestProperties;

+(instancetype)requestConfigurationWithClientAppVersion:(NSString*)clientAppVersion
                             andCustomRequestProperties:(NSDictionary*)customRequestProperties;

-(instancetype)initWithClientAppVersion:(NSString*)clientAppVersion
             andCustomRequestProperties:(NSDictionary*)customRequestProperties;

@end
