//
//  KCSImageUtils.h
//  KinveyKit
//
//  Created by Michael Katz on 1/29/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#define ImageClass UIImage
#else
#define ImageClass NSImage
#endif

@interface KCSImageUtils : NSObject

+ (ImageClass*) imageWithData:(NSData*)data;
+ (NSData*) dataFromImage:(ImageClass*)image;

@end
