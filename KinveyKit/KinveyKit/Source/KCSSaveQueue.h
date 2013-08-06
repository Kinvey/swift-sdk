//
//  SaveQueue.h
//  KinveyKit
//
//  Copyright (c) 2012-2013 Kinvey. All rights reserved.
//
// This software is licensed to you under the Kinvey terms of service located at
// http://www.kinvey.com/terms-of-use. By downloading, accessing and/or using this
// software, you hereby accept such terms of service  (and any agreement referenced
// therein) and agree that you have read, understand and agree to be bound by such
// terms of service and are of legal age to agree to such terms with Kinvey.
//
// This software contains valuable confidential and proprietary information of
// KINVEY, INC and is subject to applicable licensing agreements.
// Unauthorized reproduction, transmission or distribution of this file and its
// contents is a violation of applicable laws.
//

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
