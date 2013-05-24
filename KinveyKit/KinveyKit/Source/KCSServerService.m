//
//  KCSServerService.m
//  KinveyKit
//
//  Created by Michael Katz on 5/23/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "KCSServerService.h"

#import "KCSAsyncConnection2.h"

@implementation KCSServerService

- (void)startRequest:(KCSNetworkRequest*)request
{
    KCSAsyncConnection2* cxn = [[KCSAsyncConnection2 alloc] init];
    [cxn performRequest:request.nsurlRequest progressBlock:^(KCSConnectionProgress *progress) {
        //TODO
    } completionBlock:^(KCSConnectionResponse *response) {
        //TODO
    } failureBlock:^(NSError *error) {
        //TODO
    }];
}

@end
