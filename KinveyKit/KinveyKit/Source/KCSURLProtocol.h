//
//  KCSURLProtocol.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-03-20.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCSURLProtocol : NSURLProtocol

+(BOOL)registerClass:(Class)protocolClass;

+(void)unregisterClass:(Class)protocolClass;

+(NSArray*)protocolClasses;

@end
