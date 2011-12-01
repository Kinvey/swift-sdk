//
//  KCSList.h
//  SampleApp
//
//  Created by Brian Wilson on 11/4/11.
//  Copyright (c) 2011 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <KinveyKit/KinveyKit.h>

@class KCSListEntry;

@interface KCSList : NSObject <KCSPersistable>

@property (retain) NSMutableArray *entries;
@property (retain) NSString *listId;
@property (retain) NSString *name;
@property (retain) NSString *image;
@property (retain) UIImage *listImage;


- (id)initWithName: (NSString *)name withList: (NSMutableArray *)list;


- (BOOL)hasCustomImage;


- (id)objectAtIndex: (NSUInteger)index;
- (NSUInteger)count;


@end
