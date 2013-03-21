//
//  SaveQueue.h
//  KinveyKit
//
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//
//  This software contains valuable confidential and proprietary information of
//  KINVEY, INC and is subject to applicable licensing agreements.
//  Unauthorized reproduction, transmission or distribution of this file and its
//  contents is a violation of applicable laws.

#import <Foundation/Foundation.h>
#import "KCSBlockDefs.h"
#import "KCSOfflineSaveStore.h"

@class KCSCollection;

@interface KCSSaveQueueItem : NSObject
@property (nonatomic, strong) NSDate* mostRecentSaveDate;
@property (nonatomic, strong) id<KCSPersistable> object;
@end

@interface KCSSaveQueue : NSObject <NSCoding>
@property (nonatomic, unsafe_unretained) id<KCSOfflineSaveDelegate> delegate;

+ (KCSSaveQueue*) saveQueueForCollection:(KCSCollection*)collection uniqueIdentifier:(NSString*)identifier;

- (void) addObject:(id<KCSPersistable>)obj;
- (void) removeItem:(KCSSaveQueueItem*)item;
- (NSArray*) ids;
- (NSArray*) array;
- (NSUInteger) count;
@end
