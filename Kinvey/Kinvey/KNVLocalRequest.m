//
//  KNVLocalRequest.m
//  Kinvey
//
//  Created by Victor Barros on 2016-02-23.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import "KNVLocalRequest.h"

@implementation KNVLocalRequest

-(BOOL)isExecuting
{
    return NO;
}

-(BOOL)isCanceled
{
    return NO;
}

-(void)execute:(void (^)())completionHandler
{
    if (completionHandler) completionHandler();
}

-(void)cancel
{
    //do nothing
}

@end
