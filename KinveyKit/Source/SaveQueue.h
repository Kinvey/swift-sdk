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

@class KCSSerializedObject;

//TODO: 
@interface SaveQueueItem : NSObject
@property (nonatomic, retain) NSDate* mostRecentSaveDate;
@property (nonatomic, retain) KCSSerializedObject* object;
@end

@interface SaveQueue : NSObject
@property (nonatomic, assign) id<KCSOfflineSaveDelegate> delegate;

+ (SaveQueue*) saveQueueForCollection:(NSString*)collectionName;

- (void) addObject:(KCSSerializedObject*)obj;
- (NSArray*) ids;
- (NSOrderedSet*) set;
- (NSUInteger) count;
@end
