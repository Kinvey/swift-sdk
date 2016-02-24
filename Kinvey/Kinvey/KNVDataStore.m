//
//  KNVDataStore.m
//  Kinvey
//
//  Created by Victor Barros on 2016-02-23.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KNVDataStore.h"
#import <Kinvey/Kinvey-Swift.h>

@implementation KNVDataStore

-(id<KNVRequest>)findById:(NSString *)objectId
        completionHandler:(void (^)(NSObject<KNVPersistable> * _Nullable, NSError * _Nullable))completionHandler
{
    return nil;
}

-(id<KNVRequest>)find:(void (^)(NSArray<NSObject<KNVPersistable>*> * _Nullable, NSError * _Nullable))completionHandler
{
    return [self find:[KNVQuery new]
    completionHandler:completionHandler];
}

-(id<KNVRequest>)find:(KNVQuery *)query
    completionHandler:(void (^)(NSArray<NSObject<KNVPersistable>*>* _Nullable, NSError * _Nullable))completionHandler
{
    return nil;
}

@end
