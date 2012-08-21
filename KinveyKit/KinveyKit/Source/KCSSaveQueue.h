//
//  SaveQueue.h
//  KinveyKit
//
//  Created by Michael Katz on 8/7/12.
//  Copyright (c) 2012 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCSBlockDefs.h"
#import "KCSOfflineSaveStore.h"

@class KCSCollection;

@interface KCSSaveQueueItem : NSObject
@property (nonatomic, retain) NSDate* mostRecentSaveDate;
@property (nonatomic, retain) id<KCSPersistable> object;
@end

@interface KCSSaveQueue : NSObject
@property (nonatomic, assign) id<KCSOfflineSaveDelegate> delegate;

+ (KCSSaveQueue*) saveQueueForCollection:(KCSCollection*)collection uniqueIdentifier:(NSString*)identifier;

- (void) addObject:(id<KCSPersistable>)obj;
- (void) removeItem:(KCSSaveQueueItem*)item;
- (NSArray*) ids;
- (NSArray*) array;
- (NSUInteger) count;
@end
