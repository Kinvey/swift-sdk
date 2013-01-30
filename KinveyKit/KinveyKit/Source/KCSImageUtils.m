//
//  KCSImageUtils.m
//  KinveyKit
//
//  Created by Michael Katz on 1/29/13.
//  Copyright (c) 2013 Kinvey. All rights reserved.
//

#import "KCSImageUtils.h"

@implementation KCSImageUtils

#if TARGET_OS_IPHONE

+ (ImageClass*) imageWithData:(NSData*)data
{
     return [UIImage imageWithData:data];
}

+ (NSData*) dataFromImage:(ImageClass*)image
{
    return UIImagePNGRepresentation(image);
}

#else
+ (ImageClass*) imageWithData:(NSData*)data
{
    return [NSImage imageWithData:data];
}

+ (NSData*) dataFromImage:(ImageClass*)image
{
    NSData *imageData = [image TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    imageData = [imageRep representationUsingType:NSPNGFileType properties:nil];
    return imageData;
}


#endif



@end
