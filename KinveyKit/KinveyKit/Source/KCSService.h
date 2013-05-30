//
//  KCSService.h
//  KinveyKit
//
//  Created by Michael Katz on 5/23/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "KCSRequest.h"
#import "KinveyBlocks.h"
@protocol KCSService <NSObject>

//TODO:
//- (void) startRequest:(KCSNetworkRequest*)request;


- (void)performRequest:(NSURLRequest *)theRequest
         progressBlock:(KCSConnectionProgressBlock)onProgress
       completionBlock:(KCSConnectionCompletionBlock)onCompletion
          failureBlock:(KCSConnectionFailureBlock)onFailure;
@end

