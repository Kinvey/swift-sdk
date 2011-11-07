//
//  KCSList.h
//  SampleApp
//
//  Created by Brian Wilson on 11/4/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KCSListEntry;

@interface KCSList : NSObject

@property (retain) NSMutableArray *entries;
@property (retain) NSString *name;
@property (retain) UIImage *listImage;


- (id)initWithName: (NSString *)name withList: (NSMutableArray *)list;


- (BOOL)hasCustomImage;


- (id)objectAtIndex: (NSUInteger)index;
- (NSUInteger)count;


@end
