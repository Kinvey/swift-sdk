//
//  KCSRequest.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-08-26.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^KCSRequestCancelationBlock)();

@interface KCSRequest : NSObject

@property (readonly, getter=isCancelled) BOOL cancelled;
@property (copy) KCSRequestCancelationBlock cancellationBlock;

-(void)cancel;

@end
