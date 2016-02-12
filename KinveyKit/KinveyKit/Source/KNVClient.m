//
//  KNVClient.m
//  Kinvey
//
//  Created by Victor Barros on 2016-02-12.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KNVClient.h"

@implementation KNVClient

-(instancetype)initWithAppKey:(NSString *)appKey
                    appSecret:(NSString *)appSecret
                  apiHostName:(NSURL *)apiHostName
                 authHostName:(NSURL *)authHostName
{
    self = [super init];
    if (self) {
        self.appKey = appKey;
        self.appSecret = appSecret;
        self.apiHostName = apiHostName;
        self.authHostName = authHostName;
    }
    return self;
}

@end
