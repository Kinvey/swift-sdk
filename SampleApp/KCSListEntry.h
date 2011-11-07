//
//  KCSListEntry.h
//  SampleApp
//
//  Created by Brian Wilson on 11/4/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCSListEntry : NSObject

@property (retain) NSString *name;
@property (retain) UIImage *image;
@property (retain) NSString *imagePath;

- (id)init;
- (id)initWithName: (NSString *)name;

- (BOOL) hasCustomImage;


@end
