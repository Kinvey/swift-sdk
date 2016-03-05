//
//  KNVRequest.h
//  Kinvey
//
//  Created by Victor Barros on 2016-03-04.
//  Copyright © 2016 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol KNVRequest <NSObject>

@property (nonatomic, readonly) BOOL executing;
@property (nonatomic, readonly) BOOL canceled;
- (void)cancel;

@end
